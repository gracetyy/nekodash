class_name TutorialBubble
extends PanelContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

@export_multiline var bubble_text: String = "Swipe to slide!"

@onready var _label: Label = $Label


func _ready() -> void:
	_apply_component_state()


func _apply_component_state() -> void:
	add_theme_stylebox_override("panel", ShellThemeUtil.make_tooltip_bubble_style())
	_label.text = bubble_text
	ShellThemeUtil.apply_body(_label, ShellThemeUtil.PLUM, 16)
