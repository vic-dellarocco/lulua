#!/usr/bin/make
#--[[This file is part of the Lulua lua distro,
#	licensed under the MIT License (see the COPYRIGHT file).]]
NAME = lulua
SHELL=/bin/bash

.PHONY: all lua clean

all: lua
lua:
	@:\
	&& if [[ "$$PLAT" != "mingw"  ]]; then \
		ss=$$(uname) ; \
	  fi \
	&& if [[ "$$ss"    = "Darwin" ]]; then \
		PLAT="macosx"; \
	  elif [[ "$$ss" = "Linux"  ]]; then \
		PLAT="linux"; \
	  else \
		PLAT="mingw"; \
	  fi \
	&& if [[ "$$PLAT"  = "mingw"  ]]; then \
		cd lua5.1 ;\
		bash compile-windows.sh ;\
	  else \
		cd lua5.1; \
		make clean; \
		make "$$PLAT"; \
		make local PLAT="$$PLAT"; \
		cd ..; \
		cp ./lua5.1/bin/lua lua; \
	  fi \
	;
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
