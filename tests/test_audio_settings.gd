## Integration tests for audio settings persistence via user://settings.cfg.
## Task: S4-27
## Covers: SfxManager + MusicManager share settings.cfg without key collision,
##         roundtrip persistence works for both, no conflict with save.json.
extends GutTest


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_remove_settings_file()


func after_all() -> void:
	_remove_settings_file()


func _remove_settings_file() -> void:
	if FileAccess.file_exists("user://settings.cfg"):
		DirAccess.remove_absolute("user://settings.cfg")


# —————————————————————————————————————————————
# Tests — Key naming consistency
# —————————————————————————————————————————————

func test_sfx_and_music_share_settings_path() -> void:
	var sfx: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx)
	var music: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(music)
	assert_eq(sfx.SETTINGS_PATH, "user://settings.cfg")
	assert_eq(music.SETTINGS_PATH, "user://settings.cfg")
	assert_eq(sfx.SETTINGS_PATH, music.SETTINGS_PATH, "Both should use the same settings file")


func test_sfx_and_music_share_settings_section() -> void:
	var sfx: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx)
	var music: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(music)
	assert_eq(sfx.SETTINGS_SECTION, "audio")
	assert_eq(music.SETTINGS_SECTION, "audio")


func test_sfx_keys_do_not_collide_with_music_keys() -> void:
	var sfx: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx)
	var music: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(music)
	# All four keys must be distinct
	var keys: Array[String] = [
		sfx.KEY_SFX_VOLUME,
		sfx.KEY_SFX_MUTE,
		music.KEY_MUSIC_VOLUME,
		music.KEY_MUSIC_MUTE,
	]
	assert_eq(keys[0], "sfx_volume")
	assert_eq(keys[1], "sfx_mute")
	assert_eq(keys[2], "music_volume")
	assert_eq(keys[3], "music_mute")
	# Unique check
	for i: int in range(keys.size()):
		for j: int in range(i + 1, keys.size()):
			assert_ne(keys[i], keys[j], "Keys '%s' and '%s' must be unique" % [keys[i], keys[j]])


func test_settings_file_does_not_conflict_with_save_json() -> void:
	var sfx: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx)
	var save: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save)
	assert_ne(sfx.SETTINGS_PATH, save.SAVE_FILE_PATH,
		"Settings file must not be the same as save file")


# —————————————————————————————————————————————
# Tests — SFX roundtrip persistence
# —————————————————————————————————————————————

func test_sfx_volume_roundtrip() -> void:
	var sfx1: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx1)
	sfx1.set_volume(0.42)
	sfx1.set_muted(true)

	# New instance should load persisted values
	var sfx2: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx2)
	assert_almost_eq(sfx2.get_volume(), 0.42, 0.001, "SFX volume should persist")
	assert_true(sfx2.is_muted(), "SFX mute should persist")


func test_sfx_mute_roundtrip_false() -> void:
	var sfx1: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx1)
	sfx1.set_muted(true)
	sfx1.set_muted(false)

	var sfx2: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx2)
	assert_false(sfx2.is_muted(), "SFX mute=false should persist")


# —————————————————————————————————————————————
# Tests — Music roundtrip persistence
# —————————————————————————————————————————————

func test_music_volume_roundtrip() -> void:
	var m1: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(m1)
	m1.set_volume(0.33)
	m1.set_muted(true)

	var m2: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(m2)
	assert_almost_eq(m2.get_volume(), 0.33, 0.001, "Music volume should persist")
	assert_true(m2.is_muted(), "Music mute should persist")


func test_music_mute_roundtrip_false() -> void:
	var m1: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(m1)
	m1.set_muted(true)
	m1.set_muted(false)

	var m2: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(m2)
	assert_false(m2.is_muted(), "Music mute=false should persist")


# —————————————————————————————————————————————
# Tests — Cross-manager isolation
# —————————————————————————————————————————————

func test_sfx_write_does_not_overwrite_music() -> void:
	# Write music settings first
	var m: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(m)
	m.set_volume(0.77)

	# Write sfx settings — must not wipe music values
	var sfx: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx)
	sfx.set_volume(0.22)

	# Re-read music settings
	var m2: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(m2)
	assert_almost_eq(m2.get_volume(), 0.77, 0.001,
		"Music volume should survive SFX writes")


func test_music_write_does_not_overwrite_sfx() -> void:
	# Write sfx settings first
	var sfx: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx)
	sfx.set_volume(0.55)

	# Write music settings — must not wipe sfx values
	var m: Node = load("res://src/core/music_manager.gd").new()
	add_child_autofree(m)
	m.set_volume(0.88)

	# Re-read sfx settings
	var sfx2: Node = load("res://src/core/sfx_manager.gd").new()
	add_child_autofree(sfx2)
	assert_almost_eq(sfx2.get_volume(), 0.55, 0.001,
		"SFX volume should survive Music writes")
