## AppSettings — persistent shell/display preferences separate from progress.
## Owns non-progress menu and shell settings used by overlays and entry flow.
extends Node


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const SETTINGS_PATH: String = "user://app_settings.cfg"

const SECTION_DISPLAY: String = "display"
const SECTION_SHELL: String = "shell"
const SECTION_INPUT: String = "input"

const KEY_FULLSCREEN: String = "fullscreen"
const KEY_REDUCE_MOTION: String = "reduce_motion"
# Kept for backward compatibility with existing user settings file.
const KEY_LARGE_UI: String = "large_ui"
const KEY_SIMPLE_UI: String = "simple_ui"
const KEY_LAST_WORLD_ID: String = "last_world_id"
const KEY_TUTORIAL_SKIPPED: String = "tutorial_skipped"
const KEY_INPUT_HINT_MODE: String = "input_hint_mode"
const UI_SCALE_NORMAL: float = 1.0
const UI_SCALE_LARGE: float = 1.0
const TEXT_SCALE_NORMAL: float = 1.0
const TEXT_SCALE_LARGE: float = 1.16

const INPUT_HINT_AUTO: String = "auto"
const INPUT_HINT_TOUCH: String = "touch"
const INPUT_HINT_CONTROLLER: String = "controller"

const DEFAULTS: Dictionary = {
	SECTION_DISPLAY: {
		KEY_FULLSCREEN: false,
		KEY_REDUCE_MOTION: false,
		KEY_LARGE_UI: false,
		KEY_SIMPLE_UI: false,
	},
	SECTION_SHELL: {
		KEY_LAST_WORLD_ID: 1,
		KEY_TUTORIAL_SKIPPED: false,
	},
	SECTION_INPUT: {
		KEY_INPUT_HINT_MODE: INPUT_HINT_AUTO,
	},
}


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

signal settings_loaded
signal setting_changed(section: String, key: String, value: Variant)


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _config: ConfigFile = ConfigFile.new()
var _loaded: bool = false


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	load_settings()
	if not setting_changed.is_connected(_on_setting_changed):
		setting_changed.connect(_on_setting_changed)
	_apply_runtime_settings()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

func is_loaded() -> bool:
	return _loaded


func load_settings() -> void:
	_config = ConfigFile.new()
	var err: Error = _config.load(SETTINGS_PATH)
	if err != OK:
		_apply_defaults()
		_save_settings()
		_loaded = true
		settings_loaded.emit()
		return

	_apply_defaults()
	_loaded = true
	settings_loaded.emit()


func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	var default_value: Variant = fallback
	if DEFAULTS.has(section):
		default_value = (DEFAULTS[section] as Dictionary).get(key, fallback)
	return _config.get_value(section, key, default_value)


func set_value(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	_save_settings()
	setting_changed.emit(section, key, value)


func get_fullscreen() -> bool:
	return get_value(SECTION_DISPLAY, KEY_FULLSCREEN, false) as bool


func set_fullscreen(enabled: bool) -> void:
	set_value(SECTION_DISPLAY, KEY_FULLSCREEN, enabled)


func get_reduce_motion() -> bool:
	return get_value(SECTION_DISPLAY, KEY_REDUCE_MOTION, false) as bool


func set_reduce_motion(enabled: bool) -> void:
	set_value(SECTION_DISPLAY, KEY_REDUCE_MOTION, enabled)


func get_large_ui() -> bool:
	return get_value(SECTION_DISPLAY, KEY_LARGE_UI, false) as bool


func set_large_ui(enabled: bool) -> void:
	set_value(SECTION_DISPLAY, KEY_LARGE_UI, enabled)


func get_simple_ui() -> bool:
	return get_value(SECTION_DISPLAY, KEY_SIMPLE_UI, false) as bool


func set_simple_ui(enabled: bool) -> void:
	set_value(SECTION_DISPLAY, KEY_SIMPLE_UI, enabled)


func get_last_world_id() -> int:
	return get_value(SECTION_SHELL, KEY_LAST_WORLD_ID, 1) as int


func set_last_world_id(world_id: int) -> void:
	set_value(SECTION_SHELL, KEY_LAST_WORLD_ID, max(world_id, 1))


func get_tutorial_skipped() -> bool:
	return get_value(SECTION_SHELL, KEY_TUTORIAL_SKIPPED, false) as bool


func set_tutorial_skipped(skipped: bool) -> void:
	set_value(SECTION_SHELL, KEY_TUTORIAL_SKIPPED, skipped)


func get_input_hint_mode() -> String:
	return str(get_value(SECTION_INPUT, KEY_INPUT_HINT_MODE, INPUT_HINT_AUTO))


func set_input_hint_mode(mode: String) -> void:
	var normalized: String = mode.to_lower()
	if normalized not in [INPUT_HINT_AUTO, INPUT_HINT_TOUCH, INPUT_HINT_CONTROLLER]:
		normalized = INPUT_HINT_AUTO
	set_value(SECTION_INPUT, KEY_INPUT_HINT_MODE, normalized)


func get_effective_input_hint_mode() -> String:
	var configured_mode: String = get_input_hint_mode()
	if configured_mode != INPUT_HINT_AUTO:
		return configured_mode
	return INPUT_HINT_TOUCH if DisplayServer.is_touchscreen_available() else INPUT_HINT_CONTROLLER


func get_ui_scale_factor() -> float:
	# Large Text should not scale the full UI canvas.
	return UI_SCALE_NORMAL


func get_text_scale_factor() -> float:
	return TEXT_SCALE_LARGE if get_large_ui() else TEXT_SCALE_NORMAL


# —————————————————————————————————————————————
# Internal
# —————————————————————————————————————————————

func _apply_defaults() -> void:
	for section: String in DEFAULTS.keys():
		var section_defaults: Dictionary = DEFAULTS[section]
		for key: String in section_defaults.keys():
			if not _config.has_section_key(section, key):
				_config.set_value(section, key, section_defaults[key])


func _save_settings() -> void:
	var err: Error = _config.save(SETTINGS_PATH)
	if err != OK:
		push_error("[AppSettings] Failed to save settings: %s" % error_string(err))


func _on_setting_changed(section: String, key: String, _value: Variant) -> void:
	if section == SECTION_DISPLAY or (section == SECTION_INPUT and key == KEY_INPUT_HINT_MODE):
		_apply_runtime_settings()


func _apply_runtime_settings() -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return

	tree.root.content_scale_factor = UI_SCALE_NORMAL
	if OS.has_feature("headless"):
		return

	var target_mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if get_fullscreen() else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)
