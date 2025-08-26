#!/bin/bash
# build lua5.1 for windows on linux:
:\
&& make clean \
&& make PLAT=mingw \
&& mv src/lua.exe src/lua51.dll ../ \
;
