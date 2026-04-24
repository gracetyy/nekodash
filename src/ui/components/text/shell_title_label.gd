## ShellTitleLabel — reusable stylized heading label used in overlay scenes.
class_name ShellTitleLabel
extends Label

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

@export_range(10, 96, 1, "or_greater")
var font_size: int = 40:
	set(value):
		font_size = value
		if is_inside_tree():
			refresh_style()


func _ready() -> void:
	refresh_style()


func refresh_style() -> void:
	ShellThemeUtil.apply_title(self , font_size)
