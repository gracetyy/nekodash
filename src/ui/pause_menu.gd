## PauseMenu — gameplay pause overlay with resume, restart, and quit actions.
class_name PauseMenu
extends CanvasLayer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal resume_requested
signal restart_requested
signal main_menu_requested

var _resume_btn: BaseButton
var _restart_btn: BaseButton
var _main_menu_btn: BaseButton
var _panel: PanelContainer
var _backdrop: ColorRect
var _title_label: Label
var _music_slider: Range
var _music_mute_toggle: BaseButton
var _sfx_slider: Range
var _sfx_mute_toggle: BaseButton
var _reduce_motion_toggle: BaseButton
var _large_ui_toggle: BaseButton
var _fullscreen_toggle: BaseButton
var _input_hint_option: OptionButton
var _suppress_events: bool = false


func _ready() -> void:
	_auto_discover_ui_nodes()
	_populate_input_hint_options()
	_connect_signals()
	_connect_navigation()
	_apply_visual_style()
	_sync_controls()
	_play_intro_animation()
	if _resume_btn != null:
		_resume_btn.grab_focus()


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


func _auto_discover_ui_nodes() -> void:
	_backdrop = get_node_or_null("Backdrop") as ColorRect
	_panel = get_node_or_null("Backdrop/Panel") as PanelContainer
	_title_label = get_node_or_null("Backdrop/Panel/Margin/VBox/TitleLabel") as Label
	_music_slider = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/MusicRow/MusicSlider") as Range
	_music_mute_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/MusicRow/MusicMuteToggle") as BaseButton
	_sfx_slider = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/SfxRow/SfxSlider") as Range
	_sfx_mute_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/SfxRow/SfxMuteToggle") as BaseButton
	_reduce_motion_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/DisplaySection/ReduceMotionToggle") as BaseButton
	_large_ui_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/DisplaySection/LargeUiToggle") as BaseButton
	_fullscreen_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/DisplaySection/FullscreenToggle") as BaseButton
	_input_hint_option = get_node_or_null("Backdrop/Panel/Margin/VBox/InputSection/InputHintOption") as OptionButton
	_resume_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/ButtonStack/IconRow/ResumeBtn") as BaseButton
	_restart_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/ButtonStack/IconRow/RestartBtn") as BaseButton
	_main_menu_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/ButtonStack/IconRow/MainMenuBtn") as BaseButton


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_modal_backdrop(_backdrop)
	ShellThemeUtil.apply_panel(_panel, ShellThemeUtil.CREAM)
	if _title_label != null:
		ShellThemeUtil.apply_title(_title_label, 56)
	var section_headers: Array[NodePath] = [
		NodePath("Backdrop/Panel/Margin/VBox/AudioSection/AudioLabel"),
		NodePath("Backdrop/Panel/Margin/VBox/DisplaySection/DisplayLabel"),
		NodePath("Backdrop/Panel/Margin/VBox/InputSection/InputLabel"),
	]
	var option_labels: Array[NodePath] = [
		NodePath("Backdrop/Panel/Margin/VBox/AudioSection/MusicRow/MusicLabel"),
		NodePath("Backdrop/Panel/Margin/VBox/AudioSection/SfxRow/SfxLabel"),
	]
	for path: NodePath in section_headers:
		var header: Label = get_node_or_null(path) as Label
		if header != null:
			ShellThemeUtil.apply_title(header, 24)
	for path: NodePath in option_labels:
		var label: Label = get_node_or_null(path) as Label
		if label != null:
			ShellThemeUtil.apply_body(label, ShellThemeUtil.PLUM_SOFT, 20)
	ShellThemeUtil.apply_circle_play_button(_resume_btn, 74.0)
	ShellThemeUtil.apply_circle_replay_button(_restart_btn, 74.0)
	ShellThemeUtil.apply_circle_home_button(_main_menu_btn, 74.0)
	ShellThemeUtil.apply_slider(_music_slider)
	ShellThemeUtil.apply_slider(_sfx_slider)
	ShellThemeUtil.apply_checkbox(_music_mute_toggle)
	ShellThemeUtil.apply_checkbox(_sfx_mute_toggle)
	ShellThemeUtil.apply_checkbox(_reduce_motion_toggle)
	ShellThemeUtil.apply_checkbox(_large_ui_toggle)
	ShellThemeUtil.apply_checkbox(_fullscreen_toggle)
	if _input_hint_option != null:
		ShellThemeUtil.apply_option_button(_input_hint_option)


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
