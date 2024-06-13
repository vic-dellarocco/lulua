#!/bin/bash
set -euo pipefail

:\
&& gcc \
	-I ../lulua/lua5.1/include \
	-I sqlite3 \
	-Wall \
	-fPIC \
	-c lsqlite3.c sqlite3/sqlite3.c \
&& gcc -shared -o sqlite.so sqlite3.o lsqlite3.o \
;
