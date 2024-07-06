#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails






set -u; # fail on unset vars.


:\
&& cd zlib-1.3.1 \
&& ./configure --static \
&& sed -i -e \
	's/CFLAGS=/CFLAGS= -fPIC /' \
	Makefile \
&& make \
&& cd .. \
&& gcc \
	-I ../lulua/lua5.1/include \
	-I zlib-1.3.1 \
	-Wall \
	-fPIC \
	-c lzlib.c \
&& gcc -shared -o zlib.so ./*.o zlib-1.3.1/libz.a \
;