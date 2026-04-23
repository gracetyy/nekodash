class_name ToggleSettingRow
extends HBoxContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal toggled(button_pressed: bool)

@export var label_text: String = "Reduce Motion"

@onready var _label: Label = $SettingLabel
@onready var _toggle: CheckButton = $Toggle


func _ready() -> void:
	if not _toggle.toggled.is_connected(_on_toggle_toggled):
		_toggle.toggled.connect(_on_toggle_toggled)
	_apply_component_state()


func get_toggle() -> CheckButton:
	return _toggle


func _apply_component_state() -> void:
	_label.text = label_text
	ShellThemeUtil.apply_body(_label, ShellThemeUtil.PLUM_SOFT, 20)
	ShellThemeUtil.apply_checkbox(_toggle)


func _on_toggle_toggled(button_pressed: bool) -> void:
	toggled.emit(button_pressed)
