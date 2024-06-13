#!/bin/bash
set -euo pipefail

# VV: I only want utf8 from compat53.

OS=$(uname)

if [[ "$OS" == 'Linux' ]]; then
:\
&& gcc \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c lutf8lib.c \
&& gcc -shared -o utf8.so lutf8lib.o \
;
fi

if [[ "$OS" == 'Darwin' ]]; then
:\
&& clang \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c lutf8lib.c \
&& clang -bundle -undefined dynamic_lookup -o utf8.so lutf8lib.o \
;
fi
