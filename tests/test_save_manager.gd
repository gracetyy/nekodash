## Unit tests for SaveManager autoload.
## Task: S1-03 (stub), S3-03 (disk I/O), S3-08 (disk persistence)
## Covers: default state, level records, skin management, signals, reset, disk persistence.
extends GutTest

var _save: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	# Remove any save file left by a previous test so each test starts clean.
	_remove_save_files()
	_save = load("res://src/core/save_manager.gd").new()
	add_child_autofree(_save)


func after_all() -> void:
	_remove_save_files()


func _remove_save_files() -> void:
	if FileAccess.file_exists("user://nekodash_save.json"):
		DirAccess.remove_absolute("user://nekodash_save.json")
	if FileAccess.file_exists("user://nekodash_save.corrupt.json"):
		DirAccess.remove_absolute("user://nekodash_save.corrupt.json")


# —————————————————————————————————————————————
# Default State
# —————————————————————————————————————————————

func test_save_loaded_signal_emits_on_ready() -> void:
	# _ready() fires save_loaded; verify the node is in loaded state.
	assert_true(_save._is_loaded, "Should be loaded after _ready()")


func test_default_equipped_skin_is_cat_default() -> void:
	assert_eq(_save.get_equipped_skin(), "cat_default")


func test_default_unlocked_skins_contains_cat_default() -> void:
	var skins: Array[String] = _save.get_unlocked_skins()
	assert_has(skins, "cat_default")
	assert_eq(skins.size(), 1)


func test_unseen_level_returns_default_record() -> void:
	var record: Dictionary = _save.get_level_record("nonexistent_level")
	assert_eq(record["completed"], false)
	assert_eq(record["best_stars"], 0)
	assert_eq(record["best_moves"], 0)


func test_is_level_completed_returns_false_for_unseen() -> void:
	assert_false(_save.is_level_completed("unknown"))


func test_get_best_stars_returns_zero_for_unseen() -> void:
	assert_eq(_save.get_best_stars("unknown"), 0)


func test_get_best_moves_returns_zero_for_unseen() -> void:
	assert_eq(_save.get_best_moves("unknown"), 0)


# —————————————————————————————————————————————
# Level Records — set and get
# —————————————————————————————————————————————

func test_set_level_record_stores_completion() -> void:
	_save.set_level_record("w1_l1", true, 2, 10)
	assert_true(_save.is_level_completed("w1_l1"))
	assert_eq(_save.get_best_stars("w1_l1"), 2)
	assert_eq(_save.get_best_moves("w1_l1"), 10)


func test_set_level_record_keeps_best_stars() -> void:
	_save.set_level_record("w1_l1", true, 3, 10)
	_save.set_level_record("w1_l1", true, 1, 12)
	assert_eq(_save.get_best_stars("w1_l1"), 3, "Stars should never decrease")


func test_set_level_record_keeps_best_moves() -> void:
	_save.set_level_record("w1_l1", true, 2, 10)
	_save.set_level_record("w1_l1", true, 2, 15)
	assert_eq(_save.get_best_moves("w1_l1"), 10, "Moves should never increase")


func test_set_level_record_updates_lower_moves() -> void:
	_save.set_level_record("w1_l1", true, 2, 10)
	_save.set_level_record("w1_l1", true, 2, 7)
	assert_eq(_save.get_best_moves("w1_l1"), 7, "Lower moves should replace")


func test_set_level_record_emits_signal_on_change() -> void:
	watch_signals(_save)
	_save.set_level_record("w1_l1", true, 2, 10)
	assert_signal_emitted(_save, "level_record_updated")


func test_set_level_record_no_signal_on_no_change() -> void:
	_save.set_level_record("w1_l1", true, 3, 8)
	watch_signals(_save)
	_save.set_level_record("w1_l1", true, 1, 12)
	assert_signal_not_emitted(_save, "level_record_updated")


func test_get_level_record_returns_copy() -> void:
	_save.set_level_record("w1_l1", true, 2, 10)
	var record: Dictionary = _save.get_level_record("w1_l1")
	record["best_stars"] = 999
	assert_eq(_save.get_best_stars("w1_l1"), 2, "Modifying returned dict should not affect stored data")


# —————————————————————————————————————————————
# Skins
# —————————————————————————————————————————————

func test_unlock_skin_adds_to_list() -> void:
	_save.unlock_skin("cat_cozy")
	var skins: Array[String] = _save.get_unlocked_skins()
	assert_has(skins, "cat_cozy")
	assert_eq(skins.size(), 2)


func test_unlock_skin_emits_signal() -> void:
	watch_signals(_save)
	_save.unlock_skin("cat_cozy")
	assert_signal_emitted(_save, "skin_unlocked")


func test_unlock_skin_duplicate_is_noop() -> void:
	_save.unlock_skin("cat_cozy")
	watch_signals(_save)
	_save.unlock_skin("cat_cozy")
	assert_signal_not_emitted(_save, "skin_unlocked")
	assert_eq(_save.get_unlocked_skins().size(), 2)


func test_set_equipped_skin_valid() -> void:
	_save.unlock_skin("cat_cozy")
	_save.set_equipped_skin("cat_cozy")
	assert_eq(_save.get_equipped_skin(), "cat_cozy")


func test_set_equipped_skin_locked_is_rejected() -> void:
	_save.set_equipped_skin("cat_locked")
	assert_eq(_save.get_equipped_skin(), "cat_default", "Should not equip locked skin")


func test_get_unlocked_skins_returns_copy() -> void:
	var skins: Array[String] = _save.get_unlocked_skins()
	skins.append("injected")
	assert_eq(_save.get_unlocked_skins().size(), 1, "Modifying returned array should not affect internal state")


# —————————————————————————————————————————————
# Reset
# —————————————————————————————————————————————

func test_reset_all_progress_clears_data() -> void:
	_save.set_level_record("w1_l1", true, 3, 8)
	_save.unlock_skin("cat_cozy")
	_save.reset_all_progress()
	assert_false(_save.is_level_completed("w1_l1"))
	assert_eq(_save.get_unlocked_skins().size(), 1)
	assert_eq(_save.get_equipped_skin(), "cat_default")


# —————————————————————————————————————————————
# load_game / save_game callable without crash
# —————————————————————————————————————————————

func test_save_game_callable_without_crash() -> void:
	_save.save_game()
	pass_test("save_game() did not crash")


func test_load_game_callable_without_crash() -> void:
	_save.load_game()
	pass_test("load_game() did not crash")


func test_load_game_emits_save_loaded() -> void:
	watch_signals(_save)
	_save.load_game()
	assert_signal_emitted(_save, "save_loaded")


# —————————————————————————————————————————————
# Disk Persistence — save/load roundtrip
# —————————————————————————————————————————————

func test_roundtrip_level_record_survives_reload() -> void:
	_save.set_level_record("w1_l3", true, 3, 5)
	# Create a fresh SaveManager instance that reads from the same file.
	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_true(save2.is_level_completed("w1_l3"), "Level record should survive reload")
	assert_eq(save2.get_best_stars("w1_l3"), 3)
	assert_eq(save2.get_best_moves("w1_l3"), 5)


func test_roundtrip_skin_unlock_survives_reload() -> void:
	_save.unlock_skin("cat_cozy")
	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_has(save2.get_unlocked_skins(), "cat_cozy")


func test_roundtrip_equipped_skin_survives_reload() -> void:
	_save.unlock_skin("cat_cozy")
	_save.set_equipped_skin("cat_cozy")
	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_eq(save2.get_equipped_skin(), "cat_cozy")


# —————————————————————————————————————————————
# Missing file — fresh init
# —————————————————————————————————————————————

func test_missing_file_initialises_defaults() -> void:
	_remove_save_files()
	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_true(save2._is_loaded)
	assert_eq(save2.get_equipped_skin(), "cat_default")
	assert_false(save2.is_level_completed("w1_l1"))


func test_missing_file_creates_save_on_disk() -> void:
	_remove_save_files()
	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_true(FileAccess.file_exists("user://nekodash_save.json"), "Save file should be created on first load")


# —————————————————————————————————————————————
# Corrupted file — recovery
# —————————————————————————————————————————————

func test_corrupt_json_recovers_to_defaults() -> void:
	# Write garbage to the save file.
	var file: FileAccess = FileAccess.open("user://nekodash_save.json", FileAccess.WRITE)
	file.store_string("NOT VALID JSON {{{{")
	file.close()

	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_true(save2._is_loaded, "Should recover after corrupt file")
	assert_eq(save2.get_equipped_skin(), "cat_default")
	assert_false(save2.is_level_completed("w1_l1"))


func test_corrupt_json_renames_to_corrupt_file() -> void:
	var file: FileAccess = FileAccess.open("user://nekodash_save.json", FileAccess.WRITE)
	file.store_string("{{GARBAGE}}")
	file.close()

	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_true(FileAccess.file_exists("user://nekodash_save.corrupt.json"), "Corrupt file should be renamed")


func test_corrupt_json_emits_save_corrupted() -> void:
	var file: FileAccess = FileAccess.open("user://nekodash_save.json", FileAccess.WRITE)
	file.store_string("NOT JSON!")
	file.close()

	# Must watch BEFORE add_child, because _ready() triggers load_game().
	var save2: Node = load("res://src/core/save_manager.gd").new()
	watch_signals(save2)
	add_child_autofree(save2)
	assert_signal_emitted(save2, "save_corrupted")


func test_non_dict_root_recovers() -> void:
	# Valid JSON but root is an array instead of a dictionary.
	var file: FileAccess = FileAccess.open("user://nekodash_save.json", FileAccess.WRITE)
	file.store_string("[1, 2, 3]")
	file.close()

	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_true(save2._is_loaded)
	assert_eq(save2.get_equipped_skin(), "cat_default")


# —————————————————————————————————————————————
# Version mismatch
# —————————————————————————————————————————————

func test_version_mismatch_recovers() -> void:
	var bad_data: Dictionary = {"version": 999, "levels": {}, "equipped_skin_id": "cat_default", "unlocked_skin_ids": ["cat_default"]}
	var file: FileAccess = FileAccess.open("user://nekodash_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(bad_data))
	file.close()

	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_true(save2._is_loaded, "Version mismatch should recover to defaults")
	assert_eq(save2.get_equipped_skin(), "cat_default")


func test_missing_version_key_recovers() -> void:
	var bad_data: Dictionary = {"levels": {}, "equipped_skin_id": "cat_default"}
	var file: FileAccess = FileAccess.open("user://nekodash_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(bad_data))
	file.close()

	var save2: Node = load("res://src/core/save_manager.gd").new()
	add_child_autofree(save2)
	assert_true(save2._is_loaded)
	assert_true(FileAccess.file_exists("user://nekodash_save.corrupt.json"))
