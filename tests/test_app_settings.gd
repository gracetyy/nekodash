## Unit tests for AppSettings shell preferences persistence.
## Covers: defaults, roundtrip persistence, signal emission, file separation.
extends GutTest

var _settings: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	# Use isolated test path to avoid overwriting real player settings.
	var test_path := "user://test_app_settings.cfg"
	
	# Override static path in the script before instantiating.
	var settings_script = load("res://src/core/app_settings.gd")
	settings_script.settings_path = test_path
	
	_remove_settings_file()
	_settings = settings_script.new()
	add_child_autofree(_settings)


func after_all() -> void:
	_remove_settings_file()


func _remove_settings_file() -> void:
	var test_path := "user://test_app_settings.cfg"
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(test_path)


# —————————————————————————————————————————————
# Defaults
# —————————————————————————————————————————————

func test_defaults_loaded_on_ready() -> void:
	assert_true(_settings.is_loaded())
	assert_false(_settings.get_reduce_motion())
	assert_false(_settings.get_large_ui())
	assert_false(_settings.get_simple_ui())
	assert_false(_settings.get_dev_mode())
	assert_eq(_settings.get_input_hint_mode(), "auto")
	assert_eq(_settings.get_last_world_id(), 1)


func test_settings_file_is_separate_from_progress_and_audio() -> void:
	var save_script = load("res://src/core/save_manager.gd")
	save_script.save_file_path = "user://test_save_sep.json"
	var save = save_script.new()
	add_child_autofree(save)
	
	var sfx_script = load("res://src/core/sfx_manager.gd")
	sfx_script.settings_path = "user://test_sfx_sep.cfg"
	var sfx = sfx_script.new()
	add_child_autofree(sfx)
	
	assert_ne(_settings.settings_path, save.save_file_path)
	assert_ne(_settings.settings_path, sfx.settings_path)


# —————————————————————————————————————————————
# Persistence
# —————————————————————————————————————————————

func test_reduce_motion_roundtrip() -> void:
	_settings.set_reduce_motion(true)
	var settings2: Node = _create_new_settings()
	assert_true(settings2.get_reduce_motion())


func test_large_ui_roundtrip() -> void:
	_settings.set_large_ui(true)
	var settings2: Node = _create_new_settings()
	assert_true(settings2.get_large_ui())


func test_simple_ui_roundtrip() -> void:
	_settings.set_simple_ui(true)
	var settings2: Node = _create_new_settings()
	assert_true(settings2.get_simple_ui())


func test_ui_scale_factor_stays_normal_with_large_text_enabled() -> void:
	assert_eq(_settings.get_ui_scale_factor(), _settings.UI_SCALE_NORMAL)
	_settings.set_large_ui(true)
	assert_eq(_settings.get_ui_scale_factor(), _settings.UI_SCALE_NORMAL)


func test_text_scale_factor_reflects_large_text_setting() -> void:
	assert_eq(_settings.get_text_scale_factor(), _settings.TEXT_SCALE_NORMAL)
	_settings.set_large_ui(true)
	assert_eq(_settings.get_text_scale_factor(), _settings.TEXT_SCALE_LARGE)


func test_input_hint_mode_roundtrip() -> void:
	_settings.set_input_hint_mode("controller")
	var settings2: Node = _create_new_settings()
	assert_eq(settings2.get_input_hint_mode(), "controller")


func test_last_world_id_roundtrip() -> void:
	_settings.set_last_world_id(3)
	var settings2: Node = _create_new_settings()
	assert_eq(settings2.get_last_world_id(), 3)


func test_dev_mode_roundtrip() -> void:
	_settings.set_dev_mode(true)
	var settings2: Node = _create_new_settings()
	assert_true(settings2.get_dev_mode())


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


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

func _create_new_settings() -> Node:
	var settings_script = load("res://src/core/app_settings.gd")
	var settings_node = settings_script.new()
	add_child_autofree(settings_node)
	return settings_node
