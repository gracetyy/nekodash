class_name RibbonHeader
extends TextureRect

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

enum Variant {
	PURPLE,
	WHITE,
	YELLOW,
	GREY,
}

@export var variant: Variant = Variant.PURPLE

@export var title_text: String = "TITLE"

@export_range(18, 64, 1, "or_greater")
var title_font_size: int = 40

@export var title_color: Color = Color(1.0, 0.984, 0.957, 1.0)

@onready var _title_label: Label = $RibbonTitleLabel


func _ready() -> void:
	_apply_component_state()


func set_title(value: String) -> void:
	title_text = value
	_apply_component_state()


func get_title_label() -> Label:
	return _title_label


func _apply_component_state() -> void:
	texture = ShellThemeUtil.get_ribbon_texture(_variant_key())
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _title_label == null:
		return
	_title_label.text = title_text
	ShellThemeUtil.apply_title(_title_label, title_font_size)
	_title_label.add_theme_color_override("font_color", title_color)


func _variant_key() -> String:
	match variant:
		Variant.WHITE:
			return "white"
		Variant.YELLOW:
			return "yellow"
		Variant.GREY:
			return "grey"
		_:
			return "purple"
