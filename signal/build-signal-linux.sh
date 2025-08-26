#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails






set -u; # fail on unset vars.


:\
&& gcc \
	-I ../lulua/lua5.1/include \
	-Wall -Wno-unused-function -Wno-unused-variable \
	-fPIC \
	-c lsignal.c \
&& gcc -shared -o signal.so lsignal.o \
;