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

var _title_label: Label
var _panel: PanelContainer
var _backdrop: ColorRect
var _music_slider: Range
var _music_mute_toggle: BaseButton
var _sfx_slider: Range
var _sfx_mute_toggle: BaseButton
var _reduce_motion_toggle: BaseButton
var _large_ui_toggle: BaseButton
var _fullscreen_toggle: BaseButton
var _input_hint_option: OptionButton
var _close_btn: BaseButton


func _ready() -> void:
	_auto_discover_ui_nodes()
	_resolve_services()
	_populate_input_hint_options()
	_connect_ui()
	_apply_visual_style()
	_sync_controls()
	if not close_requested.is_connected(_handle_close_requested):
		close_requested.connect(_handle_close_requested)
	if _music_slider != null:
		_music_slider.grab_focus()


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
	if _fullscreen_toggle != null and not _fullscreen_toggle.toggled.is_connected(_on_fullscreen_toggled):
		_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	if _input_hint_option != null and not _input_hint_option.item_selected.is_connected(_on_input_hint_selected):
		_input_hint_option.item_selected.connect(_on_input_hint_selected)
	if _close_btn != null and not _close_btn.pressed.is_connected(on_close_btn_pressed):
		_close_btn.pressed.connect(on_close_btn_pressed)


func _sync_controls() -> void:
	_suppress_events = true
	if _title_label != null:
		_title_label.text = _title_text
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
	_suppress_events = false


func _on_music_slider_changed(value: float) -> void:
	if _suppress_events:
		return
	_music_manager_ref.set_volume(value / 100.0)


func _on_music_mute_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_music_manager_ref.set_muted(button_pressed)


func _on_sfx_slider_changed(value: float) -> void:
	if _suppress_events:
		return
	_sfx_manager_ref.set_volume(value / 100.0)


func _on_sfx_mute_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_sfx_manager_ref.set_muted(button_pressed)


func _on_reduce_motion_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_app_settings_ref.set_reduce_motion(button_pressed)


func _on_large_ui_toggled(button_pressed: bool) -> void:
	if _suppress_events:
		return
	_app_settings_ref.set_large_ui(button_pressed)


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
	_close_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/ButtonRow/CloseBtn") as BaseButton


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_modal_backdrop(_backdrop)
	ShellThemeUtil.apply_panel(_panel, ShellThemeUtil.CREAM)
	ShellThemeUtil.apply_pill_button(_close_btn, ShellThemeUtil.GOLD, ShellThemeUtil.GOLD_PRESSED)
