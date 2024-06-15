#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails

if [ -z "$OS" ]; then
	OS=$(uname -s)
fi
OS=$(echo "$OS" | tr '[:upper:]' '[:lower:]')
export OS

case $OS in darwin*|mac*)
	if [ -z "$MACOSX_DEPLOYMENT_TARGET" ]; then
		MACOSX_DEPLOYMENT_TARGET="10.4"
		export MACOSX_DEPLOYMENT_TARGET
	fi
	;;
esac

set -u; # fail on unset vars.

case $OS in
	linux*)
		echo "Building linenoise for Linux..."
		bash ./build-linenoise-linux.sh
		;;
	darwin*|mac*)
		echo "Building linenoise for macOS..."
		bash ./build-linenoise-macos.sh
		;;
	# win*|mingw*) # cross compile on linux for windows:
	# 	echo "Building linenoise for Windows (64-bit)..."
	# 	bash ./build-linenoise-windows.sh
	# 	;;
	*)
		echo "Unsupported OS: $OS"
		exit 1
		;;
esac
