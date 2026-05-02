## SfxManager — autoload singleton for sound effect playback.
## Implements: Sprint 4 audio system
## Task: S4-11
##
## Manages a pool of AudioStreamPlayer nodes and routes playback to either the
## SFX or UI audio bus. Persists volume/mute settings in user://settings.cfg.
##
## Usage:
##   SfxManager.play(my_stream, SfxManager.SfxBus.SFX)
##   SfxManager.play(click_stream, SfxManager.SfxBus.UI, 1.2)
##   SfxManager.set_volume(0.8)
##   SfxManager.set_muted(true)
extends Node


# —————————————————————————————————————————————
# Enums
# —————————————————————————————————————————————

## Which audio bus to route through.
enum SfxBus {
	SFX = 0,
	UI = 1,
}


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Number of AudioStreamPlayer instances in the pool.
const POOL_SIZE: int = 8

## Bus name strings — must match project audio bus names.
const BUS_NAMES: Dictionary = {
	SfxBus.SFX: "SFX",
	SfxBus.UI: "UI",
}

## Settings file path.
static var settings_path: String = "user://settings.cfg"

## Settings section and key names.
const SETTINGS_SECTION: String = "audio"
const KEY_SFX_VOLUME: String = "sfx_volume"
const KEY_SFX_MUTE: String = "sfx_mute"

## Path to the SFX library resource.
const LIB_PATH: String = "res://data/sfx_library.tres"


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

## Pool of reusable AudioStreamPlayer nodes.
var _pool: Array[AudioStreamPlayer] = []

## Index of the next player to use (round-robin).
var _pool_index: int = 0

## Current volume (0.0 – 1.0).
var _volume: float = 1.0

## Whether SFX playback is muted.
var _muted: bool = false

## Loaded SFX library.
var _lib: SfxLibrary


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_load_library()
	_create_pool()
	_load_settings()
	_apply_bus_settings()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Plays a sound effect on the specified bus. Gracefully handles null streams.
## volume_mult allows scaling the sound per-call (e.g. 1.5 for 150% volume).
func play(stream: AudioStream, bus: SfxBus = SfxBus.SFX, pitch_scale: float = 1.0, volume_mult: float = 1.0) -> void:
	if stream == null:
		push_warning("[SfxManager] play() called with null AudioStream — skipping.")
		return

	var player: AudioStreamPlayer = _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE

	player.stream = stream
	player.bus = BUS_NAMES.get(bus, "SFX")
	player.pitch_scale = pitch_scale
	# Only apply per-call volume multiplier; master volume is handled by the bus.
	player.volume_db = linear_to_db(volume_mult)
	player.play()


## Convenience method for pill button taps.
func play_button_tap() -> void:
	if _lib: play(_lib.button_tap, SfxBus.UI)


## Convenience method for circular button taps.
func play_soft_tap() -> void:
	if _lib: play(_lib.soft_tap, SfxBus.UI)


## Convenience method for locked level feedback.
func play_locked() -> void:
	if _lib: play(_lib.locked, SfxBus.UI)


## Convenience method for level completion.
func play_level_complete() -> void:
	if _lib: play(_lib.level_complete, SfxBus.SFX)


func play_star(index: int, volume_mult: float = 0.5) -> void:
	if not _lib: return
	match index:
		1: play(_lib.star_1, SfxBus.SFX, 1.0, volume_mult)
		2: play(_lib.star_2, SfxBus.SFX, 1.0, volume_mult)
		3: play(_lib.star_3, SfxBus.SFX, 1.0, volume_mult)
		_: play(_lib.no_star, SfxBus.SFX, 1.0, volume_mult)


func play_no_star(volume_mult: float = 1.0) -> void:
	if _lib: play(_lib.no_star, SfxBus.SFX, 1.0, volume_mult)


## Returns the current volume (0.0 – 1.0).
func get_volume() -> float:
	return _volume


## Sets the volume (0.0 – 1.0) and persists to settings.
func set_volume(value: float) -> void:
	_volume = clampf(value, 0.0, 1.0)
	_apply_bus_settings()
	_save_settings()


## Returns whether SFX is muted.
func is_muted() -> bool:
	return _muted


## Toggles or sets the mute state and persists to settings.
func set_muted(muted: bool) -> void:
	_muted = muted
	_apply_bus_settings()
	_save_settings()


# —————————————————————————————————————————————
# Private helpers
# —————————————————————————————————————————————

## Applies current volume and mute state to SFX and UI audio busses.
func _apply_bus_settings() -> void:
	var sfx_idx: int = AudioServer.get_bus_index(BUS_NAMES[SfxBus.SFX])
	var ui_idx: int = AudioServer.get_bus_index(BUS_NAMES[SfxBus.UI])
	
	var volume_db: float = linear_to_db(_volume)
	
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, volume_db)
		AudioServer.set_bus_mute(sfx_idx, _muted)
	if ui_idx != -1:
		AudioServer.set_bus_volume_db(ui_idx, volume_db)
		AudioServer.set_bus_mute(ui_idx, _muted)


## Creates the AudioStreamPlayer pool as child nodes.
func _create_pool() -> void:
	for i: int in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		_pool.append(player)


## Loads volume and mute settings from user://settings.cfg.
func _load_settings() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load(settings_path)
	if err != OK:
		# No settings file yet — use defaults.
		return

	_volume = config.get_value(SETTINGS_SECTION, KEY_SFX_VOLUME, 1.0)
	_muted = config.get_value(SETTINGS_SECTION, KEY_SFX_MUTE, false)


## Persists volume and mute settings to user://settings.cfg.
func _save_settings() -> void:
	var config := ConfigFile.new()
	# Load existing to preserve other sections (e.g., music settings).
	config.load(settings_path)
	config.set_value(SETTINGS_SECTION, KEY_SFX_VOLUME, _volume)
	config.set_value(SETTINGS_SECTION, KEY_SFX_MUTE, _muted)
	var err: Error = config.save(settings_path)
	if err != OK:
		push_error("[SfxManager] Failed to save settings: %s" % error_string(err))


func _load_library() -> void:
	if ResourceLoader.exists(LIB_PATH):
		_lib = load(LIB_PATH) as SfxLibrary
	else:
		push_warning("[SfxManager] SfxLibrary not found at %s" % LIB_PATH)
