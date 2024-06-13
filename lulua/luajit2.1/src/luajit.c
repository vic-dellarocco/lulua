/*
** LuaJIT frontend. Runs commands, scripts, read-eval-print (REPL) etc.
** Copyright (C) 2005-2023 Mike Pall. See Copyright Notice in luajit.h
**
** Major portions taken verbatim or adapted from the Lua interpreter.
** Copyright (C) 1994-2008 Lua.org, PUC-Rio. See Copyright Notice in lua.h
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define luajit_c

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "luajit.h"

#include "lj_arch.h"

#if LJ_TARGET_POSIX
#include <unistd.h>
#define lua_stdin_is_tty()	isatty(0)
#elif LJ_TARGET_WINDOWS
#include <io.h>
#ifdef __BORLANDC__
#define lua_stdin_is_tty()	isatty(_fileno(stdin))
#else
#define lua_stdin_is_tty()	_isatty(_fileno(stdin))
#endif
#else
#define lua_stdin_is_tty()	1
#endif

#if !LJ_TARGET_CONSOLE
#include <signal.h>
#endif

//VV:
char* LUA_INIT_PATH; //The path of the lua interpreter's init.lua file.
//:VV

static lua_State *globalL = NULL;
static const char *progname = LUA_PROGNAME;
static char *empty_argv[2] = { NULL, NULL };

#if !LJ_TARGET_CONSOLE
static void lstop(lua_State *L, lua_Debug *ar)
{
  (void)ar;  /* unused arg. */
  lua_sethook(L, NULL, 0, 0);
  /* Avoid luaL_error -- a C hook doesn't add an extra frame. */
  luaL_where(L, 0);
  lua_pushfstring(L, "%sinterrupted!", lua_tostring(L, -1));
  lua_error(L);
}

static void laction(int i)
{
  signal(i, SIG_DFL); /* if another SIGINT happens before lstop,
			 terminate process (default action) */
  lua_sethook(globalL, lstop, LUA_MASKCALL | LUA_MASKRET | LUA_MASKCOUNT, 1);
}
#endif

static void print_usage(void)
{
  fputs("usage: ", stderr);
  fputs(progname, stderr);
  fputs(" [options]... [script [args]...].\n"
  "Available options are:\n"
  "  -e chunk  Execute string " LUA_QL("chunk") ".\n"
  "  -l name   Require library " LUA_QL("name") ".\n"
  "  -b ...    Save or list bytecode.\n"
  "  -j cmd    Perform LuaJIT control command.\n"
  "  -O[opt]   Control LuaJIT optimizations.\n"
  "  -i        Enter interactive mode after executing " LUA_QL("script") ".\n"
  "  -v        Show version information.\n"
  "  --        Stop handling options.\n"
  "  -         Execute stdin and stop handling options.\n", stderr);
  fflush(stderr);
}

static void l_message(const char *msg)
{
  if (progname) { fputs(progname, stderr); fputc(':', stderr); fputc(' ', stderr); }
  fputs(msg, stderr); fputc('\n', stderr);
  fflush(stderr);
}

static int report(lua_State *L, int status)
{
  if (status && !lua_isnil(L, -1)) {
    const char *msg = lua_tostring(L, -1);
    if (msg == NULL) msg = "(error object is not a string)";
    l_message(msg);
    lua_pop(L, 1);
  }
  return status;
}

static int traceback(lua_State *L)
{
  if (!lua_isstring(L, 1)) { /* Non-string error object? Try metamethod. */
    if (lua_isnoneornil(L, 1) ||
	!luaL_callmeta(L, 1, "__tostring") ||
	!lua_isstring(L, -1))
      return 1;  /* Return non-string error object. */
    lua_remove(L, 1);  /* Replace object by result of __tostring metamethod. */
  }
  luaL_traceback(L, L, lua_tostring(L, 1), 1);
  return 1;
}

static int docall(lua_State *L, int narg, int clear)
{
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, traceback);  /* push traceback function */
  lua_insert(L, base);  /* put it under chunk and args */
#if !LJ_TARGET_CONSOLE
  signal(SIGINT, laction);
#endif
  status = lua_pcall(L, narg, (clear ? 0 : LUA_MULTRET), base);
#if !LJ_TARGET_CONSOLE
  signal(SIGINT, SIG_DFL);
#endif
  lua_remove(L, base);  /* remove traceback function */
  /* force a complete garbage collection in case of errors */
  if (status != LUA_OK) lua_gc(L, LUA_GCCOLLECT, 0);
  return status;
}

static void print_version(void)
{
  fputs(LUAJIT_VERSION " -- " LUAJIT_COPYRIGHT ". " LUAJIT_URL "\n", stdout);
}

static void print_jit_status(lua_State *L)
{
  int n;
  const char *s;
  lua_getfield(L, LUA_REGISTRYINDEX, "_LOADED");
  lua_getfield(L, -1, "jit");  /* Get jit.* module table. */
  lua_remove(L, -2);
  lua_getfield(L, -1, "status");
  lua_remove(L, -2);
  n = lua_gettop(L);
  lua_call(L, 0, LUA_MULTRET);
  fputs(lua_toboolean(L, n) ? "JIT: ON" : "JIT: OFF", stdout);
  for (n++; (s = lua_tostring(L, n)); n++) {
    putc(' ', stdout);
    fputs(s, stdout);
  }
  putc('\n', stdout);
  lua_settop(L, 0);  /* clear stack */
}

static void createargtable(lua_State *L, char **argv, int argc, int argf)
{
  int i;
  lua_createtable(L, argc - argf, argf);
  for (i = 0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i - argf);
  }
  lua_setglobal(L, "arg");
}

static int dofile(lua_State *L, const char *name)
{
  int status = luaL_loadfile(L, name) || docall(L, 0, 1);
  return report(L, status);
}

static int dostring(lua_State *L, const char *s, const char *name)
{
  int status = luaL_loadbuffer(L, s, strlen(s), name) || docall(L, 0, 1);
  return report(L, status);
}

static int dolibrary(lua_State *L, const char *name)
{
  lua_getglobal(L, "require");
  lua_pushstring(L, name);
  return report(L, docall(L, 1, 1));
}

static void write_prompt(lua_State *L, int firstline)
{
  const char *p;
  lua_getfield(L, LUA_GLOBALSINDEX, firstline ? "_PROMPT" : "_PROMPT2");
  p = lua_tostring(L, -1);
  if (p == NULL) p = firstline ? LUA_PROMPT : LUA_PROMPT2;
  fputs(p, stdout);
  fflush(stdout);
  lua_pop(L, 1);  /* remove global */
}

static int incomplete(lua_State *L, int status)
{
  if (status == LUA_ERRSYNTAX) {
    size_t lmsg;
    const char *msg = lua_tolstring(L, -1, &lmsg);
    const char *tp = msg + lmsg - (sizeof(LUA_QL("<eof>")) - 1);
    if (strstr(msg, LUA_QL("<eof>")) == tp) {
      lua_pop(L, 1);
      return 1;
    }
  }
  return 0;  /* else... */
}

static int pushline(lua_State *L, int firstline)
{
  char buf[LUA_MAXINPUT];
  write_prompt(L, firstline);
  if (fgets(buf, LUA_MAXINPUT, stdin)) {
    size_t len = strlen(buf);
    if (len > 0 && buf[len-1] == '\n')
      buf[len-1] = '\0';
    if (firstline && buf[0] == '=')
      lua_pushfstring(L, "return %s", buf+1);
    else
      lua_pushstring(L, buf);
    return 1;
  }
  return 0;
}

static int loadline(lua_State *L)
{
  int status;
  lua_settop(L, 0);
  if (!pushline(L, 1))
    return -1;  /* no input */
  for (;;) {  /* repeat until gets a complete line */
    status = luaL_loadbuffer(L, lua_tostring(L, 1), lua_strlen(L, 1), "=stdin");
    if (!incomplete(L, status)) break;  /* cannot try to add lines? */
    if (!pushline(L, 0))  /* no more input? */
      return -1;
    lua_pushliteral(L, "\n");  /* add a new line... */
    lua_insert(L, -2);  /* ...between the two lines */
    lua_concat(L, 3);  /* join them */
  }
  lua_remove(L, 1);  /* remove line */
  return status;
}

static void dotty(lua_State *L)
{
  int status;
  const char *oldprogname = progname;
  progname = NULL;
  while ((status = loadline(L)) != -1) {
    if (status == LUA_OK) status = docall(L, 0, 0);
    report(L, status);
    if (status == LUA_OK && lua_gettop(L) > 0) {  /* any result to print? */
      lua_getglobal(L, "print");
      lua_insert(L, 1);
      if (lua_pcall(L, lua_gettop(L)-1, 0, 0) != 0)
	l_message(lua_pushfstring(L, "error calling " LUA_QL("print") " (%s)",
				  lua_tostring(L, -1)));
    }
  }
  lua_settop(L, 0);  /* clear stack */
  fputs("\n", stdout);
  fflush(stdout);
  progname = oldprogname;
}

static int handle_script(lua_State *L, char **argx)
{
  int status;
  const char *fname = argx[0];
  if (strcmp(fname, "-") == 0 && strcmp(argx[-1], "--") != 0)
    fname = NULL;  /* stdin */
  status = luaL_loadfile(L, fname);
  if (status == LUA_OK) {
    /* Fetch args from arg table. LUA_INIT or -e might have changed them. */
    int narg = 0;
    lua_getglobal(L, "arg");
    if (lua_istable(L, -1)) {
      do {
	narg++;
	lua_rawgeti(L, -narg, narg);
      } while (!lua_isnil(L, -1));
      lua_pop(L, 1);
      lua_remove(L, -narg);
      narg--;
    } else {
      lua_pop(L, 1);
    }
    status = docall(L, narg, 0);
  }
  return report(L, status);
}

/* Load add-on module. */
static int loadjitmodule(lua_State *L)
{
  lua_getglobal(L, "require");
  lua_pushliteral(L, "jit.");
  lua_pushvalue(L, -3);
  lua_concat(L, 2);
  if (lua_pcall(L, 1, 1, 0)) {
    const char *msg = lua_tostring(L, -1);
    if (msg && !strncmp(msg, "module ", 7))
      goto nomodule;
    return report(L, 1);
  }
  lua_getfield(L, -1, "start");
  if (lua_isnil(L, -1)) {
  nomodule:
    l_message("unknown luaJIT command or jit.* modules not installed");
    return 1;
  }
  lua_remove(L, -2);  /* Drop module table. */
  return 0;
}

/* Run command with options. */
static int runcmdopt(lua_State *L, const char *opt)
{
  int narg = 0;
  if (opt && *opt) {
    for (;;) {  /* Split arguments. */
      const char *p = strchr(opt, ',');
      narg++;
      if (!p) break;
      if (p == opt)
	lua_pushnil(L);
      else
	lua_pushlstring(L, opt, (size_t)(p - opt));
      opt = p + 1;
    }
    if (*opt)
      lua_pushstring(L, opt);
    else
      lua_pushnil(L);
  }
  return report(L, lua_pcall(L, narg, 0, 0));
}

/* JIT engine control command: try jit library first or load add-on module. */
static int dojitcmd(lua_State *L, const char *cmd)
{
  const char *opt = strchr(cmd, '=');
  lua_pushlstring(L, cmd, opt ? (size_t)(opt - cmd) : strlen(cmd));
  lua_getfield(L, LUA_REGISTRYINDEX, "_LOADED");
  lua_getfield(L, -1, "jit");  /* Get jit.* module table. */
  lua_remove(L, -2);
  lua_pushvalue(L, -2);
  lua_gettable(L, -2);  /* Lookup library function. */
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 2);  /* Drop non-function and jit.* table, keep module name. */
    if (loadjitmodule(L))
      return 1;
  } else {
    lua_remove(L, -2);  /* Drop jit.* table. */
  }
  lua_remove(L, -2);  /* Drop module name. */
  return runcmdopt(L, opt ? opt+1 : opt);
}

/* Optimization flags. */
static int dojitopt(lua_State *L, const char *opt)
{
  lua_getfield(L, LUA_REGISTRYINDEX, "_LOADED");
  lua_getfield(L, -1, "jit.opt");  /* Get jit.opt.* module table. */
  lua_remove(L, -2);
  lua_getfield(L, -1, "start");
  lua_remove(L, -2);
  return runcmdopt(L, opt);
}

/* Save or list bytecode. */
static int dobytecode(lua_State *L, char **argv)
{
  int narg = 0;
  lua_pushliteral(L, "bcsave");
  if (loadjitmodule(L))
    return 1;
  if (argv[0][2]) {
    narg++;
    argv[0][1] = '-';
    lua_pushstring(L, argv[0]+1);
  }
  for (argv++; *argv != NULL; narg++, argv++)
    lua_pushstring(L, *argv);
  report(L, lua_pcall(L, narg, 0, 0));
  return -1;
}

/* check that argument has no extra characters at the end */
#define notail(x)	{if ((x)[2] != '\0') return -1;}

#define FLAGS_INTERACTIVE	1
#define FLAGS_VERSION		2
#define FLAGS_EXEC		4
#define FLAGS_OPTION		8
#define FLAGS_NOENV		16

static int collectargs(char **argv, int *flags)
{
  int i;
  for (i = 1; argv[i] != NULL; i++) {
    if (argv[i][0] != '-')  /* Not an option? */
      return i;
    switch (argv[i][1]) {  /* Check option. */
    case '-':
      notail(argv[i]);
      return i+1;
    case '\0':
      return i;
    case 'i':
      notail(argv[i]);
      *flags |= FLAGS_INTERACTIVE;
      /* fallthrough */
    case 'v':
      notail(argv[i]);
      *flags |= FLAGS_VERSION;
      break;
    case 'e':
      *flags |= FLAGS_EXEC;
      /* fallthrough */
    case 'j':  /* LuaJIT extension */
    case 'l':
      *flags |= FLAGS_OPTION;
      if (argv[i][2] == '\0') {
	i++;
	if (argv[i] == NULL) return -1;
      }
      break;
    case 'O': break;  /* LuaJIT extension */
    case 'b':  /* LuaJIT extension */
      if (*flags) return -1;
      *flags |= FLAGS_EXEC;
      return i+1;
    case 'E':
      *flags |= FLAGS_NOENV;
      break;
    default: return -1;  /* invalid option */
    }
  }
  return i;
}

static int runargs(lua_State *L, char **argv, int argn)
{
  int i;
  for (i = 1; i < argn; i++) {
    if (argv[i] == NULL) continue;
    lua_assert(argv[i][0] == '-');
    switch (argv[i][1]) {
    case 'e': {
      const char *chunk = argv[i] + 2;
      if (*chunk == '\0') chunk = argv[++i];
      lua_assert(chunk != NULL);
      if (dostring(L, chunk, "=(command line)") != 0)
	return 1;
      break;
      }
    case 'l': {
      const char *filename = argv[i] + 2;
      if (*filename == '\0') filename = argv[++i];
      lua_assert(filename != NULL);
      if (dolibrary(L, filename))
	return 1;
      break;
      }
    case 'j': {  /* LuaJIT extension. */
      const char *cmd = argv[i] + 2;
      if (*cmd == '\0') cmd = argv[++i];
      lua_assert(cmd != NULL);
      if (dojitcmd(L, cmd))
	return 1;
      break;
      }
    case 'O':  /* LuaJIT extension. */
      if (dojitopt(L, argv[i] + 2))
	return 1;
      break;
    case 'b':  /* LuaJIT extension. */
      return dobytecode(L, argv+i);
    default: break;
    }
  }
  return LUA_OK;
}

//VV: Runs the file "init.lua" at startup. The file must exist.
//VV: LUA_INIT environment variable is no longer used.
static int handle_luainit (lua_State *L) {
	return dofile(L, LUA_INIT_PATH);
 }


static struct Smain {
  char **argv;
  int argc;
  int status;
} smain;

static int pmain(lua_State *L)
{
  struct Smain *s = &smain;
  char **argv = s->argv;
  int argn;
  int flags = 0;
  globalL = L;
  LUAJIT_VERSION_SYM();  /* Linker-enforced version check. */

  argn = collectargs(argv, &flags);
  if (argn < 0) {  /* Invalid args? */
    print_usage();
    s->status = 1;
    return 0;
  }

  if (1) {//VV: always set noenv
    lua_pushboolean(L, 1);
    lua_setfield(L, LUA_REGISTRYINDEX, "LUA_NOENV");
  }

  /* Stop collector during library initialization. */
  lua_gc(L, LUA_GCSTOP, 0);
  luaL_openlibs(L);
  lua_gc(L, LUA_GCRESTART, -1);

  createargtable(L, argv, s->argc, argn);

  if (!flags) {
    s->status = handle_luainit(L);
    if (s->status != LUA_OK) return 0;
	//VV: All done with LUA_INIT_PATH after handle_luainit() is called.
	free(LUA_INIT_PATH);LUA_INIT_PATH=NULL;
	//:VV
  }

  if ((flags & FLAGS_VERSION)) print_version();

  s->status = runargs(L, argv, argn);
  if (s->status != LUA_OK) return 0;

  if (s->argc > argn) {
    s->status = handle_script(L, argv + argn);
    if (s->status != LUA_OK) return 0;
  }

  if ((flags & FLAGS_INTERACTIVE)) {
    print_jit_status(L);
    dotty(L);
  } else if (s->argc == argn && !(flags & (FLAGS_EXEC|FLAGS_VERSION))) {
    if (lua_stdin_is_tty()) {
      print_version();
      print_jit_status(L);
      dotty(L);
    } else {
      dofile(L, NULL);  /* Executes stdin as a file. */
    }
  }
  return 0;
}


//VV: Code to set the default paths based on the path to the exe.
#if defined(_WIN32)
	//MAX_PATH wasn't defined for mingw!
	#define MAX_PATH 260
	/*  Two ways to do this. The first uses <tchar.h> and _pgmptr .
		_pgmptr is 'depreciated', but it still works.
	 */
	///*
	#include <tchar.h>
	// static void l_locate(){//no error checks:
	// 	LUA_INIT_PATH=malloc(MAX_PATH+1); 
	// 	strcpy(LUA_INIT_PATH,_pgmptr);
	// 	*(strrchr(LUA_INIT_PATH,'\\'))='\0';
	// 	strcat(LUA_INIT_PATH,"\\init.lua");
	//  }
	static void l_locate(){//with error checks:
		//malloc
		if (LUA_INIT_PATH=malloc(MAX_PATH+1),NULL==LUA_INIT_PATH){
			fprintf(stderr, "ERROR: Unable to allocate memory for LUA_INIT_PATH.\n");
			exit(1);
		 }
		//strcpy
		if (strlen(_pgmptr)>=MAX_PATH){
			fprintf(stderr, "ERROR: File path for LUA_INIT_PATH is too long.\n");
			exit(1);
		 } else {
			strcpy(LUA_INIT_PATH,_pgmptr);
		 }
		//strrchar
		char* backslash=strrchr(LUA_INIT_PATH,'\\');
		if (backslash==NULL){
			fprintf(stderr, "ERROR: Unable to find path separator in LUA_INIT_PATH.\n");
			exit(1);
		 } else {
			*backslash='\0';
		 }
		//strcpy
		const char* init="\\init.lua";
		if (strlen(LUA_INIT_PATH)+strlen(init)>=MAX_PATH){
			fprintf(stderr, "ERROR: File path for LUA_INIT_PATH\\init.lua too long.\n");
			exit(1);
		 } else {
			strcat(LUA_INIT_PATH,init);
		 }
	 }
	 //*/
	/*  The second way uses <windows.h> and GetModuleFileNameA .*/
	/*
	#include <windows.h>
	static void l_locate(){
		char buff[MAX_PATH+1];
		DWORD nsize = sizeof(buff)/sizeof(char);
		DWORD n = GetModuleFileNameA(NULL, buff, nsize);
		char *lb;
		if (n == 0 || n == nsize || (lb = strrchr(buff, '\\')) == NULL){
			fprintf(stderr, "ERROR: Unable to determine exe path.\n");
			exit(1);
		 } else {
			*lb = '\0';
		 }
		if (LUA_INIT_PATH=malloc(MAX_PATH+1),NULL==LUA_INIT_PATH){
			fprintf(stderr, "ERROR: Unable to allocate memory for LUA_INIT_PATH.\n");
			exit(1);
		 }

		strcpy(LUA_INIT_PATH,buff);
		if (strlen(buff)>=MAX_PATH){
			fprintf(stderr, "ERROR: File path for LUA_INIT_PATH is too long.\n");
			exit(1);
		 } else {
			strcpy(LUA_INIT_PATH,buff);
		 }

		const char* init="\\init.lua";
		if (strlen(LUA_INIT_PATH)+strlen(init)>=MAX_PATH){
			fprintf(stderr, "ERROR: File path for LUA_INIT_PATH\\init.lua too long.\n");
			exit(1);
		 } else {
			strcat(LUA_INIT_PATH,init);
		 }
		
	 }
	 */
	#undef MAX_PATH
#else //Linux, MacOS
    #if defined(__APPLE__)
    #include <sys/types.h>
    #include <libproc.h>
    #endif
	/*	Sets the global variables: LUA_PATH_DEFAULT, LUA_CPATH_DEFAULT
		by finding the path to the executable at runtime.
		Exit on any error.
	 */
	static void l_locate(){
		// Find path to the exe:
			#if defined(__APPLE__)
				char exe_path[PROC_PIDPATHINFO_MAXSIZE]; // 4x PATH_MAX
				int sstval;
				sstval = proc_pidpath(  getpid(),  exe_path, sizeof(exe_path) );
			#else // linux
				char exe_path[PATH_MAX];
				ssize_t sstval;
				sstval = readlink("/proc/self/exe",exe_path, sizeof(exe_path) );
			#endif
				 if (sstval <= 0){/*readlink returns -1 on error, but 0 or fewer bytes
									read is also an error, logically. */
					fprintf(stderr,	"ERROR: Failed to get executable path.\n");
					exit(1);
				 }
				 if ( sstval >= sizeof(exe_path) || sstval >= PATH_MAX ){
					fprintf(stderr,	"ERROR: Executable path greater than or equal\n"
									"to the maximum path. Possible truncation occurred.\n");
					exit(1);
				 }
				/*  readlink doesn't null terminate.
					proc_pidpath on MacOS appears to null terminate, but I was
					unable to find documentation confirming this. In either case,
					null terminate the string:
				 */
				exe_path[sstval]='\0';

			/*	truncate the exe_path such that "/foo/bar/lua" becomes "/foo/bar" .
				"/lua" becomes "" . The template string will add the slash back in. */
			char* last_slash = strrchr(exe_path, '/');
			 if (last_slash != NULL) {
				*(last_slash) = '\0';//truncate the string.
			 } else {
				fprintf(stderr, "ERROR: Failed to find any path separator in path to\n"
								"the executable.\n");
				exit(1);
			 }
		// LUA_INIT_PATH
			// Saving the path to the exe so that I can open "$LUA_INIT_PATH/init.lua"
			size_t exe_init_path_sz;
			exe_init_path_sz=sstval+sizeof("/init.lua");
			LUA_INIT_PATH=malloc(sizeof(char)*exe_init_path_sz);
			if (NULL==LUA_INIT_PATH){
				fprintf(stderr, "ERROR: Unable to allocate memory for LUA_INIT_PATH.\n");
				exit(1);
			 }
			LUA_INIT_PATH[0]='\0';
			strcpy(LUA_INIT_PATH,exe_path);
			strcat(LUA_INIT_PATH,"/init.lua");
		// LUA_BASE_PATH
			// Saving the path to the exe so that I can open "$LUA_BASE_PATH/init.lua"
			size_t lua_base_path_sz;
			lua_base_path_sz=sstval+sizeof('/');
			LUA_BASE_PATH=malloc(sizeof(char)*lua_base_path_sz);
			if (NULL==LUA_BASE_PATH){
				fprintf(stderr, "ERROR: Unable to allocate memory for LUA_BASE_PATH.\n");
				exit(1);
			 }
			LUA_BASE_PATH[0]='\0';
			strcpy(LUA_BASE_PATH,exe_path);
			if (LUA_BASE_PATH
				&& *LUA_BASE_PATH
				&& LUA_BASE_PATH[strlen(LUA_BASE_PATH)-1] != '/'){
					strcat(LUA_BASE_PATH,"/");
			 }
		// LUA_PATH_DEFAULT
			const char LUA_PATH_DEFAULT_TEMPLATE []="%s/?.lua;%s/?/init.lua;";

			int LUA_PATH_DEFAULT_SZ=sizeof(LUA_PATH_DEFAULT_TEMPLATE)+(2*PATH_MAX);
			LUA_PATH_DEFAULT =malloc(sizeof(char)*LUA_PATH_DEFAULT_SZ);
			if (NULL==LUA_PATH_DEFAULT){
				fprintf(stderr, "ERROR: Unable to allocate memory for LUA_PATH_DEFAULT.\n");
				exit(1);
			 }

			int ival;
			ival=snprintf(LUA_PATH_DEFAULT,
				LUA_PATH_DEFAULT_SZ, // will not write more bytes than this (includes the null terminator).
				LUA_PATH_DEFAULT_TEMPLATE,// a const char[]
				exe_path,exe_path);
			 if (ival == -1){
				perror("sprintf");
				fprintf(stderr,"ERROR: sprintf failed.\n");
				exit(1);
			 }
			 if (ival >= LUA_PATH_DEFAULT_SZ ){
				perror("sprintf");
				fprintf(stderr,"ERROR: the LUA_PATH_DEFAULT buffer was too small: %d >= %d\n", ival,LUA_PATH_DEFAULT_SZ );
				exit(1);
			 }
		// LUA_CPATH_DEFAULT
			const char LUA_CPATH_DEFAULT_TEMPLATE[]="%s/?.so;";

			int LUA_CPATH_DEFAULT_SZ=sizeof(LUA_CPATH_DEFAULT_TEMPLATE)+PATH_MAX;
			LUA_CPATH_DEFAULT =malloc(sizeof(char)*LUA_CPATH_DEFAULT_SZ);
			if (NULL==LUA_CPATH_DEFAULT){
				fprintf(stderr, "ERROR: Unable to allocate memory for LUA_CPATH_DEFAULT.\n");
				exit(1);
			 }

			ival=snprintf(LUA_CPATH_DEFAULT,
				LUA_CPATH_DEFAULT_SZ, // will not write more bytes than this (includes the null terminator).
				LUA_CPATH_DEFAULT_TEMPLATE,// a const char[]
				exe_path);
			 if (ival == -1){
				perror("sprintf");
				fprintf(stderr,"ERROR: sprintf failed.\n");
				exit(1);
			 }
			 if (ival >= LUA_CPATH_DEFAULT_SZ ){
				perror("sprintf");
				fprintf(stderr,"ERROR: the LUA_PATH_DEFAULT buffer was too small: %d >= %d\n", ival,LUA_CPATH_DEFAULT_SZ );
				exit(1);
			 }
	 }
	#endif
	//:VV

int main(int argc, char **argv)
{
  int status;
  lua_State *L;
  if (!argv[0]) argv = empty_argv; else if (argv[0][0]) progname = argv[0];
  L = lua_open();
  if (L == NULL) {
    l_message("cannot create state: not enough memory");
    return EXIT_FAILURE;
  }
  smain.argc = argc;
  smain.argv = argv;
  //VV:
  l_locate(); // Linux,MacOS: Sets the global variables: LUA_PATH_DEFAULT, LUA_CPATH_DEFAULT.
  //:VV
  status = lua_cpcall(L, pmain, NULL);
  report(L, status);
  lua_close(L);
  return (status || smain.status > 0) ? EXIT_FAILURE : EXIT_SUCCESS;
}

