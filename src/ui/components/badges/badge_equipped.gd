class_name BadgeEquipped
extends PanelContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

const EQUIPPED_FILL: Color = Color(0.368627, 0.796078, 0.658824, 1.0)

@export var badge_text: String = "EQUIPPED"

@onready var _label: Label = $Label


func _ready() -> void:
	_apply_component_state()


func _apply_component_state() -> void:
	var style: StyleBoxFlat = ShellThemeUtil.make_rounded_style(EQUIPPED_FILL, ShellThemeUtil.PLUM_SOFT, 18, 0)
	style.content_margin_left = 16.0
	style.content_margin_top = 8.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)
	_label.text = badge_text
	ShellThemeUtil.apply_body(_label, Color.WHITE, 18)
