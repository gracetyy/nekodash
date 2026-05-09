## Regression tests for CatPartRig source-canvas normalization.
extends GutTest


func test_cat_part_rig_retina_part_texture_uses_authored_canvas_size() -> void:
	# Arrange
	var rig: CatPartRig = load("res://src/ui/cat_part_rig.gd").new()
	add_child_autofree(rig)
	rig._ensure_rig_nodes()
	var body_sprite: Sprite2D = rig.get_node("Body") as Sprite2D
	body_sprite.texture = load("res://assets/art/cats/parts/cat_default_body@2x.png") as Texture2D

	# Act
	var source_canvas_size: float = rig._resolve_source_canvas_size_px()

	# Assert
	assert_eq(source_canvas_size, 320.0)