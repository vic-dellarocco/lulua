# Lulua Lua Distro

  The Lulua Lua Distro provides a lua programming
  environment with a collection of additional modules.

⚠️ **Work in Progress: This software is about 156 items from the
     version 1.0 release. See TODO.TXT**

This is for making application software. Use it as a base to
make your own Lua project.

Unlike Linux system software, lulua doesn't use hard-coded
paths. You can move your lulua project almost anywhere on the
filesystem and it will still work.

Lulua provides many useful functions in it's standard
library, as well many useful preconfigured modules.

Modules:

- base64:    base64 encoder/decoder
- bit:       bit manipulation lib for Lua5.1, already enabled.
- curses:    Full screen terminal character control.
- debug:     interactive debugger, already enabled call trace() or
             breakpoint() in your code to trigger.
- fstring:   python style f-strings, already enabled use functions
             f"..." or F"..."
- gambiarra: a very simple testing framework.
- lfs:       lua filesystem, file and directory functions.
- linenoise: a "readline" alternative that actually compiles.
- lpeg:      parsing expression grammars for lua.
- luaglut:   old-school openGL.
- lunit:     a very complicated testing framework.
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

-  base64    : linux,macos?
-  bit       : all
-  curses    : linux,macos?
-  debugger  : all
-  fstring   : all
-  gambiarra : all
-  lfs       : linux,macos?
-  linenoise : linux,macos?
-  lpeg      : linux,macos?
-  luaglut   : linux,macos?
-  lunit     : all
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
