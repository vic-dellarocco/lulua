#!/bin/bash
set -euo pipefail
OS=$(uname)

if [[ "$OS" == 'Linux'  ]]; then
	:\
	&& gcc \
		-I ../lulua/lua5.1/include \
		-Wall \
		-fPIC \
		-c lbase64.c \
	&& gcc -shared -o base64.so lbase64.o \
	;
	fi
if [[ "$OS" == 'Darwin' ]]; then
	:\
	&& clang \
		-I ../lulua/lua5.1/include \
		-Wall \
		-fPIC \
		-c lbase64.c \
	&& clang -bundle -undefined dynamic_lookup -o  base64.so lbase64.o \
	;
	fi
