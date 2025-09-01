#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails






set -u; # fail on unset vars.


:\
&& rm -rf build \
&& mkdir build \
&& cd build \
&& cmake .. \
	-DWITH_LUAVER=51 -DLUA_INCLUDE_DIR=../lulua/lua5.1/include \
	-DLUA_LIBDIR=luasdl2 \
	-DWITH_DOCSDIR=luasdl2 \
&& make \
&& cd .. \
&& find build -type f -name '*.so' -exec mv {} . \; \
;