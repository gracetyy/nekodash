## ObstacleSystem — manages obstacle rendering and indexing for loaded levels.
## Implements: design/gdd/obstacle-system.md
## Task: S4-04
##
## Responsibilities:
##   1. Iterates all grid coordinates and sets TileMapLayer cells via
##      GridSystem.get_tile_art_id() for both walkable floor and BLOCKING wall tiles.
##   2. Builds _obstacle_index containing all non-NONE obstacle tiles.
##   3. Emits obstacle_registered per obstacle recorded in the index.
##   4. reset() clears the obstacle index and TileMapLayer completely.
##   5. set_obstacle_active() is stubbed at MVP with push_warning().
extends Node


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted once per obstacle tile added to the index during initialize_obstacles().
signal obstacle_registered(coord: Vector2i, type: GridSystem.ObstacleType)


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

## Maps grid coordinates to obstacle types. Only populated for tiles where
## obstacle_type != ObstacleType.NONE.
var _obstacle_index: Dictionary = {} # Dictionary[Vector2i, GridSystem.ObstacleType]

## Cached TileMapLayer reference from initialize_obstacles(). Used by reset()
## to guarantee cleanup even if the caller omits the parameter.
var _tilemap_layer: TileMapLayer = null

## Whether the system has been initialized (Initialized state).
var _initialized: bool = false


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Iterates all grid coordinates, sets TileMapLayer cells via
## GridSystem.get_tile_art_id(), and builds the obstacle index.
## Emits obstacle_registered for each non-NONE obstacle tile.
##
## Must be called AFTER GridSystem.load_grid(). The tilemap_layer parameter
## is dependency-injected to keep this system scene-agnostic and testable.
func initialize_obstacles(level_data: LevelData, tilemap_layer: TileMapLayer) -> void:
	if level_data == null:
		push_error("ObstacleSystem: initialize_obstacles() called with null LevelData.")
		return

	# Guard: Grid must be loaded first (width > 0 means loaded)
	var grid_w: int = GridSystem.get_width()
	var grid_h: int = GridSystem.get_height()

	if grid_w == 0 or grid_h == 0:
		push_error("ObstacleSystem: initialize_obstacles() called before GridSystem.load_grid(). No-op.")
		return

	# Cache the TileMapLayer reference for reset()
	_tilemap_layer = tilemap_layer

	# Defensive: if called twice without reset(), clear first to prevent duplicates
	if _initialized:
		_obstacle_index.clear()
		if _tilemap_layer != null:
			_tilemap_layer.clear()

	# Single pass over all grid coordinates — renders floor + wall tiles
	for row: int in range(grid_h):
		for col: int in range(grid_w):
			var coord := Vector2i(col, row)
			var tile: GridSystem.GridTileData = GridSystem.get_tile(coord)

			# Resolve atlas cell ID from walkability + obstacle type
			var art_id: int = GridSystem.get_tile_art_id(tile.walkability, tile.obstacle_type)

			# Set the visual cell in TileMapLayer
			if _tilemap_layer != null:
				_tilemap_layer.set_cell(coord, 0, Vector2i(art_id, 0))

			# Index non-NONE obstacle tiles
			if tile.obstacle_type != GridSystem.ObstacleType.NONE:
				_obstacle_index[coord] = tile.obstacle_type
				obstacle_registered.emit(coord, tile.obstacle_type)

	_initialized = true


## Returns the ObstacleType at coord. Returns NONE for out-of-bounds or
## coordinates not in the index.
func get_obstacle_at(coord: Vector2i) -> GridSystem.ObstacleType:
	if _obstacle_index.has(coord):
		return _obstacle_index[coord] as GridSystem.ObstacleType
	return GridSystem.ObstacleType.NONE


## Returns the full obstacle index dictionary (copy). Useful for debugging
## and level-editor tooling.
func get_obstacle_index() -> Dictionary:
	return _obstacle_index.duplicate()


## Returns the number of obstacles currently indexed.
func get_obstacle_count() -> int:
	return _obstacle_index.size()


## Returns true if initialize_obstacles() has been called and not yet reset.
func is_initialized() -> bool:
	return _initialized


## Clears the obstacle index and TileMapLayer. Called by Scene Manager when
## transitioning away from a level scene.
func reset() -> void:
	_obstacle_index.clear()
	_initialized = false

	if _tilemap_layer != null:
		_tilemap_layer.clear()
	_tilemap_layer = null


## Post-jam stub — dynamic obstacles not supported at MVP.
## Logs a warning and performs no state change.
func set_obstacle_active(_coord: Vector2i, _active: bool) -> void:
	push_warning("ObstacleSystem: set_obstacle_active() called — dynamic obstacles not supported in MVP.")
