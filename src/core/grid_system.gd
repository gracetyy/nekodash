## GridSystem — foundational autoload providing the logical tile grid.
## Implements: design/gdd/grid-system.md
## Task: S1-01
##
## The Grid System is the single source of truth for tile layout. It exposes
## a query API consumed by Sliding Movement, Coverage Tracking, BFS Solver,
## and the TileMapLayer renderer.
##
## Usage:
##   GridSystem.load_grid(level_data)
##   GridSystem.is_walkable(Vector2i(3, 2))       # -> true / false
##   GridSystem.get_tile(Vector2i(3, 2))           # -> GridTileData
##   GridSystem.get_all_walkable_tiles()            # -> Array[Vector2i]
##   GridSystem.grid_to_pixel(Vector2i(3, 2))      # -> Vector2(224.0, 160.0)
extends Node


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when the current tile size changes.
## Usage:
##   GridSystem.tile_size_changed.connect(_on_tile_size_changed)
signal tile_size_changed(tile_size_px: int)


# —————————————————————————————————————————————
# Enums
# —————————————————————————————————————————————

## Whether the cat can enter this tile.
enum TileWalkability {
	WALKABLE = 0,
	BLOCKING = 1,
}

## What kind of obstacle occupies this tile (MVP: only NONE and STATIC_WALL).
enum ObstacleType {
	NONE = 0,
	STATIC_WALL = 1,
}

## Special mechanics for the tile (traversal death, forced stop, etc.)
enum SpecialTileType {
	NONE = 0,
	KILL = 1,
	STOP_TILE = 2,
	ONE_WAY_UP = 3,
	ONE_WAY_DOWN = 4,
	ONE_WAY_LEFT = 5,
	ONE_WAY_RIGHT = 6,
}


# —————————————————————————————————————————————
# Constants (tuning knobs — see GDD Section G)
# —————————————————————————————————————————————

## Minimum allowed grid dimension (width or height).
const MIN_GRID_SIZE: int = 3

## Maximum allowed grid dimension (width or height). Levels exceeding this
## are clamped with a warning.
const MAX_GRID_SIZE: int = 15

## Pixel size of each tile. Referenced by other
## systems (Input System tap zones, TileMapLayer cell size).
const DEFAULT_TILE_SIZE_PX: int = 72

## The actual tile size used for rendering and movement, can be changed dynamically.
var _current_tile_size: int = DEFAULT_TILE_SIZE_PX


# —————————————————————————————————————————————
# Inner class
# —————————————————————————————————————————————

## Per-tile data container returned by get_tile().
class GridTileData:
	var walkability: TileWalkability
	var obstacle_type: ObstacleType
	var special_type: SpecialTileType

	func _init(
		p_walkability: TileWalkability = TileWalkability.BLOCKING,
		p_obstacle_type: ObstacleType = ObstacleType.NONE,
		p_special_type: SpecialTileType = SpecialTileType.NONE
	) -> void:
		walkability = p_walkability
		obstacle_type = p_obstacle_type
		special_type = p_special_type


# —————————————————————————————————————————————
# Private state
# —————————————————————————————————————————————

## Logical grid — sparse dictionary keyed by Vector2i.
var _tiles: Dictionary = {} # Dictionary[Vector2i, GridTileData]

## Cached list of walkable coordinates, built once in load_grid().
var _walkable_cache: Array[Vector2i] = []

## Current grid dimensions (0×0 when Uninitialized).
var _width: int = 0
var _height: int = 0


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Clears existing state and populates the tile dictionary from a LevelData
## resource. Clamps dimensions to MAX_GRID_SIZE. Caches walkable tile list.
##
## Usage:
##   GridSystem.load_grid(level_data)
func load_grid(level_data: LevelData) -> void:
	_clear()

	if level_data == null:
		push_warning("GridSystem: load_grid() called with null LevelData.")
		return

	# Reject undersized grids — they are malformed content, not clampable
	if level_data.grid_width < MIN_GRID_SIZE or level_data.grid_height < MIN_GRID_SIZE:
		push_error(
			"GridSystem: LevelData grid (%dx%d) is below MIN_GRID_SIZE (%d). Rejected."
			% [level_data.grid_width, level_data.grid_height, MIN_GRID_SIZE]
		)
		return

	# Clamp oversized dimensions down to MAX_GRID_SIZE
	_width = mini(level_data.grid_width, MAX_GRID_SIZE)
	_height = mini(level_data.grid_height, MAX_GRID_SIZE)

	if level_data.grid_width > MAX_GRID_SIZE or level_data.grid_height > MAX_GRID_SIZE:
		push_warning(
			"GridSystem: LevelData grid (%dx%d) exceeds MAX_GRID_SIZE (%d). Clamped to %dx%d."
			% [level_data.grid_width, level_data.grid_height, MAX_GRID_SIZE, _width, _height]
		)

	# Populate tiles from packed arrays
	var walkability_arr: PackedInt32Array = level_data.walkability_tiles
	var obstacle_arr: PackedInt32Array = level_data.obstacle_tiles
	var special_arr: PackedInt32Array = level_data.special_tiles
	for row in range(_height):
		for col in range(_width):
			var index: int = col + row * level_data.grid_width
			# Guard against short arrays — default to BLOCKING / NONE
			var walk_val: int = walkability_arr[index] if index < walkability_arr.size() else TileWalkability.BLOCKING
			var obs_val: int = obstacle_arr[index] if index < obstacle_arr.size() else ObstacleType.NONE
			var spec_val: int = special_arr[index] if index < special_arr.size() else SpecialTileType.NONE

			var tile := GridTileData.new(
				walk_val as TileWalkability,
				obs_val as ObstacleType,
				spec_val as SpecialTileType
			)

			var coord := Vector2i(col, row)
			_tiles[coord] = tile

			if walk_val == TileWalkability.WALKABLE and obs_val == ObstacleType.NONE and spec_val != SpecialTileType.KILL:
				_walkable_cache.append(coord)

	if _walkable_cache.is_empty():
		push_error("GridSystem: Level '%s' has zero walkable tiles." % level_data.level_id)


## Returns true if the tile at coord is WALKABLE. Out-of-bounds -> false.
##
## Usage:
##   var can_enter: bool = GridSystem.is_walkable(Vector2i(3, 2))
func is_walkable(coord: Vector2i) -> bool:
	if not _tiles.has(coord):
		return false
	var tile: GridTileData = _tiles[coord]
	return tile.walkability == TileWalkability.WALKABLE and tile.obstacle_type == ObstacleType.NONE


## Returns true if the tile at coord is a KILL tile.
func is_kill(coord: Vector2i) -> bool:
	if not _tiles.has(coord):
		return false
	return _tiles[coord].special_type == SpecialTileType.KILL


## Returns true if the tile at coord is a STOP_TILE.
func is_stop_tile(coord: Vector2i) -> bool:
	if not _tiles.has(coord):
		return false
	return _tiles[coord].special_type == SpecialTileType.STOP_TILE


## Returns the allowed entry direction for a ONE_WAY tile, or Vector2i.ZERO if not ONE_WAY.
func get_one_way_direction(coord: Vector2i) -> Vector2i:
	if not _tiles.has(coord):
		return Vector2i.ZERO
	var type: SpecialTileType = _tiles[coord].special_type
	match type:
		SpecialTileType.ONE_WAY_UP: return Vector2i.UP
		SpecialTileType.ONE_WAY_DOWN: return Vector2i.DOWN
		SpecialTileType.ONE_WAY_LEFT: return Vector2i.LEFT
		SpecialTileType.ONE_WAY_RIGHT: return Vector2i.RIGHT
		_: return Vector2i.ZERO


## Returns the GridTileData for coord. Out-of-bounds -> default BLOCKING/NONE.
## Never returns null.
##
## Usage:
##   var tile: GridSystem.GridTileData = GridSystem.get_tile(Vector2i(3, 2))
func get_tile(coord: Vector2i) -> GridTileData:
	if _tiles.has(coord):
		return _tiles[coord]
	return GridTileData.new(TileWalkability.BLOCKING, ObstacleType.NONE)


## Returns a copy of the cached walkable tile coordinate list. The cache is
## built once during load_grid(); this method duplicates it to prevent
## callers from mutating internal state.
##
## Usage:
##   var walkable: Array[Vector2i] = GridSystem.get_all_walkable_tiles()
func get_all_walkable_tiles() -> Array[Vector2i]:
	return _walkable_cache.duplicate()


## Returns grid width. 0 if Uninitialized.
func get_width() -> int:
	return _width


## Returns grid height. 0 if Uninitialized.
func get_height() -> int:
	return _height


## Returns the current tile size in pixels.
func get_tile_size() -> int:
	return _current_tile_size


## Sets the current tile size in pixels.
func set_tile_size(value: int) -> void:
	var next_size: int = maxi(1, value)
	if next_size == _current_tile_size:
		return
	_current_tile_size = next_size
	tile_size_changed.emit(_current_tile_size)


## Converts a grid coordinate to pixel-space center position.
##
## Usage:
##   var px: Vector2 = GridSystem.grid_to_pixel(Vector2i(1, 2))
func grid_to_pixel(coord: Vector2i) -> Vector2:
	return Vector2(coord) * _current_tile_size + Vector2.ONE * (_current_tile_size * 0.5)


## Maps a (walkability, obstacle_type) pair to a TileMapLayer atlas cell ID.
## Atlas IDs are placeholders until Art Director defines the tile atlas.
##
## Usage:
##   var cell_id: int = GridSystem.get_tile_art_id(
##       GridSystem.TileWalkability.WALKABLE, GridSystem.ObstacleType.NONE)
func get_tile_art_id(walkability: TileWalkability, obstacle_type: ObstacleType) -> int:
	# Placeholder mapping — will be updated when tile atlas is authored.
	if walkability == TileWalkability.BLOCKING:
		if obstacle_type == ObstacleType.STATIC_WALL:
			return 1
		return 1 # plain wall
	return 0 # walkable floor


# —————————————————————————————————————————————
# Private helpers
# —————————————————————————————————————————————

## Resets all grid state to Uninitialized.
func _clear() -> void:
	_tiles.clear()
	_walkable_cache.clear()
	_width = 0
	_height = 0
