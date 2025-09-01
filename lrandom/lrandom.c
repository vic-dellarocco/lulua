/*
* lrandom.c
* random-number library for Lua based on the Mersenne Twister
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 27 Jul 2018 09:24:52
* This code is hereby placed in the public domain and also under the MIT license
*/

#include <math.h>

#include "lua.h"
#include "lauxlib.h"
#include "mycompat.h"

#include "random.c"

#define MYNAME		"random"
#define MYVERSION	MYNAME " library for " LUA_VERSION " / Jul 2018 / "\
			"using " AUTHOR
#define MYTYPE		MYNAME " handle"

#define SEED		2018UL

static MT *Pget(lua_State *L, int i)
{
 return luaL_checkudata(L,i,MYTYPE);
}

static MT *Pnew(lua_State *L)
{
 MT *c=lua_newuserdata(L,sizeof(MT));
 luaL_setmetatable(L,MYTYPE);
 return c;
}

static int Lnew(lua_State *L)			/** new([seed]) */
{
 lua_Number seed=luaL_optnumber(L,1,SEED);
 MT *c=Pnew(L);
 init_genrand(c,seed);
 return 1;
}

static int Lclone(lua_State *L)			/** clone(c) */
{
 MT *c=Pget(L,1);
 MT *d=Pnew(L);
 *d=*c;
 return 1;
}

static int Lseed(lua_State *L)			/** seed(c,[seed]) */
{
 MT *c=Pget(L,1);
 init_genrand(c,luaL_optnumber(L,2,SEED));
 lua_settop(L,1);
 return 1;
}

static int Lvalue(lua_State *L)			/** value(c,[a,b]) */
{
 MT *c=Pget(L,1);
 double a,b,r=genrand(c);
 switch (lua_gettop(L))
 {
  case 1:
   lua_pushnumber(L,r);
   return 1;
  case 2:
   a=1;
   b=luaL_checknumber(L,2);
   break;
  default:
   a=luaL_checknumber(L,2);
   b=luaL_checknumber(L,3);
   break;
 }
 if (a>b) { double t=a; a=b; b=t; }
 a=ceil(a);
 b=floor(b);
 if (a>b) return 0;
 r=a+floor(r*(b-a+1));
 lua_pushnumber(L,r);
 return 1;
}

#if LUA_VERSION_NUM <= 502
static int Ltostring(lua_State *L)
{
 lua_pushfstring(L,"%s: %p",MYTYPE,(void*)Pget(L,1));
 return 1;
}
#define MYTOSTRING {"__tostring",Ltostring},
#else
#define MYTOSTRING
#endif

static const luaL_Reg R[] =
{
	MYTOSTRING
	{ "clone",	Lclone		},
	{ "new",	Lnew		},
	{ "seed",	Lseed		},
	{ "value",	Lvalue		},
	{ NULL,		NULL		}
};

LUALIB_API int luaopen_random(lua_State *L)
{
 luaL_newmetatable(L,MYTYPE);
 luaL_setfuncs(L,R,0);
 lua_pushliteral(L,"version");			/** version */
 lua_pushliteral(L,MYVERSION);
 lua_settable(L,-3);
 lua_pushliteral(L,"__index");
 lua_pushvalue(L,-2);
 lua_settable(L,-3);
 lua_pushliteral(L,"__call");			/** __call(c) */
 lua_pushliteral(L,"value");
 lua_gettable(L,-3);
 lua_settable(L,-3);
 return 1;
}
