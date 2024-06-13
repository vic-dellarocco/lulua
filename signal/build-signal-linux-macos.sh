#!/bin/bash
set -euo pipefail
OS=$(uname)

if [[ "$OS" == 'Linux'  ]]; then
	:\
	&& gcc \
		-I ../lulua/lua5.1/include \
		-Wall -Wno-unused-function -Wno-unused-variable \
		-fPIC \
		-c lsignal.c \
	&& gcc -shared -o signal.so lsignal.o \
	;
	fi
if [[ "$OS" == 'Darwin' ]]; then
	:\
	&& clang \
		-I ../lulua/lua5.1/include \
		-Wall \
		-fPIC \
		-c lsignal.c \
	&& clang -bundle -undefined dynamic_lookup -o signal.so lsignal.o \
	;
	fi
