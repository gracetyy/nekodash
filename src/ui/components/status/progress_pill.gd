class_name ProgressPill
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

@export var value_text: String = "0 / 0"

@export var icon_texture: Texture2D = ShellThemeUtil.STAR_SMALL_FILLED_TEXTURE

@export var show_icon: bool = true

var _is_component_ready: bool = false

@onready var _background: TextureRect = $Background
@onready var _icon: TextureRect = $Content/Icon
@onready var _value_label: Label = $Content/ValueLabel


func _ready() -> void:
	_is_component_ready = true
	_apply_visuals()
	_update_display()


func set_value_text(text_value: String) -> void:
	value_text = text_value
	if _is_component_ready:
		_update_display()


func _apply_visuals() -> void:
	_background.texture = ShellThemeUtil.STAR_PILL_TEXTURE
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ShellThemeUtil.apply_body(_value_label, ShellThemeUtil.PLUM, 24)


func _update_display() -> void:
	if not _is_component_ready:
		return
	_icon.visible = show_icon
	_icon.texture = icon_texture
	_value_label.text = value_text
