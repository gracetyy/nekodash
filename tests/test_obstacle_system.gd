## Unit tests for ObstacleSystem.
## Task: S4-15
## Covers: obstacle index populated, blocking in index, walkable not in index,
##         obstacle_registered signal, reset() clears, set_obstacle_active() stub.
extends GutTest

var _obstacle_sys: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_obstacle_sys = load("res://src/gameplay/obstacle_system.gd").new()
	add_child_autofree(_obstacle_sys)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Creates a minimal LevelData with the given walkability + obstacle arrays.
func _make_level(
	width: int,
	height: int,
	walkability: PackedInt32Array,
	obstacles: PackedInt32Array
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = "test_obs"
	ld.grid_width = width
	ld.grid_height = height
	ld.walkability_tiles = walkability
	ld.obstacle_tiles = obstacles
	ld.cat_start = Vector2i(1, 1)
	return ld


## Builds a 3×3 grid with two STATIC_WALL obstacles at (0,0) and (2,2).
## Border = BLOCKING, center (1,1) = WALKABLE.
func _make_3x3_one_obstacle() -> LevelData:
	var walk := PackedInt32Array([
		1, 1, 1,
		1, 0, 1,
		1, 1, 1,
	])
	var obs := PackedInt32Array([
		1, 0, 0,
		0, 0, 0,
		0, 0, 1,
	])
	return _make_level(3, 3, walk, obs)


## Creates a stub TileMapLayer for initialize_obstacles().
func _make_tilemap() -> TileMapLayer:
	var tl := TileMapLayer.new()
	add_child_autofree(tl)
	return tl


## Loads a level into the GridSystem autoload and initializes obstacles.
func _setup_obstacles(ld: LevelData) -> TileMapLayer:
	GridSystem.load_grid(ld)
	var tl: TileMapLayer = _make_tilemap()
	_obstacle_sys.initialize_obstacles(ld, tl)
	return tl


# —————————————————————————————————————————————
# Tests
# —————————————————————————————————————————————

func test_obstacle_index_populated_correctly() -> void:
	var ld: LevelData = _make_3x3_one_obstacle()
	_setup_obstacles(ld)
	# Two obstacles: (0,0) and (2,2) both STATIC_WALL
	assert_eq(_obstacle_sys.get_obstacle_count(), 2, "Should have 2 obstacles indexed")


func test_blocking_tiles_with_obstacle_in_index() -> void:
	var ld: LevelData = _make_3x3_one_obstacle()
	_setup_obstacles(ld)
	var obs_type: int = _obstacle_sys.get_obstacle_at(Vector2i(0, 0))
	assert_eq(obs_type, GridSystem.ObstacleType.STATIC_WALL, "Obstacle at (0,0) should be STATIC_WALL")


func test_walkable_tiles_not_in_index() -> void:
	var ld: LevelData = _make_3x3_one_obstacle()
	_setup_obstacles(ld)
	var obs_type: int = _obstacle_sys.get_obstacle_at(Vector2i(1, 1))
	assert_eq(obs_type, GridSystem.ObstacleType.NONE, "Walkable tile (1,1) should NOT be in obstacle index")


func test_obstacle_registered_signal_fires() -> void:
	var ld: LevelData = _make_3x3_one_obstacle()
	GridSystem.load_grid(ld)
	var tl: TileMapLayer = _make_tilemap()

	# Watch the signal before calling initialize
	watch_signals(_obstacle_sys)
	_obstacle_sys.initialize_obstacles(ld, tl)

	assert_signal_emit_count(_obstacle_sys, "obstacle_registered", 2,
		"obstacle_registered should fire once per obstacle (2 total)")


func test_reset_clears_index() -> void:
	var ld: LevelData = _make_3x3_one_obstacle()
	_setup_obstacles(ld)
	assert_eq(_obstacle_sys.get_obstacle_count(), 2, "Pre-condition: 2 obstacles")

	_obstacle_sys.reset()

	assert_eq(_obstacle_sys.get_obstacle_count(), 0, "After reset, obstacle count should be 0")
	assert_false(_obstacle_sys.is_initialized(), "After reset, initialized flag should be false")


func test_set_obstacle_active_stub_warns() -> void:
	var ld: LevelData = _make_3x3_one_obstacle()
	_setup_obstacles(ld)

	# set_obstacle_active is a stub — should push_warning and not crash.
	_obstacle_sys.set_obstacle_active(Vector2i(0, 0), false)
	pass_test("set_obstacle_active() did not crash")


func test_get_obstacle_index_returns_copy() -> void:
	var ld: LevelData = _make_3x3_one_obstacle()
	_setup_obstacles(ld)

	var index: Dictionary = _obstacle_sys.get_obstacle_index()
	assert_eq(index.size(), 2, "Index copy should have 2 entries")
	# Mutating the copy should not affect the system
	index.clear()
	assert_eq(_obstacle_sys.get_obstacle_count(), 2, "Original index should be unaffected")


func test_initialize_before_grid_loaded_is_noop() -> void:
	# Reset the GridSystem so width/height are 0
	GridSystem.load_grid(null)

	var ld: LevelData = _make_3x3_one_obstacle()
	var tl: TileMapLayer = _make_tilemap()
	_obstacle_sys.initialize_obstacles(ld, tl)

	assert_eq(_obstacle_sys.get_obstacle_count(), 0, "Should not index anything without grid loaded")
	assert_false(_obstacle_sys.is_initialized(), "Should remain uninitialized")
