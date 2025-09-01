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
	-c lbase64.c \
&& $CC -shared -o base64.dll lbase64.o -L.. -l:lua51.dll \
;
