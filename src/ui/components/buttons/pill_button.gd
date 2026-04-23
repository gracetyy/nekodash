class_name PillButton
extends Button

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

enum Variant {
	PRIMARY,
	SECONDARY,
	TERTIARY,
	DANGER,
}

@export var variant: Variant = Variant.PRIMARY

@export_range(44.0, 120.0, 1.0, "or_greater")
var min_height_px: float = 60.0


func _ready() -> void:
	_apply_component_state()


func _apply_component_state() -> void:
	match variant:
		Variant.SECONDARY:
			ShellThemeUtil.apply_pill_button(self , ShellThemeUtil.MINT, ShellThemeUtil.MINT_PRESSED)
		Variant.TERTIARY:
			ShellThemeUtil.apply_pill_button(self , ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED)
		Variant.DANGER:
			ShellThemeUtil.apply_pill_button(self , ShellThemeUtil.BLUSH, ShellThemeUtil.LILAC_PRESSED, Color.WHITE)
		_:
			ShellThemeUtil.apply_pill_button(self , ShellThemeUtil.GOLD, ShellThemeUtil.GOLD_PRESSED)
	custom_minimum_size.y = maxf(custom_minimum_size.y, min_height_px)
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	expand_icon = false
	clip_text = false
