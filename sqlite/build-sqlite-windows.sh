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
	-I sqlite3 \
	-Wall \
	-fPIC \
	-c lsqlite3.c sqlite3/sqlite3.c \
&& $CC -shared -o sqlite.dll sqlite3.o lsqlite3.o -L.. -l:lua51.dll \
;
