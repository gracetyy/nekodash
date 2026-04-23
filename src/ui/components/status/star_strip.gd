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

var _is_component_ready: bool = false

@onready var _star_nodes: Array[TextureRect] = [
	$Star1,
	$Star2,
	$Star3,
]
@onready var _sentinel_label: Label = $StarSentinel


func _ready() -> void:
	_is_component_ready = true
	_apply_component_state()


func set_earned(value: int) -> void:
	earned_count = value
	if _is_component_ready:
		_apply_component_state()


func configure(
	new_earned_count: int,
	new_size_tier: int = size_tier,
	new_layout_variant: int = layout_variant,
	new_empty_mode: int = empty_mode,
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
	custom_minimum_size = _layout_size(star_size)
	for index: int in range(_star_nodes.size()):
		var star: TextureRect = _star_nodes[index]
		star.visible = true
		star.texture = _filled_texture() if index < earned_count else _empty_texture()
		star.custom_minimum_size = Vector2(star_size, star_size)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_place_star(star, index, star_size)


func _layout_size(star_size: float) -> Vector2:
	if layout_variant == LayoutVariant.CELEBRATION:
		return Vector2(304.0, 122.0)
	return Vector2((star_size * 3.0) + (row_spacing_px * 2.0), star_size)


func _place_star(star: TextureRect, index: int, star_size: float) -> void:
	if layout_variant == LayoutVariant.CELEBRATION:
		var positions: Array[Vector2] = [
			Vector2(0.0, 16.0),
			Vector2(100.0, 0.0),
			Vector2(200.0, 16.0),
		]
		var rotations: Array[float] = [-26.0, 0.0, 26.0]
		star.position = positions[index]
		star.rotation_degrees = rotations[index]
		return

	star.rotation_degrees = 0.0
	star.position = Vector2((star_size + row_spacing_px) * float(index), 0.0)


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
