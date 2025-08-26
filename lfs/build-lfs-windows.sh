#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails

CC=x86_64-w64-mingw32-gcc
export HOST_CC=gcc
export TARGET_SYS=Windows \


set -u; # fail on unset vars.


:\
&& $CC \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c -o src/lfs.o src/lfs.c \
&& $CC -shared -o src/lfs.dll src/lfs.o -L.. -l:lua51.dll \
&& mv src/lfs.dll ./lfs.dll \
;
