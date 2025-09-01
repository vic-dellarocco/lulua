/*
* lint64.c
* 64-bit integers for Lua
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 30 Jul 2018 14:04:27
* This code is hereby placed in the public domain and also under the MIT license
*/

#include <limits.h>
#include <stdlib.h>

#define Int		long long
#define FMT		"%lld"
#define atoI		atoll

#include "lua.h"
#include "lauxlib.h"
#include "mycompat.h"

#define MYNAME		"int64"
#define MYTYPE		MYNAME
#define MYVERSION	MYTYPE " library for " LUA_VERSION " / Jul 2018"

#define Z(i)		Pget(L,i)
#define	I(x)		((Int)(x))

static int Pnew(lua_State *L, Int z)
{
 Int *p=lua_newuserdata(L,sizeof(Int));
 luaL_setmetatable(L,MYTYPE);
 *p=z;
 return 1;
}

static Int Pget(lua_State *L, int i)
{
 luaL_checkany(L,i);
 switch (lua_type(L,i))
 {
  case LUA_TNUMBER:
   return luaL_checknumber(L,i);
  case LUA_TSTRING:
   return atoI(luaL_checkstring(L,i));
  default:
   return *((Int*)luaL_checkudata(L,i,MYTYPE));
 }
}

static int Ltostring(lua_State *L)		/** tostring(z) */
{
 char b[64];
 sprintf(b,FMT,Z(1));
 lua_pushstring(L,b);
 return 1;
}

static int Ltonumber(lua_State *L)		/** tonumber(z) */
{
 lua_pushnumber(L,(lua_Number)Z(1));
 return 1;
}

static int Ldiv(lua_State *L)			/** __div(z,w) */
{
 Int z=Z(1);
 Int w=Z(2);
 if (w==0) return luaL_error(L, "attempt to divide by zero");
 return Pnew(L,z/w);
}

static int Lpow(lua_State *L)			/** __pow(z,n) */
{
 Int z=Z(1);
 Int n=Z(2);
 Int r;
 if (n<0) return luaL_error(L,"exponent cannot be negative");
 if (z==I(2))
  r= (n>=I(8*sizeof(Int))) ? 0 : (I(1)<<n);
 else
 {
  for (r=1; n>0; n>>=1)
  {
   if (n&1) r*=z;
   z*=z;
  }
 }
 return Pnew(L,r);
}

#define add(z,w)	((z)+(w))
#define sub(z,w)	((z)-(w))
#define mod(z,w)	((z)%(w))
#define mul(z,w)	((z)*(w))
#define neg(z)		(-(z))
#define new(z)		(z)
#define eq(z,w)		((z)==(w))
#define le(z,w)		((z)<=(w))
#define lt(z,w)		((z)<(w))

#define A(f,e)	static int L##f(lua_State *L) { return Pnew(L,e); }
#define C(f,e)	static int L##f(lua_State *L) { lua_pushboolean(L,e); return 1;}
#define B(f)	A(f,f(Z(1),Z(2)))
#define F(f)	A(f,f(Z(1)))
#define T(f)	C(f,f(Z(1),Z(2)))

B(add)			/** __add(z,w) */
B(mod)			/** __mod(z,w) */
B(mul)			/** __mul(z,w) */
B(sub)			/** __sub(z,w) */
F(neg)			/** __unm(z) */
F(new)			/** new(z) */
T(eq)			/** __eq(z,w) */
T(le)			/** __le(z,w) */
T(lt)			/** __lt(z,w) */

static const luaL_Reg R[] =
{
	{ "__add",	Ladd	},
	{ "__div",	Ldiv	},
	{ "__eq",	Leq	},
	{ "__idiv",	Ldiv	},
	{ "__le",	Lle	},
	{ "__lt",	Llt	},
	{ "__mod",	Lmod	},
	{ "__mul",	Lmul	},
	{ "__pow",	Lpow	},
	{ "__sub",	Lsub	},
	{ "__tostring",	Ltostring},		/** __tostring(z) */
	{ "__unm",	Lneg	},
	{ "new",	Lnew	},
	{ "tonumber",	Ltonumber},
	{ "tostring",	Ltostring},
	{ NULL,		NULL	}
};

LUALIB_API int luaopen_int64(lua_State *L)
{
 if (sizeof(Int)<8)
  luaL_error(L,"int64 cannot work with %d-byte values",sizeof(Int));
 luaL_newmetatable(L,MYTYPE);
 luaL_setfuncs(L,R,0);
 lua_pushliteral(L,"version");			/** version */
 lua_pushliteral(L,MYVERSION);
 lua_settable(L,-3);
 lua_pushliteral(L,"min");			/** min */
 Pnew(L,LLONG_MIN);
 lua_settable(L,-3);
 lua_pushliteral(L,"max");			/** max */
 Pnew(L,LLONG_MAX);
 lua_settable(L,-3);
 return 1;
}
