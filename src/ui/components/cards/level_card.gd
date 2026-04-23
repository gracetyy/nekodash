class_name LevelCard
extends PanelContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const LEVEL_CARD_HOVER_TWEEN_META: String = "_component_level_card_hover_tween"

signal pressed(level_id: String)
signal locked_pressed(level_id: String)

@export var level_id: String = ""
@export_range(1, 999, 1, "or_greater")
var level_number: int = 1

@export_enum("unlocked", "locked", "complete")
var card_state: String = "unlocked"

@export_range(0, 3, 1, "or_greater")
var earned_stars: int = 0

@export_range(80.0, 320.0, 1.0, "or_greater")
var min_width: float = 120.0

@export_range(1.0, 1.2, 0.01, "or_greater")
var hover_scale: float = 1.04

@export_range(0.01, 0.5, 0.01, "or_greater")
var hover_duration_sec: float = 0.1

var _is_component_ready: bool = false

@onready var _number_label: Label = $CardMargin/VBox/NumberLabel
@onready var _star_strip: Control = $CardMargin/VBox/StarStrip
@onready var _lock_center: Control = $CardMargin/VBox/LockCenter
@onready var _lock_icon: TextureRect = $CardMargin/VBox/LockCenter/LockIcon
@onready var _overlay_button: Button = $OverlayButton


func _ready() -> void:
	_is_component_ready = true
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	_overlay_button.add_theme_stylebox_override("normal", empty_style)
	_overlay_button.add_theme_stylebox_override("hover", empty_style)
	_overlay_button.add_theme_stylebox_override("pressed", empty_style)
	_overlay_button.add_theme_stylebox_override("focus", empty_style)
	_overlay_button.add_theme_stylebox_override("disabled", empty_style)
	if not _overlay_button.pressed.is_connected(_on_overlay_pressed):
		_overlay_button.pressed.connect(_on_overlay_pressed)
	if not _overlay_button.mouse_entered.is_connected(_on_overlay_mouse_entered):
		_overlay_button.mouse_entered.connect(_on_overlay_mouse_entered)
	if not _overlay_button.mouse_exited.is_connected(_on_overlay_mouse_exited):
		_overlay_button.mouse_exited.connect(_on_overlay_mouse_exited)
	_apply_component_state()


func configure(new_level_id: String, number: int, state: String, stars: int) -> void:
	level_id = new_level_id
	level_number = number
	card_state = state
	earned_stars = stars
	if _is_component_ready:
		_apply_component_state()


func _apply_component_state() -> void:
	if not _is_component_ready:
		return
	custom_minimum_size = Vector2(min_width, 132.0)
	add_theme_stylebox_override("panel", ShellThemeUtil.make_level_card_style(card_state))
	_number_label.visible = card_state != "locked"
	_star_strip.visible = card_state != "locked"
	_lock_center.visible = card_state == "locked"
	_lock_icon.texture = ShellThemeUtil.WORLD_MAP_LOCK_TEXTURE
	if _number_label.visible:
		_number_label.text = str(level_number)
		_number_label.add_theme_font_override("font", ShellThemeUtil.FONT_DISPLAY)
		_number_label.add_theme_font_size_override("font_size", 42)
		_number_label.add_theme_color_override("font_color", ShellThemeUtil.PLUM)
		if _star_strip != null and _star_strip.has_method("configure"):
			_star_strip.call("configure", clampi(earned_stars, 0, 3), 1, 0, 0, 3.0)


func _on_overlay_pressed() -> void:
	if card_state == "locked":
		locked_pressed.emit(level_id)
		return
	pressed.emit(level_id)


func _on_overlay_mouse_entered() -> void:
	if card_state == "locked":
		return
	_animate_hover(Vector2(hover_scale, hover_scale))


func _on_overlay_mouse_exited() -> void:
	if card_state == "locked":
		return
	_animate_hover(Vector2.ONE)


func _animate_hover(target_scale: Vector2) -> void:
	pivot_offset = size * 0.5
	if AppSettings != null and AppSettings.get_reduce_motion():
		scale = target_scale
		return
	var prior_tween: Tween = null
	if has_meta(LEVEL_CARD_HOVER_TWEEN_META):
		prior_tween = get_meta(LEVEL_CARD_HOVER_TWEEN_META) as Tween
	if prior_tween != null and prior_tween.is_valid():
		prior_tween.kill()
	var tween: Tween = create_tween()
	tween.tween_property(self , "scale", target_scale, hover_duration_sec) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	set_meta(LEVEL_CARD_HOVER_TWEEN_META, tween)
