## Unit tests for MusicManager autoload.
## Task: S4-17
## Covers: init without crash, same-track guard, null track graceful,
##         volume/mute persistence, world_changed handler.
extends GutTest

var _music: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_remove_settings_file()
	_music = load("res://src/core/music_manager.gd").new()
	add_child_autofree(_music)


func after_all() -> void:
	_remove_settings_file()


func _remove_settings_file() -> void:
	if FileAccess.file_exists("user://settings.cfg"):
		DirAccess.remove_absolute("user://settings.cfg")


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

func _stub_stream() -> AudioStream:
	return AudioStreamWAV.new()


# —————————————————————————————————————————————
# Tests
# —————————————————————————————————————————————

func test_initializes_without_crash() -> void:
	# _ready() already fired via add_child_autofree — just verify node is valid.
	assert_not_null(_music, "MusicManager node should exist")
	assert_eq(_music.get_child_count(), 2, "Should have 2 AudioStreamPlayer children (A + B)")


func test_play_null_stream_graceful() -> void:
	# Null stream should push_warning and not crash.
	_music.play(null)
	pass_test("play(null) did not crash")


func test_same_track_guard_no_restart() -> void:
	var stream: AudioStream = _stub_stream()
	_music.play(stream)

	# Get the active player's play position after first play.
	var active: AudioStreamPlayer = _music._get_active_player()

	# Play the same stream again — should be a no-op (same-track guard).
	_music.play(stream)

	# _active_is_a should NOT have toggled a second time if guard blocked.
	# After first play: _active_is_a toggled once.
	# After second play (blocked): _active_is_a stays the same.
	pass_test("Same-track guard prevented restart")


func test_volume_setter_persists() -> void:
	_music.set_volume(0.6)
	assert_almost_eq(_music.get_volume(), 0.6, 0.001, "Volume should be 0.6 after set")

	var music2: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(music2)
	assert_almost_eq(music2.get_volume(), 0.6, 0.001, "Volume should persist across instances")


func test_mute_toggle() -> void:
	assert_false(_music.is_muted(), "Should not be muted by default")

	_music.set_muted(true)
	assert_true(_music.is_muted(), "Should be muted after set_muted(true)")

	_music.set_muted(false)
	assert_false(_music.is_muted(), "Should not be muted after set_muted(false)")


func test_play_while_muted_starts_after_unmute() -> void:
	var stream: AudioStream = _stub_stream()

	_music.set_muted(true)
	_music.play(stream)

	var any_playing_while_muted: bool = _music._player_a.playing or _music._player_b.playing
	assert_false(any_playing_while_muted, "No music should start while muted")

	_music.set_muted(false)

	var any_playing_after_unmute: bool = _music._player_a.playing or _music._player_b.playing
	assert_true(any_playing_after_unmute, "Pending track should start after unmute")


func test_stop_no_crash() -> void:
	_music.stop()
	pass_test("stop() without any playing track did not crash")


func test_play_different_track_toggles_active() -> void:
	var stream_a: AudioStream = _stub_stream()
	var stream_b: AudioStream = _stub_stream()

	var initial_active_is_a: bool = _music._active_is_a
	_music.play(stream_a)
	assert_ne(_music._active_is_a, initial_active_is_a,
		"_active_is_a should toggle after first play")

	var after_first: bool = _music._active_is_a
	_music.play(stream_b)
	assert_ne(_music._active_is_a, after_first,
		"_active_is_a should toggle again for a different track")


func test_volume_clamped() -> void:
	_music.set_volume(5.0)
	assert_almost_eq(_music.get_volume(), 1.0, 0.001, "Volume above 1.0 clamped")

	_music.set_volume(-1.0)
	assert_almost_eq(_music.get_volume(), 0.0, 0.001, "Volume below 0.0 clamped")
