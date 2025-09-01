#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails






set -u; # fail on unset vars.


:\
&& gcc \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c -o src/lfs.o src/lfs.c \
&& gcc -shared -o src/lfs.so src/lfs.o \
&& mv src/lfs.so ./lfs.so \
;