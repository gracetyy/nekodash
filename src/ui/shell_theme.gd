class_name ShellTheme
extends RefCounted

const CREAM: Color = Color(0.992, 0.969, 0.902, 1.0)
const CREAM_SOFT: Color = Color(0.972, 0.937, 0.859, 1.0)
const PLUM: Color = Color(0.353, 0.247, 0.369, 1.0)
const PLUM_SOFT: Color = Color(0.467, 0.365, 0.506, 1.0)
const GOLD: Color = Color(0.969, 0.776, 0.286, 1.0)
const GOLD_PRESSED: Color = Color(0.925, 0.706, 0.239, 1.0)
const LILAC: Color = Color(0.824, 0.745, 0.918, 1.0)
const LILAC_PRESSED: Color = Color(0.741, 0.659, 0.859, 1.0)
const MINT: Color = Color(0.722, 0.906, 0.816, 1.0)
const MINT_PRESSED: Color = Color(0.639, 0.831, 0.745, 1.0)
const BLUSH: Color = Color(0.973, 0.816, 0.835, 1.0)
const DISABLED_FILL: Color = Color(0.823, 0.808, 0.835, 1.0)
const DISABLED_TEXT: Color = Color(0.519, 0.467, 0.561, 1.0)
const OVERLAY: Color = Color(0.118, 0.086, 0.141, 0.62)

const DEFAULT_BORDER_WIDTH: int = 5
const DEFAULT_RADIUS: int = 28


static func make_rounded_style(
	fill: Color,
	border: Color = PLUM,
	radius: int = DEFAULT_RADIUS,
	border_width: int = DEFAULT_BORDER_WIDTH
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 16.0
	style.content_margin_top = 12.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 12.0
	return style


static func make_button_styles(
	fill: Color,
	pressed_fill: Color,
	font_color: Color = PLUM
) -> Dictionary:
	var normal: StyleBoxFlat = make_rounded_style(fill)
	var hover: StyleBoxFlat = make_rounded_style(fill.lightened(0.04))
	var pressed: StyleBoxFlat = make_rounded_style(pressed_fill)
	var disabled: StyleBoxFlat = make_rounded_style(DISABLED_FILL, PLUM_SOFT)
	return {
		"normal": normal,
		"hover": hover,
		"pressed": pressed,
		"focus": hover,
		"disabled": disabled,
		"font_color": font_color,
	}


static func apply_pill_button(
	button: BaseButton,
	fill: Color,
	pressed_fill: Color,
	font_color: Color = PLUM,
	min_height: float = 58.0
) -> void:
	if button == null:
		return
	var styles: Dictionary = make_button_styles(fill, pressed_fill, font_color)
	button.custom_minimum_size = Vector2(0.0, min_height)
	button.add_theme_color_override("font_color", styles["font_color"])
	button.add_theme_color_override("font_hover_color", styles["font_color"])
	button.add_theme_color_override("font_pressed_color", styles["font_color"])
	button.add_theme_color_override("font_focus_color", styles["font_color"])
	button.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	button.add_theme_stylebox_override("normal", styles["normal"])
	button.add_theme_stylebox_override("hover", styles["hover"])
	button.add_theme_stylebox_override("pressed", styles["pressed"])
	button.add_theme_stylebox_override("focus", styles["focus"])
	button.add_theme_stylebox_override("disabled", styles["disabled"])


static func apply_panel(panel: PanelContainer, fill: Color = CREAM) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", make_rounded_style(fill))


static func apply_modal_backdrop(backdrop: ColorRect) -> void:
	if backdrop == null:
		return
	backdrop.color = OVERLAY


static func apply_progress_bar(bar: ProgressBar) -> void:
	if bar == null:
		return
	bar.add_theme_stylebox_override("background", make_rounded_style(CREAM_SOFT, PLUM_SOFT, 18, 4))
	bar.add_theme_stylebox_override("fill", make_rounded_style(GOLD, PLUM, 18, 4))


static func apply_title(label: Label, size: int = 48) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", PLUM)
	label.add_theme_font_size_override("font_size", size)


static func apply_body(label: Label, color: Color = PLUM_SOFT, size: int = 18) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
