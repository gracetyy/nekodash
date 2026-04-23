class_name HUDMoveCounter
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

@export var prefix_text: String = "Moves"

@export var moves_text: String = "0"

@onready var _background: TextureRect = $MoveCounterBg
@onready var _prefix_label: Label = $MovesPrefix
@onready var _value_label: Label = $MoveLabel


func _ready() -> void:
	_apply_visuals()
	_update_display()


func set_moves_value(value: int) -> void:
	moves_text = str(value)
	_update_display()


func get_moves_label() -> Label:
	return _value_label


func _apply_visuals() -> void:
	_background.texture = ShellThemeUtil.MOVE_COUNTER_TEXTURE
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_prefix_label.add_theme_color_override("font_color", Color(0.972, 0.922, 0.761, 1.0))
	_prefix_label.add_theme_font_size_override("font_size", 21)
	_prefix_label.add_theme_font_override("font", ShellThemeUtil.FONT_DISPLAY)
	_value_label.add_theme_color_override("font_color", Color(0.972, 0.922, 0.761, 1.0))
	_value_label.add_theme_font_size_override("font_size", 34)
	_value_label.add_theme_font_override("font", ShellThemeUtil.FONT_DISPLAY)


func _update_display() -> void:
	_prefix_label.text = prefix_text
	_value_label.text = moves_text
