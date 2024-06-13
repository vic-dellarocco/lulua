#!/bin/bash
set -euo pipefail

:\
&& export MACOSX_DEPLOYMENT_TARGET=10.5 \
&& clang \
	-I ../lulua/lua5.1/include \
	-I sqlite3 \
	-Wall \
	-fPIC \
	-c lsqlite3.c sqlite3/sqlite3.c \
&& clang -bundle -undefined dynamic_lookup -o sqlite.so sqlite3.o lsqlite3.o \
;
