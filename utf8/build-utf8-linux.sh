#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails






set -u; # fail on unset vars.


:\
&& gcc \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c lutf8lib.c \
&& gcc -shared -o utf8.so lutf8lib.o \
;