#!/bin/bash
set -euo pipefail

OS=$(uname)

if [[ "$OS" == 'Linux' ]]; then
	make linux
fi

if [[ "$OS" == 'Darwin' ]]; then
	make macosx
fi
