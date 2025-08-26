#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails

if [ -z "$MACOSX_DEPLOYMENT_TARGET" ]; then
	MACOSX_DEPLOYMENT_TARGET="10.4"
	export MACOSX_DEPLOYMENT_TARGET
fi

set -u; # fail on unset vars.


:\
&& cd zlib-1.3 \
&& ./configure --static \
&& sed -i -e \
	's/CFLAGS=/CFLAGS= -fPIC /' \
	Makefile \
&& make \
&& cd .. \
&& clang \
	-I ../lulua/lua5.1/include \
	-I zlib-1.3 \
	-Wall \
	-fPIC \
	-c lzlib.c \
&& clang -bundle -undefined dynamic_lookup -o zlib.so ./*.o zlib-1.3/libz.a \
;