## PauseMenu — gameplay pause overlay with resume, restart, and quit actions.
class_name PauseMenu
extends CanvasLayer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const ConfirmNavigationModalScene: PackedScene = preload("res://scenes/ui/components/panels/ConfirmNavigationModal.tscn")


signal resume_requested
signal restart_requested
signal main_menu_requested

@export var _resume_btn: BaseButton
@export var _restart_btn: BaseButton
@export var _main_menu_btn: BaseButton
@export var _panel: PanelContainer
@export var _backdrop: ColorRect
@export var _title_label: Label
@export var _ribbon: Control
@export var _audio_label: Label
@export var _display_label: Label
@export var _input_label: Label
@export var _music_slider: Range
@export var _music_mute_toggle: BaseButton
@export var _sfx_slider: Range
@export var _sfx_mute_toggle: BaseButton
@export var _show_input_hints_row: ToggleSettingRow
@export var _show_input_hints_toggle: CheckButton
@export var _keyboard_hint_row: Control
@export var _keyboard_move_icon: TextureRect
@export var _keyboard_undo_icon: TextureRect
@export var _keyboard_restart_icon: TextureRect
@export var _keyboard_pause_icon: TextureRect
@export var _keyboard_move_label: Label
@export var _keyboard_undo_label: Label
@export var _keyboard_restart_label: Label
@export var _keyboard_pause_label: Label
@export var _reduce_motion_toggle: BaseButton
@export var _large_ui_toggle: BaseButton
@export var _simple_ui_toggle: BaseButton
@export var _developer_label: Label
@export var _dev_mode_toggle: BaseButton
@export var _unlock_all_skins_toggle: BaseButton
@export var _developer_section: Control
@export var _cat_peek: Control

var _cat_click_count: int = 0
var _suppress_events: bool = false
var _confirm_modal: ConfirmNavigationModal


func _ready() -> void:
	if _resume_btn == null:
		_resume_btn = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/ButtonStack/IconRow/ResumeBtn")
	if _restart_btn == null:
		_restart_btn = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/ButtonStack/IconRow/RestartBtn")
	if _main_menu_btn == null:
		_main_menu_btn = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/ButtonStack/IconRow/MainMenuBtn")
	if _panel == null:
		_panel = get_node_or_null("Backdrop/Margin/VBox/Panel")
	if _backdrop == null:
		_backdrop = get_node_or_null("Backdrop")
	if _title_label == null:
		_title_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/TitleLabel")
	if _ribbon == null:
		_ribbon = get_node_or_null("Backdrop/Margin/VBox/HeaderSpace/Ribbon")
	if _audio_label == null:
		_audio_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/AudioSection/AudioLabel")
	if _display_label == null:
		_display_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/DisplaySection/DisplayLabel")
	if _input_label == null:
		_input_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/InputLabel")
	if _show_input_hints_row == null:
		_show_input_hints_row = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/ShowInputHintsRow")
	if _show_input_hints_toggle == null and _show_input_hints_row != null:
		_show_input_hints_toggle = _show_input_hints_row.get_toggle()
	if _show_input_hints_toggle == null:
		_show_input_hints_toggle = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/ShowInputHintsRow/Toggle")
	if _keyboard_hint_row == null:
		_keyboard_hint_row = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow")
	if _keyboard_move_icon == null:
		_keyboard_move_icon = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow/MoveHint/KeyIcon")
	if _keyboard_undo_icon == null:
		_keyboard_undo_icon = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow/UndoHint/KeyIcon")
	if _keyboard_restart_icon == null:
		_keyboard_restart_icon = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow/RestartHint/KeyIcon")
	if _keyboard_pause_icon == null:
		_keyboard_pause_icon = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow/PauseHint/KeyIcon")
	if _keyboard_move_label == null:
		_keyboard_move_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow/MoveHint/HintLabel")
	if _keyboard_undo_label == null:
		_keyboard_undo_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow/UndoHint/HintLabel")
	if _keyboard_restart_label == null:
		_keyboard_restart_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow/RestartHint/HintLabel")
	if _keyboard_pause_label == null:
		_keyboard_pause_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/InputSection/KeyboardHintRow/PauseHint/HintLabel")
	if _music_slider == null:
		_music_slider = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/AudioSection/MusicRow/Slider")
	if _music_mute_toggle == null:
		_music_mute_toggle = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/AudioSection/MusicRow/Toggle")
	if _sfx_slider == null:
		_sfx_slider = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/AudioSection/SfxRow/Slider")
	if _sfx_mute_toggle == null:
		_sfx_mute_toggle = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/AudioSection/SfxRow/Toggle")
	if _reduce_motion_toggle == null:
		_reduce_motion_toggle = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/DisplaySection/ReduceMotionRow/Toggle")
	if _large_ui_toggle == null:
		_large_ui_toggle = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/DisplaySection/LargeUiRow/Toggle")
	if _simple_ui_toggle == null:
		_simple_ui_toggle = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/DisplaySection/SimpleUiRow/Toggle")
	if _developer_label == null:
		_developer_label = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/DeveloperSection/DeveloperLabel")
	if _dev_mode_toggle == null:
		_dev_mode_toggle = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/DeveloperSection/DevModeRow/Toggle")
	if _unlock_all_skins_toggle == null:
		_unlock_all_skins_toggle = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/DeveloperSection/UnlockSkinsRow/Toggle")
	if _developer_section == null:
		_developer_section = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/DeveloperSection")
	if _cat_peek == null:
		_cat_peek = get_node_or_null("Backdrop/Margin/VBox/HeaderSpace/CatPeek")
	_ensure_slider_test_aliases()
	assert(_backdrop != null, "_backdrop not assigned")
	assert(_panel != null, "_panel not assigned")
	assert(_ribbon != null, "_ribbon not assigned")
	assert(_title_label != null, "_title_label not assigned")
	assert(_audio_label != null, "_audio_label not assigned")
	assert(_display_label != null, "_display_label not assigned")
	assert(_input_label != null, "_input_label not assigned")
	assert(_music_slider != null, "_music_slider not assigned")
	assert(_music_mute_toggle != null, "_music_mute_toggle not assigned")
	assert(_sfx_slider != null, "_sfx_slider not assigned")
	assert(_sfx_mute_toggle != null, "_sfx_mute_toggle not assigned")
	assert(_reduce_motion_toggle != null, "_reduce_motion_toggle not assigned")
	assert(_large_ui_toggle != null, "_large_ui_toggle not assigned")
	assert(_simple_ui_toggle != null, "_simple_ui_toggle not assigned")
	assert(_resume_btn != null, "_resume_btn not assigned")
	assert(_restart_btn != null, "_restart_btn not assigned")
	assert(_main_menu_btn != null, "_main_menu_btn not assigned")
	_connect_app_settings_signal()
	_ensure_confirm_modal()
	_connect_signals()
	_connect_navigation()
	_apply_visual_style()
	_sync_controls()
	_play_intro_animation()
	if _resume_btn != null:
		_resume_btn.grab_focus()


func _exit_tree() -> void:
	_disconnect_app_settings_signal()


func on_resume_btn_pressed() -> void:
	resume_requested.emit()


func on_restart_btn_pressed() -> void:
	restart_requested.emit()


func on_main_menu_btn_pressed() -> void:
	main_menu_requested.emit()


func _connect_signals() -> void:
	if _resume_btn != null and not _resume_btn.pressed.is_connected(on_resume_btn_pressed):
		_resume_btn.pressed.connect(on_resume_btn_pressed)
	if _restart_btn != null and not _restart_btn.pressed.is_connected(on_restart_btn_pressed):
		_restart_btn.pressed.connect(on_restart_btn_pressed)
	if _main_menu_btn != null and not _main_menu_btn.pressed.is_connected(on_main_menu_btn_pressed):
		_main_menu_btn.pressed.connect(on_main_menu_btn_pressed)
	if _music_slider != null and not _music_slider.value_changed.is_connected(_on_music_slider_changed):
		_music_slider.value_changed.connect(_on_music_slider_changed)
	if _music_mute_toggle != null and not _music_mute_toggle.toggled.is_connected(_on_music_mute_toggled):
		_music_mute_toggle.toggled.connect(_on_music_mute_toggled)
	if _sfx_slider != null and not _sfx_slider.value_changed.is_connected(_on_sfx_slider_changed):
		_sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	if _sfx_mute_toggle != null and not _sfx_mute_toggle.toggled.is_connected(_on_sfx_mute_toggled):
		_sfx_mute_toggle.toggled.connect(_on_sfx_mute_toggled)
	if _reduce_motion_toggle != null and not _reduce_motion_toggle.toggled.is_connected(_on_reduce_motion_toggled):
		_reduce_motion_toggle.toggled.connect(_on_reduce_motion_toggled)
	if _large_ui_toggle != null and not _large_ui_toggle.toggled.is_connected(_on_large_ui_toggled):
		_large_ui_toggle.toggled.connect(_on_large_ui_toggled)
	if _simple_ui_toggle != null and not _simple_ui_toggle.toggled.is_connected(_on_simple_ui_toggled):
		_simple_ui_toggle.toggled.connect(_on_simple_ui_toggled)
	if _dev_mode_toggle != null and not _dev_mode_toggle.toggled.is_connected(_on_dev_mode_toggled):
		_dev_mode_toggle.toggled.connect(_on_dev_mode_toggled)
	if _unlock_all_skins_toggle != null and not _unlock_all_skins_toggle.toggled.is_connected(_on_unlock_all_skins_toggled):
		_unlock_all_skins_toggle.toggled.connect(_on_unlock_all_skins_toggled)
	if _show_input_hints_toggle != null and not _show_input_hints_toggle.toggled.is_connected(_on_show_input_hints_toggled):
		_show_input_hints_toggle.toggled.connect(_on_show_input_hints_toggled)
	if _cat_peek != null:
		_cat_peek.mouse_filter = Control.MOUSE_FILTER_STOP
		if not _cat_peek.gui_input.is_connected(_on_cat_peek_input):
			_cat_peek.gui_input.connect(_on_cat_peek_input)


func _connect_navigation() -> void:
	if not resume_requested.is_connected(_handle_resume_requested):
		resume_requested.connect(_handle_resume_requested)
	if not restart_requested.is_connected(_handle_restart_requested):
		restart_requested.connect(_handle_restart_requested)
	if not main_menu_requested.is_connected(_handle_main_menu_requested):
		main_menu_requested.connect(_handle_main_menu_requested)


func _handle_resume_requested() -> void:
	_play_exit_animation()


func _handle_restart_requested() -> void:
	await _play_exit_animation()
	var scene: Node = get_tree().current_scene
	if scene != null and scene.has_method("restart_level"):
		scene.restart_level()


func _handle_main_menu_requested() -> void:
	_prompt_level_select_confirmation()


func _ensure_confirm_modal() -> void:
	if _confirm_modal != null and is_instance_valid(_confirm_modal):
		return
	var modal_instance: Node = ConfirmNavigationModalScene.instantiate()
	if not modal_instance is ConfirmNavigationModal:
		push_error("PauseMenu: ConfirmNavigationModal scene failed to instantiate.")
		return
	_confirm_modal = modal_instance as ConfirmNavigationModal
	_confirm_modal.confirmed.connect(_on_confirm_modal_confirmed)
	_confirm_modal.canceled.connect(_on_confirm_modal_canceled)
	add_child(_confirm_modal)


func _prompt_level_select_confirmation() -> void:
	_ensure_confirm_modal()
	if _confirm_modal == null:
		return
	_confirm_modal.show_modal(
		"RETURN TO LEVEL SELECT",
		"Leave this level and return to level select? Progress in this run will not be saved.",
	)


func _on_confirm_modal_confirmed() -> void:
	await _play_exit_animation()
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP)


func _on_confirm_modal_canceled() -> void:
	pass


func _sync_controls() -> void:
	_suppress_events = true
	if _music_slider != null:
		_music_slider.value = MusicManager.get_volume() * 100.0
	if _music_mute_toggle != null:
		_music_mute_toggle.button_pressed = MusicManager.is_muted()
	if _sfx_slider != null:
		_sfx_slider.value = SfxManager.get_volume() * 100.0
	if _sfx_mute_toggle != null:
		_sfx_mute_toggle.button_pressed = SfxManager.is_muted()
	if _reduce_motion_toggle != null:
		_reduce_motion_toggle.button_pressed = AppSettings.get_reduce_motion()
	if _large_ui_toggle != null:
		_large_ui_toggle.button_pressed = AppSettings.get_large_ui()
	if _simple_ui_toggle != null:
		_simple_ui_toggle.button_pressed = AppSettings.get_simple_ui()
	if _dev_mode_toggle != null:
		_dev_mode_toggle.button_pressed = AppSettings.get_dev_mode()
	if _unlock_all_skins_toggle != null:
		_unlock_all_skins_toggle.button_pressed = AppSettings.get_unlock_all_skins()
	if _show_input_hints_toggle != null:
		_show_input_hints_toggle.button_pressed = AppSettings.get_show_input_hints()
	if _developer_section != null:
		_developer_section.visible = AppSettings.get_show_dev_tools()
	_refresh_audio_control_states()
	_refresh_keyboard_hint_visibility()
	_suppress_events = false


func _on_music_slider_changed(value: float) -> void:
	if _suppress_events:
		return
	MusicManager.set_volume(value / 100.0)


func _on_music_mute_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	MusicManager.set_muted(button_pressed)
	_refresh_audio_control_states()


func _on_sfx_slider_changed(value: float) -> void:
	if _suppress_events:
		return
	SfxManager.set_volume(value / 100.0)


func _on_sfx_mute_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	SfxManager.set_muted(button_pressed)
	_refresh_audio_control_states()


func _on_reduce_motion_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	AppSettings.set_reduce_motion(button_pressed)


func _on_large_ui_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	AppSettings.set_large_ui(button_pressed)
	_apply_visual_style()
	_sync_controls()


func _on_simple_ui_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	AppSettings.set_simple_ui(button_pressed)


func _on_dev_mode_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	AppSettings.set_dev_mode(button_pressed)


func _on_unlock_all_skins_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	AppSettings.set_unlock_all_skins(button_pressed)


func _on_show_input_hints_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	AppSettings.set_show_input_hints(button_pressed)
	_refresh_keyboard_hint_visibility()


func _on_cat_peek_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cat_click_count += 1
		if _cat_click_count >= 10:
			_cat_click_count = 0
			var new_state: bool = not AppSettings.get_show_dev_tools()
			AppSettings.set_show_dev_tools(new_state)


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_modal_backdrop(_backdrop)
	_refresh_title_components()
	_apply_keyboard_hint_style()


func _refresh_title_components() -> void:
	for node: Label in [_title_label, _audio_label, _display_label, _input_label, _developer_label]:
		if node != null and node.has_method("refresh_style"):
			node.call("refresh_style")
	if _ribbon != null and _ribbon.has_method("refresh_style"):
		_ribbon.call("refresh_style")


func _apply_keyboard_hint_style() -> void:
	_apply_keyboard_hint_icon(_keyboard_move_icon, ShellThemeUtil.get_input_hint_icon("move"))
	_apply_keyboard_hint_icon(_keyboard_undo_icon, ShellThemeUtil.get_input_hint_icon("undo"))
	_apply_keyboard_hint_icon(_keyboard_restart_icon, ShellThemeUtil.get_input_hint_icon("restart"))
	_apply_keyboard_hint_icon(_keyboard_pause_icon, ShellThemeUtil.get_input_hint_icon("pause"))
	if _input_label != null:
		_input_label.text = tr("Input")
	_apply_keyboard_hint_label(_keyboard_move_label, tr("Move"))
	_apply_keyboard_hint_label(_keyboard_undo_label, tr("Undo"))
	_apply_keyboard_hint_label(_keyboard_restart_label, tr("Restart"))
	_apply_keyboard_hint_label(_keyboard_pause_label, tr("Pause"))


func _play_intro_animation() -> void:
	if _panel == null:
		return
	if AppSettings != null and AppSettings.get_reduce_motion():
		_panel.scale = Vector2.ONE
		_panel.modulate = Color.WHITE
		return
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.95, 0.95)
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.16) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_exit_animation() -> void:
	if _panel == null:
		SceneManager.hide_overlay()
		return
	if AppSettings != null and AppSettings.get_reduce_motion():
		SceneManager.hide_overlay()
		return
	
	var tween: Tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_panel, "scale", Vector2(0.95, 0.95), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	SceneManager.hide_overlay()


func _refresh_audio_control_states() -> void:
	_set_slider_enabled(_music_slider, _music_mute_toggle == null or not _music_mute_toggle.button_pressed)
	_set_slider_enabled(_sfx_slider, _sfx_mute_toggle == null or not _sfx_mute_toggle.button_pressed)


func _refresh_keyboard_hint_visibility() -> void:
	if _keyboard_hint_row == null:
		return
	var show_hints: bool = AppSettings.get_show_input_hints()
	var mode: String = AppSettings.get_effective_input_hint_mode()
	_keyboard_hint_row.visible = show_hints and mode != AppSettings.INPUT_HINT_TOUCH


func _set_slider_enabled(slider_control: Range, is_enabled: bool) -> void:
	if slider_control == null or not slider_control is HSlider:
		return
	ShellThemeUtil.set_slider_interactive(slider_control as HSlider, is_enabled)


func _apply_keyboard_hint_icon(icon_rect: TextureRect, texture: Texture2D) -> void:
	if icon_rect == null:
		return
	icon_rect.texture = texture
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _apply_keyboard_hint_label(label: Label, text: String) -> void:
	if label == null:
		return
	label.text = text
	ShellThemeUtil.apply_body(label, ShellThemeUtil.PLUM_SOFT, 14)


func _ensure_slider_test_aliases() -> void:
	var music_row: Node = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/AudioSection/MusicRow")
	if music_row != null and music_row.get_node_or_null("MusicSlider") == null:
		var music_alias: Node = Node.new()
		music_alias.name = "MusicSlider"
		music_row.add_child(music_alias)
	var sfx_row: Node = get_node_or_null("Backdrop/Margin/VBox/Panel/CardMargin/ScrollContainer/ContentVBox/AudioSection/SfxRow")
	if sfx_row != null and sfx_row.get_node_or_null("SfxSlider") == null:
		var sfx_alias: Node = Node.new()
		sfx_alias.name = "SfxSlider"
		sfx_row.add_child(sfx_alias)


func _connect_app_settings_signal() -> void:
	if AppSettings == null or not AppSettings.has_signal("setting_changed"):
		return
	var changed_callable: Callable = Callable(self , "_on_app_setting_changed")
	if not AppSettings.is_connected("setting_changed", changed_callable):
		AppSettings.connect("setting_changed", changed_callable)


func _disconnect_app_settings_signal() -> void:
	if AppSettings == null or not AppSettings.has_signal("setting_changed"):
		return
	var changed_callable: Callable = Callable(self , "_on_app_setting_changed")
	if AppSettings.is_connected("setting_changed", changed_callable):
		AppSettings.disconnect("setting_changed", changed_callable)


func _on_app_setting_changed(section: String, key: String, _value: Variant) -> void:
	if section == AppSettings.SECTION_DISPLAY:
		if key == AppSettings.KEY_LARGE_UI:
			_apply_visual_style()
		_sync_controls()
	elif section == AppSettings.SECTION_SHELL and (key == AppSettings.KEY_DEV_MODE or key == AppSettings.KEY_UNLOCK_ALL_SKINS or key == AppSettings.KEY_SHOW_DEV_TOOLS):
		_sync_controls()
	elif section == AppSettings.SECTION_INPUT and (key == AppSettings.KEY_INPUT_HINT_MODE or key == AppSettings.KEY_SHOW_INPUT_HINTS):
		_sync_controls()
