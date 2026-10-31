#!/bin/sh
set -e

VERSION=$(tr '\n' ' ' < Project.xml | grep -o '<app [^>]*' | grep -o 'version="[^"]*"' | head -n 1 | cut -d '"' -f 2)

haxe docs/docs.hxml

haxelib run dox \
	-theme ./docs/theme \
	-i docs \
	-o pages \
	--title "Journey Through Aubekhia Documentation" \
	-in "jta" \
	--toplevel-package jta \
	-D source-path "https://github.com/JoaTH-Team/JTA/tree/main/source" \
	-D logo "https://raw.githubusercontent.com/JoaTH-Team/JTA/main/docs/icon_small.png" \
	-D website "https://joalor64.itch.io/journey-through-aubekhia" \
	-D version "$VERSION"