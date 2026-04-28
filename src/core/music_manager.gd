## MusicManager — autoload singleton for background music with cross-fade.
## Implements: Sprint 4 audio system
## Task: S4-13
##
## Manages two AudioStreamPlayer nodes for cross-fading between tracks.
## Subscribes to SceneManager.transition_completed and SceneManager.world_changed
## to auto-switch music based on screen and world context.
##
## Usage:
##   MusicManager.play(my_track)        # cross-fades to new track
##   MusicManager.stop()                # fades out current track
##   MusicManager.set_volume(0.7)
##   MusicManager.set_muted(true)
extends Node


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Audio bus name — must match project audio bus.
const BUS_NAME: String = "Music"

## Cross-fade duration in seconds.
const CROSSFADE_DURATION: float = 1.0

## Settings file path (shared with SfxManager).
const SETTINGS_PATH: String = "user://settings.cfg"

## Settings section and key names.
const SETTINGS_SECTION: String = "audio"
const KEY_MUSIC_VOLUME: String = "music_volume"
const KEY_MUSIC_MUTE: String = "music_mute"


# —————————————————————————————————————————————
# Screen-to-track mapping
# —————————————————————————————————————————————

## Maps SceneManager.Screen → AudioStream.
var _screen_tracks: Dictionary = {
	SceneManager.Screen.MAIN_MENU: preload("res://assets/audio/bgm/opening.ogg"),
	SceneManager.Screen.WORLD_MAP: preload("res://assets/audio/bgm/opening.ogg"),
	SceneManager.Screen.SKIN_SELECT: preload("res://assets/audio/bgm/skin_select.ogg"),
	SceneManager.Screen.OPENING: preload("res://assets/audio/bgm/opening.ogg"),
	SceneManager.Screen.CREDITS: preload("res://assets/audio/bgm/opening.ogg"),
}

## Maps world_id string → AudioStream for per-world gameplay music.
var _world_tracks: Dictionary = {
	"1": preload("res://assets/audio/bgm/bedroom.wav"),
	"2": preload("res://assets/audio/bgm/kitchen.ogg"),
	"3": preload("res://assets/audio/bgm/living_room.ogg"),
	"99": preload("res://assets/audio/bgm/hku.ogg"),
}


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

## The two cross-fade players.
var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer

## Which player is currently active (true = A, false = B).
var _active_is_a: bool = true

## The stream currently playing (for same-track guard).
var _current_stream: AudioStream

## Current volume (0.0 – 1.0).
var _volume: float = 1.0

## Whether music is muted.
var _muted: bool = false

## Current world ID (for world-specific track selection).
var _current_world_id: String = ""


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_create_players()
	_load_settings()
	_connect_scene_manager_signals()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Plays a track with cross-fade. Null streams are gracefully ignored.
## Same-track guard prevents restarting an already-playing track.
func play(stream: AudioStream) -> void:
	if stream == null:
		push_warning("[MusicManager] play() called with null AudioStream — skipping.")
		return

	# Same-track guard: don't restart only if this stream is already active.
	if stream == _current_stream and (_player_a.playing or _player_b.playing):
		return

	_current_stream = stream

	if _muted:
		return

	var incoming: AudioStreamPlayer = _player_a if _active_is_a else _player_b
	var outgoing: AudioStreamPlayer = _player_b if _active_is_a else _player_a

	# Fade out outgoing
	if outgoing.playing:
		var fade_out: Tween = create_tween()
		fade_out.tween_property(outgoing, "volume_db", -80.0, CROSSFADE_DURATION)
		fade_out.tween_callback(outgoing.stop)

	# Start incoming
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	var fade_in: Tween = create_tween()
	fade_in.tween_property(incoming, "volume_db", linear_to_db(_volume), CROSSFADE_DURATION)

	# Swap active player for next cross-fade
	_active_is_a = not _active_is_a


## Stops music with a fade-out.
func stop() -> void:
	_current_stream = null
	for player: AudioStreamPlayer in [_player_a, _player_b]:
		if player.playing:
			var fade: Tween = create_tween()
			fade.tween_property(player, "volume_db", -80.0, CROSSFADE_DURATION)
			fade.tween_callback(player.stop)


## Returns the current volume (0.0 – 1.0).
func get_volume() -> float:
	return _volume


## Sets the volume (0.0 – 1.0) and persists to settings.
func set_volume(value: float) -> void:
	_volume = clampf(value, 0.0, 1.0)
	# Update active player volume immediately
	var active: AudioStreamPlayer = _get_active_player()
	if active.playing:
		active.volume_db = linear_to_db(_volume)
	_save_settings()


## Returns whether music is muted.
func is_muted() -> bool:
	return _muted


## Sets the mute state and persists to settings.
func set_muted(muted: bool) -> void:
	_muted = muted
	if _muted:
		for player: AudioStreamPlayer in [_player_a, _player_b]:
			if player.playing:
				player.volume_db = -80.0
	else:
		# Unmute: restore active volume, or start pending stream if playback
		# was requested while muted.
		var active: AudioStreamPlayer = _get_active_player()
		if active.playing:
			active.volume_db = linear_to_db(_volume)
		elif _current_stream != null:
			play(_current_stream)
	_save_settings()


# —————————————————————————————————————————————
# Private helpers
# —————————————————————————————————————————————

## Returns the player that is currently playing (or was last assigned).
## After play(), _active_is_a points to the NEXT player, so the current one
## is the opposite.
func _get_active_player() -> AudioStreamPlayer:
	return _player_b if _active_is_a else _player_a


## Creates the two AudioStreamPlayer nodes for cross-fading.
func _create_players() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.name = "MusicPlayerA"
	_player_a.bus = BUS_NAME
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.name = "MusicPlayerB"
	_player_b.bus = BUS_NAME
	add_child(_player_b)


## Connects to SceneManager signals for automatic track switching.
func _connect_scene_manager_signals() -> void:
	if not SceneManager.transition_completed.is_connected(_on_transition_completed):
		SceneManager.transition_completed.connect(_on_transition_completed)
	if not SceneManager.world_changed.is_connected(_on_world_changed):
		SceneManager.world_changed.connect(_on_world_changed)
	if not SceneManager.overlay_opened.is_connected(_on_overlay_opened):
		SceneManager.overlay_opened.connect(_on_overlay_opened)


## Handles screen transitions — selects track based on screen type.
func _on_transition_completed(to_screen: SceneManager.Screen) -> void:
	# For GAMEPLAY screens, world_changed handles track selection.
	if to_screen == SceneManager.Screen.GAMEPLAY:
		return

	var track: AudioStream = _screen_tracks.get(to_screen)
	if track != null:
		play(track)


## Handles overlay opening — OPTIONS overlay uses opening track.
func _on_overlay_opened(overlay: SceneManager.Overlay) -> void:
	if overlay == SceneManager.Overlay.OPTIONS:
		var track: AudioStream = _screen_tracks.get(SceneManager.Screen.MAIN_MENU)
		if track != null:
			play(track)


## Handles world changes — selects track based on world_id.
func _on_world_changed(world_id: String) -> void:
	_current_world_id = world_id
	var track: AudioStream = _world_tracks.get(world_id)
	if track != null:
		play(track)


## Loads music volume and mute settings from user://settings.cfg.
func _load_settings() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load(SETTINGS_PATH)
	if err != OK:
		return
	_volume = config.get_value(SETTINGS_SECTION, KEY_MUSIC_VOLUME, 1.0)
	_muted = config.get_value(SETTINGS_SECTION, KEY_MUSIC_MUTE, false)


## Persists music volume and mute settings to user://settings.cfg.
func _save_settings() -> void:
	var config := ConfigFile.new()
	# Load existing to preserve other sections (e.g., SFX settings).
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, KEY_MUSIC_VOLUME, _volume)
	config.set_value(SETTINGS_SECTION, KEY_MUSIC_MUTE, _muted)
	var err: Error = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("[MusicManager] Failed to save settings: %s" % error_string(err))
