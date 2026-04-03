## Unit tests for LevelData .tres files and GridSystem integration.
## Task: S1-04, S4-28
## Covers: .tres loading, GridSystem population, metadata, walkable counts,
##         slide-line coverage test (section 4 of solvability guide),
##         obstacle levels L4–L8 structure and star thresholds.
extends GutTest

var _grid: Node

# Level paths
const W1_L1_PATH: String = "res://data/levels/world1/w1_l1.tres"
const W1_L2_PATH: String = "res://data/levels/world1/w1_l2.tres"
const W1_L3_PATH: String = "res://data/levels/world1/w1_l3.tres"
const W1_L4_PATH: String = "res://data/levels/world1/w1_l4.tres"
const W1_L5_PATH: String = "res://data/levels/world1/w1_l5.tres"
const W1_L6_PATH: String = "res://data/levels/world1/w1_l6.tres"
const W1_L7_PATH: String = "res://data/levels/world1/w1_l7.tres"
const W1_L8_PATH: String = "res://data/levels/world1/w1_l8.tres"


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
# Level 4: First Fork (6×6, 14 walkable, 2 obstacles)
# —————————————————————————————————————————————

func test_level_w1_l4_loads_successfully() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	assert_eq(level.level_id, "w1_l4")


func test_level_w1_l4_metadata() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	assert_eq(level.world_id, 1)
	assert_eq(level.level_index, 4)
	assert_eq(level.display_name, "")


func test_level_w1_l4_grid_dimensions() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	assert_eq(level.grid_width, 6)
	assert_eq(level.grid_height, 6)


func test_level_w1_l4_populates_grid_system() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_width(), 6)
	assert_eq(_grid.get_height(), 6)


func test_level_w1_l4_walkable_count() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_all_walkable_tiles().size(), 14)


func test_level_w1_l4_cat_start_is_walkable() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	_grid.load_grid(level)
	assert_true(_grid.is_walkable(level.cat_start), "Cat start must be walkable")


func test_level_w1_l4_has_obstacles() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	var obs_count: int = 0
	for i: int in range(level.obstacle_tiles.size()):
		if level.obstacle_tiles[i] != 0:
			obs_count += 1
	assert_eq(obs_count, 2, "w1_l4 should have 2 obstacle tiles")


func test_level_w1_l4_minimum_moves_set() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	assert_eq(level.minimum_moves, 8)


func test_level_w1_l4_star_thresholds_ascending() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	assert_true(level.star_3_moves <= level.star_2_moves, "star_3 <= star_2")
	assert_true(level.star_2_moves <= level.star_1_moves, "star_2 <= star_1")


func test_level_w1_l4_star_3_above_minimum() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	assert_eq(level.star_3_moves, level.minimum_moves + 1,
		"Obstacle levels: star_3 = minimum_moves + 1")


func test_level_w1_l4_passes_slide_line_coverage() -> void:
	var level: LevelData = _load_level(W1_L4_PATH)
	assert_true(_passes_slide_line_coverage(level), "Must pass slide-line coverage test")


# —————————————————————————————————————————————
# Level 5: Split Path (6×6, 14 walkable, 2 obstacles)
# —————————————————————————————————————————————

func test_level_w1_l5_loads_successfully() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	assert_eq(level.level_id, "w1_l5")


func test_level_w1_l5_metadata() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	assert_eq(level.world_id, 1)
	assert_eq(level.level_index, 5)
	assert_eq(level.display_name, "")


func test_level_w1_l5_grid_dimensions() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	assert_eq(level.grid_width, 6)
	assert_eq(level.grid_height, 6)


func test_level_w1_l5_populates_grid_system() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_width(), 6)
	assert_eq(_grid.get_height(), 6)


func test_level_w1_l5_walkable_count() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_all_walkable_tiles().size(), 14)


func test_level_w1_l5_cat_start_is_walkable() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	_grid.load_grid(level)
	assert_true(_grid.is_walkable(level.cat_start), "Cat start must be walkable")


func test_level_w1_l5_has_obstacles() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	var obs_count: int = 0
	for i: int in range(level.obstacle_tiles.size()):
		if level.obstacle_tiles[i] != 0:
			obs_count += 1
	assert_eq(obs_count, 2, "w1_l5 should have 2 obstacle tiles")


func test_level_w1_l5_minimum_moves_set() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	assert_eq(level.minimum_moves, 9)


func test_level_w1_l5_star_thresholds_ascending() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	assert_true(level.star_3_moves <= level.star_2_moves, "star_3 <= star_2")
	assert_true(level.star_2_moves <= level.star_1_moves, "star_2 <= star_1")


func test_level_w1_l5_star_3_above_minimum() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	assert_eq(level.star_3_moves, level.minimum_moves + 1,
		"Obstacle levels: star_3 = minimum_moves + 1")


func test_level_w1_l5_passes_slide_line_coverage() -> void:
	var level: LevelData = _load_level(W1_L5_PATH)
	assert_true(_passes_slide_line_coverage(level), "Must pass slide-line coverage test")


# —————————————————————————————————————————————
# Level 6: Triple Wall (6×6, 13 walkable, 3 obstacles)
# —————————————————————————————————————————————

func test_level_w1_l6_loads_successfully() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	assert_eq(level.level_id, "w1_l6")


func test_level_w1_l6_metadata() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	assert_eq(level.world_id, 1)
	assert_eq(level.level_index, 6)
	assert_eq(level.display_name, "")


func test_level_w1_l6_grid_dimensions() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	assert_eq(level.grid_width, 6)
	assert_eq(level.grid_height, 6)


func test_level_w1_l6_populates_grid_system() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_width(), 6)
	assert_eq(_grid.get_height(), 6)


func test_level_w1_l6_walkable_count() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_all_walkable_tiles().size(), 13)


func test_level_w1_l6_cat_start_is_walkable() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	_grid.load_grid(level)
	assert_true(_grid.is_walkable(level.cat_start), "Cat start must be walkable")


func test_level_w1_l6_has_obstacles() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	var obs_count: int = 0
	for i: int in range(level.obstacle_tiles.size()):
		if level.obstacle_tiles[i] != 0:
			obs_count += 1
	assert_eq(obs_count, 3, "w1_l6 should have 3 obstacle tiles")


func test_level_w1_l6_minimum_moves_set() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	assert_eq(level.minimum_moves, 11)


func test_level_w1_l6_star_thresholds_ascending() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	assert_true(level.star_3_moves <= level.star_2_moves, "star_3 <= star_2")
	assert_true(level.star_2_moves <= level.star_1_moves, "star_2 <= star_1")


func test_level_w1_l6_star_3_above_minimum() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	assert_eq(level.star_3_moves, level.minimum_moves + 1,
		"Obstacle levels: star_3 = minimum_moves + 1")


func test_level_w1_l6_passes_slide_line_coverage() -> void:
	var level: LevelData = _load_level(W1_L6_PATH)
	assert_true(_passes_slide_line_coverage(level), "Must pass slide-line coverage test")


# —————————————————————————————————————————————
# Level 7: Open Arena (7×7, 22 walkable, 3 obstacles)
# —————————————————————————————————————————————

func test_level_w1_l7_loads_successfully() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	assert_eq(level.level_id, "w1_l7")


func test_level_w1_l7_metadata() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	assert_eq(level.world_id, 1)
	assert_eq(level.level_index, 7)
	assert_eq(level.display_name, "")


func test_level_w1_l7_grid_dimensions() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	assert_eq(level.grid_width, 7)
	assert_eq(level.grid_height, 7)


func test_level_w1_l7_populates_grid_system() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_width(), 7)
	assert_eq(_grid.get_height(), 7)


func test_level_w1_l7_walkable_count() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_all_walkable_tiles().size(), 22)


func test_level_w1_l7_cat_start_is_walkable() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	_grid.load_grid(level)
	assert_true(_grid.is_walkable(level.cat_start), "Cat start must be walkable")


func test_level_w1_l7_has_obstacles() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	var obs_count: int = 0
	for i: int in range(level.obstacle_tiles.size()):
		if level.obstacle_tiles[i] != 0:
			obs_count += 1
	assert_eq(obs_count, 3, "w1_l7 should have 3 obstacle tiles")


func test_level_w1_l7_minimum_moves_set() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	assert_eq(level.minimum_moves, 11)


func test_level_w1_l7_star_thresholds_ascending() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	assert_true(level.star_3_moves <= level.star_2_moves, "star_3 <= star_2")
	assert_true(level.star_2_moves <= level.star_1_moves, "star_2 <= star_1")


func test_level_w1_l7_star_3_above_minimum() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	assert_eq(level.star_3_moves, level.minimum_moves + 1,
		"Obstacle levels: star_3 = minimum_moves + 1")


func test_level_w1_l7_passes_slide_line_coverage() -> void:
	var level: LevelData = _load_level(W1_L7_PATH)
	assert_true(_passes_slide_line_coverage(level), "Must pass slide-line coverage test")


# —————————————————————————————————————————————
# Level 8: Grand Maze (7×7, 22 walkable, 3 obstacles)
# —————————————————————————————————————————————

func test_level_w1_l8_loads_successfully() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	assert_eq(level.level_id, "w1_l8")


func test_level_w1_l8_metadata() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	assert_eq(level.world_id, 1)
	assert_eq(level.level_index, 8)
	assert_eq(level.display_name, "")


func test_level_w1_l8_grid_dimensions() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	assert_eq(level.grid_width, 7)
	assert_eq(level.grid_height, 7)


func test_level_w1_l8_populates_grid_system() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_width(), 7)
	assert_eq(_grid.get_height(), 7)


func test_level_w1_l8_walkable_count() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	_grid.load_grid(level)
	assert_eq(_grid.get_all_walkable_tiles().size(), 22)


func test_level_w1_l8_cat_start_is_walkable() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	_grid.load_grid(level)
	assert_true(_grid.is_walkable(level.cat_start), "Cat start must be walkable")


func test_level_w1_l8_has_obstacles() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	var obs_count: int = 0
	for i: int in range(level.obstacle_tiles.size()):
		if level.obstacle_tiles[i] != 0:
			obs_count += 1
	assert_eq(obs_count, 3, "w1_l8 should have 3 obstacle tiles")


func test_level_w1_l8_minimum_moves_set() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	assert_eq(level.minimum_moves, 12)


func test_level_w1_l8_star_thresholds_ascending() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	assert_true(level.star_3_moves <= level.star_2_moves, "star_3 <= star_2")
	assert_true(level.star_2_moves <= level.star_1_moves, "star_2 <= star_1")


func test_level_w1_l8_star_3_above_minimum() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	assert_eq(level.star_3_moves, level.minimum_moves + 1,
		"Obstacle levels: star_3 = minimum_moves + 1")


func test_level_w1_l8_passes_slide_line_coverage() -> void:
	var level: LevelData = _load_level(W1_L8_PATH)
	assert_true(_passes_slide_line_coverage(level), "Must pass slide-line coverage test")


# —————————————————————————————————————————————
# Cross-level consistency checks (all 8 levels)
# —————————————————————————————————————————————

func test_level_ids_are_unique() -> void:
	var paths: Array[String] = [
		W1_L1_PATH, W1_L2_PATH, W1_L3_PATH, W1_L4_PATH,
		W1_L5_PATH, W1_L6_PATH, W1_L7_PATH, W1_L8_PATH,
	]
	var ids: Dictionary = {}
	for p: String in paths:
		var ld: LevelData = _load_level(p)
		assert_false(ids.has(ld.level_id), "Duplicate level_id: %s" % ld.level_id)
		ids[ld.level_id] = true
	assert_eq(ids.size(), 8, "Should have 8 unique level IDs")


func test_level_indices_are_sequential() -> void:
	var paths: Array[String] = [
		W1_L1_PATH, W1_L2_PATH, W1_L3_PATH, W1_L4_PATH,
		W1_L5_PATH, W1_L6_PATH, W1_L7_PATH, W1_L8_PATH,
	]
	for i: int in range(paths.size()):
		var ld: LevelData = _load_level(paths[i])
		assert_eq(ld.level_index, i + 1, "Level index should be %d" % (i + 1))


func test_all_levels_same_world() -> void:
	var paths: Array[String] = [
		W1_L1_PATH, W1_L2_PATH, W1_L3_PATH, W1_L4_PATH,
		W1_L5_PATH, W1_L6_PATH, W1_L7_PATH, W1_L8_PATH,
	]
	for p: String in paths:
		var ld: LevelData = _load_level(p)
		assert_eq(ld.world_id, 1, "%s should be world 1" % ld.level_id)


func test_star_3_equals_minimum_moves_for_tutorials() -> void:
	var tutorial_paths: Array[String] = [W1_L1_PATH, W1_L2_PATH, W1_L3_PATH]
	for p: String in tutorial_paths:
		var ld: LevelData = _load_level(p)
		assert_eq(ld.star_3_moves, ld.minimum_moves,
			"%s: tutorial star_3 should equal minimum_moves" % ld.level_id)


func test_star_3_above_minimum_for_obstacle_levels() -> void:
	var obstacle_paths: Array[String] = [
		W1_L4_PATH, W1_L5_PATH, W1_L6_PATH, W1_L7_PATH, W1_L8_PATH,
	]
	for p: String in obstacle_paths:
		var ld: LevelData = _load_level(p)
		assert_eq(ld.star_3_moves, ld.minimum_moves + 1,
			"%s: obstacle star_3 should equal minimum_moves + 1" % ld.level_id)


func test_minimum_moves_increases_monotonically() -> void:
	var paths: Array[String] = [
		W1_L1_PATH, W1_L2_PATH, W1_L3_PATH, W1_L4_PATH,
		W1_L5_PATH, W1_L6_PATH, W1_L7_PATH, W1_L8_PATH,
	]
	var prev_min: int = 0
	for p: String in paths:
		var ld: LevelData = _load_level(p)
		assert_true(ld.minimum_moves >= prev_min,
			"%s: minimum_moves should not decrease" % ld.level_id)
		prev_min = ld.minimum_moves
