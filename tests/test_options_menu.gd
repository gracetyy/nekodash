## Unit tests for OptionsMenu shell overlay.
## Covers: injected service sync, control write-through, and close signaling.
extends GutTest

var _menu: Node
var _settings: MockSettings
var _music: MockAudioManager
var _sfx: MockAudioManager


class MockSettings extends Node:
	var fullscreen: bool = false
	var reduce_motion: bool = false
	var large_ui: bool = false
	var input_hint_mode: String = AppSettings.INPUT_HINT_AUTO

	func get_fullscreen() -> bool:
		return fullscreen

	func set_fullscreen(enabled: bool) -> void:
		fullscreen = enabled

	func get_reduce_motion() -> bool:
		return reduce_motion

	func set_reduce_motion(enabled: bool) -> void:
		reduce_motion = enabled

	func get_large_ui() -> bool:
		return large_ui

	func set_large_ui(enabled: bool) -> void:
		large_ui = enabled

	func get_input_hint_mode() -> String:
		return input_hint_mode

	func set_input_hint_mode(mode: String) -> void:
		input_hint_mode = mode


class MockAudioManager extends Node:
	var volume: float = 1.0
	var muted: bool = false

	func get_volume() -> float:
		return volume

	func set_volume(value: float) -> void:
		volume = value

	func is_muted() -> bool:
		return muted

	func set_muted(value: bool) -> void:
		muted = value


func before_each() -> void:
	_settings = MockSettings.new()
	add_child_autofree(_settings)

	_music = MockAudioManager.new()
	add_child_autofree(_music)

	_sfx = MockAudioManager.new()
	add_child_autofree(_sfx)

	_menu = load("res://scenes/ui/options_overlay.tscn").instantiate()
	_menu.set_services(_settings, _music, _sfx)
	add_child_autofree(_menu)


func test_receive_scene_params_updates_title_text() -> void:
	_menu.queue_free()
	_menu = load("res://scenes/ui/options_overlay.tscn").instantiate()
	_menu.receive_scene_params({"title": "Paused Options"})
	_menu.set_services(_settings, _music, _sfx)
	add_child_autofree(_menu)

	var title_label: Label = _menu.get_node("Backdrop/Panel/Margin/VBox/TitleLabel") as Label
	assert_eq(title_label.text, "Paused Options")


func test_sync_controls_reads_injected_services() -> void:
	_menu.queue_free()
	_settings.fullscreen = true
	_settings.reduce_motion = true
	_settings.large_ui = true
	_settings.input_hint_mode = AppSettings.INPUT_HINT_CONTROLLER
	_music.volume = 0.35
	_music.muted = true
	_sfx.volume = 0.65
	_sfx.muted = true

	_menu = load("res://scenes/ui/options_overlay.tscn").instantiate()
	_menu.set_services(_settings, _music, _sfx)
	add_child_autofree(_menu)

	var music_slider: HSlider = _menu.get_node("Backdrop/Panel/Margin/VBox/AudioSection/MusicRow/MusicSlider") as HSlider
	var music_mute: CheckButton = _menu.get_node("Backdrop/Panel/Margin/VBox/AudioSection/MusicRow/MusicMuteToggle") as CheckButton
	var sfx_slider: HSlider = _menu.get_node("Backdrop/Panel/Margin/VBox/AudioSection/SfxRow/SfxSlider") as HSlider
	var sfx_mute: CheckButton = _menu.get_node("Backdrop/Panel/Margin/VBox/AudioSection/SfxRow/SfxMuteToggle") as CheckButton
	var reduce_motion: CheckButton = _menu.get_node("Backdrop/Panel/Margin/VBox/DisplaySection/ReduceMotionToggle") as CheckButton
	var large_ui: CheckButton = _menu.get_node("Backdrop/Panel/Margin/VBox/DisplaySection/LargeUiToggle") as CheckButton
	var fullscreen: CheckButton = _menu.get_node("Backdrop/Panel/Margin/VBox/DisplaySection/FullscreenToggle") as CheckButton
	var input_hint: OptionButton = _menu.get_node("Backdrop/Panel/Margin/VBox/InputSection/InputHintOption") as OptionButton

	assert_eq(music_slider.value, 35.0)
	assert_true(music_mute.button_pressed)
	assert_eq(sfx_slider.value, 65.0)
	assert_true(sfx_mute.button_pressed)
	assert_true(reduce_motion.button_pressed)
	assert_true(large_ui.button_pressed)
	assert_true(fullscreen.button_pressed)
	assert_eq(input_hint.selected, 2)


func test_controls_write_through_to_services() -> void:
	_menu._on_music_slider_changed(25.0)
	_menu._on_music_mute_toggled(true)
	_menu._on_sfx_slider_changed(40.0)
	_menu._on_sfx_mute_toggled(true)
	_menu._on_reduce_motion_toggled(true)
	_menu._on_large_ui_toggled(true)
	_menu._on_fullscreen_toggled(true)
	_menu._on_input_hint_selected(1)

	assert_eq(_music.volume, 0.25)
	assert_true(_music.muted)
	assert_eq(_sfx.volume, 0.4)
	assert_true(_sfx.muted)
	assert_true(_settings.reduce_motion)
	assert_true(_settings.large_ui)
	assert_true(_settings.fullscreen)
	assert_eq(_settings.input_hint_mode, AppSettings.INPUT_HINT_TOUCH)


func test_close_button_emits_close_requested() -> void:
	watch_signals(_menu)
	_menu.on_close_btn_pressed()
	assert_signal_emitted(_menu, "close_requested")
