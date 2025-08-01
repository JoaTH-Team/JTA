#if !macro
import flixel.*;
import flixel.util.*;
import flixel.math.*;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.*;
import flixel.input.keyboard.*;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.addons.transition.FlxTransitionableState;
import openfl.Lib;
import openfl.Assets;
import lime.app.Application;
#if sys
import sys.*;
import sys.io.*;
#else
import openfl.Assets;
#end
import haxe.*;
#end

using StringTools;

#if !debug
@:noDebug
#end
