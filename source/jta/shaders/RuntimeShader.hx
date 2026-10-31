package jta.shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
import jta.Assets;

/**
 * A shader that's generated at runtime instead of being compiled.
 *
 * ```haxe
 * var shader = new RuntimeShader('example');
 * FlxG.camera.filters = [shader.toFilter()];
 * sprite.shader = shader;
 * ```
 */
class RuntimeShader extends FlxRuntimeShader
{
	/**
	 * Seconds since the shader was made. Sent to the shader as `iTime` by `update()`.
	 */
	public var time:Float = 0;

	/**
	 * @param fragmentSource The fragment shader: a name in `assets/shaders/` (`example`) or a full path (`assets/shaders/example.frag`).
	 * @param vertexSource The vertex shader, same as above (optional).
	 */
	public function new(fragmentSource:String, ?vertexSource:String)
	{
		super(load(fragmentSource, 'frag'), (vertexSource != null) ? load(vertexSource, 'vert') : null);
	}

	/**
	 * Wraps the shader in a `ShaderFilter`, for `FlxCamera.filters` (or `FlxG.game.filters`).
	 */
	public function toFilter():ShaderFilter
	{
		return new ShaderFilter(this);
	}

	/**
	 * Adds to `time` and sends it to the shader's `iTime` uniform (if it has one).
	 * Call this from the state's `update()`.
	 */
	public function update(elapsed:Float):Void
	{
		time += elapsed;

		if (Reflect.field(data, 'iTime') != null)
			setFloat('iTime', time);
	}

	/**
	 * Reads a shader file. Returns null (so the default shader is used) if it can't be found.
	 */
	static function load(source:String, ext:String):Null<String>
	{
		final path:String = (source.indexOf('/') >= 0) ? source : Paths.shader(source, ext);

		if (!Assets.exists(path))
		{
			FlxG.log.error('Shader file "$path" not found, using the default shader.');
			return null;
		}

		return Assets.getText(path);
	}
}
