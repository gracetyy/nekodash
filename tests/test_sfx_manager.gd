## Unit tests for SfxManager autoload.
## Task: S4-16
## Covers: play with valid stream, play with null, volume setter, mute toggle,
##         pool wrap, bus routing.
extends GutTest

var _sfx: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_remove_settings_file()
	_sfx = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(_sfx)


func after_all() -> void:
	_remove_settings_file()


func _remove_settings_file() -> void:
	if FileAccess.file_exists("user://settings.cfg"):
		DirAccess.remove_absolute("user://settings.cfg")


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Returns a lightweight stub AudioStream for testing (no actual audio needed).
func _stub_stream() -> AudioStream:
	return AudioStreamWAV.new()


# —————————————————————————————————————————————
# Tests
# —————————————————————————————————————————————

func test_play_valid_stream_no_crash() -> void:
	var stream: AudioStream = _stub_stream()
	_sfx.play(stream)
	pass_test("play() with valid stream did not crash")


func test_play_null_stream_warns_no_crash() -> void:
	# Null stream should push_warning and not crash.
	_sfx.play(null)
	pass_test("play(null) did not crash")


func test_volume_setter_persists() -> void:
	_sfx.set_volume(0.5)
	assert_almost_eq(_sfx.get_volume(), 0.5, 0.001, "Volume should be 0.5 after set")

	# Create a fresh instance — it should load the persisted value.
	var sfx2: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx2)
	assert_almost_eq(sfx2.get_volume(), 0.5, 0.001, "Volume should persist across instances")


func test_volume_clamped_to_range() -> void:
	_sfx.set_volume(2.0)
	assert_almost_eq(_sfx.get_volume(), 1.0, 0.001, "Volume above 1.0 should be clamped to 1.0")

	_sfx.set_volume(-0.5)
	assert_almost_eq(_sfx.get_volume(), 0.0, 0.001, "Volume below 0.0 should be clamped to 0.0")


func test_mute_toggle() -> void:
	assert_false(_sfx.is_muted(), "Should not be muted by default")

	_sfx.set_muted(true)
	assert_true(_sfx.is_muted(), "Should be muted after set_muted(true)")

	# Play should be silent when muted — no crash.
	_sfx.play(_stub_stream())
	pass_test("play() while muted did not crash")

	_sfx.set_muted(false)
	assert_false(_sfx.is_muted(), "Should not be muted after set_muted(false)")


func test_pool_wraps_when_full() -> void:
	var stream: AudioStream = _stub_stream()
	# Play POOL_SIZE + 1 times to trigger wrap-around.
	for i: int in range(_sfx.POOL_SIZE + 1):
		_sfx.play(stream)
	pass_test("Pool wrap-around (oldest reused) did not crash")


func test_bus_routing_sfx() -> void:
	var stream: AudioStream = _stub_stream()
	_sfx.play(stream, _sfx.SfxBus.SFX)
	# The last-used player should have bus = "SFX"
	# Pool index was incremented after play, so the used player is at (index - 1).
	var used_index: int = (_sfx._pool_index - 1 + _sfx.POOL_SIZE) % _sfx.POOL_SIZE
	var player: AudioStreamPlayer = _sfx._pool[used_index]
	assert_eq(player.bus, "SFX", "Player bus should be 'SFX' when using SfxBus.SFX")


func test_bus_routing_ui() -> void:
	var stream: AudioStream = _stub_stream()
	_sfx.play(stream, _sfx.SfxBus.UI)
	var used_index: int = (_sfx._pool_index - 1 + _sfx.POOL_SIZE) % _sfx.POOL_SIZE
	var player: AudioStreamPlayer = _sfx._pool[used_index]
	assert_eq(player.bus, "UI", "Player bus should be 'UI' when using SfxBus.UI")


func test_default_volume_is_one() -> void:
	assert_almost_eq(_sfx.get_volume(), 1.0, 0.001, "Default volume should be 1.0")


func test_pool_size_is_eight() -> void:
	assert_eq(_sfx._pool.size(), 8, "Pool should contain 8 AudioStreamPlayers")
