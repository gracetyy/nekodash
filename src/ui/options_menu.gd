## OptionsMenu — shell options overlay backed by AppSettings and audio managers.
class_name OptionsMenu
extends CanvasLayer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal close_requested

var _title_text: String = "Options"
var _return_overlay: int = -1
var _suppress_events: bool = false

var _app_settings_ref: Node
var _music_manager_ref: Node
var _sfx_manager_ref: Node

@export var _title_label: Label
@export var _ribbon: TextureRect
@export var _audio_label: Label
@export var _display_label: Label
@export var _input_label: Label
@export var _panel: PanelContainer
@export var _backdrop: ColorRect
@export var _music_slider: Range
@export var _music_mute_toggle: BaseButton
@export var _sfx_slider: Range
@export var _sfx_mute_toggle: BaseButton
@export var _reduce_motion_toggle: BaseButton
@export var _large_ui_toggle: BaseButton
@export var _simple_ui_toggle: BaseButton
@export var _fullscreen_toggle: BaseButton
@export var _input_hint_option: OptionButton
@export var _replay_tutorial_btn: BaseButton
@export var _tutorial_label: Label
@export var _developer_label: Label
@export var _dev_mode_toggle: BaseButton
@export var _close_btn: BaseButton

var _sfx_button_tap: AudioStream = AudioStreamWAV.new()


func _ready() -> void:
	if _backdrop == null:
		_backdrop = get_node_or_null("Backdrop")
	if _panel == null:
		_panel = get_node_or_null("Backdrop/Panel")
	if _ribbon == null:
		_ribbon = get_node_or_null("Backdrop/Ribbon")
	if _title_label == null:
		_title_label = get_node_or_null("Backdrop/Panel/Margin/VBox/TitleLabel")
	if _audio_label == null:
		_audio_label = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/AudioLabel")
	if _display_label == null:
		_display_label = get_node_or_null("Backdrop/Panel/Margin/VBox/DisplaySection/DisplayLabel")
	if _input_label == null:
		_input_label = get_node_or_null("Backdrop/Panel/Margin/VBox/InputSection/InputLabel")
	if _music_slider == null:
		_music_slider = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/MusicRow/Slider")
	if _music_mute_toggle == null:
		_music_mute_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/MusicRow/Toggle")
	if _sfx_slider == null:
		_sfx_slider = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/SfxRow/Slider")
	if _sfx_mute_toggle == null:
		_sfx_mute_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/AudioSection/SfxRow/Toggle")
	if _reduce_motion_toggle == null:
		_reduce_motion_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/DisplaySection/ReduceMotionRow/Toggle")
	if _large_ui_toggle == null:
		_large_ui_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/DisplaySection/LargeUiRow/Toggle")
	if _simple_ui_toggle == null:
		_simple_ui_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/DisplaySection/SimpleUiRow/Toggle")
	if _fullscreen_toggle == null:
		_fullscreen_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/DisplaySection/FullscreenRow/Toggle")
	if _input_hint_option == null:
		_input_hint_option = get_node_or_null("Backdrop/Panel/Margin/VBox/InputSection/InputHintRow/OptionButton")
	if _tutorial_label == null:
		_tutorial_label = get_node_or_null("Backdrop/Panel/Margin/VBox/TutorialSection/TutorialLabel")
	if _replay_tutorial_btn == null:
		_replay_tutorial_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/TutorialSection/CenterContainer/ReplayTutorialBtn")
	if _developer_label == null:
		_developer_label = get_node_or_null("Backdrop/Panel/Margin/VBox/DeveloperSection/DeveloperLabel")
	if _dev_mode_toggle == null:
		_dev_mode_toggle = get_node_or_null("Backdrop/Panel/Margin/VBox/DeveloperSection/DevModeRow/Toggle")
	if _close_btn == null:
		_close_btn = get_node_or_null("Backdrop/CloseBtn")
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
	assert(_fullscreen_toggle != null, "_fullscreen_toggle not assigned")
	assert(_input_hint_option != null, "_input_hint_option not assigned")
	assert(_dev_mode_toggle != null, "_dev_mode_toggle not assigned")
	assert(_close_btn != null, "_close_btn not assigned")
	_resolve_services()
	_connect_settings_signal()
	_populate_input_hint_options()
	_connect_ui()
	_apply_visual_style()
	_sync_controls()
	_play_intro_animation()
	if not close_requested.is_connected(_handle_close_requested):
		close_requested.connect(_handle_close_requested)
	if _music_slider != null and _music_slider.editable:
		_music_slider.grab_focus()


func _exit_tree() -> void:
	_disconnect_settings_signal()


func receive_scene_params(params: Dictionary) -> void:
	_title_text = str(params.get("title", "Options"))
	_return_overlay = params.get("return_overlay", -1) as int


func set_services(app_settings_ref: Node, music_manager_ref: Node, sfx_manager_ref: Node) -> void:
	_app_settings_ref = app_settings_ref
	_music_manager_ref = music_manager_ref
	_sfx_manager_ref = sfx_manager_ref


func on_close_btn_pressed() -> void:
	close_requested.emit()


func _handle_close_requested() -> void:
	if _return_overlay >= 0:
		SceneManager.show_overlay(_return_overlay, {
			"pause_tree": true,
		})
	else:
		SceneManager.hide_overlay()


func _resolve_services() -> void:
	if _app_settings_ref == null:
		_app_settings_ref = AppSettings
	if _music_manager_ref == null:
		_music_manager_ref = MusicManager
	if _sfx_manager_ref == null:
		_sfx_manager_ref = SfxManager


func _connect_settings_signal() -> void:
	if _app_settings_ref == null:
		return
	if not _app_settings_ref.has_signal("setting_changed"):
		return
	var changed_callable: Callable = Callable(self , "_on_app_setting_changed")
	if not _app_settings_ref.is_connected("setting_changed", changed_callable):
		_app_settings_ref.connect("setting_changed", changed_callable)


func _disconnect_settings_signal() -> void:
	if _app_settings_ref == null:
		return
	if not _app_settings_ref.has_signal("setting_changed"):
		return
	var changed_callable: Callable = Callable(self , "_on_app_setting_changed")
	if _app_settings_ref.is_connected("setting_changed", changed_callable):
		_app_settings_ref.disconnect("setting_changed", changed_callable)


func _populate_input_hint_options() -> void:
	if _input_hint_option == null or _input_hint_option.item_count > 0:
		return
	_input_hint_option.add_item("Auto")
	_input_hint_option.add_item("Touch")
	_input_hint_option.add_item("Keyboard / Controller")


func _connect_ui() -> void:
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
	if _fullscreen_toggle != null and not _fullscreen_toggle.toggled.is_connected(_on_fullscreen_toggled):
		_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	if _input_hint_option != null and not _input_hint_option.item_selected.is_connected(_on_input_hint_selected):
		_input_hint_option.item_selected.connect(_on_input_hint_selected)
	if _dev_mode_toggle != null and not _dev_mode_toggle.toggled.is_connected(_on_dev_mode_toggled):
		_dev_mode_toggle.toggled.connect(_on_dev_mode_toggled)
	if _replay_tutorial_btn != null and not _replay_tutorial_btn.pressed.is_connected(_on_replay_tutorial_pressed):
		_replay_tutorial_btn.pressed.connect(_on_replay_tutorial_pressed)
	if _close_btn != null and not _close_btn.pressed.is_connected(on_close_btn_pressed):
		_close_btn.pressed.connect(on_close_btn_pressed)


func _sync_controls() -> void:
	_suppress_events = true
	if _title_label != null:
		_title_label.text = _title_text
	if _ribbon != null:
		var ribbon_text: String = _title_text
		if ribbon_text.length() <= 8:
			ribbon_text = ribbon_text.to_upper()
		if _ribbon.has_method("set_title"):
			_ribbon.call("set_title", ribbon_text)
	if _music_slider != null:
		_music_slider.value = _music_manager_ref.get_volume() * 100.0
	if _music_mute_toggle != null:
		_music_mute_toggle.button_pressed = _music_manager_ref.is_muted()
	if _sfx_slider != null:
		_sfx_slider.value = _sfx_manager_ref.get_volume() * 100.0
	if _sfx_mute_toggle != null:
		_sfx_mute_toggle.button_pressed = _sfx_manager_ref.is_muted()
	if _reduce_motion_toggle != null:
		_reduce_motion_toggle.button_pressed = _app_settings_ref.get_reduce_motion()
	if _large_ui_toggle != null:
		_large_ui_toggle.button_pressed = _app_settings_ref.get_large_ui()
	if _simple_ui_toggle != null:
		_simple_ui_toggle.button_pressed = _app_settings_ref.get_simple_ui()
	if _fullscreen_toggle != null:
		_fullscreen_toggle.button_pressed = _app_settings_ref.get_fullscreen()
	if _input_hint_option != null:
		match _app_settings_ref.get_input_hint_mode():
			AppSettings.INPUT_HINT_TOUCH:
				_input_hint_option.select(1)
			AppSettings.INPUT_HINT_CONTROLLER:
				_input_hint_option.select(2)
			_:
				_input_hint_option.select(0)
	if _dev_mode_toggle != null:
		_dev_mode_toggle.button_pressed = _app_settings_ref.get_dev_mode()
	_refresh_audio_control_states()
	_sync_tutorial_button_state()
	_suppress_events = false


func _on_music_slider_changed(value: float) -> void:
	if _suppress_events:
		return
	_music_manager_ref.set_volume(value / 100.0)


func _on_music_mute_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_music_manager_ref.set_muted(button_pressed)
	_refresh_audio_control_states()


func _on_sfx_slider_changed(value: float) -> void:
	if _suppress_events:
		return
	_sfx_manager_ref.set_volume(value / 100.0)


func _on_sfx_mute_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_sfx_manager_ref.set_muted(button_pressed)
	_refresh_audio_control_states()


func _on_reduce_motion_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_app_settings_ref.set_reduce_motion(button_pressed)


func _on_large_ui_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_app_settings_ref.set_large_ui(button_pressed)
	_apply_visual_style()
	_sync_controls()


func _on_simple_ui_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_app_settings_ref.set_simple_ui(button_pressed)


func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_app_settings_ref.set_fullscreen(button_pressed)


func _on_input_hint_selected(index: int) -> void:
	if _suppress_events:
		return
	match index:
		1:
			_app_settings_ref.set_input_hint_mode(AppSettings.INPUT_HINT_TOUCH)
		2:
			_app_settings_ref.set_input_hint_mode(AppSettings.INPUT_HINT_CONTROLLER)
		_:
			_app_settings_ref.set_input_hint_mode(AppSettings.INPUT_HINT_AUTO)


func _on_dev_mode_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_app_settings_ref.set_dev_mode(button_pressed)


func _on_replay_tutorial_pressed() -> void:
	if _suppress_events:
		return
	_app_settings_ref.set_tutorial_skipped(false)
	# Provide some feedback.
	if _replay_tutorial_btn is Button:
		_replay_tutorial_btn.text = "Tutorial Reset!"
	SfxManager.play(_sfx_button_tap, SfxManager.SfxBus.UI)
	
	# Load level 1 immediately and navigate
	var cat: LevelCatalogue = load("res://data/level_catalogue.tres")
	if cat != null:
		var l1: LevelData = null
		for l in cat.levels:
			if l.level_id == "w1_l1":
				l1 = l
				break
		if l1 != null:
			SceneManager.hide_overlay()
			SceneManager.go_to(SceneManager.Screen.GAMEPLAY, {
				"level_data": l1
			})


func _sync_tutorial_button_state() -> void:
	if _replay_tutorial_btn == null:
		return
	_replay_tutorial_btn.disabled = false
	if _replay_tutorial_btn is Button:
		_replay_tutorial_btn.text = "Replay Tutorial"


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_modal_backdrop(_backdrop)
	_refresh_title_components()


func _refresh_title_components() -> void:
	for node: Label in [_title_label, _audio_label, _display_label, _input_label, _tutorial_label, _developer_label]:
		if node != null and node.has_method("refresh_style"):
			node.call("refresh_style")
	if _ribbon != null and _ribbon.has_method("refresh_style"):
		_ribbon.call("refresh_style")


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


func _on_app_setting_changed(section: String, key: String, _value: Variant) -> void:
	if section == AppSettings.SECTION_DISPLAY:
		if key == AppSettings.KEY_LARGE_UI:
			_apply_visual_style()
		_sync_controls()
	elif section == AppSettings.SECTION_SHELL and key == AppSettings.KEY_DEV_MODE:
		_sync_controls()
	elif section == AppSettings.SECTION_INPUT and key == AppSettings.KEY_INPUT_HINT_MODE:
		_sync_controls()
