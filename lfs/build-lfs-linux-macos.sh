#!/bin/bash
set -euo pipefail

OS=$(uname)

if [[ "$OS" == 'Linux' ]]; then
:\
&& gcc -I ../lulua/lua5.1/include \-Wall -fPIC -c -o src/lfs.o src/lfs.c \
&& gcc -shared -o src/lfs.so src/lfs.o \
&& mv src/lfs.so ./lfs.so \
;
fi

if [[ "$OS" == 'Darwin' ]]; then
:\
&& export MACOSX_DEPLOYMENT_TARGET=10.5 \
&& clang -I ../lulua/lua5.1/include \-Wall -fPIC -c -o src/lfs.o src/lfs.c \
&& clang -bundle -undefined dynamic_lookup -o src/lfs.so src/lfs.o \
&& mv src/lfs.so ./lfs.so \
;
fi
