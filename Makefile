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
FORCE:

.PHONY:   all lua lulua modules
.PHONY:   docs clean archive release tarball test
.PHONY:   base64 curses lfs linenoise lpeg luaglut
.PHONY:   posix sdl signal sqlite utf8 zlib
.PHONY:   dirinfo

default:  lulua
all:      lulua modules

dirinfo:  FORCE #debug: print out some directory info.
	@:\
	&& echo  ${CURDIR} $(shell realpath $(shell pwd)) ${NAME} \
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
	&& tar -cvf ./ARCHIVES/$$(date -u +%F_%H-%M-%S)"_${NAME}".tar "${NAME}" \
	;
release: assert-project-structure
	:\
	&& cd .. \
	&& tar -cvf ./RELEASES/${NAME}-${VERSION}.tar "${NAME}" \
	;
tarball: #devel:always makes a tarball, one directory above.
	:\
	&& cd .. \
	&& tar -cvf $$(date -u +%F_%H-%M-%S)"_${NAME}".tar "${NAME}" \
	;
tests: FORCE test
test:
	./lua stdlib.lua -t
commit: clean
	: \
	&& git add --all \
	&& git commit \
		--date="`date -u +%Y-%m-%dT%H:%M:%S%z`" \
		--file=COMMIT_MESSAGE -a \
	&& :> COMMIT_MESSAGE \
	;
docs: # underspecified: does require lua to be built.
	:\
	&& ./lua stdlib.lua --docs > DOCS/stdlib.docs.txt || { echo "Lua script failed."; exit 1; } \
	&& awk '{if (length($$0) > 64) {exit 1;}}' DOCS/stdlib.docs.txt || { echo 'stdlib.docs.txt: lines too long.'; exit 1; } \
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

modules: base64 curses lfs linenoise lpeg luaglut posix sdl signal sqlite utf8 zlib ##target:build the aforementioned lua interpreter and all modules.
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
luaglut:   lua ##module:linux,macos?          [openGL.]
	:\
	&& cd luaglut \
	&& bash build-luaglut.sh \
	;
posix:     lua ##module:linux,macos?          [posix.]
	:\
	&& cd posix \
	&& bash build-posix-linux-macos.sh \
	;
sdl:       lua ##module:linux                 [multimedia.]
	:\
	&& OS=$$(uname) \
	&& if [[ "$$OS" != 'Linux' ]]; then \
		echo 'Linux is required.'; \
		exit 1; \
		fi
	:\
	&& cd sdl \
	&& bash build-sdl-linux.sh \
	;
signal:    lua ##module:linux,macos?          [handle signals.]
	:\
	&& cd signal \
	&& bash build-signal-linux-macos.sh \
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
	&& bash build-utf8-linux-macos.sh \
	;
zlib:      lua ##module:linux,macos?          [file compression.]
	:\
	&& cd zlib \
	&& bash build-zlib-linux-macos.sh \
	;
