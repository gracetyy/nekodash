## MainMenu — title screen with navigation to World Map and Skins.
## Task: S3-04 (bug fix — back button target), S4-14 (Skins + CatSprite wiring)
##
## Simple title screen that lets the player start the game by navigating
## to the World Map. Acts as the landing screen and the back-button target
## from WorldMap. Shows CatSprite using the equipped skin placeholder.
@tool
class_name MainMenu
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const CatPartRigScript = preload("res://src/ui/cat_part_rig.gd")
const ICON_PLAY: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_play.png")
const ICON_CAT: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_cat.png")
const ICON_SETTINGS: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_settings.png")
const ICON_INFO: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_info.png")
const TITLE_TEXTURE_LANDSCAPE: Texture2D = preload("res://assets/art/ui/headers/nekodash_title_landscape.png")
const TITLE_TEXTURE_PORTRAIT: Texture2D = preload("res://assets/art/ui/headers/nekodash_title_portrait.png")
const TITLE_PORTRAIT_MAX_WIDTH: float = 700.0

@export_category("Menu Cat")
## If true, menu root exports override global CatRigProfile defaults.
@export var menu_cat_override_global_defaults: bool = true

## Display size for the menu cat rig in pixels.
@export_range(64.0, 320.0, 1.0, "or_greater")
var menu_cat_size_px: float = 168.0

## Vertical anchor of the menu cat within the illustration rect (0 top, 1 bottom).
@export_range(0.0, 1.0, 0.01)
var menu_cat_vertical_anchor_ratio: float = 0.56

## Fine-tune x/y offset of the menu cat rig from its anchored position.
@export var menu_cat_offset: Vector2 = Vector2.ZERO

## Face overlay variant shown on the menu cat.
@export_enum("idle", "blink", "excited", "relax", "smile")
var menu_cat_face_variant: String = "idle"

## Idle tail sway amplitude in degrees for the menu cat.
@export_range(0.0, 30.0, 0.1, "or_greater")
var menu_cat_idle_tail_swing_degrees: float = 8.0

## Idle tail sway cycle duration in seconds for the menu cat.
@export_range(0.1, 5.0, 0.01, "or_greater")
var menu_cat_idle_tail_swing_period_sec: float = 1.55


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
var _menu_cat_rig: Node
var _buttons_box: VBoxContainer
var _editor_menu_cat_signature: String = ""
var _menu_cat_layout_refresh_queued: bool = false


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_auto_discover_ui_nodes()
	_connect_signals()
	_apply_visual_style()
	_refresh_title_texture_variant()
	_play_intro_animation()
	_set_up_menu_cat_rig()
	_schedule_menu_cat_layout_refresh()
	_editor_menu_cat_signature = _build_menu_cat_signature()
	set_process(true)
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
	if _cat_illustration != null and not _cat_illustration.resized.is_connected(_on_cat_illustration_resized):
		_cat_illustration.resized.connect(_on_cat_illustration_resized)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_editor_menu_cat_preview()
		return
	if _menu_cat_rig == null:
		return
	_set_menu_cat_rig_property("idle_enabled", not _is_reduce_motion_enabled())


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
		"highlight_world_id": _call_app_settings_int("get_last_world_id", 1),
	})


func _apply_visual_style() -> void:
	if _hero_card != null:
		_hero_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
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
	_schedule_menu_cat_layout_refresh()


func _on_cat_illustration_resized() -> void:
	_schedule_menu_cat_layout_refresh()


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


func _set_up_menu_cat_rig() -> void:
	if _cat_illustration == null:
		set_process(false)
		return

	_cat_illustration.texture = null

	var existing_rig: Node = _cat_illustration.get_node_or_null("MenuCatRig")
	if existing_rig != null and existing_rig.get_script() == CatPartRigScript:
		_menu_cat_rig = existing_rig
	else:
		if existing_rig != null:
			existing_rig.queue_free()
		_menu_cat_rig = CatPartRigScript.new() as Node
		_menu_cat_rig.name = "MenuCatRig"
		_cat_illustration.add_child(_menu_cat_rig)

	if SaveManager != null:
		_set_menu_cat_rig_property("skin_id_override", _resolve_equipped_skin_safe())
	else:
		_set_menu_cat_rig_property("skin_id_override", "")

	_apply_menu_cat_exports_to_rig()

	_schedule_menu_cat_layout_refresh()
	set_process(true)


func _apply_menu_cat_exports_to_rig() -> void:
	_set_menu_cat_rig_property("override_display_locally", menu_cat_override_global_defaults)
	_set_menu_cat_rig_property("override_idle_locally", menu_cat_override_global_defaults)
	_set_menu_cat_rig_property("override_face_locally", menu_cat_override_global_defaults)
	_set_menu_cat_rig_property("display_size_px", menu_cat_size_px)
	_set_menu_cat_rig_property("display_offset", menu_cat_offset)
	_set_menu_cat_rig_property("face_variant", menu_cat_face_variant)
	_set_menu_cat_rig_property("idle_tail_swing_degrees", menu_cat_idle_tail_swing_degrees)
	_set_menu_cat_rig_property("idle_tail_swing_period_sec", menu_cat_idle_tail_swing_period_sec)
	_set_menu_cat_rig_property("idle_enabled", not _is_reduce_motion_enabled())
	_call_menu_cat_rig_method("refresh_rig")


func _sync_editor_menu_cat_preview() -> void:
	if not is_inside_tree():
		return
	if _cat_illustration == null:
		_auto_discover_ui_nodes()
	if _cat_illustration == null:
		return
	if _menu_cat_rig == null or _menu_cat_rig.get_script() != CatPartRigScript:
		_set_up_menu_cat_rig()
	var signature: String = _build_menu_cat_signature()
	if signature == _editor_menu_cat_signature:
		return
	_editor_menu_cat_signature = signature
	_apply_menu_cat_exports_to_rig()
	_update_menu_cat_layout()


func _build_menu_cat_signature() -> String:
	return "|".join([
		str(menu_cat_override_global_defaults),
		str(menu_cat_size_px),
		str(menu_cat_vertical_anchor_ratio),
		str(menu_cat_offset),
		menu_cat_face_variant,
		str(menu_cat_idle_tail_swing_degrees),
		str(menu_cat_idle_tail_swing_period_sec),
	])


func _resolve_equipped_skin_safe() -> String:
	var equipped_skin: String = _call_save_manager_string("get_equipped_skin")
	if not equipped_skin.is_empty():
		return equipped_skin
	return _call_save_manager_string("get_equipped_skin_id")


func _update_menu_cat_layout() -> void:
	if _menu_cat_rig == null or _cat_illustration == null:
		return

	_menu_cat_rig.position = Vector2(
		_cat_illustration.size.x * 0.5,
		_cat_illustration.size.y * menu_cat_vertical_anchor_ratio
	)


func _schedule_menu_cat_layout_refresh() -> void:
	if _menu_cat_layout_refresh_queued:
		return
	_menu_cat_layout_refresh_queued = true
	call_deferred("_refresh_menu_cat_layout_deferred")


func _refresh_menu_cat_layout_deferred() -> void:
	_menu_cat_layout_refresh_queued = false
	if _menu_cat_rig == null or _cat_illustration == null:
		return

	# First pass handles immediate size changes, second pass catches container
	# layout updates that settle one frame later during scene transitions.
	_update_menu_cat_layout()
	await get_tree().process_frame
	_update_menu_cat_layout()


func _set_menu_cat_rig_property(property_name: StringName, value: Variant) -> void:
	if _menu_cat_rig == null:
		return
	if _menu_cat_rig.get_script() != CatPartRigScript:
		return
	_menu_cat_rig.set(property_name, value)


func _call_menu_cat_rig_method(method_name: StringName) -> void:
	if _menu_cat_rig == null:
		return
	if _menu_cat_rig.get_script() != CatPartRigScript:
		return
	if _menu_cat_rig.has_method(method_name):
		_menu_cat_rig.call(method_name)


func _is_reduce_motion_enabled() -> bool:
	return _call_app_settings_bool("get_reduce_motion", false)


func _call_save_manager_string(method_name: StringName, fallback: String = "") -> String:
	if SaveManager == null:
		return fallback
	var method_callable: Callable = Callable(SaveManager, method_name)
	if not method_callable.is_valid():
		return fallback
	var value: Variant = method_callable.call()
	if value is String and not (value as String).is_empty():
		return value as String
	return fallback


func _call_app_settings_bool(method_name: StringName, fallback: bool) -> bool:
	if AppSettings == null:
		return fallback
	var method_callable: Callable = Callable(AppSettings, method_name)
	if not method_callable.is_valid():
		return fallback
	var value: Variant = method_callable.call()
	if value is bool:
		return value as bool
	return fallback


func _call_app_settings_int(method_name: StringName, fallback: int) -> int:
	if AppSettings == null:
		return fallback
	var method_callable: Callable = Callable(AppSettings, method_name)
	if not method_callable.is_valid():
		return fallback
	var value: Variant = method_callable.call()
	if value is int:
		return value as int
	return fallback
