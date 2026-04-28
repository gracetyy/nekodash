@tool
class_name RibbonHeader
extends NinePatchRect

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
var title_font_size: int = 32

@export var title_color: Color = Color(1.0, 0.984, 0.957, 1.0)

@export_range(0, 120, 1, "or_greater")
var title_horizontal_padding: int = 42

@export_range(12, 64, 1, "or_greater")
var title_min_font_size: int = 18

@onready var _title_label: Label = $RibbonTitleLabel


func _ready() -> void:
	_apply_component_state()
	call_deferred("_apply_component_state")


func refresh_style() -> void:
	_apply_component_state()


func set_title(value: String) -> void:
	title_text = value
	_apply_component_state()


func get_title_label() -> Label:
	return _title_label


func _apply_component_state() -> void:
	texture = ShellThemeUtil.get_ribbon_texture(_variant_key())
	
	# NinePatchRect configuration
	patch_margin_left = 52
	patch_margin_top = 22
	patch_margin_right = 52
	patch_margin_bottom = 28
	
	axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	
	if _title_label == null:
		return
		
	# Ensure label is centered in the stretchable middle area
	_title_label.anchor_left = 0.0
	_title_label.anchor_top = 0.0
	_title_label.anchor_right = 1.0
	_title_label.anchor_bottom = 1.0
	
	_title_label.offset_left = float(title_horizontal_padding)
	_title_label.offset_right = - float(title_horizontal_padding)
	_title_label.offset_top = 0.0
	_title_label.offset_bottom = -6.0 # Visual adjustment for ribbon shape
	
	_title_label.clip_text = true
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.text = title_text
	
	ShellThemeUtil.apply_title(_title_label, title_font_size)
	_fit_title_to_label_width()
	_title_label.add_theme_color_override("font_color", title_color)


func _fit_title_to_label_width() -> void:
	if _title_label == null:
		return
	if title_text.is_empty():
		return

	var available_width: float = _title_label.size.x
	if available_width <= 0.0:
		# If size is not yet calculated, use custom_minimum_size as fallback
		available_width = custom_minimum_size.x - (title_horizontal_padding * 2)
		if available_width <= 0.0:
			return

	for candidate_size: int in range(title_font_size, title_min_font_size - 1, -1):
		ShellThemeUtil.apply_title(_title_label, candidate_size)
		var font: Font = _title_label.get_theme_font("font")
		if font == null:
			continue
		var font_px: int = _title_label.get_theme_font_size("font_size")
		var width_px: float = font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_px).x
		if width_px <= available_width:
			return


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
