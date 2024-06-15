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
		echo "Building lfs for Linux..."
		bash ./build-lfs-linux.sh
		;;
	darwin*|mac*)
		echo "Building lfs for macOS..."
		bash ./build-lfs-macos.sh
		;;
	win*|mingw*) # cross compile on linux for windows:
		echo "Building lfs for Windows (64-bit)..."
		bash ./build-lfs-windows.sh
		;;
	*)
		echo "Unsupported OS: $OS"
		exit 1
		;;
esac
