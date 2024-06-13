#!/bin/bash
set -euo pipefail
OS=$(uname)

if [[ "$OS" == 'Linux'  ]]; then
	:\
	&& gcc \
		-I ../lulua/lua5.1/include \
		-Wall \
		-fPIC \
		-c curses.c strings.c \
	&& gcc -shared -o curses.so curses.o strings.o -lncurses \
	;
	fi
if [[ "$OS" == 'Darwin' ]]; then
	:\
	&& clang \
		-I ../lulua/lua5.1/include \
		-Wall \
		-fPIC \
		-c curses.c strings.c \
	&& clang -bundle -undefined dynamic_lookup -o curses.so curses.o strings.o -lncurses \
	;
	fi
