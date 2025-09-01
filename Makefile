#!/usr/bin/make
#This file is part of the Lulua Lua Distro,
#licensed under the MIT License (see the COPYRIGHT file).

# To build:
#   Linux/Macos: make lulua # it will autodetect.
#   Windows:     OS=win make lulua  # Builds sqlite.dll too
#                #Or
#                make winlua        # Builds sqlite.dll too
#
# To build modules:
#   Linux/Macos: make modules
#   Windows:     make sqlite

# Sqlite is the only compiled module available for Windows,
# but it is well worth it to have sqlite available in Love2d.

# No output logging "make -s" has the same effect.
# Choose one, comment the other out.
# Silent by default:
# ifndef VERBOSE
# MAKEFLAGS += --silent
# endif
# Silent by option:
ifdef SILENT
MAKEFLAGS += --silent
endif

# Accept OS from environment or detect it with uname:
ifeq ("$(OS)", "")
OS := $(shell uname -s)
endif
OS := $(shell echo "$$OS" | tr '[:upper:]' '[:lower:]')
export OS

# Accept MACOSX_DEPLOYMENT_TARGET from environment or set it:
OS_PREFIX := $(shell echo $(OS) | cut -c1-3)
ifeq ($(OS_PREFIX),mac)
ifeq ("$(MACOSX_DEPLOYMENT_TARGET)", "")
MACOSX_DEPLOYMENT_TARGET := "10.4"
endif
export MACOSX_DEPLOYMENT_TARGET
endif
ifeq ($(OS),darwin)
ifeq ("$(MACOSX_DEPLOYMENT_TARGET)", "")
MACOSX_DEPLOYMENT_TARGET := "10.4"
endif
export MACOSX_DEPLOYMENT_TARGET
endif

# Set default target immediately after OS detection.
.PHONY: default
default:  lulua ;


################################################################
# A little tutorial: How to embed python into a makefile.
#
# How to define a multiline string variable for your python script:
define MULTILINE_EXAMPLE
# A comment in the script.
import sys
print(sys.argv)
endef
# It is now available as $(MULTILINE_EXAMPLE) as a makefile variable.
export MULTILINE_EXAMPLE
# It is now also available as "$$MULTILINE_EXAMPLE" as a shell variable.

# How to embed a python script in your makefile: two ways:

# 1: Using a predefined multiline string:
python-multiline-embed:
	@python -c "$$MULTILINE_EXAMPLE" foo bar ;

# You must be very careful when using multiline strings.
# Dollar signs can be misinterpreted as either makefile
# vars or shell vars depending on the context.
#
# Only the multiline version allows comments *in* the script.

# 2: More direct:
python-direct-embed:
	@# You can put comments outside of the script.
	@echo 'if 1: ~\
		import sys ~\
		print(sys.argv) ~\
		' | sed 's/~/\n/' | python - foo bar ;

# The direct embed is more complicated, but it allows
# indentation.
#
# Start the python script with "if 1:" so that you can choose
# the indentation level.
#
# Be sure to use a single quoted string for the
# python script. Pass in any variables as command line args.
# The first command line arg must be a dash "-". This makes
# the python interpreter read the script from stdin.
#
# In the script, you will have to choose a char sequence that
# will be replaced by a newline char. I have used a single
# tilde here. Edit the sed portion if you change this.
#
# Each line needs to end in a line-continuation char sequence:
# a backslash followed immediately by a newline.
#
# Choose a specific version of python for your app and ship it.
# Python code is not portable even though it *SEEMS* to be.
#
# End tutorial.
################################################################



# If you have the "column" command, You can type "make help"
# to get a nice help message for this makefile.
# "column" is in the util-linux package.
# <https://www.kernel.org/pub/linux/utils/util-linux/>
define LULUA_MAKEFILE_HELP
Lulua Makefile Help

  The Lulua Lua Distro provides a lua programming
  environment with a collection of additional modules.
endef
export LULUA_MAKEFILE_HELP
.PHONY: help_msg
help_msg:
	@echo "$$LULUA_MAKEFILE_HELP";

.PHONY: help_targets
help_targets: help_msg
	@echo '';
	@echo 'Targets:';
	@grep -E '^[a-zA-Z0-9_-]+:.*?##.*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##target:\(.*\)/\1 \3/p' \
	| column -d -N Targets:,'' -t -l 2 -s ' ' | sed 's/^/  /'
	@echo '';
	@echo 'Modules:';
	@grep -E '^[a-zA-Z0-9_-]+:.*?##.*$$' $(MAKEFILE_LIST) \
	| sed -n 's/^\(.*\): \(.*\)##module:\(.*\)/\1 \3/p' \
	| column -d -N Modules:,'' -t -l 2 -s ' ' | sed 's/^/  /'

.PHONY: help
help: help_msg help_targets

# My project structure, if yours is not like this,
# you won't be able to make archives or releases.
define LULUA_PROJECT_STRUCTURE
Example project structure:
  LULUA
    ARCHIVES (must exist)
    RELEASES (must exist)
      lulua  (Makefile is here)
endef
export LULUA_PROJECT_STRUCTURE
ARCHIVES_EXISTS := $(shell [ -d "../ARCHIVES" ] && echo true || echo false)
RELEASES_EXISTS := $(shell [ -d "../RELEASES" ] && echo true || echo false)
.PHONY: assert-project-structure
assert-project-structure:
	@echo "Checking project structure:";
	@if [[ "$(ARCHIVES_EXISTS)" != "true" \
		|| "$(RELEASES_EXISTS)" != "true" ]]; then \
		echo "Required project structure for this feature is missing."; \
		echo "$$LULUA_PROJECT_STRUCTURE"; \
		exit 1; \
	fi

# Must be in the lulua dir.
ifneq ($(CURDIR),$(shell realpath $(shell pwd)))
$(error "This Makefile must be run from the directory in which it resides.")
endif

# I do expect that you have bash.
NAME 	=lulua
BASE 	:=$(shell basename $(shell pwd))
VERSION :=$(shell head -n 1 VERSION)
SHELL 	:=/bin/bash
export BASE

#%%
.PHONY: FORCE
FORCE: ;

.PHONY:   all lulua modules
all:      lulua modules

# Developer tools:
proginfo: FORCE       #devel print out program info.
	@echo "$(BASE): $(NAME)-v$(VERSION)"
dirinfo:  FORCE       #devel print out some directory info.
	@:\
	&& echo  ${CURDIR} $(shell realpath $(shell pwd)) ${NAME} \
	;
log:      FORCE       #devel git log "--oneline" as I like it
	@git log --oneline
diff:     FORCE       #devel "git difftool"
	@:\
	&& git difftool \
	;
commit:   FORCE clean #devel commit to git with COMMIT_MESSAGE
	: \
	&& git add --all \
	&& git commit \
		--date="`date -u +%Y-%m-%dT%H:%M:%S%z`" \
		--file=COMMIT_MESSAGE -a \
	&& :> COMMIT_MESSAGE \
	;
recommit: FORCE clean #devel allow recommit with different commit message and more!
	@:\
	&& git add --all \
	&& git commit --amend \
		--date="`date -u +%Y-%m-%dT%H:%M:%S%z`" \
		--file=COMMIT_MESSAGE -a \
	&& :> COMMIT_MESSAGE \
	;
snapshot: FORCE clean #devel snapshot commit to git with date/time as message.
	: \
	&& DT=`date -u +%Y-%m-%dT%H:%M:%S%z` \
	&& git add --all \
	&& git commit \
		--date="$$DT" \
		-m "$$DT" \
	;

# Use "make reset N" to squash your snapshot commits away. Then do a "make commit".
# make reset N --> git reset --mixed HEAD~N
RESET_LEVEL := $(if $(filter reset,$(firstword $(MAKECMDGOALS))),$(word 2,$(MAKECMDGOALS)))
export RESET_LEVEL
.PHONY: $(RESET_LEVEL)
$(RESET_LEVEL):
	@: ;
.PHONY: reset
reset:
	@if [[ -z $$RESET_LEVEL ]]; then echo "Must specify a reset level."; exit 1; fi
	@echo "git reset --mixed HEAD~$(RESET_LEVEL)"
	@:\
	&& read -p "Reset $(RESET_LEVEL) levels? (y/N): " confirm \
	&& [ "$$confirm" = "y" -o "$$confirm" = "Y" ] \
	&& git reset --mixed HEAD~$$RESET_LEVEL \
	;

.PHONY: docs clean archive release tarball
docs: lua #devel regenerate docs.
	@:\
	&& ./lua stdlib.lua --docs > stdlib.docs.txt || { echo "Lua script failed."; exit 1; } \
	&& awk '{if (length($$0) > 64) {exit 1;}}' stdlib.docs.txt || { echo 'stdlib.docs.txt: lines too long.'; exit 1; } \
	;
clean:    #devel abrasive cleaner.
	# binaries
	rm -f lua; 			true
	rm -f lua.exe;		true
	rm -f lua51.dll; 	true
	# linenoise history file:
	rm -f history.txt; true
	# lulua
	:\
	&& cd lulua \
	&& make clean \
	;
	find . -name '*.so'  -delete ;
	find . -name '*.o'   -delete ;
	find . -name '*.la'  -delete ;
	find . -name '*.a'   -delete ;
	find . -name '*.dll' -delete ;
	find . -name '*.exe' -delete ;
	find . -name 'a.out' -delete ;
	:\
	&& cd zlib/zlib-1.3.1 \
	&& make distclean ; true \
	;
	rm -rf sdl/build; true
	:\
	&& cd luaglut \
	&& make clean \
	;
	rm -f test.db       || true
	rm -f txt-zlib.gz   || true
	rm -f txt.lines.out || true
	rm -f txt.out       || true

archive: assert-project-structure #devel put an archive into the ../ARCHIVES dir.
	:\
	&& cd .. \
	&& tar -czvf ./ARCHIVES/$$(date -u +%F_%H-%M-%S)"_${NAME}".tgz "${NAME}" \
	;
release: assert-project-structure clean #devel get a tarball without .git
	:\
	&& cd .. \
	&& tar  --exclude='.git' \
		-czvf ./RELEASES/${NAME}-${VERSION}.tar "${NAME}" \
	;
tarball: #devel:always makes a tarball, one directory above.
	:\
	&& cd .. \
	&& tar -czvf $$(date -u +%F_%H-%M-%S)"_${NAME}".tgz "${NAME}" \
	;


# lulua:
# Conditional dependencies based on the OS variable
OS_PREFIX := $(shell echo $(OS) | cut -c1-3)
ifeq ($(OS_PREFIX),win)
lua: winlua
else
lua:
	: "lua:lulua:" \
	&& cd lulua \
	&& make lua \
	&& mv lua ../lua \
	;
endif
lulua: lua ##target:build the customized lua interpreter.

winlua: lua.exe windows-modules ##target:build lua and sqlite for windows (Cross compile on linux).
windows-modules:
	: 'sqlite:windows' \
	&& cd sqlite \
	&& export OS=win64 && bash build-sqlite.sh \
	;
lulua/lua5.1/include/lua.h:
	# Build for Linux at least once before building for Windows:
	: "lua:lulua:" \
	&& cd lulua \
	&& make lua \
	&& mv lua ../lua \
	;
lua.exe: lulua/lua5.1/include/lua.h
	: "lua:lulua-mingw:" \
	&& cd lulua \
	&& PLAT=mingw make lua \
	&& mv lua.exe ../lua.exe \
	&& mv lua51.dll ../lua51.dll \
	;

# Test the stdlib: Note that some tests will fail if you haven't built the necessary modules.
.PHONY: tests test test-love
tests: ##target:run stdlib tests for lua and love2d.
	make test
	make test-love
test: lua
	./lua stdlib.lua -t
test-love:
	love . LOVE2D -t

# I usually don't need liblua.a or luac.
# Get liblua.a.
.PHONY: liblua-linux
liblua-linux: lua
	: "liblua-linux" \
	&& cd lulua/lua5.1/src \
	&& cp liblua.a  ../../../liblua.a  \
	;
# Get luac.
.PHONY: luac-linux
luac-linux: lua
	: "luac-linux" \
	&& cp ./lulua/lua5.1/bin/luac  luac  \
	;

# Modules:
.PHONY:   base64 curses int64 lfs linenoise lpeg lrandom
.PHONY:   luaglut posix sdl signal sqlite utf8 zlib
modules: base64 curses int64 lfs linenoise lpeg lrandom luaglut posix sdl signal sqlite utf8 zlib ##target:build the aforementioned lua interpreter and all modules.
base64:    lua ##module:linux,macos?          [base64 encode/decode.]
	: 'base64:' \
	&& cd base64 \
	&& bash build-base64.sh \
	;
curses:    lua ##module:linux,macos?          [full-screen text terminal manipulation.]
	:\
	&& cd curses \
	&& bash build-curses.sh \
	;
int64:     lua ##module:linux                 [64 bit integers.]
	:\
	&& cd int64 \
	&& make LUA_TOPDIR=../lulua/lua5.1 \
	;
lfs:       lua ##module:linux,macos?          [lua filesystem.]
	:\
	&& cd lfs \
	&& bash build-lfs.sh \
	;
linenoise: lua ##module:linux,macos?          [terminal text input.]
	:\
	&& cd linenoise \
	&& bash  build-linenoise.sh \
	;
lpeg:      lua ##module:linux,macos?          [parsers.]
	:\
	&& cd lpeg \
	&& bash build-lpeg.sh \
	;
lrandom:   lua ##module:linux                 [mersenne twister.]
	:\
	&& cd lrandom \
	&& make \
	;
luaglut:   lua ##module:linux,macos?          [openGL.]
	:\
	&& cd luaglut \
	&& bash build-luaglut.sh \
	;
posix:     lua ##module:linux,macos?          [posix.]
	:\
	&& cd posix \
	&& bash build-posix.sh \
	;
sdl:       lua ##module:linux                 [multimedia.]
	:\
	&& cd sdl \
	&& bash build-sdl.sh \
	;
signal:    lua ##module:linux,macos?          [handle signals.]
	:\
	&& cd signal \
	&& bash build-signal.sh \
	;
sqlite:    lua ##module:linux,macos,windows   [database.]
	:\
	&& : 'sqlite:' \
	&& cd sqlite \
	&& bash build-sqlite.sh \
	;
utf8:      lua ##module:linux,macos?          [utf8 module from compat53.]
	:\
	&& cd utf8 \
	&& bash build-utf8.sh \
	;
zlib:      lua ##module:linux,macos?          [file compression.]
	:\
	&& cd zlib \
	&& bash build-zlib.sh \
	;

# module tests: This is interactive. You will have to close some windows.
# Not tested in module tests:
# test-curses because it is interactive and needs a signal to exit.
# test-signal because it exits with SIGTERM on purpose!
# test-debug: must uncomment the paths for this in init.lua .
test-modules: test-base64 test-bit test-int64 \
test-fstring test-gambiarra test-lfs test-lpeg test-lrandom \
test-luaglut test-lunit test-sdl test-sqlite test-zlib

test-base64:
	./lua base64/test._lua

test-bit:
	./lua bit/contrib/bittest.lua

test-curses: # is interactive. ctrl-c to exit.
	./lua curses/test/test.lua

test-int64:
	./lua int64/test.lua

# test-debug: must uncomment the paths for this in init.lua .
# You must run this from the main lulua dir.
# test-debug:
# 	: \
# 	&& cd debug/test \
# 	&& ../../lua test.lua

test-fstring:
	./lua fstring/examples/demo.lua
	./lua fstring/examples/env.lua
	./lua fstring/examples/fahrenheit.lua
	./lua fstring/examples/upvalue.lua

test-gambiarra:
	./lua gambiarra/examples/tap.lua

test-lfs:
	./lua lfs/tests/test.lua

test-lpeg:
	./lua lpeg/test._lua

test-lrandom:
	:\
	&& cd lrandom \
	&& make test \
	;

test-luaglut:
	./lua luaglut/glut_test1.lua
	./lua luaglut/glut_test2.lua
	cd luaglut && ../lua demo-falling-leaves.lua

test-lunit:
	./lua lunit/lua/lunit/selftest.lua

test-nativefs: # love2d only
	cd nativefs/test && love .

test-penlight:
	./lua penlight/run._lua

# The joystick test needs a joystick.
# sdl tcp and udp are broken or else my firewall is blocking it.
# The audio test is ANNOYING.
# The paths and rwops tests create garbage files.
# Overall, these tests are annoying.
# Use Love2d instead, if you can.
test-sdl:
# 	./lua sdl/examples/audio/audio.lua
# 	./lua sdl/examples/font/font.lua
	./lua sdl/examples/image/image.lua
# 	./lua sdl/examples/joystick/joystick.lua
# 	./lua sdl/examples/keyboard/keyboard.lua
# 	./lua sdl/examples/paths/paths.lua
# 	./lua sdl/examples/rwops/rwops.lua
# 	./lua sdl/examples/threads/channel.lua

# Exits with SIGTERM on purpose:
test-signal:
	./lua signal/test._lua

# Spews out a database file:
test-sqlite:
	./lua sqlite/test/test.lua
	./lua sqlite/test/tests-sqlite3.lua

test-utf8:
	./lua utf8/tests/test.lua

# Spews out some garbage files:
test-zlib:
	./lua zlib/test_prologue.lua
	./lua zlib/test_gzip.lua
	./lua zlib/test_zlib2.lua
	./lua zlib/test_zlib3.lua
