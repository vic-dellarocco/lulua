#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails

CC=x86_64-w64-mingw32-gcc
export HOST_CC=gcc
export TARGET_SYS=Windows \
# It won't work:
exit 1
set -u; # fail on unset vars.
#The only way this works is if you find a compatible curses library
#and find out how to link to it, so right now, IT DOESN'T WORK.
:\
&& $CC \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c curses.c strings.c \
&& $CC -shared -o curses.dll curses.o strings.o -L.. -l:lua51.dll -lncurses \
;
