# Lulua Lua Distro

  The Lulua Lua Distro provides a lua programming
  environment with a collection of additional modules.

This is for making application software. Use it as a base to
make your own Lua project.

Lulua doesn't use hard-coded paths. You can move your lulua
project almost anywhere on the filesystem and it will still work.

Alternatively, you can use the stdlib and modules with love2d.

Lulua provides many useful functions in it's standard
library, as well many useful preconfigured modules.

As of version 1.0.1, Lulua will no longer be available with git
history. I don't want to see your git history, nor do I want you
to see mine. Use git locally if you want. I do. Realize that
git history enables some nasty micromanagement. It feels yucky.
People fixate on it. It's disgusting! I think it was a mistake
to have so much of it public.

Git history has also been used to train artificial intelligence
models. Think of that when you wonder why git hosting is *free*.

Modules:

- base64:    base64 encoder/decoder
- bit:       bit manipulation lib for Lua5.1, already enabled.
- curses:    Full screen terminal character control.
- debug:     interactive debugger, already enabled call trace() or
             breakpoint() in your code to trigger.
- fstring:   python style f-strings, already enabled use functions
             f"..." or F"..."
- gambiarra: a very simple testing framework.
- int64:     64 bit integers.
- lfs:       lua filesystem, file and directory functions.
- linenoise: a "readline" alternative that actually compiles.
- lpeg:      parsing expression grammars for lua.
- lrandom:   Mersenne Twister random number generator.
- luaglut:   old-school openGL.
- lunit:     a very complicated testing framework.
- nativefs:  Love2d only: remove filesystem restrictions.
- penlight:  another standard library for lua, already enabled
             imported as "penlight". Very good.
- posix:     lua posix, 
- sdl:       simple direct media layer.
- signal:    raise and catch system signals.
- sqlite:    sql database.
- utf8:      utf8 functions from the compat53 module.
- zlib:      file compression functions.

<details>
<summary>System Requirements</summary>

"?" indicates untested on the system in question.
Also, if it is macos, it means I don't care.

-  base64    : linux,macos?
-  bit       : all
-  curses    : linux,macos?
-  debugger  : all
-  fstring   : all
-  gambiarra : all
-  int64     : linux
-  lfs       : linux,macos?
-  linenoise : linux,macos?
-  lpeg      : linux,macos?
-  lrandom   : linux
-  luaglut   : linux,macos?
-  lunit     : all
-  nativefs  : love2d
-  penlight  : all
-  posix     : linux,macos?
-  sdl       : linux
-  signal    : linux,macos?
-  sqlite    : linux,macos,windows
-  utf8      : linux,macos?
-  zlib      : linux,macos?

</details>

---

## How to Build

To get help:

```bash
	make help
```

The help message will provide system compatibility information
for each module. A question mark indicates that a module is
untested for the system in question.


### MacOS or Linux

```bash
	make lulua
	make modules
```

When using a MacOS host, make sure that you have the correct
value set for the MACOSX_DEPLOYMENT_TARGET environment variable.
You can set this in the Makefile or from the shell.

Ex:

```bash
	MACOSX_DEPLOYMENT_TARGET=10.6 make lulua
```

### Windows

Binaries for Windows can be made by cross-compiling when using a
Linux host.

```bash
	OS=win64 make lulua
	OS=win64 make sqlite
```

---

Customize everything as you see fit. Use "init.lua" to
require modules and define functions for your custom lua. Put
all of your lua modules in the same directory as the lua
interpreter. You can delete any modules that you don't need.

The header files for lua5.1 will be in lulua/lua5.1/include .
Use these files when building C modules.

---

## Technical Details

I have disabled the Lua interpreter's checks for environment
variables and I have modified the iterpreter so that it can find
itself in the filesystem. On startup, the lulua lua interpreter
runs the file "init.lua" that is in the same directory as the
interpreter. This file must exist. It can be blank.

The package.base variable is provided and set to the path of the
lua interpreter's directory.

An example of using package.path, and package.cpath.
Note: package.base ends in a directory separator character.

```lua
	package.path =package.path ..package.base.."lpeg/?.lua;"  --re
	package.cpath=package.cpath..package.base.."lpeg/?.so;" --lpeg
```
