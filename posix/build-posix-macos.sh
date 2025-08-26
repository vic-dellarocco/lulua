#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails

if [ -z "$MACOSX_DEPLOYMENT_TARGET" ]; then
	MACOSX_DEPLOYMENT_TARGET="10.4"
	export MACOSX_DEPLOYMENT_TARGET
fi

set -u; # fail on unset vars.


:\
&& cp ../lua build-aux/lua \
&& touch build-aux/init.lua \
&& build-aux/lua build-aux/luke LUA_INCDIR=../lulua/lua5.1/include \
&& cp lib/posix/*.lua  . \
&& cp -r macosx/posix/* . \
&& rm build-aux/lua \
&& rm build-aux/init.lua \
;