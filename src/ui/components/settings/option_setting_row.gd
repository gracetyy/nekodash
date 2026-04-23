class_name OptionSettingRow
extends VBoxContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal item_selected(index: int)

@export var label_text: String = "Input Hints"

@onready var _label: Label = $SettingLabel
@onready var _option_button: OptionButton = $OptionButton


func _ready() -> void:
	if not _option_button.item_selected.is_connected(_on_item_selected):
		_option_button.item_selected.connect(_on_item_selected)
	_apply_component_state()


func get_option_button() -> OptionButton:
	return _option_button


func _apply_component_state() -> void:
	_label.text = label_text
	ShellThemeUtil.apply_title(_label, 24)
	ShellThemeUtil.apply_option_button(_option_button)


func _on_item_selected(index: int) -> void:
	item_selected.emit(index)
