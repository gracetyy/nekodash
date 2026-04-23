class_name ModalPanel
extends PanelContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")


func _ready() -> void:
	ShellThemeUtil.apply_panel(self, ShellThemeUtil.CREAM)
