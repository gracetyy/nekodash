## MainMenu — title screen with navigation to World Map and Skins.
## Task: S3-04 (bug fix — back button target), S4-14 (Skins + CatSprite wiring)
##
## Simple title screen that lets the player start the game by navigating
## to the World Map. Acts as the landing screen and the back-button target
## from WorldMap. Shows CatSprite using the equipped skin placeholder.
class_name MainMenu
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const ICON_PLAY: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_play.png")
const ICON_CAT: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_cat.png")
const ICON_SETTINGS: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_settings.png")
const ICON_INFO: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_info.png")
const TITLE_TEXTURE_LANDSCAPE: Texture2D = preload("res://assets/art/ui/headers/nekodash_title_landscape.png")
const TITLE_TEXTURE_PORTRAIT: Texture2D = preload("res://assets/art/ui/headers/nekodash_title_portrait.png")
const CAT_IDLE_TEXTURE: Texture2D = preload("res://assets/art/cats/cat_default_idle@2x.png")
const CAT_IDLE_TAIL_UP_TEXTURE: Texture2D = preload("res://assets/art/cats/cat_default_idle_tail_up@2x.png")
const CAT_IDLE_TAIL_DOWN_TEXTURE: Texture2D = preload("res://assets/art/cats/cat_default_idle_tail_down@2x.png")
const TITLE_PORTRAIT_MAX_WIDTH: float = 700.0
const CAT_TAIL_BLEND_PERIOD_SEC: float = 1.4


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when the play button is pressed.
signal play_requested


# —————————————————————————————————————————————
# Child node references
# —————————————————————————————————————————————

var _play_btn: BaseButton
var _options_btn: BaseButton
var _credits_btn: BaseButton
var _skins_btn: BaseButton
var _hero_card: PanelContainer
var _hint_label: Label
var _title_texture: TextureRect
var _cat_illustration: TextureRect
var _cat_tail_overlay: TextureRect
var _buttons_box: VBoxContainer
var _cat_tail_blend_time_sec: float = 0.0


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_auto_discover_ui_nodes()
	_connect_signals()
	_apply_visual_style()
	_refresh_title_texture_variant()
	_play_intro_animation()
	_set_up_cat_idle_animation()
	if _play_btn != null:
		_play_btn.grab_focus()


# —————————————————————————————————————————————
# Private methods
# —————————————————————————————————————————————

func _auto_discover_ui_nodes() -> void:
	_play_btn = _find_child_safe("PlayBtn", "BaseButton") as BaseButton
	_options_btn = _find_child_safe("OptionsBtn", "BaseButton") as BaseButton
	_credits_btn = _find_child_safe("CreditsBtn", "BaseButton") as BaseButton
	_skins_btn = _find_child_safe("SkinsBtn", "BaseButton") as BaseButton
	_hero_card = _find_child_safe("HeroCard", "PanelContainer") as PanelContainer
	_hint_label = _find_child_safe("HintLabel", "Label") as Label
	_title_texture = _find_child_safe("TitleLabel", "TextureRect") as TextureRect
	_cat_illustration = _find_child_safe("CatIllustration", "TextureRect") as TextureRect
	_cat_tail_overlay = _find_child_safe("CatTailOverlay", "TextureRect") as TextureRect
	_buttons_box = _find_child_safe("Buttons", "VBoxContainer") as VBoxContainer


func _find_child_safe(child_name: String, expected_type: String) -> Node:
	var node: Node = find_child(child_name, true, false)
	if node == null:
		push_warning("MainMenu: expected child '%s' (%s) not found." % [child_name, expected_type])
	return node


func _connect_signals() -> void:
	if _play_btn != null:
		_play_btn.pressed.connect(_on_play_btn_pressed)
	if _options_btn != null:
		_options_btn.pressed.connect(_on_options_btn_pressed)
	if _credits_btn != null:
		_credits_btn.pressed.connect(_on_credits_btn_pressed)
	if _skins_btn != null:
		_skins_btn.pressed.connect(_on_skins_btn_pressed)
	if not resized.is_connected(_on_main_menu_resized):
		resized.connect(_on_main_menu_resized)


func _process(delta: float) -> void:
	if _cat_illustration == null or _cat_tail_overlay == null:
		return
	if _is_reduce_motion_enabled():
		_cat_illustration.texture = CAT_IDLE_TEXTURE
		_cat_tail_overlay.visible = false
		return
	_cat_tail_blend_time_sec += delta
	_update_cat_tail_animation()


func _on_play_btn_pressed() -> void:
	play_requested.emit()
	_navigate_to_world_map()


func _on_options_btn_pressed() -> void:
	SceneManager.show_overlay(SceneManager.Overlay.OPTIONS, {
		"title": "Options",
	})


func _on_credits_btn_pressed() -> void:
	SceneManager.go_to(SceneManager.Screen.CREDITS)


func _on_skins_btn_pressed() -> void:
	SceneManager.go_to(SceneManager.Screen.SKIN_SELECT)


func _navigate_to_world_map() -> void:
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP, {
		"highlight_world_id": AppSettings.get_last_world_id(),
	})


func _apply_visual_style() -> void:
	if _hero_card != null:
		_hero_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	ShellThemeUtil.apply_pill_button(_play_btn, ShellThemeUtil.GOLD, ShellThemeUtil.GOLD_PRESSED)
	ShellThemeUtil.apply_pill_button(_skins_btn, ShellThemeUtil.MINT, ShellThemeUtil.MINT_PRESSED)
	ShellThemeUtil.apply_pill_button(_options_btn, ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED)
	ShellThemeUtil.apply_pill_button(_credits_btn, ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED)
	_apply_button_icon(_play_btn, ICON_PLAY)
	_apply_button_icon(_skins_btn, ICON_CAT)
	_apply_button_icon(_options_btn, ICON_SETTINGS)
	_apply_button_icon(_credits_btn, ICON_INFO)
	if _hint_label != null:
		_hint_label.text = ""
		_hint_label.visible = false
		ShellThemeUtil.apply_body(_hint_label, ShellThemeUtil.PLUM_SOFT, 16)


func _on_main_menu_resized() -> void:
	_refresh_title_texture_variant()


func _refresh_title_texture_variant() -> void:
	if _title_texture == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var use_portrait_title: bool = viewport_size.x < TITLE_PORTRAIT_MAX_WIDTH
	if use_portrait_title:
		_title_texture.texture = TITLE_TEXTURE_PORTRAIT
		_title_texture.custom_minimum_size = Vector2(320.0, 228.0)
	else:
		_title_texture.texture = TITLE_TEXTURE_LANDSCAPE
		_title_texture.custom_minimum_size = Vector2(560.0, 220.0)


func _apply_button_icon(button: BaseButton, icon: Texture2D) -> void:
	if button == null or icon == null or not button is Button:
		return
	var text_button: Button = button as Button
	text_button.icon = icon
	text_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_button.add_theme_constant_override("icon_max_width", 34)
	text_button.add_theme_constant_override("h_separation", 14)


func _play_intro_animation() -> void:
	if _is_reduce_motion_enabled():
		return
	if _hero_card != null:
		_hero_card.pivot_offset = _hero_card.size * 0.5
		_hero_card.scale = Vector2(0.97, 0.97)
		_hero_card.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var hero_tween: Tween = create_tween()
		hero_tween.tween_property(_hero_card, "modulate:a", 1.0, 0.24) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		hero_tween.parallel().tween_property(_hero_card, "scale", Vector2.ONE, 0.26) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _buttons_box != null:
		var button_index: int = 0
		for child: Node in _buttons_box.get_children():
			if not child is Control:
				continue
			var button_control: Control = child as Control
			button_control.modulate = Color(1.0, 1.0, 1.0, 0.0)
			button_control.scale = Vector2(0.96, 0.96)
			button_control.pivot_offset = button_control.size * 0.5
			var button_tween: Tween = create_tween()
			var delay_sec: float = 0.06 + float(button_index) * 0.04
			button_tween.tween_property(button_control, "modulate:a", 1.0, 0.18).set_delay(delay_sec)
			button_tween.parallel().tween_property(button_control, "scale", Vector2.ONE, 0.2).set_delay(delay_sec) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			button_index += 1


func _set_up_cat_idle_animation() -> void:
	if _cat_illustration == null or _cat_tail_overlay == null:
		set_process(false)
		return
	_cat_tail_blend_time_sec = 0.0
	_cat_illustration.texture = CAT_IDLE_TEXTURE
	_cat_tail_overlay.texture = CAT_IDLE_TAIL_UP_TEXTURE
	_cat_tail_overlay.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_cat_tail_overlay.visible = not _is_reduce_motion_enabled()
	_update_cat_tail_animation()
	set_process(true)


func _update_cat_tail_animation() -> void:
	if _cat_illustration == null or _cat_tail_overlay == null:
		return
	_cat_illustration.texture = CAT_IDLE_TEXTURE
	_cat_tail_overlay.visible = true
	var cycle: float = fposmod(_cat_tail_blend_time_sec / CAT_TAIL_BLEND_PERIOD_SEC, 1.0) * 4.0
	var segment: int = int(floor(cycle))
	var local: float = cycle - float(segment)
	var smooth: float = local * local * (3.0 - (2.0 * local))
	match segment:
		0:
			_cat_tail_overlay.texture = CAT_IDLE_TAIL_UP_TEXTURE
			_cat_tail_overlay.modulate = Color(1.0, 1.0, 1.0, 1.0 - smooth)
		1:
			_cat_tail_overlay.texture = CAT_IDLE_TAIL_DOWN_TEXTURE
			_cat_tail_overlay.modulate = Color(1.0, 1.0, 1.0, smooth)
		2:
			_cat_tail_overlay.texture = CAT_IDLE_TAIL_DOWN_TEXTURE
			_cat_tail_overlay.modulate = Color(1.0, 1.0, 1.0, 1.0 - smooth)
		_:
			_cat_tail_overlay.texture = CAT_IDLE_TAIL_UP_TEXTURE
			_cat_tail_overlay.modulate = Color(1.0, 1.0, 1.0, smooth)


func _is_reduce_motion_enabled() -> bool:
	return AppSettings != null and AppSettings.get_reduce_motion()
