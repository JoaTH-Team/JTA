package jta.states.level;

/**
 * A 2D point/pair stored in level JSON as `{"x": 0, "y": 0}`.
 * Objects instead of `[x, y]` arrays, since JSON arrays cast badly to typed arrays on hxcpp.
 */
typedef LevelPoint =
{
	var x:Float;
	var y:Float;
}

/**
 * Special behavior for one or more tiles of a level's main tilemap (`map.csv`).
 * Used in `level.json` (`tileProperties`) and by `Level.loadMap()` / `Level.setTileProperty()`.
 *
 * ```json
 * "tileProperties": [
 *     { "tile": 9, "range": 3, "collision": "oneway" },
 *     { "tile": 12, "effect": "bounce", "power": 450 },
 *     { "tile": 13, "collision": "none", "effect": "kill" }
 * ]
 * ```
 */
typedef TileProperty =
{
	/**
	 * The tile's number in `map.csv` (its position in the tileset, counting from 0).
	 */
	var tile:Int;

	/**
	 * How many tiles in a row (starting at `tile`) get these properties. Defaults to 1.
	 */
	@:optional var range:Int;

	/**
	 * Which sides of the tile are solid. Defaults to `solid`.
	 * - `solid` / `any`: solid on every side (the normal behavior)
	 * - `none`: not solid at all (you pass through it)
	 * - `oneway` / `platform`: can be stood on, but you can jump up through it from below
	 * - `up`, `down`, `left`, `right`, `wall` (left + right): only those sides are solid.
	 *   Combine them with `|`, e.g. `"up|left"`.
	 */
	@:optional var collision:String;

	/**
	 * What happens when the player touches the tile (or stands in it, for non-solid tiles):
	 * - `kill`: kills the player
	 * - `bounce`: launches the player up (`power` = speed, default 400)
	 * - `bounceLeft` / `bounceRight`: launches the player sideways (`power` = speed, default 300)
	 * - or the name of a custom effect added by a level script with `registerTileEffect()`
	 */
	@:optional var effect:String;

	/**
	 * Strength for the effect (e.g. how high `bounce` launches you).
	 */
	@:optional var power:Float;
}

/**
 * The contents of `assets/levels/<world>/<level>/level.json`.
 * Every field except `name` is optional.
 *
 * The level's ID is its folder path, e.g. `world1/lev1`.
 * Next to `level.json`, the loader looks for `map.csv`, `objects.csv` and (optionally) `background.csv`.
 */
typedef LevelData =
{
	/**
	 * Display name. If it starts with `$`, it's treated as a locale key and looked up in `levels.csv`.
	 */
	var name:String;

	/**
	 * Sort order within the world (lower comes first). Defaults to 0, ties are sorted by ID.
	 */
	@:optional var order:Int;

	/**
	 * Image in `images/menu/level/` used on the level select. Falls back to the placeholder.
	 */
	@:optional var cover:String;

	/**
	 * If `true`, the level is loaded but doesn't show up on the level select (e.g. test levels).
	 */
	@:optional var hidden:Bool;

	/**
	 * Music track in `music/` to play when the level starts.
	 */
	@:optional var music:String;

	/**
	 * Tileset folder in `images/tiles/`. Uses `main.png` for the map and `background.png` for the background layer.
	 */
	@:optional var tileset:String;

	/**
	 * Tile size in pixels (tiles are square). Defaults to 16. Also used as the object grid size.
	 */
	@:optional var tileSize:Int;

	/**
	 * Background color, e.g. `"#00B5E2"`.
	 */
	@:optional var bgColor:String;

	/**
	 * Camera zoom. Defaults to 1.
	 */
	@:optional var zoom:Float;

	/**
	 * Whether the camera follows the player. Defaults to `true`.
	 */
	@:optional var cameraFollow:Bool;

	/**
	 * Player ID to spawn. Defaults to `mainplayer`.
	 */
	@:optional var player:String;

	/**
	 * Where the player spawns, in pixels.
	 */
	@:optional var spawn:LevelPoint;

	/**
	 * Scroll factor of the background tile layer. Defaults to `{"x": 1, "y": 1}`.
	 */
	@:optional var backgroundScroll:LevelPoint;

	/**
	 * Video (in `videos/`, no extension) played after the level is completed, e.g. `cutscenes/world1`.
	 */
	@:optional var endCutscene:String;

	/**
	 * Time limit in seconds. If set, a timer counts down on the HUD and the player loses a life when it hits 0.
	 * Leave it out for an untimed level.
	 */
	@:optional var timeLimit:Float;

	/**
	 * Special tiles in `map.csv`: one-way platforms, non-solid tiles, bouncy or deadly tiles, etc.
	 * See `TileProperty`.
	 */
	@:optional var tileProperties:Array<TileProperty>;
}

/**
 * The contents of `assets/levels/<world>/world.json`. Optional; a world without one sorts last.
 */
typedef WorldData =
{
	/**
	 * Display name (or `$` locale key in `levels.csv`). Shown on the world map and level select.
	 */
	@:optional var name:String;

	/**
	 * Sort order of the world on the world map and level select.
	 */
	@:optional var order:Int;

	/**
	 * If `true`, the world doesn't show up on the world map (e.g. test worlds, or worlds that aren't made yet).
	 */
	@:optional var hidden:Bool;

	/**
	 * Where the world's node sits on the world map, in pixels of `images/menu/worldmap/map.png` (before it's scaled up).
	 */
	@:optional var mapPosition:LevelPoint;

	/**
	 * Optional image in `images/menu/worldmap/` to use for this world's node instead of `node.png`.
	 * Same layout as `node.png`: 4 frames of 16x16 (open, cleared, locked, coming soon).
	 */
	@:optional var icon:String;
}
