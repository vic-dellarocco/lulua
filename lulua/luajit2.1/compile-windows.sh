#!/bin/bash
# build luajit for windows on linux:
:\
&& make clean \
&& make CROSS=x86_64-w64-mingw32- HOST_CC=gcc TARGET_SYS=Windows \
&& mv src/luajit.exe src/lua51.dll ../ \
;
