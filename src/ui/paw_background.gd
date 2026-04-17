## PawBackground — tiled cream backdrop using the shipped paw-print texture.
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const PAW_PATTERN_TEXTURE: Texture2D = preload("res://assets/art/backgrounds/paw_tile_256.png")

@export var base_color: Color = ShellThemeUtil.CREAM
@export var pattern_tint: Color = Color(1.0, 0.91, 0.8, 0.34)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)


func _draw() -> void:
	var draw_size: Vector2 = size
	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		return

	draw_rect(Rect2(Vector2.ZERO, draw_size), base_color, true)

	var pattern_size: Vector2 = PAW_PATTERN_TEXTURE.get_size()
	if pattern_size.x <= 0.0 or pattern_size.y <= 0.0:
		return

	var y: float = 0.0
	while y < draw_size.y + pattern_size.y:
		var x: float = 0.0
		while x < draw_size.x + pattern_size.x:
			draw_texture_rect(
				PAW_PATTERN_TEXTURE,
				Rect2(Vector2(x, y), pattern_size),
				false,
				pattern_tint
			)
			x += pattern_size.x
		y += pattern_size.y


func _on_resized() -> void:
	queue_redraw()
