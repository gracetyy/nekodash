class_name StarStrip
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

enum SizeTier {
	SMALL,
	MEDIUM,
	LARGE,
}

enum LayoutVariant {
	ROW,
	CELEBRATION,
}

enum EmptyMode {
	EMPTY,
	HOLLOW,
}

@export_range(-1, 3, 1)
var earned_count: int = 0

@export var size_tier: SizeTier = SizeTier.MEDIUM

@export var layout_variant: LayoutVariant = LayoutVariant.ROW

@export var empty_mode: EmptyMode = EmptyMode.EMPTY

@export_range(0.0, 32.0, 1.0, "or_greater")
var row_spacing_px: float = 6.0

@export_range(-12.0, 12.0, 1.0)
var row_horizontal_nudge_px: float = 0.0

var _is_component_ready: bool = false

@export var _star1: TextureRect
@export var _star2: TextureRect
@export var _star3: TextureRect
@export var _sentinel_label: Label
var _star_nodes: Array[TextureRect] = []


func _ready() -> void:
	if _star1 == null:
		_star1 = get_node_or_null("Star1")
	if _star2 == null:
		_star2 = get_node_or_null("Star2")
	if _star3 == null:
		_star3 = get_node_or_null("Star3")
	if _sentinel_label == null:
		_sentinel_label = get_node_or_null("StarSentinel")
	assert(_star1 != null, "_star1 not assigned")
	assert(_star2 != null, "_star2 not assigned")
	assert(_star3 != null, "_star3 not assigned")
	assert(_sentinel_label != null, "_sentinel_label not assigned")
	_star_nodes = [_star1, _star2, _star3]
	_is_component_ready = true
	_apply_component_state()


func set_earned(value: int) -> void:
	earned_count = value
	if _is_component_ready:
		_apply_component_state()


func configure(
	new_earned_count: int,
	new_size_tier: SizeTier = size_tier,
	new_layout_variant: LayoutVariant = layout_variant,
	new_empty_mode: EmptyMode = empty_mode,
	new_row_spacing_px: float = row_spacing_px
) -> void:
	earned_count = new_earned_count
	size_tier = new_size_tier
	layout_variant = new_layout_variant
	empty_mode = new_empty_mode
	row_spacing_px = new_row_spacing_px
	if _is_component_ready:
		_apply_component_state()


func _apply_component_state() -> void:
	if not _is_component_ready:
		return
	if earned_count < 0:
		for star: TextureRect in _star_nodes:
			star.visible = false
		_sentinel_label.visible = true
		return

	_sentinel_label.visible = false
	var star_size: float = _star_size_px()
	var layout_size: Vector2 = _layout_size(star_size)
	custom_minimum_size = layout_size
	for index: int in range(_star_nodes.size()):
		var star: TextureRect = _star_nodes[index]
		star.visible = true
		star.texture = _filled_texture() if index < earned_count else _empty_texture()
		star.custom_minimum_size = Vector2(star_size, star_size)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_place_star(star, index, star_size, layout_size.x)


func _layout_size(star_size: float) -> Vector2:
	if layout_variant == LayoutVariant.CELEBRATION:
		return Vector2(304.0, 122.0)
	return Vector2((star_size * 3.0) + (row_spacing_px * 2.0), star_size)


func _place_star(star: TextureRect, index: int, star_size: float, row_width: float) -> void:
	if layout_variant == LayoutVariant.CELEBRATION:
		var positions: Array[Vector2] = [
			Vector2(0.0, 16.0),
			Vector2(100.0, 0.0),
			Vector2(200.0, 16.0),
		]
		star.position = positions[index]
		star.rotation_degrees = 0.0
		return

	star.rotation_degrees = 0.0
	var offset_x: float = maxf(0.0, (size.x - row_width) * 0.5) + row_horizontal_nudge_px
	star.position = Vector2(offset_x + (star_size + row_spacing_px) * float(index), 0.0)


func _star_size_px() -> float:
	match size_tier:
		SizeTier.SMALL:
			return 18.0
		SizeTier.LARGE:
			return 104.0
		_:
			return 28.0


func _filled_texture() -> Texture2D:
	match size_tier:
		SizeTier.SMALL:
			return ShellThemeUtil.STAR_SMALL_FILLED_TEXTURE
		SizeTier.LARGE:
			return ShellThemeUtil.STAR_LARGE_FILLED_TEXTURE
		_:
			return ShellThemeUtil.STAR_MEDIUM_FILLED_TEXTURE


func _empty_texture() -> Texture2D:
	match size_tier:
		SizeTier.SMALL:
			if empty_mode == EmptyMode.HOLLOW:
				return ShellThemeUtil.STAR_SMALL_HOLLOW_TEXTURE
			return ShellThemeUtil.STAR_SMALL_EMPTY_TEXTURE
		SizeTier.LARGE:
			if empty_mode == EmptyMode.HOLLOW:
				return ShellThemeUtil.STAR_LARGE_HOLLOW_TEXTURE
			return ShellThemeUtil.STAR_LARGE_EMPTY_TEXTURE
		_:
			if empty_mode == EmptyMode.HOLLOW:
				return ShellThemeUtil.STAR_MEDIUM_HOLLOW_TEXTURE
			return ShellThemeUtil.STAR_MEDIUM_EMPTY_TEXTURE
