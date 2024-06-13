#!/bin/bash
set -euo pipefail

OS=$(uname)

if [[ "$OS" == 'Linux' ]]; then
:\
&& cd zlib-1.3 \
&& ./configure --static \
&& sed -i -e \
	's/CFLAGS=/CFLAGS= -fPIC /' \
	Makefile \
&& make \
&& cd .. \
&& gcc \
	-I ../lulua/lua5.1/include \
	-I zlib-1.3 \
	-Wall \
	-fPIC \
	-c lzlib.c \
&& gcc -shared -o zlib.so ./*.o zlib-1.3/libz.a \
;
fi

if [[ "$OS" == 'Darwin' ]]; then
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
fi
