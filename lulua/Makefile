#!/usr/bin/make
#--[[This file is part of the Lulua lua distro,
#	licensed under the MIT License (see the COPYRIGHT file).]]
NAME = lulua
SHELL=/bin/bash

.PHONY: all lua clean
all: lua

ifndef PLAT
PLAT := $(shell uname -s)
export PLAT
endif

ifeq ("$(PLAT)", "Darwin")
PLAT := macosx
export PLAT
endif

ifeq ("$(PLAT)", "Linux")
PLAT := linux
export PLAT
endif

ifeq ("$(PLAT)", "mingw")
lua:
	: "lulua:mingw" \
	&& cd lua5.1 \
	&& make clean \
	&& make PLAT=mingw \
	&& mv src/lua.exe src/lua51.dll ../ \
	;
else
lua:
	: "lulua:" \
	&& cd lua5.1 \
	&& make clean \
	&& make "$$PLAT" \
	&& make local \
	&& cd .. \
	&& cp ./lua5.1/bin/lua lua \
	;
endif

clean:
	# lua
	@: \
	&& cd  lua5.1 \
	&& make clean \
	&& rm -f bin/lua \
	&& rm -f bin/luac \
	&& cd .. \
	&& rm -f lua \
	;
	# mac
	@: \
	&& find . -type f -name ".DS_Store"  -delete \
	&& find . -type f -name "._*"		 -delete \
	;
	#
	@: \
	&& rm -rf lua-5.1.5 \
	;
	#
	@: \
	&& cd  lua5.1 \
	&& rm -rf bin/ \
	&& rm -rf include/ \
	&& rm -rf lib/ \
	&& rm -rf man/ \
	&& rm -rf share/ \
	&& cd .. \
	;

##
.PHONY: archive commit checks hydrate patches
# archive:
# 	@: \
# 	&& DIR="$$(basename $$(pwd) )" \
# 	&& cd .. \
# 	&& tar -czf ../ARCHIVES/"$$DIR"_"$$(date -u +%F_%T_%z)".tgz "$$DIR" \
# 	;
# commit: clean
# 	@: \
# 	&& git add --all \
# 	&& git commit \
# 		--date="`date -u +%Y-%m-%dT%H:%M:%S%z`" \
# 		--file=COMMIT_MESSAGE -a \
# 	&& :> COMMIT_MESSAGE \
# 	;
checks:
	: "Checksums" \
	&& sha256sum -c SUMS.TXT \
	;
hydrate: checks
	@if [ ! -d lua5.1 ]; then \
		echo "hydrating lua5.1 ." \
		&& tar xzf lua-5.1.5.tar.gz \
		&& cd lua-5.1.5 \
		&& patch -s -p1 < ../lua-5.1.5.patch \
		&& cd .. \
		&& mv lua-5.1.5 lua5.1 \
		;\
	else echo "lua5.1 is already hydrated." ;\
	fi
patches:
	tar xzf lua-5.1.5.tar.gz  && diff -ruN lua-5.1.5 lua5.1 	> lua-5.1.5.patch;  [ $$? -eq 1 ]
