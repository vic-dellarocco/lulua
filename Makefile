#!/usr/bin/make
#This file is part of the Lulua Lua Distro,
#licensed under the MIT License (see the COPYRIGHT file).

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

define LULUA_PROJECT_STRUCTURE
Example project structure:
  LULUA
    ARCHIVES (must exist)
    RELEASES (must exist)
      lulua  (the branch name) (Makefile is here)
      luluaX (a possible alternative branch)
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

ifneq ($(CURDIR),$(shell realpath $(shell pwd)))
$(error "This Makefile must be run from the directory in which it resides.")
endif

NAME 	:=$(shell basename $(shell pwd))
VERSION :=$(shell head -n 1 VERSION)
SHELL 	:=/bin/bash

#%%
.PHONY: FORCE
FORCE: ;

.PHONY:   all lua lulua modules
.PHONY:   docs clean archive release tarball 
.PHONY:   tests test test-love
.PHONY:   base64 curses int64 lfs linenoise lpeg lrandom luaglut
.PHONY:   posix sdl signal sqlite utf8 zlib

all:      lulua modules

dirinfo:  FORCE #devel print out some directory info.
	@:\
	&& echo  ${CURDIR} $(shell realpath $(shell pwd)) ${NAME} \
	;
log:      FORCE #devel git log "--oneline" as I like it
	@git log --oneline
diff:     FORCE #devel "git difftool"
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

clean:
	# binaries
	rm lua; 		true
	rm lua.exe;		true
	rm lua51.dll; 	true
	# linenoise history file:
	rm history.txt; true
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
	&& cd zlib/zlib-1.3 \
	&& make distclean ; true \
	;
	rm -r sdl/build; true
	:\
	&& cd luaglut \
	&& make clean \
	;
	rm test.db; true
archive: assert-project-structure
	:\
	&& cd .. \
	&& tar -czvf ./ARCHIVES/$$(date -u +%F_%H-%M-%S)"_${NAME}".tgz "${NAME}" \
	;
release: assert-project-structure #devel get a tarball without .git
	:\
	&& cd .. \
	&& tar  --exclude='.git' \
			--exclude='NOTES.TXT'	\
		-czvf ./RELEASES/${NAME}-${VERSION}.tar "${NAME}" \
	;
tarball: #devel:always makes a tarball, one directory above.
	:\
	&& cd .. \
	&& tar -czvf $$(date -u +%F_%H-%M-%S)"_${NAME}".tgz "${NAME}" \
	;
tests: ##target:run stdlib tests for lua and love2d.
	make test
	make test-love
test:
	./lua stdlib.lua -t
test-love:
	love . LOVE2D -t
docs: # underspecified: it requires that lua has been built.
	@:\
	&& ./lua stdlib.lua --docs > stdlib.docs.txt || { echo "Lua script failed."; exit 1; } \
	&& awk '{if (length($$0) > 64) {exit 1;}}' stdlib.docs.txt || { echo 'stdlib.docs.txt: lines too long.'; exit 1; } \
	;

#%%
# Conditional dependencies based on the OS variable
OS_PREFIX := $(shell echo $(OS) | cut -c1-3)
ifeq ($(OS_PREFIX),win)
lua:
	@ if [[ ! -f "lulua/lua5.1/include/lua.h" ]]; then \
		: "lua:lulua:" \
		&& echo "make: Building target 'OS=win lua'." \
		&& cd lulua \
		&& make lua \
		&& mv lua ../lua \
		; \
		else \
		echo "make: Nothing to be done for 'OS=win lua'." \
		; \
		fi
	@ if [[ ! -f "lua51.dll" ]]; then \
		: "OS=win lua:lulua-mingw:" \
		&& echo "make: Building target 'OS=win lua:lulua-mingw'." \
		&& cd lulua \
		&& PLAT=mingw make lua \
		&& mv lua.exe ../lua.exe \
		&& mv lua51.dll ../lua51.dll \
		; \
		else \
		echo "make: Nothing to be done for 'OS=win lua:lulua-mingw'." \
		; \
		fi
else
lua:
	@ if [[ ! -f "lulua/lua5.1/include/lua.h" ]]; then \
		: "lua:lulua:" \
		&& echo "make: Building target 'lua'." \
		&& cd lulua \
		&& make lua \
		&& mv lua ../lua \
		; \
		else \
		echo "make: Nothing to be done for 'lua'." \
		; \
		fi
endif

lulua:  ##target:build the customized lua interpreter.
	: "lulua:" \
	&& cd lulua \
	&& make lua \
	&& mv lua ../lua \
	;
lulua-mingw:     # windows build
	: "lulua-mingw:" \
	&& cd lulua \
	&& PLAT=mingw make lua \
	&& mv lua.exe ../lua.exe \
	&& mv lua51.dll ../lua51.dll \
	;

# Get liblua.a, liblua.so.
.PHONY: liblua-linux
liblua-linux: lulua
	: "liblua-linux" \
	&& cd lulua/lua5.1/src \
	&& gcc -shared -o liblua.so liblua.a \
	&& cp liblua.a  ../../../liblua.a  \
	&& cp liblua.so ../../../liblua.so \
	;
# Get luac.
.PHONY: luac-linux
luac-linux: lulua
	: "luac-linux" \
	&& cp ./lulua/lua5.1/bin/luac  luac  \
	;

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

# module tests:
test-base64:
	./lua base64/test._lua

test-bit:
	./lua bit/contrib/bittest.lua

test-curses: # is interactive. ctrl-c to exit.
	./lua curses/test/test.lua

test-int64:
	./lua int64/test.lua

# Tests here were not designed to be run from one dir above:
# test-debug: # broken.
# 	./lua debug/test/test.lua

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

# The test suite here seems exhaustive.
# It isn't set up to run from 2 directories above (which is
# where the Makefile is). I'm in no hurry to fix it because
# it seems like it spews files.
# test-nativefs: # love2d only
# 	love nativefs/test

# test-penlight: # pl.List conflicts with lulua List type.
# pl.app tests fail too. That's where I stopped.
# 	./lua penlight/run._lua

# The joystick test needs a joystick.
# sdl tcp and udp are broken or else my firewall is blocking it.
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
