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

## Volume adjustment when ducked (e.g. during pause).
const DUCKED_VOLUME_DB: float = -3.0


# —————————————————————————————————————————————
# Resources
# —————————————————————————————————————————————

const GLOBAL_AUDIO_PATH: String = "res://data/global_audio.tres"
const CATALOGUE_PATH: String = "res://data/level_catalogue.tres"

var _global_audio: GlobalAudioSettings
var _catalogue: LevelCatalogue


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

## Track volume ducking state (for overlays).
var _is_ducked: bool = false

var _fade_in_tween: Tween
var _fade_out_tween: Tween


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_create_players()
	_load_resources()
	_load_settings()
	_apply_bus_settings()
	_connect_scene_manager_signals()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Plays a track with cross-fade. Null streams are gracefully ignored.
## Same-track guard prevents restarting an already-playing track.
func play(stream: AudioStream) -> void:
	if stream == null:
		return

	if stream == _current_stream and (_player_a.playing or _player_b.playing):
		return

	_current_stream = stream

	var incoming: AudioStreamPlayer = _player_a if _active_is_a else _player_b
	var outgoing: AudioStreamPlayer = _player_b if _active_is_a else _player_a

	# Stop any existing tweens to prevent volume fighting
	if _fade_in_tween: _fade_in_tween.kill()
	if _fade_out_tween: _fade_out_tween.kill()

	# Fade out outgoing
	if outgoing.playing:
		_fade_out_tween = create_tween()
		_fade_out_tween.tween_property(outgoing, "volume_db", -80.0, CROSSFADE_DURATION)
		_fade_out_tween.tween_callback(outgoing.stop)

	# Start incoming
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	_fade_in_tween = create_tween()
	_fade_in_tween.tween_property(incoming, "volume_db", 0.0, CROSSFADE_DURATION)

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
	_apply_bus_settings()
	_save_settings()


## Returns whether music is muted.
func is_muted() -> bool:
	return _muted


## Sets the mute state and persists to settings.
func set_muted(muted: bool) -> void:
	_muted = muted
	_apply_bus_settings()
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
	_player_a.process_mode = Node.PROCESS_MODE_ALWAYS
	_player_a.finished.connect(_on_player_finished.bind(_player_a))
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.name = "MusicPlayerB"
	_player_b.bus = BUS_NAME
	_player_b.process_mode = Node.PROCESS_MODE_ALWAYS
	_player_b.finished.connect(_on_player_finished.bind(_player_b))
	add_child(_player_b)


func _load_resources() -> void:
	if ResourceLoader.exists(GLOBAL_AUDIO_PATH):
		_global_audio = load(GLOBAL_AUDIO_PATH) as GlobalAudioSettings

	if ResourceLoader.exists(CATALOGUE_PATH):
		_catalogue = load(CATALOGUE_PATH) as LevelCatalogue
	
	# Small delay before initial play to ensure audio driver is ready (prevents WASAPI warnings)
	get_tree().create_timer(0.1).timeout.connect(_identify_and_play_initial_track)


## Connects to SceneManager signals for automatic track switching.
func _connect_scene_manager_signals() -> void:
	if not SceneManager.transition_completed.is_connected(_on_transition_completed):
		SceneManager.transition_completed.connect(_on_transition_completed)
	if not SceneManager.world_changed.is_connected(_on_world_changed):
		SceneManager.world_changed.connect(_on_world_changed)
	if not SceneManager.overlay_opened.is_connected(_on_overlay_opened):
		SceneManager.overlay_opened.connect(_on_overlay_opened)
	if not SceneManager.overlay_closed.is_connected(_on_overlay_closed):
		SceneManager.overlay_closed.connect(_on_overlay_closed)


## Handles screen transitions — selects track based on screen type.
func _on_transition_completed(to_screen: SceneManager.Screen) -> void:
	# For GAMEPLAY screens, world_changed handles track selection.
	if to_screen == SceneManager.Screen.GAMEPLAY:
		return

	if _global_audio == null:
		return
		
	var track: AudioStream = _global_audio.screen_tracks.get(to_screen)
	if track != null:
		play(track)


## Handles overlay opening — OPTIONS overlay ducks or switches track, PAUSE/LEVEL_COMPLETE ducks volume.
func _on_overlay_opened(overlay: SceneManager.Overlay) -> void:
	if overlay == SceneManager.Overlay.OPTIONS:
		# If we're in gameplay, duck the gameplay music instead of switching to opening track.
		if SceneManager.get_current_screen() == SceneManager.Screen.GAMEPLAY:
			_is_ducked = true
			_apply_bus_settings()
		else:
			if _global_audio == null:
				return
			var track: AudioStream = _global_audio.screen_tracks.get(SceneManager.Screen.MAIN_MENU)
			if track != null:
				play(track)
	
	elif overlay == SceneManager.Overlay.PAUSE or overlay == SceneManager.Overlay.LEVEL_COMPLETE:
		_is_ducked = true
		_apply_bus_settings()


## Handles overlay closing — restores volume if it was ducked.
func _on_overlay_closed(overlay: SceneManager.Overlay) -> void:
	if _is_ducked:
		_is_ducked = false
		_apply_bus_settings()


## Handles world changes — selects track based on world_id.
func _on_world_changed(world_id: String) -> void:
	_current_world_id = world_id
	
	if _catalogue == null:
		return
		
	var found: bool = false
	var w_id_int: int = world_id.to_int()
	for world: WorldData in _catalogue.worlds:
		if world.world_id == w_id_int:
			if world.bgm_track != null:
				play(world.bgm_track)
				found = true
			break
	
	if not found and _global_audio != null and _global_audio.fallback_track != null:
		print("[MusicManager] No world BGM found for ", world_id, ", using fallback.")
		play(_global_audio.fallback_track)


## Applies current volume, mute, and ducking state to the Music audio bus.
func _apply_bus_settings() -> void:
	var bus_idx: int = AudioServer.get_bus_index(BUS_NAME)
	if bus_idx == -1:
		push_warning("[MusicManager] Music bus not found: " + BUS_NAME)
		return
	
	var target_db: float = linear_to_db(_volume)
	if _is_ducked:
		target_db += DUCKED_VOLUME_DB
	
	AudioServer.set_bus_volume_db(bus_idx, target_db)
	AudioServer.set_bus_mute(bus_idx, _muted)


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


func _on_player_finished(player: AudioStreamPlayer) -> void:
	# If the stream that just finished is still the one we want to play,
	# restart it to achieve infinite looping.
	if player.stream == _current_stream:
		player.play()


func _identify_and_play_initial_track() -> void:
	if SceneManager == null:
		return
	var current: SceneManager.Screen = SceneManager.get_current_screen()
	if current != SceneManager.Screen.GAMEPLAY:
		_on_transition_completed(current)
	else:
		# For gameplay, check if we have a current world ID saved or active
		if _current_world_id != "":
			_on_world_changed(_current_world_id)
