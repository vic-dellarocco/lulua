#!/bin/bash
set -e ;         # fail if a command fails
set -o pipefail; # fail if a pipe command fails

if [ -z "$OS" ]; then
	OS=$(uname -s)
fi
OS=$(echo "$OS" | tr '[:upper:]' '[:lower:]')

case $OS in
	linux*)
		echo "Building sqlite for Linux..."
		bash ./build-sqlite-linux.sh
		;;
	darwin*|mac*)
		echo "Building sqlite for macOS..."
		bash ./build-sqlite-macos.sh
		;;
	win*|mingw*) # cross compile on linux for windows:
		echo "Building sqlite for Windows (64-bit)..."
		bash ./build-sqlite-windows.sh
		;;
	*)
		echo "Unsupported OS: $OS"
		exit 1
		;;
esac
