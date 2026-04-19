## Unit tests for GridSystem autoload.
## Task: S1-01
## Covers: is_walkable, get_tile, get_all_walkable_tiles, grid_to_pixel,
##         load_grid, edge cases (out-of-bounds, clamp, reload).
extends GutTest

var _grid: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_grid = load("res://src/core/grid_system.gd").new()
	add_child_autofree(_grid)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Builds a minimal LevelData for a width×height grid.
## walkability is a flat array of TileWalkability int values (row-major).
func _make_level(
	width: int,
	height: int,
	walkability: PackedInt32Array,
	obstacles: PackedInt32Array = PackedInt32Array()
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = "test_level"
	ld.grid_width = width
	ld.grid_height = height
	ld.walkability_tiles = walkability
	if obstacles.is_empty():
		obstacles.resize(walkability.size())
		obstacles.fill(0) # ObstacleType.NONE
	ld.obstacle_tiles = obstacles
	ld.cat_start = Vector2i(1, 1)
	return ld


## Builds a 5×5 grid: border walls, interior walkable.
func _make_5x5_bordered() -> LevelData:
	var w: int = 5
	var h: int = 5
	var walk := PackedInt32Array()
	walk.resize(w * h)
	for row in range(h):
		for col in range(w):
			var is_border: bool = (row == 0 or row == h - 1 or col == 0 or col == w - 1)
			walk[col + row * w] = 1 if is_border else 0 # BLOCKING=1, WALKABLE=0
	var obs := PackedInt32Array()
	obs.resize(w * h)
	obs.fill(0)
	return _make_level(w, h, walk, obs)


# —————————————————————————————————————————————
# Tests: Uninitialized state
# —————————————————————————————————————————————

func test_grid_system_uninitialized_width_returns_zero() -> void:
	assert_eq(_grid.get_width(), 0)


func test_grid_system_uninitialized_height_returns_zero() -> void:
	assert_eq(_grid.get_height(), 0)


func test_grid_system_uninitialized_is_walkable_returns_false() -> void:
	assert_false(_grid.is_walkable(Vector2i(0, 0)))


func test_grid_system_uninitialized_get_all_walkable_returns_empty() -> void:
	assert_eq(_grid.get_all_walkable_tiles().size(), 0)


# —————————————————————————————————————————————
# Tests: load_grid — basic
# —————————————————————————————————————————————

func test_grid_system_load_grid_sets_dimensions() -> void:
	# Arrange
	var ld := _make_5x5_bordered()

	# Act
	_grid.load_grid(ld)

	# Assert
	assert_eq(_grid.get_width(), 5)
	assert_eq(_grid.get_height(), 5)


func test_grid_system_load_grid_border_tile_is_blocking() -> void:
	# Arrange
	var ld := _make_5x5_bordered()

	# Act
	_grid.load_grid(ld)

	# Assert — all border tiles should be BLOCKING
	assert_false(_grid.is_walkable(Vector2i(0, 0)), "Top-left corner")
	assert_false(_grid.is_walkable(Vector2i(4, 0)), "Top-right corner")
	assert_false(_grid.is_walkable(Vector2i(0, 4)), "Bottom-left corner")
	assert_false(_grid.is_walkable(Vector2i(4, 4)), "Bottom-right corner")
	assert_false(_grid.is_walkable(Vector2i(2, 0)), "Top edge midpoint")


func test_grid_system_load_grid_interior_tile_is_walkable() -> void:
	# Arrange
	var ld := _make_5x5_bordered()

	# Act
	_grid.load_grid(ld)

	# Assert — interior 3×3 should be WALKABLE
	assert_true(_grid.is_walkable(Vector2i(1, 1)))
	assert_true(_grid.is_walkable(Vector2i(2, 2)))
	assert_true(_grid.is_walkable(Vector2i(3, 3)))


func test_grid_system_load_grid_walkable_count_correct() -> void:
	# Arrange — 5×5 border grid has 3×3 = 9 walkable tiles
	var ld := _make_5x5_bordered()

	# Act
	_grid.load_grid(ld)

	# Assert
	assert_eq(_grid.get_all_walkable_tiles().size(), 9)


# —————————————————————————————————————————————
# Tests: is_walkable — out-of-bounds
# —————————————————————————————————————————————

func test_grid_system_is_walkable_negative_coord_returns_false() -> void:
	# Arrange
	_grid.load_grid(_make_5x5_bordered())

	# Act & Assert
	assert_false(_grid.is_walkable(Vector2i(-1, 0)))
	assert_false(_grid.is_walkable(Vector2i(0, -1)))
	assert_false(_grid.is_walkable(Vector2i(-5, -5)))


func test_grid_system_is_walkable_far_out_of_bounds_returns_false() -> void:
	# Arrange — 5×5 grid
	_grid.load_grid(_make_5x5_bordered())

	# Act & Assert
	assert_false(_grid.is_walkable(Vector2i(100, 100)))
	assert_false(_grid.is_walkable(Vector2i(5, 0)))
	assert_false(_grid.is_walkable(Vector2i(0, 5)))


# —————————————————————————————————————————————
# Tests: get_tile — out-of-bounds
# —————————————————————————————————————————————

func test_grid_system_get_tile_out_of_bounds_returns_blocking() -> void:
	# Arrange
	_grid.load_grid(_make_5x5_bordered())

	# Act
	var tile = _grid.get_tile(Vector2i(100, 100))

	# Assert
	assert_not_null(tile)
	assert_eq(tile.walkability, _grid.TileWalkability.BLOCKING)
	assert_eq(tile.obstacle_type, _grid.ObstacleType.NONE)


# —————————————————————————————————————————————
# Tests: grid_to_pixel
# —————————————————————————————————————————————

func test_grid_system_grid_to_pixel_origin() -> void:
	# Act — tile (0,0) center with 72px tiles
	var px: Vector2 = _grid.grid_to_pixel(Vector2i(0, 0))

	# Assert — center of tile at (0,0) = (36, 36)
	assert_eq(px, Vector2(36.0, 36.0))


func test_grid_system_grid_to_pixel_offset_tile() -> void:
	# Act — tile (3, 2) with 72px tiles
	var px: Vector2 = _grid.grid_to_pixel(Vector2i(3, 2))

	# Assert — 3*72 + 36 = 252, 2*72 + 36 = 180
	assert_eq(px, Vector2(252.0, 180.0))


# —————————————————————————————————————————————
# Tests: load_grid — reload clears stale data
# —————————————————————————————————————————————

func test_grid_system_load_grid_twice_clears_stale_data() -> void:
	# Arrange — load a 5×5, then reload with a 3×3 (all walkable)
	_grid.load_grid(_make_5x5_bordered())
	assert_eq(_grid.get_width(), 5)

	var small_walk := PackedInt32Array()
	small_walk.resize(9)
	small_walk.fill(0) # all WALKABLE
	var ld2 := _make_level(3, 3, small_walk)

	# Act
	_grid.load_grid(ld2)

	# Assert — old 5×5 data gone; dimensions updated; walkable count correct
	assert_eq(_grid.get_width(), 3)
	assert_eq(_grid.get_height(), 3)
	assert_eq(_grid.get_all_walkable_tiles().size(), 9)
	# Old coordinate from 5×5 should no longer exist
	assert_false(_grid.is_walkable(Vector2i(4, 4)))


# —————————————————————————————————————————————
# Tests: load_grid — clamp oversized grid
# —————————————————————————————————————————————

func test_grid_system_load_grid_oversized_clamped_to_max() -> void:
	# Arrange — 20×20 level (exceeds MAX_GRID_SIZE=15)
	var w: int = 20
	var h: int = 20
	var walk := PackedInt32Array()
	walk.resize(w * h)
	walk.fill(0) # all WALKABLE
	var ld := _make_level(w, h, walk)

	# Act
	_grid.load_grid(ld)

	# Assert — dimensions clamped
	assert_eq(_grid.get_width(), 15)
	assert_eq(_grid.get_height(), 15)


# —————————————————————————————————————————————
# Tests: load_grid — reject undersized grid
# —————————————————————————————————————————————

func test_grid_system_load_grid_undersized_rejected() -> void:
	# Arrange — 2×2 level (below MIN_GRID_SIZE=3)
	var walk := PackedInt32Array()
	walk.resize(4)
	walk.fill(0) # all WALKABLE
	var ld := _make_level(2, 2, walk)

	# Act
	_grid.load_grid(ld)

	# Assert — stays uninitialized (rejected, not clamped up)
	assert_eq(_grid.get_width(), 0)
	assert_eq(_grid.get_height(), 0)
	assert_eq(_grid.get_all_walkable_tiles().size(), 0)


func test_grid_system_load_grid_undersized_one_axis_rejected() -> void:
	# Arrange — 2×5 level (width below MIN_GRID_SIZE)
	var walk := PackedInt32Array()
	walk.resize(10)
	walk.fill(0)
	var ld := _make_level(2, 5, walk)

	# Act
	_grid.load_grid(ld)

	# Assert — rejected
	assert_eq(_grid.get_width(), 0)


# —————————————————————————————————————————————
# Tests: zero walkable tiles
# —————————————————————————————————————————————

func test_grid_system_load_grid_zero_walkable_no_crash() -> void:
	# Arrange — 3×3, all BLOCKING
	var walk := PackedInt32Array()
	walk.resize(9)
	walk.fill(1) # all BLOCKING
	var ld := _make_level(3, 3, walk)

	# Act — should not crash
	_grid.load_grid(ld)

	# Assert
	assert_eq(_grid.get_all_walkable_tiles().size(), 0)


# —————————————————————————————————————————————
# Tests: get_tile_art_id
# —————————————————————————————————————————————

func test_grid_system_art_id_walkable_returns_zero() -> void:
	var id: int = _grid.get_tile_art_id(
		_grid.TileWalkability.WALKABLE, _grid.ObstacleType.NONE
	)
	assert_eq(id, 0)


func test_grid_system_art_id_blocking_returns_one() -> void:
	var id: int = _grid.get_tile_art_id(
		_grid.TileWalkability.BLOCKING, _grid.ObstacleType.STATIC_WALL
	)
	assert_eq(id, 1)


# —————————————————————————————————————————————
# Tests: null LevelData
# —————————————————————————————————————————————

func test_grid_system_load_grid_null_no_crash() -> void:
	# Act — should not crash, just warn
	_grid.load_grid(null)

	# Assert — stays uninitialized
	assert_eq(_grid.get_width(), 0)
	assert_eq(_grid.get_height(), 0)


# —————————————————————————————————————————————
# Tests: get_tile — valid tiles
# —————————————————————————————————————————————

func test_grid_system_get_tile_walkable_returns_correct_data() -> void:
	# Arrange
	_grid.load_grid(_make_5x5_bordered())

	# Act — interior tile (1,1) is WALKABLE
	var tile = _grid.get_tile(Vector2i(1, 1))

	# Assert
	assert_eq(tile.walkability, _grid.TileWalkability.WALKABLE)
	assert_eq(tile.obstacle_type, _grid.ObstacleType.NONE)


func test_grid_system_get_tile_blocking_returns_correct_data() -> void:
	# Arrange
	_grid.load_grid(_make_5x5_bordered())

	# Act — border tile (0,0) is BLOCKING
	var tile = _grid.get_tile(Vector2i(0, 0))

	# Assert
	assert_eq(tile.walkability, _grid.TileWalkability.BLOCKING)


# —————————————————————————————————————————————
# Tests: all-walkable grid (GDD edge case)
# —————————————————————————————————————————————

func test_grid_system_all_walkable_grid_valid() -> void:
	# Arrange — 4×4, all WALKABLE (no walls)
	var walk := PackedInt32Array()
	walk.resize(16)
	walk.fill(0) # all WALKABLE
	var ld := _make_level(4, 4, walk)

	# Act
	_grid.load_grid(ld)

	# Assert — all 16 tiles walkable
	assert_eq(_grid.get_all_walkable_tiles().size(), 16)
	assert_true(_grid.is_walkable(Vector2i(0, 0)))
	assert_true(_grid.is_walkable(Vector2i(3, 3)))


# —————————————————————————————————————————————
# Tests: obstacle_tiles stored correctly
# —————————————————————————————————————————————

func test_grid_system_obstacle_type_stored() -> void:
	# Arrange — 3×3, one STATIC_WALL obstacle at (1,1)
	var walk := PackedInt32Array()
	walk.resize(9)
	walk.fill(1) # all BLOCKING
	var obs := PackedInt32Array()
	obs.resize(9)
	obs.fill(0) # all NONE
	obs[4] = 1 # (1,1) = STATIC_WALL: index = 1 + 1*3 = 4
	var ld := _make_level(3, 3, walk, obs)

	# Act
	_grid.load_grid(ld)

	# Assert
	var tile = _grid.get_tile(Vector2i(1, 1))
	assert_eq(tile.obstacle_type, _grid.ObstacleType.STATIC_WALL)
	# Other tiles have NONE
	var corner = _grid.get_tile(Vector2i(0, 0))
	assert_eq(corner.obstacle_type, _grid.ObstacleType.NONE)


# —————————————————————————————————————————————
# Tests: walkable cache is independent copy
# —————————————————————————————————————————————

func test_grid_system_get_all_walkable_returns_independent_copy() -> void:
	# Arrange
	_grid.load_grid(_make_5x5_bordered())
	var original_count: int = _grid.get_all_walkable_tiles().size()

	# Act — mutate the returned array
	var returned: Array[Vector2i] = _grid.get_all_walkable_tiles()
	returned.clear()

	# Assert — internal cache unaffected
	assert_eq(_grid.get_all_walkable_tiles().size(), original_count)


# —————————————————————————————————————————————
# Tests: walkable cache contains correct coordinates
# —————————————————————————————————————————————

func test_grid_system_walkable_cache_contains_correct_coords() -> void:
	# Arrange
	_grid.load_grid(_make_5x5_bordered())

	# Act
	var walkable: Array[Vector2i] = _grid.get_all_walkable_tiles()

	# Assert — all 9 interior tiles present
	assert_true(walkable.has(Vector2i(1, 1)))
	assert_true(walkable.has(Vector2i(2, 2)))
	assert_true(walkable.has(Vector2i(3, 3)))
	assert_true(walkable.has(Vector2i(1, 3)))
	assert_true(walkable.has(Vector2i(3, 1)))
	# Border tiles absent
	assert_false(walkable.has(Vector2i(0, 0)))
	assert_false(walkable.has(Vector2i(4, 4)))


# —————————————————————————————————————————————
# Tests: ObstacleType blocks is_walkable
# —————————————————————————————————————————————

func test_grid_system_static_wall_obstacle_on_walkable_tile_is_not_walkable() -> void:
	# Arrange — 3×3 all-walkable grid with a STATIC_WALL obstacle at (1,1)
	var walk := PackedInt32Array()
	walk.resize(9)
	walk.fill(0) # all WALKABLE
	var obs := PackedInt32Array()
	obs.resize(9)
	obs.fill(0) # all NONE
	obs[4] = 1 # (1,1) index=4 = STATIC_WALL
	var ld := _make_level(3, 3, walk, obs)

	# Act
	_grid.load_grid(ld)

	# Assert — WALKABLE floor + STATIC_WALL obstacle must count as not-walkable
	assert_false(_grid.is_walkable(Vector2i(1, 1)), "STATIC_WALL tile must not be walkable")
	# Other interior tiles unchanged
	assert_true(_grid.is_walkable(Vector2i(0, 0)))
	assert_true(_grid.is_walkable(Vector2i(2, 2)))


func test_grid_system_static_wall_tile_excluded_from_walkable_cache() -> void:
	# Arrange — 5×5 bordered grid with a STATIC_WALL at (2,2) which is otherwise walkable
	var ld: LevelData = _make_5x5_bordered()
	var obs: PackedInt32Array = ld.obstacle_tiles
	obs[2 + 2 * 5] = 1 # (2,2) = STATIC_WALL
	ld.obstacle_tiles = obs

	# Act
	_grid.load_grid(ld)

	# Assert — 9 interior tiles minus 1 STATIC_WALL = 8 tiles in cache
	var walkable: Array[Vector2i] = _grid.get_all_walkable_tiles()
	assert_eq(walkable.size(), 8, "STATIC_WALL tile must not appear in walkable cache")
	assert_false(walkable.has(Vector2i(2, 2)), "STATIC_WALL coord must be absent from cache")
	# Remaining interior tiles still present
	assert_true(walkable.has(Vector2i(1, 1)))
	assert_true(walkable.has(Vector2i(3, 3)))


func test_grid_system_walkable_tile_with_no_obstacle_is_still_walkable() -> void:
	# Arrange — confirm that a WALKABLE + NONE tile is correctly walkable (regression)
	var walk := PackedInt32Array()
	walk.resize(9)
	walk.fill(0) # all WALKABLE
	var obs := PackedInt32Array()
	obs.resize(9)
	obs.fill(0) # all NONE
	var ld := _make_level(3, 3, walk, obs)

	# Act
	_grid.load_grid(ld)

	# Assert
	assert_true(_grid.is_walkable(Vector2i(1, 1)))
	assert_true(_grid.is_walkable(Vector2i(0, 0)))
