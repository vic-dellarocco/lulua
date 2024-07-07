#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails






set -u; # fail on unset vars.


:\
&& gcc \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c curses.c strings.c \
&& gcc -shared -o curses.so curses.o strings.o -lncurses \
;
