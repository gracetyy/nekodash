class_name SliderSettingRow
extends HBoxContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal value_changed(value: float)
signal toggle_toggled(button_pressed: bool)

@export var label_text: String = "Music"

@export var toggle_text: String = "Mute"

@export var show_toggle: bool = true

@onready var _label: Label = $SettingLabel
@onready var _slider: HSlider = $Slider
@onready var _toggle_label: Label = $ToggleLabel
@onready var _toggle: CheckButton = $Toggle


func _ready() -> void:
	if not _slider.value_changed.is_connected(_on_slider_value_changed):
		_slider.value_changed.connect(_on_slider_value_changed)
	if not _toggle.toggled.is_connected(_on_toggle_toggled):
		_toggle.toggled.connect(_on_toggle_toggled)
	_apply_component_state()


func get_slider() -> HSlider:
	return _slider


func get_toggle() -> CheckButton:
	return _toggle


func _apply_component_state() -> void:
	_label.text = label_text
	_toggle_label.text = toggle_text
	_toggle_label.visible = show_toggle
	_toggle.visible = show_toggle
	ShellThemeUtil.apply_body(_label, ShellThemeUtil.PLUM_SOFT, 20)
	ShellThemeUtil.apply_body(_toggle_label, ShellThemeUtil.PLUM_SOFT, 20)
	ShellThemeUtil.apply_slider(_slider)
	ShellThemeUtil.apply_checkbox(_toggle)


func _on_slider_value_changed(value: float) -> void:
	value_changed.emit(value)


func _on_toggle_toggled(button_pressed: bool) -> void:
	toggle_toggled.emit(button_pressed)
