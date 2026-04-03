## Unit tests for LevelData .tres files and GridSystem integration.
## Task: S1-04
## Covers: .tres loading, GridSystem population, metadata, walkable counts,
##         slide-line coverage test (section 4 of solvability guide).
extends GutTest

var _grid: Node

# Level paths
const W1_L1_PATH: String = "res://data/levels/world1/w1_l1.tres"
const W1_L2_PATH: String = "res://data/levels/world1/w1_l2.tres"
const W1_L3_PATH: String = "res://data/levels/world1/w1_l3.tres"


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_grid = load("res://src/core/grid_system.gd").new()
	add_child_autofree(_grid)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Loads a LevelData from the given path.
func _load_level(path: String) -> LevelData:
	var level: LevelData = load(path) as LevelData
	assert_not_null(level, "Failed to load LevelData from %s" % path)
	return level


## Slide-line coverage test (section 4.1 of solvability guide).
## Returns true if every walkable tile lies on at least one horizontal or
## vertical slide line of length >= 2.
func _passes_slide_line_coverage(level: LevelData) -> bool:
	# Build a set of walkable coords
	var walkable: Dictionary = {} # Dictionary[Vector2i, bool]
	for row in range(level.grid_height):
		for col in range(level.grid_width):
			var index: int = col + row * level.grid_width
			if index < level.walkability_tiles.size():
				if level.walkability_tiles[index] == 0: # WALKABLE
					walkable[Vector2i(col, row)] = true

	# For each walkable tile, check if it's on a slide line >= 2 tiles
	for tile: Vector2i in walkable:
		var on_slide_line: bool = false

		# Check horizontal line through this tile
		var h_start: Vector2i = tile
		while walkable.has(h_start + Vector2i.LEFT):
			h_start += Vector2i.LEFT
		var h_end: Vector2i = tile
		while walkable.has(h_end + Vector2i.RIGHT):
			h_end += Vector2i.RIGHT
		if h_start != h_end:
			on_slide_line = true

		# Check vertical line through this tile
		if not on_slide_line:
			var v_start: Vector2i = tile
			while walkable.has(v_start + Vector2i.UP):
				v_start += Vector2i.UP
			var v_end: Vector2i = tile
			while walkable.has(v_end + Vector2i.DOWN):
				v_end += Vector2i.DOWN
			if v_start != v_end:
				on_slide_line = true

		if not on_slide_line:
			return false

	return true


# —————————————————————————————————————————————
# Level 1: First Steps (4×3, 2 walkable tiles)
# —————————————————————————————————————————————

func test_level_w1_l1_loads_successfully() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	assert_eq(level.level_id, "w1_l1")


func test_level_w1_l1_metadata() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	assert_eq(level.world_id, 1)
	assert_eq(level.level_index, 1)
	assert_eq(level.display_name, "")


func test_level_w1_l1_grid_dimensions() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	assert_eq(level.grid_width, 4)
	assert_eq(level.grid_height, 3)


func test_level_w1_l1_populates_grid_system() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_width(), 4)
	assert_eq(_grid.get_height(), 3)


func test_level_w1_l1_walkable_count() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_all_walkable_tiles().size(), 2)


func test_level_w1_l1_cat_start_is_walkable() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	_grid.load_grid(level)
	assert_true(_grid.is_walkable(level.cat_start), "Cat start must be walkable")


func test_level_w1_l1_minimum_moves_set() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	assert_eq(level.minimum_moves, 1)


func test_level_w1_l1_star_thresholds_ascending() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	assert_true(level.star_3_moves <= level.star_2_moves, "star_3 <= star_2")
	assert_true(level.star_2_moves <= level.star_1_moves, "star_2 <= star_1")


func test_level_w1_l1_passes_slide_line_coverage() -> void:
	var level: LevelData = _load_level(W1_L1_PATH)
	assert_true(_passes_slide_line_coverage(level), "Must pass slide-line coverage test")


# —————————————————————————————————————————————
# Level 2: Turn the Corner (4×4, 4 walkable tiles)
# —————————————————————————————————————————————

func test_level_w1_l2_loads_successfully() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	assert_eq(level.level_id, "w1_l2")


func test_level_w1_l2_metadata() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	assert_eq(level.world_id, 1)
	assert_eq(level.level_index, 2)
	assert_eq(level.display_name, "")


func test_level_w1_l2_grid_dimensions() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	assert_eq(level.grid_width, 4)
	assert_eq(level.grid_height, 4)


func test_level_w1_l2_populates_grid_system() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_width(), 4)
	assert_eq(_grid.get_height(), 4)


func test_level_w1_l2_walkable_count() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_all_walkable_tiles().size(), 4)


func test_level_w1_l2_cat_start_is_walkable() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	_grid.load_grid(level)
	assert_true(_grid.is_walkable(level.cat_start), "Cat start must be walkable")


func test_level_w1_l2_minimum_moves_set() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	assert_eq(level.minimum_moves, 3)


func test_level_w1_l2_star_thresholds_ascending() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	assert_true(level.star_3_moves <= level.star_2_moves, "star_3 <= star_2")
	assert_true(level.star_2_moves <= level.star_1_moves, "star_2 <= star_1")


func test_level_w1_l2_passes_slide_line_coverage() -> void:
	var level: LevelData = _load_level(W1_L2_PATH)
	assert_true(_passes_slide_line_coverage(level), "Must pass slide-line coverage test")


# —————————————————————————————————————————————
# Level 3: Central Wall (5×5, 8 walkable tiles)
# —————————————————————————————————————————————

func test_level_w1_l3_loads_successfully() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	assert_eq(level.level_id, "w1_l3")


func test_level_w1_l3_metadata() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	assert_eq(level.world_id, 1)
	assert_eq(level.level_index, 3)
	assert_eq(level.display_name, "")


func test_level_w1_l3_grid_dimensions() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	assert_eq(level.grid_width, 5)
	assert_eq(level.grid_height, 5)


func test_level_w1_l3_populates_grid_system() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_width(), 5)
	assert_eq(_grid.get_height(), 5)


func test_level_w1_l3_walkable_count() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_all_walkable_tiles().size(), 8)


func test_level_w1_l3_cat_start_is_walkable() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	_grid.load_grid(level)
	assert_true(_grid.is_walkable(level.cat_start), "Cat start must be walkable")


func test_level_w1_l3_center_wall_is_blocking() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	_grid.load_grid(level)
	assert_false(_grid.is_walkable(Vector2i(2, 2)), "Center tile (2,2) must be blocking wall")


func test_level_w1_l3_center_wall_has_obstacle_type() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	_grid.load_grid(level)
	var tile: GridSystem.GridTileData = _grid.get_tile(Vector2i(2, 2))
	assert_eq(tile.obstacle_type, 1, "Center wall should be STATIC_WALL (1)")


func test_level_w1_l3_minimum_moves_set() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	assert_eq(level.minimum_moves, 4)


func test_level_w1_l3_star_thresholds_ascending() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	assert_true(level.star_3_moves <= level.star_2_moves, "star_3 <= star_2")
	assert_true(level.star_2_moves <= level.star_1_moves, "star_2 <= star_1")


func test_level_w1_l3_passes_slide_line_coverage() -> void:
	var level: LevelData = _load_level(W1_L3_PATH)
	assert_true(_passes_slide_line_coverage(level), "Must pass slide-line coverage test")


# —————————————————————————————————————————————
# Cross-level consistency checks
# —————————————————————————————————————————————

func test_level_ids_are_unique() -> void:
	var l1: LevelData = _load_level(W1_L1_PATH)
	var l2: LevelData = _load_level(W1_L2_PATH)
	var l3: LevelData = _load_level(W1_L3_PATH)
	var ids: Array[String] = [l1.level_id, l2.level_id, l3.level_id]
	# Check no duplicates
	assert_eq(ids.size(), 3)
	assert_ne(ids[0], ids[1])
	assert_ne(ids[1], ids[2])
	assert_ne(ids[0], ids[2])


func test_level_indices_are_sequential() -> void:
	var l1: LevelData = _load_level(W1_L1_PATH)
	var l2: LevelData = _load_level(W1_L2_PATH)
	var l3: LevelData = _load_level(W1_L3_PATH)
	assert_eq(l1.level_index, 1)
	assert_eq(l2.level_index, 2)
	assert_eq(l3.level_index, 3)


func test_all_levels_same_world() -> void:
	var l1: LevelData = _load_level(W1_L1_PATH)
	var l2: LevelData = _load_level(W1_L2_PATH)
	var l3: LevelData = _load_level(W1_L3_PATH)
	assert_eq(l1.world_id, 1)
	assert_eq(l2.world_id, 1)
	assert_eq(l3.world_id, 1)


func test_star_3_equals_minimum_moves_for_all_tutorials() -> void:
	var l1: LevelData = _load_level(W1_L1_PATH)
	var l2: LevelData = _load_level(W1_L2_PATH)
	var l3: LevelData = _load_level(W1_L3_PATH)
	assert_eq(l1.star_3_moves, l1.minimum_moves, "w1_l1: star_3 should equal minimum_moves")
	assert_eq(l2.star_3_moves, l2.minimum_moves, "w1_l2: star_3 should equal minimum_moves")
	assert_eq(l3.star_3_moves, l3.minimum_moves, "w1_l3: star_3 should equal minimum_moves")
