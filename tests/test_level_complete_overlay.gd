## Regression tests for level-complete visual parity across plain scene and overlay flows.
extends GutTest


func test_level_complete_plain_scene_ready_applies_rotated_side_stars() -> void:
	# Arrange
	var scene: PackedScene = load("res://scenes/ui/level_complete.tscn")
	var screen: Control = scene.instantiate() as Control
	add_child_autofree(screen)

	# Act
	await get_tree().process_frame
	await get_tree().process_frame

	# Assert
	var star_1: Control = screen.get_node("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star1") as Control
	var star_2: Control = screen.get_node("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star2") as Control
	var star_3: Control = screen.get_node("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star3") as Control
	assert_eq(star_1.rotation_degrees, -26.0)
	assert_eq(star_2.rotation_degrees, 0.0)
	assert_eq(star_3.rotation_degrees, 26.0)


func test_level_complete_overlay_params_applies_rotated_side_stars() -> void:
	# Arrange
	var overlay_scene: PackedScene = load("res://scenes/ui/level_complete_overlay.tscn")
	var overlay: CanvasLayer = overlay_scene.instantiate() as CanvasLayer
	var level_data: LevelData = load("res://data/levels/world1/w1_l1.tres") as LevelData
	var next_level_data: LevelData = load("res://data/levels/world1/w1_l2.tres") as LevelData
	overlay.receive_scene_params({
		"level_data": level_data,
		"stars": 3,
		"final_moves": 8,
		"prev_best_moves": 9,
		"was_previously_completed": true,
		"next_level_data": next_level_data,
	})
	add_child_autofree(overlay)

	# Act
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# Assert
	var content: Control = overlay.get_node("Content") as Control
	var star_1: Control = content.get_node("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star1") as Control
	var star_2: Control = content.get_node("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star2") as Control
	var star_3: Control = content.get_node("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star3") as Control
	assert_eq(star_1.rotation_degrees, -26.0)
	assert_eq(star_2.rotation_degrees, 0.0)
	assert_eq(star_3.rotation_degrees, 26.0)


func test_level_complete_perfect_result_uses_smile_cat_variant() -> void:
	# Arrange
	var overlay_scene: PackedScene = load("res://scenes/ui/level_complete_overlay.tscn")
	var overlay: CanvasLayer = overlay_scene.instantiate() as CanvasLayer
	var level_data: LevelData = load("res://data/levels/world1/w1_l1.tres") as LevelData
	var next_level_data: LevelData = load("res://data/levels/world1/w1_l2.tres") as LevelData
	assert_gt(level_data.minimum_moves, 0)
	overlay.receive_scene_params({
		"level_data": level_data,
		"stars": 3,
		"final_moves": level_data.minimum_moves,
		"prev_best_moves": level_data.minimum_moves + 1,
		"was_previously_completed": true,
		"next_level_data": next_level_data,
	})
	add_child_autofree(overlay)

	# Act
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# Assert
	var content: Control = overlay.get_node("Content") as Control
	var cat_illustration: TextureRect = content.get_node("MarginContainer/ResultsCard/CardMargin/VBox/CatIllustration") as TextureRect
	assert_eq(cat_illustration.texture.resource_path, "res://assets/art/cats/cat_default_smile.png")