#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails

if [ -z "$MACOSX_DEPLOYMENT_TARGET" ]; then
	MACOSX_DEPLOYMENT_TARGET="10.4"
	export MACOSX_DEPLOYMENT_TARGET
fi

set -u; # fail on unset vars.


:\
&& clang \
	-I ../lulua/lua5.1/include \
	-Wall \
	-fPIC \
	-c lsignal.c \
&& clang -bundle -undefined dynamic_lookup -o signal.so lsignal.o \
;