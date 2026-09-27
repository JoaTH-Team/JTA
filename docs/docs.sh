#!/bin/sh
haxe docs/docs.hxml
haxelib run dox -theme ./docs/theme -i docs -o pages --title "Journey Through Aubekhia Documentation" -in "jta" --toplevel-package jta -D source-path https://github.com/JoaTH-Team/JTA/tree/main/source -D logo "https://raw.githubusercontent.com/JoaTH-Team/JTA/main/icon_small.png"