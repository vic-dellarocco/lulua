#!/bin/bash
set -euo pipefail
OS=$(uname)

if [[ "$OS" == 'Linux' ]]; then
:\
&& gcc \
	-I ../lulua/lua5.1/include \
	-Wall -fPIC \
	-c linenoise.c encodings/utf8.c linenoiselib.c \
&& gcc -shared -o linenoise.so ./*.o \
;
fi

if [[ "$OS" == 'Darwin' ]]; then
:\
&& clang \
	-I ../lulua/lua5.1/include \
	-Wall -fPIC \
	-c linenoise.c encodings/utf8.c linenoiselib.c \
&& clang -bundle -undefined dynamic_lookup -o linenoise.so ./*.o \
;
fi
