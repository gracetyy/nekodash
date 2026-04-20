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
const SLIDER_TRACK_COLOR: Color = Color(0.647059, 0.835294, 0.741176, 1.0)
const SLIDER_TRACK_BORDER_COLOR: Color = Color(0.486275, 0.466667, 0.494118, 1.0)
const SLIDER_FILL_COLOR: Color = Color(0.498039, 0.705882, 0.6, 1.0)
const SLIDER_TRACK_DISABLED_COLOR: Color = Color(0.776471, 0.772549, 0.788235, 1.0)
const SLIDER_TRACK_DISABLED_BORDER_COLOR: Color = Color(0.486275, 0.466667, 0.494118, 1.0)
const SLIDER_FILL_DISABLED_COLOR: Color = Color(0.67451, 0.635294, 0.67451, 1.0)

const DEFAULT_BORDER_WIDTH: int = 5
const DEFAULT_RADIUS: int = 28
const PILL_HOVER_SCALE: float = 1.05
const PILL_HOVER_DURATION_SEC: float = 0.12
const PILL_HOVER_WIRED_META: String = "_shell_pill_hover_wired"
const PILL_HOVER_TWEEN_META: String = "_shell_pill_hover_tween"
const CIRCLE_HOVER_SCALE: float = 1.08
const CIRCLE_HOVER_DURATION_SEC: float = 0.1
const CIRCLE_HOVER_WIRED_META: String = "_shell_circle_hover_wired"
const CIRCLE_HOVER_TWEEN_META: String = "_shell_circle_hover_tween"
const SLIDER_MIN_HEIGHT_PX: float = 22.0
const FREDOKA_BODY_FONT_PATH: String = "res://assets/fonts/Fredoka-Body-SemiBold.tres"
const FREDOKA_DISPLAY_FONT_PATH: String = "res://assets/fonts/Fredoka-Display-Bold.tres"
const FREDOKA_VARIABLE_FALLBACK: FontFile = preload("res://assets/fonts/Fredoka-Variable.ttf")

static var FONT_BODY: Font = _load_font_or_fallback(FREDOKA_BODY_FONT_PATH)
static var FONT_DISPLAY: Font = _load_font_or_fallback(FREDOKA_DISPLAY_FONT_PATH)
static var _checkbox_icons: Dictionary = {}

const TITLE_TEXTURE: Texture2D = preload("res://assets/art/ui/headers/nekodash_title_landscape.png")
const PANEL_TEXTURE: Texture2D = preload("res://assets/art/ui/panels/panel_modal_normal.png")
const STAR_PILL_TEXTURE: Texture2D = preload("res://assets/art/ui/hud/star_pill.png")
const MOVE_COUNTER_TEXTURE: Texture2D = preload("res://assets/art/ui/hud/move-counter-bg.png")
const LEVEL_CARD_UNLOCKED_TEXTURE: Texture2D = preload("res://assets/art/ui/world_map/level_card_unlocked.png")
const LEVEL_CARD_LOCKED_TEXTURE: Texture2D = preload("res://assets/art/ui/world_map/level_card_locked.png")
const LEVEL_CARD_COMPLETE_TEXTURE: Texture2D = preload("res://assets/art/ui/world_map/level_card_3star.png")
const WORLD_MAP_LOCK_TEXTURE: Texture2D = preload("res://assets/art/ui/world_map/icon_lock.png")
const BADGE_NEW_BEST_TEXTURE: Texture2D = preload("res://assets/art/ui/badges/badge_new_best.png")
const RIBBON_GREY_TEXTURE: Texture2D = preload("res://assets/art/ui/headers/ribbon_grey.png")
const RIBBON_PURPLE_TEXTURE: Texture2D = preload("res://assets/art/ui/headers/ribbon_purple.png")
const RIBBON_WHITE_TEXTURE: Texture2D = preload("res://assets/art/ui/headers/ribbon_white.png")
const RIBBON_YELLOW_TEXTURE: Texture2D = preload("res://assets/art/ui/headers/ribbon_yellow.png")
const CHECKBOX_EMPTY_TEXTURE: Texture2D = preload("res://assets/art/ui/settings/checkbox_empty.png")
const CHECKBOX_CHECKED_TEXTURE: Texture2D = preload("res://assets/art/ui/settings/checkbox_checked.png")
const CHECKBOX_DISABLED_TEXTURE: Texture2D = preload("res://assets/art/ui/settings/checkbox_disabled.png")
const CIRCLE_BACK_NORMAL_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_arrow_left_normal.png")
const CIRCLE_BACK_HOVER_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_arrow_left_hover.png")
const CIRCLE_BACK_PRESSED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_arrow_left_pressed.png")
const CIRCLE_BACK_DISABLED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_arrow_left_disabled.png")
const CIRCLE_CLOSE_NORMAL_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_close_normal.png")
const CIRCLE_CLOSE_HOVER_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_close_hover.png")
const CIRCLE_CLOSE_PRESSED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_close_pressed.png")
const CIRCLE_CLOSE_DISABLED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_close_disabled.png")
const CIRCLE_PLAY_NORMAL_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_play_normal.png")
const CIRCLE_PLAY_HOVER_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_play_hover.png")
const CIRCLE_PLAY_PRESSED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_play_pressed.png")
const CIRCLE_PLAY_DISABLED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_play_disabled.png")
const CIRCLE_REPLAY_NORMAL_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_replay_normal.png")
const CIRCLE_REPLAY_HOVER_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_replay_hover.png")
const CIRCLE_REPLAY_PRESSED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_replay_pressed.png")
const CIRCLE_REPLAY_DISABLED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_replay_disabled.png")
const CIRCLE_HOME_NORMAL_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_home_normal.png")
const CIRCLE_HOME_HOVER_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_home_hover.png")
const CIRCLE_HOME_PRESSED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_home_pressed.png")
const CIRCLE_HOME_DISABLED_TEXTURE: Texture2D = preload("res://assets/art/ui/buttons/circular/btn_circle_home_disabled.png")
const STAR_SMALL_FILLED_TEXTURE: Texture2D = preload("res://assets/art/ui/stars/star_small_filled.png")
const STAR_SMALL_EMPTY_TEXTURE: Texture2D = preload("res://assets/art/ui/stars/star_small_empty.png")
const STAR_SMALL_HOLLOW_TEXTURE: Texture2D = preload("res://assets/art/ui/stars/star_small_hollow.png")
const STAR_MEDIUM_FILLED_TEXTURE: Texture2D = preload("res://assets/art/ui/stars/star_medium_filled.png")
const STAR_MEDIUM_EMPTY_TEXTURE: Texture2D = preload("res://assets/art/ui/stars/star_medium_empty.png")
const STAR_LARGE_FILLED_TEXTURE: Texture2D = preload("res://assets/art/ui/stars/star_large_filled.png")
const STAR_LARGE_EMPTY_TEXTURE: Texture2D = preload("res://assets/art/ui/stars/star_large_empty.png")

const _PILL_TEXTURES: Dictionary = {
	"primary": {
		"normal": preload("res://assets/art/ui/buttons/pill_bases/primary_normal.png"),
		"hover": preload("res://assets/art/ui/buttons/pill_bases/primary_hover.png"),
		"pressed": preload("res://assets/art/ui/buttons/pill_bases/primary_pressed.png"),
	},
	"secondary": {
		"normal": preload("res://assets/art/ui/buttons/pill_bases/secondary_normal.png"),
		"hover": preload("res://assets/art/ui/buttons/pill_bases/secondary_hover.png"),
		"pressed": preload("res://assets/art/ui/buttons/pill_bases/secondary_pressed.png"),
	},
	"tertiary": {
		"normal": preload("res://assets/art/ui/buttons/pill_bases/tertiary_normal.png"),
		"hover": preload("res://assets/art/ui/buttons/pill_bases/tertiary_hover.png"),
		"pressed": preload("res://assets/art/ui/buttons/pill_bases/tertiary_pressed.png"),
	},
	"danger": {
		"normal": preload("res://assets/art/ui/buttons/pill_bases/danger_normal.png"),
		"hover": preload("res://assets/art/ui/buttons/pill_bases/danger_hover.png"),
		"pressed": preload("res://assets/art/ui/buttons/pill_bases/danger_pressed.png"),
	},
	"disabled": {
		"normal": preload("res://assets/art/ui/buttons/pill_bases/disabled.png"),
		"hover": preload("res://assets/art/ui/buttons/pill_bases/disabled.png"),
		"pressed": preload("res://assets/art/ui/buttons/pill_bases/disabled.png"),
	},
}


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


static func make_texture_style(
	texture: Texture2D,
	left: int,
	top: int,
	right: int,
	bottom: int,
	content_left: float = 0.0,
	content_top: float = 0.0,
	content_right: float = 0.0,
	content_bottom: float = 0.0
) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = left
	style.texture_margin_top = top
	style.texture_margin_right = right
	style.texture_margin_bottom = bottom
	style.content_margin_left = content_left
	style.content_margin_top = content_top
	style.content_margin_right = content_right
	style.content_margin_bottom = content_bottom
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


static func make_panel_style() -> StyleBoxTexture:
	return make_texture_style(PANEL_TEXTURE, 44, 44, 54, 54, 26.0, 26.0, 26.0, 28.0)


static func make_star_pill_style() -> StyleBoxTexture:
	return make_texture_style(STAR_PILL_TEXTURE, 26, 6, 26, 10, 18.0, 8.0, 18.0, 12.0)


static func make_level_card_style(state: String) -> StyleBoxTexture:
	var texture: Texture2D = LEVEL_CARD_UNLOCKED_TEXTURE
	match state:
		"locked":
			texture = LEVEL_CARD_LOCKED_TEXTURE
		"complete":
			texture = LEVEL_CARD_COMPLETE_TEXTURE
	return make_texture_style(texture, 20, 20, 20, 20, 16.0, 16.0, 16.0, 16.0)


static func make_world_card_style(selected: bool = false) -> StyleBoxTexture:
	var style: StyleBoxTexture = make_panel_style()
	style.modulate_color = Color(1.0, 0.949, 0.839, 1.0) if selected else CREAM
	return style


static func get_ribbon_texture(variant: String) -> Texture2D:
	match variant.to_lower():
		"grey":
			return RIBBON_GREY_TEXTURE
		"white":
			return RIBBON_WHITE_TEXTURE
		"yellow":
			return RIBBON_YELLOW_TEXTURE
		_:
			return RIBBON_PURPLE_TEXTURE


static func make_ribbon_style(variant: String = "purple") -> StyleBoxTexture:
	return make_texture_style(get_ribbon_texture(variant), 52, 22, 52, 28, 30.0, 14.0, 30.0, 20.0)


static func _pill_variant_from_fill(fill: Color) -> String:
	if fill == GOLD:
		return "primary"
	if fill == MINT:
		return "secondary"
	if fill == BLUSH:
		return "danger"
	if fill == DISABLED_FILL:
		return "disabled"
	return "tertiary"


static func _pill_style(variant: String, state: String) -> StyleBoxTexture:
	var textures: Dictionary = _PILL_TEXTURES.get(variant, _PILL_TEXTURES["primary"])
	var texture: Texture2D = textures.get(state, textures["normal"]) as Texture2D
	# Keep cap curvature consistent across states to avoid corner mismatch.
	return make_texture_style(texture, 52, 24, 52, 24, 30.0, 14.0, 30.0, 18.0)


static func _ensure_fonts_loaded() -> void:
	pass


static func _text_scale_factor() -> float:
	var text_scale: float = _call_app_settings_float("get_text_scale_factor", -1.0)
	if text_scale > 0.0:
		return text_scale

	var ui_scale: float = _call_app_settings_float("get_ui_scale_factor", -1.0)
	if ui_scale > 0.0:
		return ui_scale

	return 1.0


static func _is_reduce_motion_enabled() -> bool:
	return _call_app_settings_bool("get_reduce_motion", false)


static func _call_app_settings_float(method_name: StringName, fallback: float) -> float:
	if AppSettings == null:
		return fallback
	var method_callable: Callable = Callable(AppSettings, method_name)
	if not method_callable.is_valid():
		return fallback
	var value: Variant = method_callable.call()
	if value is float:
		return value as float
	if value is int:
		return float(value)
	return fallback


static func _call_app_settings_bool(method_name: StringName, fallback: bool) -> bool:
	if AppSettings == null:
		return fallback
	var method_callable: Callable = Callable(AppSettings, method_name)
	if not method_callable.is_valid():
		return fallback
	var value: Variant = method_callable.call()
	if value is bool:
		return value as bool
	return fallback


static func _scaled_font_size(base_size: int) -> int:
	return maxi(1, int(round(float(base_size) * _text_scale_factor())))

static func _load_font_or_fallback(path: String) -> Font:
	var loaded: Resource = load(path)
	if loaded is Font:
		return loaded as Font
	return FREDOKA_VARIABLE_FALLBACK


static func apply_pill_button(
	button: BaseButton,
	fill: Color,
	_pressed_fill: Color,
	font_color: Color = PLUM,
	min_height: float = 60.0
) -> void:
	if button == null:
		return
	_ensure_fonts_loaded()
	var variant: String = _pill_variant_from_fill(fill)
	var resolved_font_color: Color = font_color
	if variant == "danger":
		resolved_font_color = Color.WHITE
	button.custom_minimum_size = Vector2(0.0, maxf(min_height, 60.0 * _text_scale_factor()))
	button.add_theme_font_override("font", FONT_DISPLAY)
	button.add_theme_font_size_override("font_size", _scaled_font_size(30))
	button.add_theme_color_override("font_color", resolved_font_color)
	button.add_theme_color_override("font_hover_color", resolved_font_color)
	button.add_theme_color_override("font_pressed_color", resolved_font_color)
	button.add_theme_color_override("font_hover_pressed_color", resolved_font_color)
	button.add_theme_color_override("font_focus_color", resolved_font_color)
	button.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	button.add_theme_constant_override("h_separation", 10)
	button.add_theme_stylebox_override("normal", _pill_style(variant, "normal"))
	button.add_theme_stylebox_override("hover", _pill_style(variant, "hover"))
	button.add_theme_stylebox_override("pressed", _pill_style(variant, "pressed"))
	button.add_theme_stylebox_override("focus", _pill_style(variant, "normal"))
	button.add_theme_stylebox_override("disabled", _pill_style("disabled", "normal"))
	_wire_pill_hover_feedback(button)


static func _wire_pill_hover_feedback(button: BaseButton) -> void:
	if button == null:
		return
	if button.has_meta(PILL_HOVER_WIRED_META):
		return

	var entered_callable: Callable = Callable(ShellTheme, "_on_pill_hover_entered").bind(button)
	var exited_callable: Callable = Callable(ShellTheme, "_on_pill_hover_exited").bind(button)
	if not button.mouse_entered.is_connected(entered_callable):
		button.mouse_entered.connect(entered_callable)
	if not button.mouse_exited.is_connected(exited_callable):
		button.mouse_exited.connect(exited_callable)
	button.set_meta(PILL_HOVER_WIRED_META, true)


static func _on_pill_hover_entered(button: BaseButton) -> void:
	_animate_pill_hover_scale(button, Vector2(PILL_HOVER_SCALE, PILL_HOVER_SCALE))


static func _on_pill_hover_exited(button: BaseButton) -> void:
	_animate_pill_hover_scale(button, Vector2.ONE)


static func _animate_pill_hover_scale(button: BaseButton, target_scale: Vector2) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	if _is_reduce_motion_enabled():
		button.scale = target_scale
		return

	var prior_tween: Tween = null
	if button.has_meta(PILL_HOVER_TWEEN_META):
		prior_tween = button.get_meta(PILL_HOVER_TWEEN_META) as Tween
	if prior_tween != null and prior_tween.is_valid():
		prior_tween.kill()

	var tween: Tween = button.create_tween()
	tween.tween_property(button, "scale", target_scale, PILL_HOVER_DURATION_SEC) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta(PILL_HOVER_TWEEN_META, tween)


static func apply_option_button(option_button: OptionButton) -> void:
	if option_button == null:
		return
	_ensure_fonts_loaded()
	option_button.custom_minimum_size = Vector2(maxf(186.0, option_button.custom_minimum_size.x), maxf(60.0, 56.0 * _text_scale_factor()))
	option_button.add_theme_font_override("font", FONT_BODY)
	option_button.add_theme_font_size_override("font_size", _scaled_font_size(20))
	option_button.add_theme_color_override("font_color", PLUM)
	option_button.add_theme_color_override("font_hover_color", PLUM)
	option_button.add_theme_color_override("font_pressed_color", PLUM)
	option_button.add_theme_color_override("font_focus_color", PLUM)
	option_button.add_theme_color_override("font_hover_pressed_color", PLUM)
	option_button.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	option_button.add_theme_constant_override("h_separation", 12)
	var normal_style: StyleBoxFlat = make_rounded_style(CREAM, PLUM_SOFT, 24, 2)
	var hover_style: StyleBoxFlat = make_rounded_style(CREAM_SOFT, PLUM_SOFT, 24, 2)
	var pressed_style: StyleBoxFlat = make_rounded_style(LILAC, PLUM_SOFT, 24, 2)
	var disabled_style: StyleBoxFlat = make_rounded_style(DISABLED_FILL, PLUM_SOFT, 24, 2)
	normal_style.content_margin_left = 16.0
	normal_style.content_margin_right = 16.0
	hover_style.content_margin_left = 16.0
	hover_style.content_margin_right = 16.0
	pressed_style.content_margin_left = 16.0
	pressed_style.content_margin_right = 16.0
	disabled_style.content_margin_left = 16.0
	disabled_style.content_margin_right = 16.0
	option_button.add_theme_stylebox_override("normal", normal_style)
	option_button.add_theme_stylebox_override("hover", hover_style)
	option_button.add_theme_stylebox_override("pressed", pressed_style)
	option_button.add_theme_stylebox_override("focus", hover_style)
	option_button.add_theme_stylebox_override("disabled", disabled_style)

	var popup: PopupMenu = option_button.get_popup()
	if popup == null:
		return
	popup.set("transparent", true)
	popup.set("transparent_bg", true)
	popup.set("borderless", true)
	popup.add_theme_font_override("font", FONT_BODY)
	popup.add_theme_font_size_override("font_size", _scaled_font_size(18))
	popup.add_theme_color_override("font_color", PLUM)
	popup.add_theme_color_override("font_hover_color", PLUM)
	popup.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	var popup_panel: StyleBoxFlat = make_rounded_style(CREAM, PLUM_SOFT, 26, 3)
	popup_panel.content_margin_left = 16.0
	popup_panel.content_margin_top = 12.0
	popup_panel.content_margin_right = 16.0
	popup_panel.content_margin_bottom = 12.0
	popup_panel.anti_aliasing = true
	popup_panel.corner_detail = 16
	popup_panel.expand_margin_left = 2.0
	popup_panel.expand_margin_top = 2.0
	popup_panel.expand_margin_right = 2.0
	popup_panel.expand_margin_bottom = 2.0
	popup.add_theme_stylebox_override("panel", popup_panel)
	popup.add_theme_stylebox_override("panel_disabled", popup_panel)
	var popup_item_normal: StyleBoxFlat = make_rounded_style(CREAM, Color(0.0, 0.0, 0.0, 0.0), 18, 0)
	popup_item_normal.content_margin_left = 14.0
	popup_item_normal.content_margin_right = 14.0
	popup_item_normal.content_margin_top = 8.0
	popup_item_normal.content_margin_bottom = 8.0
	popup_item_normal.anti_aliasing = true
	popup_item_normal.corner_detail = 12
	var popup_hover: StyleBoxFlat = make_rounded_style(CREAM_SOFT, PLUM_SOFT, 18, 2)
	popup_hover.content_margin_left = 14.0
	popup_hover.content_margin_right = 14.0
	popup_hover.content_margin_top = 8.0
	popup_hover.content_margin_bottom = 8.0
	popup_hover.anti_aliasing = true
	popup_hover.corner_detail = 12
	popup.add_theme_stylebox_override("normal", popup_item_normal)
	popup.add_theme_stylebox_override("hover", popup_hover)
	popup.add_theme_stylebox_override("focus", popup_hover)


static func apply_panel(panel: PanelContainer, _fill: Color = CREAM) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", make_panel_style())


static func apply_modal_backdrop(backdrop: ColorRect) -> void:
	if backdrop == null:
		return
	backdrop.color = OVERLAY


static func apply_progress_bar(bar: ProgressBar) -> void:
	if bar == null:
		return
	bar.add_theme_stylebox_override("background", _make_slider_track_style(false))
	bar.add_theme_stylebox_override("fill", _make_slider_fill_style(false))


static func apply_title(label: Label, size: int = 48) -> void:
	if label == null:
		return
	_ensure_fonts_loaded()
	label.add_theme_font_override("font", FONT_DISPLAY)
	label.add_theme_color_override("font_color", PLUM)
	label.add_theme_font_size_override("font_size", _scaled_font_size(size))


static func apply_body(label: Label, color: Color = PLUM_SOFT, size: int = 18) -> void:
	if label == null:
		return
	_ensure_fonts_loaded()
	label.add_theme_font_override("font", FONT_BODY)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", _scaled_font_size(size))


static func apply_checkbox(toggle: BaseButton) -> void:
	if toggle == null:
		return
	_ensure_fonts_loaded()
	var checkbox_icons: Dictionary = _get_checkbox_icons()
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	toggle.custom_minimum_size = Vector2(toggle.custom_minimum_size.x, maxf(toggle.custom_minimum_size.y, 48.0 * _text_scale_factor()))
	toggle.add_theme_icon_override("checked", checkbox_icons.get("checked", CHECKBOX_CHECKED_TEXTURE) as Texture2D)
	toggle.add_theme_icon_override("unchecked", checkbox_icons.get("unchecked", CHECKBOX_EMPTY_TEXTURE) as Texture2D)
	toggle.add_theme_icon_override("checked_disabled", checkbox_icons.get("disabled", CHECKBOX_DISABLED_TEXTURE) as Texture2D)
	toggle.add_theme_icon_override("unchecked_disabled", checkbox_icons.get("disabled", CHECKBOX_DISABLED_TEXTURE) as Texture2D)
	toggle.add_theme_font_override("font", FONT_BODY)
	toggle.add_theme_font_size_override("font_size", _scaled_font_size(20))
	toggle.add_theme_color_override("font_color", PLUM)
	toggle.add_theme_color_override("font_hover_color", PLUM)
	toggle.add_theme_color_override("font_pressed_color", PLUM)
	toggle.add_theme_color_override("font_hover_pressed_color", PLUM)
	toggle.add_theme_color_override("font_focus_color", PLUM)
	toggle.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	toggle.add_theme_constant_override("h_separation", 10)
	toggle.add_theme_constant_override("icon_max_width", 32)
	toggle.add_theme_stylebox_override("normal", empty)
	toggle.add_theme_stylebox_override("hover", empty)
	toggle.add_theme_stylebox_override("pressed", empty)
	toggle.add_theme_stylebox_override("focus", empty)
	toggle.add_theme_stylebox_override("disabled", empty)
	if toggle is CheckButton:
		var check_button: CheckButton = toggle as CheckButton
		check_button.clip_text = false
		check_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		check_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		check_button.expand_icon = false
		if check_button.text.strip_edges() != "":
			check_button.custom_minimum_size.x = maxf(check_button.custom_minimum_size.x, 152.0 * _text_scale_factor())


static func apply_slider(range_control: Range) -> void:
	if range_control == null or not range_control is HSlider:
		return
	var slider: HSlider = range_control as HSlider
	var min_width: float = maxf(slider.custom_minimum_size.x, 186.0)
	slider.custom_minimum_size = Vector2(min_width, SLIDER_MIN_HEIGHT_PX)
	set_slider_interactive(slider, slider.editable)


static func set_slider_interactive(slider: HSlider, interactive: bool) -> void:
	if slider == null:
		return
	if interactive:
		slider.add_theme_stylebox_override("slider", _make_slider_track_style(false))
		slider.add_theme_stylebox_override("grabber_area", _make_slider_fill_style(false))
		slider.add_theme_stylebox_override("grabber_area_highlight", _make_slider_fill_style(false))
		slider.add_theme_stylebox_override("grabber_area_disabled", _make_slider_fill_style(true))
		slider.remove_theme_icon_override("grabber")
		slider.remove_theme_icon_override("grabber_highlight")
		slider.remove_theme_icon_override("grabber_disabled")
		slider.mouse_filter = Control.MOUSE_FILTER_STOP
		slider.focus_mode = Control.FOCUS_ALL
	else:
		slider.add_theme_stylebox_override("slider", _make_slider_track_style(true))
		slider.add_theme_stylebox_override("grabber_area", _make_slider_fill_style(true))
		slider.add_theme_stylebox_override("grabber_area_highlight", _make_slider_fill_style(true))
		slider.add_theme_stylebox_override("grabber_area_disabled", _make_slider_fill_style(true))
		slider.remove_theme_icon_override("grabber")
		slider.remove_theme_icon_override("grabber_highlight")
		slider.remove_theme_icon_override("grabber_disabled")
		slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slider.focus_mode = Control.FOCUS_NONE
		if slider.has_focus():
			slider.release_focus()
	slider.editable = interactive
	slider.add_theme_constant_override("center_grabber", 1)
	slider.add_theme_constant_override("grabber_offset", 0)


static func _make_slider_track_style(disabled: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SLIDER_TRACK_DISABLED_COLOR if disabled else SLIDER_TRACK_COLOR
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = SLIDER_TRACK_DISABLED_BORDER_COLOR if disabled else SLIDER_TRACK_BORDER_COLOR
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	return style


static func _make_slider_fill_style(disabled: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SLIDER_FILL_DISABLED_COLOR if disabled else SLIDER_FILL_COLOR
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


static func _get_checkbox_icons() -> Dictionary:
	if not _checkbox_icons.is_empty():
		return _checkbox_icons
	_checkbox_icons["checked"] = _build_scaled_texture(CHECKBOX_CHECKED_TEXTURE, 32)
	_checkbox_icons["unchecked"] = _build_scaled_texture(CHECKBOX_EMPTY_TEXTURE, 32)
	_checkbox_icons["disabled"] = _build_scaled_texture(CHECKBOX_DISABLED_TEXTURE, 32)
	return _checkbox_icons


static func _build_scaled_texture(source: Texture2D, target_size: int) -> Texture2D:
	if source == null:
		return null
	var image: Image = source.get_image()
	if image == null or image.is_empty():
		return source
	image.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


static func apply_circle_icon_button(
	button: BaseButton,
	normal: Texture2D,
	hover: Texture2D,
	pressed: Texture2D,
	disabled: Texture2D,
	size: float = 64.0
) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(size, size)
	if button is TextureButton:
		var texture_button: TextureButton = button as TextureButton
		texture_button.ignore_texture_size = true
		texture_button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
		texture_button.texture_normal = normal
		texture_button.texture_hover = hover
		texture_button.texture_pressed = pressed
		texture_button.texture_disabled = disabled
		texture_button.texture_focused = hover
		_wire_circle_hover_feedback(button)
		return

	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	button.text = ""
	button.icon = normal
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)
	_wire_circle_hover_feedback(button)


static func _wire_circle_hover_feedback(button: BaseButton) -> void:
	if button == null:
		return
	if button.has_meta(CIRCLE_HOVER_WIRED_META):
		return

	var entered_callable: Callable = Callable(ShellTheme, "_on_circle_hover_entered").bind(button)
	var exited_callable: Callable = Callable(ShellTheme, "_on_circle_hover_exited").bind(button)
	if not button.mouse_entered.is_connected(entered_callable):
		button.mouse_entered.connect(entered_callable)
	if not button.mouse_exited.is_connected(exited_callable):
		button.mouse_exited.connect(exited_callable)
	button.set_meta(CIRCLE_HOVER_WIRED_META, true)


static func _on_circle_hover_entered(button: BaseButton) -> void:
	_animate_circle_hover_scale(button, Vector2(CIRCLE_HOVER_SCALE, CIRCLE_HOVER_SCALE))


static func _on_circle_hover_exited(button: BaseButton) -> void:
	_animate_circle_hover_scale(button, Vector2.ONE)


static func _animate_circle_hover_scale(button: BaseButton, target_scale: Vector2) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	if AppSettings != null and AppSettings.get_reduce_motion():
		button.scale = target_scale
		return

	var prior_tween: Tween = null
	if button.has_meta(CIRCLE_HOVER_TWEEN_META):
		prior_tween = button.get_meta(CIRCLE_HOVER_TWEEN_META) as Tween
	if prior_tween != null and prior_tween.is_valid():
		prior_tween.kill()

	var tween: Tween = button.create_tween()
	tween.tween_property(button, "scale", target_scale, CIRCLE_HOVER_DURATION_SEC) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	button.set_meta(CIRCLE_HOVER_TWEEN_META, tween)


static func apply_circle_back_button(button: BaseButton, size: float = 64.0) -> void:
	apply_circle_icon_button(
		button,
		CIRCLE_BACK_NORMAL_TEXTURE,
		CIRCLE_BACK_HOVER_TEXTURE,
		CIRCLE_BACK_PRESSED_TEXTURE,
		CIRCLE_BACK_DISABLED_TEXTURE,
		size
	)


static func apply_circle_close_button(button: BaseButton, size: float = 58.0) -> void:
	apply_circle_icon_button(
		button,
		CIRCLE_CLOSE_NORMAL_TEXTURE,
		CIRCLE_CLOSE_HOVER_TEXTURE,
		CIRCLE_CLOSE_PRESSED_TEXTURE,
		CIRCLE_CLOSE_DISABLED_TEXTURE,
		size
	)


static func apply_circle_play_button(button: BaseButton, size: float = 62.0) -> void:
	apply_circle_icon_button(
		button,
		CIRCLE_PLAY_NORMAL_TEXTURE,
		CIRCLE_PLAY_HOVER_TEXTURE,
		CIRCLE_PLAY_PRESSED_TEXTURE,
		CIRCLE_PLAY_DISABLED_TEXTURE,
		size
	)


static func apply_circle_replay_button(button: BaseButton, size: float = 62.0) -> void:
	apply_circle_icon_button(
		button,
		CIRCLE_REPLAY_NORMAL_TEXTURE,
		CIRCLE_REPLAY_HOVER_TEXTURE,
		CIRCLE_REPLAY_PRESSED_TEXTURE,
		CIRCLE_REPLAY_DISABLED_TEXTURE,
		size
	)


static func apply_circle_home_button(button: BaseButton, size: float = 62.0) -> void:
	apply_circle_icon_button(
		button,
		CIRCLE_HOME_NORMAL_TEXTURE,
		CIRCLE_HOME_HOVER_TEXTURE,
		CIRCLE_HOME_PRESSED_TEXTURE,
		CIRCLE_HOME_DISABLED_TEXTURE,
		size
	)
