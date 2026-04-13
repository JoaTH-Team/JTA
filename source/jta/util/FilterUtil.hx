package jta.util;

import jta.Data;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

/**
 * Utility class for managing color filters.
 * Provides predefined color matrices that simulate various types of color blindness and
 * allows creating ColorMatrixFilter instances for use in image processing.
 */
class FilterUtil
{
	/**
	 * Map of color blindness simulation filters as arrays of floats.
	 * Each entry represents a color matrix that can be used to simulate specific types of color blindness.
	 */
	private static final filters:Map<String, Array<Float>> = [
		'Deuteranopia' => [
			 0.43, 0.72, -0.15, 0, 0,
			 0.34, 0.57,  0.09, 0, 0,
			-0.02, 0.03,  1.00, 0, 0,
			    0,    0,     0, 1, 0
		],
		'Deuteranomaly' => [
			  0.8,   0.2,     0, 0, 0,
			0.258, 0.742,     0, 0, 0,
			    0, 0.142, 0.858, 0, 0,
			    0,     0,     0, 1, 0
		],
		'Protanopia' => [
			0.20,  0.99, -0.19, 0, 0,
			0.16,  0.79,  0.04, 0, 0,
			0.01, -0.01,  1.00, 0, 0,
			   0,     0,     0, 1, 0
		],
		'Protanomaly' => [
			0.817, 0.183,     0, 0, 0,
			0.333, 0.667,     0, 0, 0,
			    0, 0.125, 0.875, 0, 0,
			    0,     0,     0, 1, 0
		],
		'Tritanopia' => [
			0.97, 0.11, -0.08, 0, 0,
			0.02, 0.82,  0.16, 0, 0,
			0.06, 0.88,  0.18, 0, 0,
			   0,    0,     0, 1, 0
		],
		'Tritanomaly' => [
			0.967, 0.033,     0, 0, 0,
			    0, 0.733, 0.267, 0, 0,
			    0, 0.183, 0.817, 0, 0,
			    0,     0,     0, 1, 0
		],
		'Achromatopsia' => [
			0.299, 0.587, 0.114, 0, 0,
			0.299, 0.587, 0.114, 0, 0,
			0.299, 0.587, 0.114, 0, 0,
			    0,     0,     0, 1, 0
		],
		'Achromatomaly' => [
			0.618, 0.320, 0.062, 0, 0,
			0.163, 0.775, 0.062, 0, 0,
			0.163, 0.320, 0.516, 0, 0,
			    0,     0,     0, 1, 0
		],
		'Gameboy' => [
			   0,    0,    0, 0, 0,
			0.33, 0.34, 0.33, 0, 0,
			   0,    0,    0, 0, 0,
			   0,    0,    0, 1, 0
		],
		'Virtual Boy' => [
			0.34, 0.33, 0.33, 0, 0,
			   0,    0,    0, 0, 0,
			   0,    0,    0, 0, 0,
			   0,    0,    0, 1, 0
		]
	];

	/**
	 * Retrieves a ColorMatrixFilter based on the provided filter name.
	 * @param name The name of the filter (e.g., 'Deuteranopia', 'Protanopia').
	 * @return A ColorMatrixFilter instance representing the color transformation for the specified color blindness type, or null if the filter does not exist.
	 */
	public static function getFilter(name:String):Null<BitmapFilter>
	{
		final matrix:Null<Array<Float>> = filters.get(name);

		if (matrix != null && matrix.length > 0)
			return new ColorMatrixFilter(matrix);
		else
			return null;
	}

	/**
	 * Retrieves the list of available filter names.
	 * @return An array of strings representing the keys in the filters map.
	 */
	public static function getFiltersKeys():Array<String>
	{
		final orderedKeys:Array<String> = [
			'Deuteranopia',
			'Deuteranomaly',
			'Protanopia',
			'Protanomaly',
			'Tritanopia',
			'Tritanomaly',
			'Achromatopsia',
			'Achromatomaly',
			'Gameboy',
			'Virtual Boy'
		];
		return [for (k in orderedKeys) if (filters.exists(k)) k];
	}

	/**
	 * Reloads and applies a specified color filter to the game.
	 * @param filter The name of the filter to apply.
	 */
	public static function reloadGameFilter(filter:String):Void
	{
		if (filter == null || filter.length <= 0)
			return;

		Data.settings.filter = filter;

		if (getFiltersKeys().contains(filter))
		{
			final filterName:Null<String> = Data.settings.filter;

			if (filterName != null)
			{
				final bitmapFilter:Null<BitmapFilter> = getFilter(filterName);

				if (bitmapFilter != null)
					FlxG.game.setFilters([bitmapFilter]);
			}
		}
		else
			FlxG.game.setFilters([]);
	}
}
