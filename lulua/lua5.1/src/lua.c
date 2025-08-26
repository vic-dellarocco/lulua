/*
** $Id: lua.c,v 1.160.1.2 2007/12/28 15:32:23 roberto Exp $
** Lua stand-alone interpreter
** See Copyright Notice in lua.h
*/


#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define lua_c

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"

//VV:
char* LUA_INIT_PATH; //The path of the lua interpreter's init.lua file.
//:VV

static lua_State *globalL = NULL;

static const char *progname = LUA_PROGNAME;



static void lstop (lua_State *L, lua_Debug *ar) {
  (void)ar;  /* unused arg. */
  lua_sethook(L, NULL, 0, 0);
  luaL_error(L, "interrupted!");
}


static void laction (int i) {
  signal(i, SIG_DFL); /* if another SIGINT happens before lstop,
                              terminate process (default action) */
  lua_sethook(globalL, lstop, LUA_MASKCALL | LUA_MASKRET | LUA_MASKCOUNT, 1);
}


static void print_usage (void) {
  fprintf(stderr,
  "usage: %s [options] [script [args]].\n"
  "Available options are:\n"
  "  -e stat  execute string " LUA_QL("stat") "\n"
  "  -l name  require library " LUA_QL("name") "\n"
  "  -i       enter interactive mode after executing " LUA_QL("script") "\n"
  "  -v       show version information\n"
  "  --       stop handling options\n"
  "  -        execute stdin and stop handling options\n"
  ,
  progname);
  fflush(stderr);
}


static void l_message (const char *pname, const char *msg) {
  if (pname) fprintf(stderr, "%s: ", pname);
  fprintf(stderr, "%s\n", msg);
  fflush(stderr);
}


static int report (lua_State *L, int status) {
  if (status && !lua_isnil(L, -1)) {
    const char *msg = lua_tostring(L, -1);
    if (msg == NULL) msg = "(error object is not a string)";
    l_message(progname, msg);
    lua_pop(L, 1);
  }
  return status;
}


static int traceback (lua_State *L) {
  if (!lua_isstring(L, 1))  /* 'message' not a string? */
    return 1;  /* keep it intact */
  lua_getfield(L, LUA_GLOBALSINDEX, "debug");
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return 1;
  }
  lua_getfield(L, -1, "traceback");
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 2);
    return 1;
  }
  lua_pushvalue(L, 1);  /* pass error message */
  lua_pushinteger(L, 2);  /* skip this function and traceback */
  lua_call(L, 2, 1);  /* call debug.traceback */
  return 1;
}


static int docall (lua_State *L, int narg, int clear) {
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, traceback);  /* push traceback function */
  lua_insert(L, base);  /* put it under chunk and args */
  signal(SIGINT, laction);
  status = lua_pcall(L, narg, (clear ? 0 : LUA_MULTRET), base);
  signal(SIGINT, SIG_DFL);
  lua_remove(L, base);  /* remove traceback function */
  /* force a complete garbage collection in case of errors */
  if (status != 0) lua_gc(L, LUA_GCCOLLECT, 0);
  return status;
}


static void print_version (void) {
  l_message(NULL, LUA_RELEASE "  " LUA_COPYRIGHT);
}


static int getargs (lua_State *L, char **argv, int n) {
  int narg;
  int i;
  int argc = 0;
  while (argv[argc]) argc++;  /* count total number of arguments */
  narg = argc - (n + 1);  /* number of arguments to the script */
  luaL_checkstack(L, narg + 3, "too many arguments to script");
  for (i=n+1; i < argc; i++)
    lua_pushstring(L, argv[i]);
  lua_createtable(L, narg, n + 1);
  for (i=0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i - n);
  }
  return narg;
}


static int dofile (lua_State *L, const char *name) {
  int status = luaL_loadfile(L, name) || docall(L, 0, 1);
  return report(L, status);
}


static int dostring (lua_State *L, const char *s, const char *name) {
  int status = luaL_loadbuffer(L, s, strlen(s), name) || docall(L, 0, 1);
  return report(L, status);
}


static int dolibrary (lua_State *L, const char *name) {
  lua_getglobal(L, "require");
  lua_pushstring(L, name);
  return report(L, docall(L, 1, 1));
}


static const char *get_prompt (lua_State *L, int firstline) {
  const char *p;
  lua_getfield(L, LUA_GLOBALSINDEX, firstline ? "_PROMPT" : "_PROMPT2");
  p = lua_tostring(L, -1);
  if (p == NULL) p = (firstline ? LUA_PROMPT : LUA_PROMPT2);
  lua_pop(L, 1);  /* remove global */
  return p;
}


static int incomplete (lua_State *L, int status) {
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


static int pushline (lua_State *L, int firstline) {
  char buffer[LUA_MAXINPUT];
  char *b = buffer;
  size_t l;
  const char *prmt = get_prompt(L, firstline);
  if (lua_readline(L, b, prmt) == 0)
    return 0;  /* no input */
  l = strlen(b);
  if (l > 0 && b[l-1] == '\n')  /* line ends with newline? */
    b[l-1] = '\0';  /* remove it */
  if (firstline && b[0] == '=')  /* first line starts with `=' ? */
    lua_pushfstring(L, "return %s", b+1);  /* change it to `return' */
  else
    lua_pushstring(L, b);
  lua_freeline(L, b);
  return 1;
}


static int loadline (lua_State *L) {
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
  lua_saveline(L, 1);
  lua_remove(L, 1);  /* remove line */
  return status;
}


static void dotty (lua_State *L) {
  int status;
  const char *oldprogname = progname;
  progname = NULL;
  while ((status = loadline(L)) != -1) {
    if (status == 0) status = docall(L, 0, 0);
    report(L, status);
    if (status == 0 && lua_gettop(L) > 0) {  /* any result to print? */
      lua_getglobal(L, "print");
      lua_insert(L, 1);
      if (lua_pcall(L, lua_gettop(L)-1, 0, 0) != 0)
        l_message(progname, lua_pushfstring(L,
                               "error calling " LUA_QL("print") " (%s)",
                               lua_tostring(L, -1)));
    }
  }
  lua_settop(L, 0);  /* clear stack */
  fputs("\n", stdout);
  fflush(stdout);
  progname = oldprogname;
}


static int handle_script (lua_State *L, char **argv, int n) {
  int status;
  const char *fname;
  int narg = getargs(L, argv, n);  /* collect arguments */
  lua_setglobal(L, "arg");
  fname = argv[n];
  if (strcmp(fname, "-") == 0 && strcmp(argv[n-1], "--") != 0) 
    fname = NULL;  /* stdin */
  status = luaL_loadfile(L, fname);
  lua_insert(L, -(narg+1));
  if (status == 0)
    status = docall(L, narg, 0);
  else
    lua_pop(L, narg);      
  return report(L, status);
}


/* check that argument has no extra characters at the end */
#define notail(x)	{if ((x)[2] != '\0') return -1;}


static int collectargs (char **argv, int *pi, int *pv, int *pe) {
  int i;
  for (i = 1; argv[i] != NULL; i++) {
    if (argv[i][0] != '-')  /* not an option? */
        return i;
    switch (argv[i][1]) {  /* option */
      case '-':
        notail(argv[i]);
        return (argv[i+1] != NULL ? i+1 : 0);
      case '\0':
        return i;
      case 'i':
        notail(argv[i]);
        *pi = 1;  /* go through */
      case 'v':
        notail(argv[i]);
        *pv = 1;
        break;
      case 'e':
        *pe = 1;  /* go through */
      case 'l':
        if (argv[i][2] == '\0') {
          i++;
          if (argv[i] == NULL) return -1;
        }
        break;
      default: return -1;  /* invalid option */
    }
  }
  return 0;
}


static int runargs (lua_State *L, char **argv, int n) {
  int i;
  for (i = 1; i < n; i++) {
    if (argv[i] == NULL) continue;
    lua_assert(argv[i][0] == '-');
    switch (argv[i][1]) {  /* option */
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
          return 1;  /* stop if file fails */
        break;
      }
      default: break;
    }
  }
  return 0;
}

//VV: Runs the file "init.lua" at startup. The file must exist.
//VV: LUA_INIT environment variable is no longer used.
static int handle_luainit (lua_State *L) {
	return dofile(L, LUA_INIT_PATH);
 }


struct Smain {
  int argc;
  char **argv;
  int status;
};


static int pmain (lua_State *L) {
  struct Smain *s = (struct Smain *)lua_touserdata(L, 1);
  char **argv = s->argv;
  int script;
  int has_i = 0, has_v = 0, has_e = 0;
  globalL = L;
  if (argv[0] && argv[0][0]) progname = argv[0];
  lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
  luaL_openlibs(L);  /* open libraries */
  lua_gc(L, LUA_GCRESTART, 0);

  script = collectargs(argv, &has_i, &has_v, &has_e);
  if (script < 0) {  /* invalid args? */
    print_usage();
    s->status = 1;
    return 0;
  }

  if (has_v){
	print_version();
   } else {
	s->status = handle_luainit(L);
	if (s->status != 0){return 0;}
	free(LUA_INIT_PATH);LUA_INIT_PATH=NULL;
   }

  s->status = runargs(L, argv, (script > 0) ? script : s->argc);

  if (s->status != 0) return 0;
  if (script)
    s->status = handle_script(L, argv, script);
  if (s->status != 0) return 0;
  if (has_i)
    dotty(L);
  else if (script == 0 && !has_e && !has_v) {
    if (lua_stdin_is_tty()) {
      print_version();
      dotty(L);
    }
    else dofile(L, NULL);  /* executes stdin as a file */
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


int main (int argc, char **argv) {
  int status;
  struct Smain s;
  lua_State *L = lua_open();  /* create state */
  if (L == NULL) {
    l_message(argv[0], "cannot create state: not enough memory");
    return EXIT_FAILURE;
  }
  s.argc = argc;
  s.argv = argv;
  //VV: Sets lulua global variables:
  l_locate(); // Sets: LUA_INIT_PATH, LUA_BASE_PATH, LUA_PATH_DEFAULT, LUA_CPATH_DEFAULT.
  //:VV
  status = lua_cpcall(L, &pmain, &s);
  report(L, status);
  lua_close(L);
  return (status || s.status) ? EXIT_FAILURE : EXIT_SUCCESS;
}

