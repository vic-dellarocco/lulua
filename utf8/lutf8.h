/*
** $Id: lprefix.h,v 1.2 2014/12/29 16:54:13 roberto Exp $
** Definitions for Lua code that must come before any other header file
** See Copyright Notice in lua.h
*/

#ifndef lutf8_h
#define lutf8_h


/*
** Allows POSIX/XSI stuff
*/
#if !defined(LUA_USE_C89)	/* { */

#if !defined(_XOPEN_SOURCE)
#define _XOPEN_SOURCE           600
#elif _XOPEN_SOURCE == 0
#undef _XOPEN_SOURCE  /* use -D_XOPEN_SOURCE=0 to undefine it */
#endif

/*
** Allows manipulation of large files in gcc and some other compilers
*/
#if !defined(LUA_32BITS) && !defined(_FILE_OFFSET_BITS)
#define _LARGEFILE_SOURCE       1
#define _FILE_OFFSET_BITS       64
#endif

#endif				/* } */


/*
** Windows stuff
*/
#if defined(_WIN32) 	/* { */

#if !defined(_CRT_SECURE_NO_WARNINGS)
#define _CRT_SECURE_NO_WARNINGS  /* avoid warnings about ISO C functions */
#endif

#endif			/* } */


/* COMPAT53 adaptation */
#include "c-api/compat-5.3.h"

#undef LUAMOD_API
#define LUAMOD_API extern


#ifdef lutf8lib_c
// #  define luaopen_utf8 luaopen_compat53_utf8
/* we don't support the %U format string of lua_pushfstring!
 * code below adapted from the Lua 5.3 sources:
 */
static const char *compat53_utf8_escape (lua_State* L, long x) {
  if (x < 0x80) { /* ASCII */
    char c = (char)x;
    lua_pushlstring(L, &c, 1);
  } else {
    char buff[8] = { 0 };
    unsigned int mfb = 0x3f;
    int n = 1;
    do {
      buff[8 - (n++)] = (char)(0x80|(x & 0x3f));
      x >>= 6;
      mfb >>= 1;
    } while (x > mfb);
    buff[8-n] = (char)((~mfb << 1) | x);
    lua_pushlstring(L, buff+8-n, n);
  }
  return lua_tostring(L, -1);
}
#  define lua_pushfstring(L, fmt, l) \
  compat53_utf8_escape(L, l)
#endif


#endif //lutf8_h
