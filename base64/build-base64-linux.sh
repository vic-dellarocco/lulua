#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails






set -u; # fail on unset vars.


:\
&& gcc \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c lbase64.c \
&& gcc -shared -o base64.so lbase64.o \
;

