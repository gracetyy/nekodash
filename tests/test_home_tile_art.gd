## Unit tests for HomeTileArt gameplay board theming and obstacle packing.
extends GutTest

const HomeTileArtScript = preload("res://src/ui/home_tile_art.gd")


func _make_bordered_level(
	level_id: String,
	width: int,
	height: int,
	interior_blocked: Array[Vector2i],
	world_id: int = 1,
) -> LevelData:
	var level_data := LevelData.new()
	level_data.level_id = level_id
	level_data.world_id = world_id
	level_data.grid_width = width
	level_data.grid_height = height
	level_data.cat_start = Vector2i(1, 1)

	var walkability := PackedInt32Array()
	walkability.resize(width * height)
	for row: int in range(height):
		for col: int in range(width):
			var coord: Vector2i = Vector2i(col, row)
			var is_border: bool = (
				row == 0
				or row == height - 1
				or col == 0
				or col == width - 1
			)
			walkability[col + row * width] = (
				GridSystem.TileWalkability.BLOCKING
				if is_border or interior_blocked.has(coord)
				else GridSystem.TileWalkability.WALKABLE
			)

	var obstacles := PackedInt32Array()
	obstacles.resize(width * height)
	obstacles.fill(GridSystem.ObstacleType.NONE)

	level_data.walkability_tiles = walkability
	level_data.obstacle_tiles = obstacles
	return level_data


func _find_obstacle_by_size(layout: Dictionary, target_size: Vector2i) -> Dictionary:
	for obstacle_draw: Dictionary in layout.get("obstacles", []):
		var size: Vector2i = obstacle_draw.get("size", Vector2i.ZERO) as Vector2i
		if size == target_size:
			return obstacle_draw
	return {}


func _is_oriented_wall_path(wall_path: String) -> bool:
	var oriented_tokens: Array[String] = [
		"top",
		"bottom",
		"left",
		"right",
		"top_left_corner",
		"top_right_corner",
		"bottom_left_corner",
		"bottom_right_corner",
	]
	for token: String in oriented_tokens:
		if wall_path.ends_with("/%s.png" % token):
			return true
	return false


func test_simple_ui_layout_uses_placeholder_textures() -> void:
	var level_data: LevelData = _make_bordered_level("simple_ui", 4, 4, [Vector2i(1, 1)])
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, true)

	assert_eq(layout.get("floor_path", ""), "res://assets/art/tiles/grids/grid_mint.png")
	assert_eq(layout.get("visited_path", ""), "res://assets/art/tiles/grids/grid_yellow.png")
	assert_eq(layout.get("blocking_path", ""), "res://assets/art/tiles/grids/grid_purple.png")
	assert_eq((layout.get("wall_draws", []) as Array).size(), 0)
	assert_eq((layout.get("obstacles", []) as Array).size(), 0)


func test_world_one_art_layout_uses_bedroom_floor_and_oriented_bedroom_walls() -> void:
	var level_data: LevelData = _make_bordered_level("bedroom_floor", 4, 4, [])
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)

	var wall_draws: Array = layout.get("wall_draws", []) as Array
	var first_wall: Dictionary = wall_draws[0] as Dictionary

	assert_true(str(layout.get("floor_path", "")).ends_with("/assets/art/tiles/home/bedroom/1x1_floor_tile/normal.png"))
	assert_true(str(layout.get("visited_path", "")).ends_with("/assets/art/tiles/home/bedroom/1x1_floor_tile/visited.png"))
	assert_true(str(first_wall.get("path", "")).contains("/assets/art/tiles/home/bedroom/1x1_wall_tile/"))
	for wall_draw: Dictionary in wall_draws:
		var wall_path: String = str(wall_draw.get("path", ""))
		assert_true(wall_path.contains("/assets/art/tiles/home/bedroom/1x1_wall_tile/"))
		assert_true(
			_is_oriented_wall_path(wall_path),
			"Wall asset should use oriented role sprite: %s" % wall_path
		)


func test_edge_walls_use_oriented_role_sprites() -> void:
	var level_data: LevelData = _make_bordered_level("edge_walls", 3, 3, [])
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)
	var wall_draws: Array = layout.get("wall_draws", []) as Array

	for wall_draw: Dictionary in wall_draws:
		var wall_path: String = str(wall_draw.get("path", ""))
		assert_true(wall_path.contains("/assets/art/tiles/home/bedroom/1x1_wall_tile/"))
		assert_true(
			_is_oriented_wall_path(wall_path),
			"Edge wall should use oriented role sprite: %s" % wall_path
		)


func test_side_facing_obstacle_can_use_left_or_right_wall() -> void:
	# Side-facing obstacles should work against either left or right walls
	var level_data: LevelData = _make_bordered_level(
		"side_facing_both",
		5,
		5,
		[Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
	)
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)
	var obstacle_draw: Dictionary = {}
	
	for obs: Dictionary in layout.get("obstacles", []):
		var size: Vector2i = obs.get("size", Vector2i.ZERO) as Vector2i
		if size == Vector2i(1, 3):
			obstacle_draw = obs
			break
	
	# Should have found a 1x3 side-facing obstacle with orientation set
	assert_ne(obstacle_draw, {})
	var orientation: int = obstacle_draw.get("side_facing_orientation", 0) as int
	assert_true(orientation != 0, "Side-facing obstacle should have orientation (1 or -1)")


func test_tabletop_offset_is_set_for_shelf_assets() -> void:
	var level_data: LevelData = _make_bordered_level(
		"tabletop_test",
		5,
		4,
		[Vector2i(1, 1), Vector2i(2, 1)]
	)
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)
	var shelf_draw: Dictionary = {}
	
	for obs: Dictionary in layout.get("obstacles", []):
		var size: Vector2i = obs.get("size", Vector2i.ZERO) as Vector2i
		if size == Vector2i(2, 1):
			shelf_draw = obs
			break
	
	assert_ne(shelf_draw, {})
	var offset: float = shelf_draw.get("tabletop_offset_y", 0.0) as float
	# Offset should be set to place tabletop in upper area (0.25 = 25% from top)
	assert_gt(offset, 0.0, "Shelf should have tabletop offset for upper placement")


func test_vertical_block_pair_prefers_1x2_obstacle_asset() -> void:
	var level_data: LevelData = _make_bordered_level(
		"vertical_pair",
		4,
		5,
		[Vector2i(1, 1), Vector2i(1, 2)]
	)
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)
	var obstacle_draw: Dictionary = _find_obstacle_by_size(layout, Vector2i(1, 2))

	assert_ne(obstacle_draw, {})
	assert_true(str(obstacle_draw.get("path", "")).contains("/assets/art/tiles/home/bedroom/1x2_obstacle_tile/"))


func test_horizontal_block_pair_uses_2x1_asset_without_rotating_1x2() -> void:
	var level_data: LevelData = _make_bordered_level(
		"horizontal_pair",
		5,
		4,
		[Vector2i(1, 1), Vector2i(2, 1)]
	)
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)
	var obstacle_draw: Dictionary = _find_obstacle_by_size(layout, Vector2i(2, 1))

	assert_ne(obstacle_draw, {})
	assert_true(str(obstacle_draw.get("path", "")).contains("/assets/art/tiles/home/common/2x1_obstacle_tile/"))
	assert_false(str(obstacle_draw.get("path", "")).contains("/assets/art/tiles/home/bedroom/1x2_obstacle_tile/"))


func test_side_facing_asset_requires_wall_to_the_right() -> void:
	var level_data: LevelData = _make_bordered_level(
		"side_facing_allowed",
		3,
		5,
		[Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
	)
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)
	var obstacle_draw: Dictionary = _find_obstacle_by_size(layout, Vector2i(1, 3))

	assert_ne(obstacle_draw, {})
	assert_true(str(obstacle_draw.get("path", "")).contains("/assets/art/tiles/home/common/1x3_obstacle_tile_side_facing/"))


func test_side_facing_asset_is_skipped_when_no_side_is_wall() -> void:
	var level_data: LevelData = _make_bordered_level(
		"side_facing_blocked",
		5,
		5,
		[Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]
	)
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)

	for obstacle_draw: Dictionary in layout.get("obstacles", []):
		assert_false(str(obstacle_draw.get("path", "")).contains("/assets/art/tiles/home/common/1x3_obstacle_tile_side_facing/"))


func test_shelf_and_table_assets_receive_tabletop_overlay() -> void:
	var level_data: LevelData = _make_bordered_level(
		"tabletop_overlay",
		5,
		4,
		[Vector2i(1, 1), Vector2i(2, 1)]
	)
	var layout: Dictionary = HomeTileArtScript.build_layout(level_data, false)
	var obstacle_draw: Dictionary = _find_obstacle_by_size(layout, Vector2i(2, 1))

	assert_ne(obstacle_draw, {})
	assert_not_null(obstacle_draw.get("tabletop_texture", null))
	assert_true(str(obstacle_draw.get("tabletop_path", "")).contains("/assets/art/tiles/home/common/0.5x0.5_tabletop_item/"))
