#! /bin/sh

haxe docs/docs.hxml
haxelib run dox -i docs -o pages --title "Journey Through Aubekhia Documentation" -D source-path https://github.com/JoaTH-Team/JTA/tree/main/source