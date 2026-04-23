## PauseMenu — gameplay pause overlay with resume, restart, and quit actions.
class_name PauseMenu
extends CanvasLayer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal resume_requested
signal restart_requested
signal main_menu_requested

@export var _resume_btn: BaseButton
@export var _restart_btn: BaseButton
@export var _main_menu_btn: BaseButton
@export var _panel: PanelContainer
@export var _backdrop: ColorRect
@export var _title_label: Label
@export var _ribbon_title_label: Label
@export var _audio_label: Label
@export var _display_label: Label
@export var _input_label: Label
@export var _music_slider: Range
@export var _music_mute_toggle: BaseButton
@export var _sfx_slider: Range
@export var _sfx_mute_toggle: BaseButton
@export var _reduce_motion_toggle: BaseButton
@export var _large_ui_toggle: BaseButton
@export var _fullscreen_toggle: BaseButton
@export var _input_hint_option: OptionButton
var _suppress_events: bool = false


func _ready() -> void:
	assert(_backdrop != null, "_backdrop not assigned")
	assert(_panel != null, "_panel not assigned")
	assert(_ribbon_title_label != null, "_ribbon_title_label not assigned")
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
	assert(_fullscreen_toggle != null, "_fullscreen_toggle not assigned")
	assert(_input_hint_option != null, "_input_hint_option not assigned")
	assert(_resume_btn != null, "_resume_btn not assigned")
	assert(_restart_btn != null, "_restart_btn not assigned")
	assert(_main_menu_btn != null, "_main_menu_btn not assigned")
	_connect_app_settings_signal()
	_populate_input_hint_options()
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
	if _fullscreen_toggle != null and not _fullscreen_toggle.toggled.is_connected(_on_fullscreen_toggled):
		_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	if _input_hint_option != null and not _input_hint_option.item_selected.is_connected(_on_input_hint_selected):
		_input_hint_option.item_selected.connect(_on_input_hint_selected)


func _connect_navigation() -> void:
	if not resume_requested.is_connected(_handle_resume_requested):
		resume_requested.connect(_handle_resume_requested)
	if not restart_requested.is_connected(_handle_restart_requested):
		restart_requested.connect(_handle_restart_requested)
	if not main_menu_requested.is_connected(_handle_main_menu_requested):
		main_menu_requested.connect(_handle_main_menu_requested)


func _handle_resume_requested() -> void:
	SceneManager.hide_overlay()


func _handle_restart_requested() -> void:
	SceneManager.hide_overlay()
	var scene: Node = get_tree().current_scene
	if scene != null and scene.has_method("restart_level"):
		scene.restart_level()


func _handle_main_menu_requested() -> void:
	SceneManager.hide_overlay()
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)


func _populate_input_hint_options() -> void:
	if _input_hint_option == null or _input_hint_option.item_count > 0:
		return
	_input_hint_option.add_item("Auto")
	_input_hint_option.add_item("Touch")
	_input_hint_option.add_item("Keyboard / Controller")


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
	if _fullscreen_toggle != null:
		_fullscreen_toggle.button_pressed = AppSettings.get_fullscreen()
	if _input_hint_option != null:
		match AppSettings.get_input_hint_mode():
			AppSettings.INPUT_HINT_TOUCH:
				_input_hint_option.select(1)
			AppSettings.INPUT_HINT_CONTROLLER:
				_input_hint_option.select(2)
			_:
				_input_hint_option.select(0)
	_refresh_audio_control_states()
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


func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	AppSettings.set_fullscreen(button_pressed)


func _on_input_hint_selected(index: int) -> void:
	if _suppress_events:
		return
	match index:
		1:
			AppSettings.set_input_hint_mode(AppSettings.INPUT_HINT_TOUCH)
		2:
			AppSettings.set_input_hint_mode(AppSettings.INPUT_HINT_CONTROLLER)
		_:
			AppSettings.set_input_hint_mode(AppSettings.INPUT_HINT_AUTO)


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_modal_backdrop(_backdrop)
	if _title_label != null:
		ShellThemeUtil.apply_title(_title_label, 56)
	if _ribbon_title_label != null:
		ShellThemeUtil.apply_title(_ribbon_title_label, 28)
		_ribbon_title_label.add_theme_color_override("font_color", Color(1.0, 0.984, 0.957, 1.0))
	ShellThemeUtil.apply_title(_audio_label, 24)
	ShellThemeUtil.apply_title(_display_label, 24)
	ShellThemeUtil.apply_title(_input_label, 24)


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


func _refresh_audio_control_states() -> void:
	_set_slider_enabled(_music_slider, _music_mute_toggle == null or not _music_mute_toggle.button_pressed)
	_set_slider_enabled(_sfx_slider, _sfx_mute_toggle == null or not _sfx_mute_toggle.button_pressed)


func _set_slider_enabled(slider_control: Range, is_enabled: bool) -> void:
	if slider_control == null or not slider_control is HSlider:
		return
	ShellThemeUtil.set_slider_interactive(slider_control as HSlider, is_enabled)


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
	if section == "display" and key == "large_ui":
		_apply_visual_style()
		_sync_controls()
