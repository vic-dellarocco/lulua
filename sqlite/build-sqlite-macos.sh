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
	-I sqlite3 \
	-Wall \
	-fPIC \
	-c lsqlite3.c sqlite3/sqlite3.c \
&& clang -bundle -undefined dynamic_lookup -o sqlite.so sqlite3.o lsqlite3.o \
;
