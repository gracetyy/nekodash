## Unit tests for AppSettings shell preferences persistence.
## Covers: defaults, roundtrip persistence, signal emission, file separation.
extends GutTest

var _settings: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_remove_settings_file()
	_settings = load("res://src/core/app_settings.gd").new()
	add_child_autofree(_settings)


func after_all() -> void:
	_remove_settings_file()


func _remove_settings_file() -> void:
	if FileAccess.file_exists("user://app_settings.cfg"):
		DirAccess.remove_absolute("user://app_settings.cfg")


# —————————————————————————————————————————————
# Defaults
# —————————————————————————————————————————————

func test_defaults_loaded_on_ready() -> void:
	assert_true(_settings.is_loaded())
	assert_false(_settings.get_reduce_motion())
	assert_false(_settings.get_large_ui())
	assert_eq(_settings.get_input_hint_mode(), "auto")
	assert_eq(_settings.get_last_world_id(), 1)


func test_settings_file_is_separate_from_progress_and_audio() -> void:
	var save: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save)
	var sfx: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx)
	assert_ne(_settings.SETTINGS_PATH, save.SAVE_FILE_PATH)
	assert_ne(_settings.SETTINGS_PATH, sfx.SETTINGS_PATH)


# —————————————————————————————————————————————
# Persistence
# —————————————————————————————————————————————

func test_reduce_motion_roundtrip() -> void:
	_settings.set_reduce_motion(true)
	var settings2: Node = load("res://src/core/app_settings.gd").new()
	add_child_autofree(settings2)
	assert_true(settings2.get_reduce_motion())


func test_large_ui_roundtrip() -> void:
	_settings.set_large_ui(true)
	var settings2: Node = load("res://src/core/app_settings.gd").new()
	add_child_autofree(settings2)
	assert_true(settings2.get_large_ui())


func test_ui_scale_factor_reflects_large_ui_setting() -> void:
	assert_eq(_settings.get_ui_scale_factor(), _settings.UI_SCALE_NORMAL)
	_settings.set_large_ui(true)
	assert_eq(_settings.get_ui_scale_factor(), _settings.UI_SCALE_LARGE)


func test_input_hint_mode_roundtrip() -> void:
	_settings.set_input_hint_mode("controller")
	var settings2: Node = load("res://src/core/app_settings.gd").new()
	add_child_autofree(settings2)
	assert_eq(settings2.get_input_hint_mode(), "controller")


func test_last_world_id_roundtrip() -> void:
	_settings.set_last_world_id(3)
	var settings2: Node = load("res://src/core/app_settings.gd").new()
	add_child_autofree(settings2)
	assert_eq(settings2.get_last_world_id(), 3)


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

func test_setting_changed_emits_with_payload() -> void:
	watch_signals(_settings)
	_settings.set_reduce_motion(true)
	assert_signal_emitted_with_parameters(
		_settings,
		"setting_changed",
		[_settings.SECTION_DISPLAY, _settings.KEY_REDUCE_MOTION, true]
	)
