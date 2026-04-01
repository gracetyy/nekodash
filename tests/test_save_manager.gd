## Unit tests for SaveManager autoload stub.
## Task: S1-03
## Covers: default state, level records, skin management, signals, reset.
extends GutTest

var _save: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_save = load("res://src/core/save_manager.gd").new()
	add_child_autofree(_save)


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
