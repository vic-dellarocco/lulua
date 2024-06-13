#!/bin/bash
set -euo pipefail

OS=$(uname)

if [[ "$OS" == 'Linux' ]]; then
:\
&& cp ../lua build-aux/lua \
&& touch build-aux/init.lua \
&& build-aux/lua build-aux/luke LUA_INCDIR=../lulua/lua5.1/include \
&& cp lib/posix/*.lua  . \
&& cp -r linux/posix/* . \
&& rm build-aux/lua \
&& rm build-aux/init.lua \
;
fi

if [[ "$OS" == 'Darwin' ]]; then
:\
&& cp ../lua build-aux/lua \
&& touch build-aux/init.lua \
&& build-aux/lua build-aux/luke LUA_INCDIR=../lulua/lua5.1/include \
&& cp lib/posix/*.lua  . \
&& cp -r macosx/posix/* . \
&& rm build-aux/lua \
&& rm build-aux/init.lua \
;
fi

# to clean:
# find . -type f -iname '*.so' -delete
#