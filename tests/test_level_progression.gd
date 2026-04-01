## Unit tests for LevelProgression gameplay node.
## Task: S2-03
## Covers: catalogue loading, unlock logic, SaveManager writes, signal emission,
##         world completion, sentinel handling, edge cases per GDD.
##
## Acceptance criteria: LP-1 through LP-10 from design/gdd/level-progression.md
extends GutTest

var _lp: Node
var _sr: Node

# Signal tracking
var _record_saved_log: Array = []
var _next_unlocked_log: Array = []
var _world_completed_log: Array = []


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	# Reset SaveManager between tests
	SaveManager._data = {}
	SaveManager._is_loaded = true
	SaveManager._init_default_data()

	_lp = load("res://src/gameplay/level_progression.gd").new()
	add_child_autofree(_lp)

	_sr = load("res://src/gameplay/star_rating_system.gd").new()
	add_child_autofree(_sr)

	_record_saved_log.clear()
	_next_unlocked_log.clear()
	_world_completed_log.clear()

	_lp.level_record_saved.connect(_on_level_record_saved)
	_lp.next_level_unlocked.connect(_on_next_level_unlocked)
	_lp.world_completed.connect(_on_world_completed)


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_level_record_saved(level_id: String, stars: int, final_moves: int) -> void:
	_record_saved_log.append({
		"level_id": level_id,
		"stars": stars,
		"final_moves": final_moves,
	})


func _on_next_level_unlocked(level_data: LevelData) -> void:
	_next_unlocked_log.append(level_data)


func _on_world_completed(world_id: int) -> void:
	_world_completed_log.append(world_id)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Creates a minimal LevelData with the given parameters.
func _make_level(id: String, world: int, index: int) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = id
	ld.world_id = world
	ld.level_index = index
	ld.display_name = "Test %s" % id
	ld.grid_width = 5
	ld.grid_height = 5
	ld.minimum_moves = 5
	ld.star_3_moves = 5
	ld.star_2_moves = 7
	ld.star_1_moves = 10
	ld.walkability_tiles = PackedInt32Array()
	ld.walkability_tiles.resize(25)
	ld.walkability_tiles.fill(0)
	ld.obstacle_tiles = PackedInt32Array()
	ld.obstacle_tiles.resize(25)
	ld.obstacle_tiles.fill(-1)
	ld.cat_start = Vector2i(0, 0)
	return ld


## Builds a catalogue with a standard 2-world layout (3 + 2 = 5 levels).
func _make_standard_catalogue() -> LevelCatalogue:
	var cat: LevelCatalogue = LevelCatalogue.new()
	cat.levels.append(_make_level("w1_l1", 1, 1))
	cat.levels.append(_make_level("w1_l2", 1, 2))
	cat.levels.append(_make_level("w1_l3", 1, 3))
	cat.levels.append(_make_level("w2_l1", 2, 1))
	cat.levels.append(_make_level("w2_l2", 2, 2))
	return cat


## Initializes LevelProgression with the standard catalogue.
func _init_standard() -> void:
	_lp.initialize(_make_standard_catalogue(), _sr)


## Marks a level as completed in SaveManager directly (for setup).
func _complete_level(level_id: String, stars: int = 1, moves: int = 10) -> void:
	SaveManager.set_level_record(level_id, true, stars, moves)


# —————————————————————————————————————————————
# Section 1 — Initialization
# —————————————————————————————————————————————

func test_initialize_sets_initialized_flag() -> void:
	_init_standard()
	assert_true(_lp.is_initialized())


func test_not_initialized_by_default() -> void:
	assert_false(_lp.is_initialized())


func test_initialize_with_null_catalogue_does_not_crash() -> void:
	_lp.initialize(null, _sr)
	assert_false(_lp.is_initialized())


func test_initialize_with_null_star_rating_does_not_crash() -> void:
	var cat: LevelCatalogue = _make_standard_catalogue()
	_lp.initialize(cat, null)
	assert_false(_lp.is_initialized())


func test_level_count_matches_catalogue() -> void:
	_init_standard()
	assert_eq(_lp.get_level_count(), 5)


func test_set_current_level() -> void:
	_init_standard()
	var ld := _make_level("w1_l1", 1, 1)
	_lp.set_current_level(ld)
	# No crash, no error — just smoke test.
	pass_test("set_current_level accepted LevelData without error.")


# —————————————————————————————————————————————
# Section 2 — Catalogue sorting (AC: LP-9)
# —————————————————————————————————————————————

func test_catalogue_sorted_by_world_then_index() -> void:
	var cat: LevelCatalogue = LevelCatalogue.new()
	# Intentionally out of order
	cat.levels.append(_make_level("w2_l2", 2, 2))
	cat.levels.append(_make_level("w1_l1", 1, 1))
	cat.levels.append(_make_level("w1_l3", 1, 3))
	cat.levels.append(_make_level("w2_l1", 2, 1))
	cat.levels.append(_make_level("w1_l2", 1, 2))

	_lp.initialize(cat, _sr)

	# Verify get_next_level follows sorted order
	var next: LevelData = _lp.get_next_level("w1_l1")
	assert_eq(next.level_id, "w1_l2", "After w1_l1 should come w1_l2")

	next = _lp.get_next_level("w1_l3")
	assert_eq(next.level_id, "w2_l1", "After w1_l3 should come w2_l1 (cross-world)")

	next = _lp.get_next_level("w2_l2")
	assert_null(next, "After last level, get_next_level should return null")


func test_get_levels_for_world_returns_correct_subset() -> void:
	_init_standard()
	var w1_levels: Array = _lp.get_levels_for_world(1)
	assert_eq(w1_levels.size(), 3)
	assert_eq(w1_levels[0].level_id, "w1_l1")
	assert_eq(w1_levels[1].level_id, "w1_l2")
	assert_eq(w1_levels[2].level_id, "w1_l3")


func test_get_levels_for_world_returns_empty_for_unknown() -> void:
	_init_standard()
	var w99: Array = _lp.get_levels_for_world(99)
	assert_eq(w99.size(), 0)


func test_get_world_count() -> void:
	_init_standard()
	assert_eq(_lp.get_world_count(), 2)


# —————————————————————————————————————————————
# Section 3 — Unlock Logic (AC: LP-1, LP-2, LP-3, LP-4)
# —————————————————————————————————————————————

func test_first_level_always_unlocked_lp1() -> void:
	_init_standard()
	assert_true(
		_lp.is_level_unlocked("w1_l1"),
		"LP-1: First level (w1, l1) must always be unlocked."
	)


func test_second_level_locked_initially_lp2() -> void:
	_init_standard()
	assert_false(
		_lp.is_level_unlocked("w1_l2"),
		"LP-2: Level after first should be locked if first not completed."
	)


func test_second_level_unlocks_after_first_completed_lp2() -> void:
	_init_standard()
	_complete_level("w1_l1")
	assert_true(
		_lp.is_level_unlocked("w1_l2"),
		"LP-2: Level unlocks when previous is completed."
	)


func test_cross_world_unlock_lp3() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_complete_level("w1_l2")
	_complete_level("w1_l3")
	assert_true(
		_lp.is_level_unlocked("w2_l1"),
		"LP-3: First level of next world unlocks when last level of previous world completed."
	)


func test_cross_world_locked_if_prev_world_incomplete_lp3() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_complete_level("w1_l2")
	# w1_l3 NOT completed
	assert_false(
		_lp.is_level_unlocked("w2_l1"),
		"LP-3: Cross-world unlock blocked until last level of prev world completed."
	)


func test_zero_stars_is_sufficient_for_unlock_lp4() -> void:
	_init_standard()
	# Complete w1_l1 with 0 stars — should still unlock w1_l2
	_complete_level("w1_l1", 0, 20)
	assert_true(
		_lp.is_level_unlocked("w1_l2"),
		"LP-4: Completion with 0 stars is sufficient to unlock next level."
	)


func test_unknown_level_id_returns_not_unlocked() -> void:
	_init_standard()
	assert_false(_lp.is_level_unlocked("nonexistent"))


# —————————————————————————————————————————————
# Section 4 — Record saved signal (AC: LP-5)
# —————————————————————————————————————————————

func test_level_record_saved_emitted_on_rating_lp5() -> void:
	_init_standard()
	_sr.rating_computed.emit("w1_l1", 3, 5)
	assert_eq(
		_record_saved_log.size(), 1,
		"LP-5: level_record_saved must emit once per rating_computed."
	)
	assert_eq(_record_saved_log[0]["level_id"], "w1_l1")
	assert_eq(_record_saved_log[0]["stars"], 3)
	assert_eq(_record_saved_log[0]["final_moves"], 5)


func test_level_record_saved_writes_to_save_manager_lp5() -> void:
	_init_standard()
	_sr.rating_computed.emit("w1_l1", 2, 8)
	assert_true(SaveManager.is_level_completed("w1_l1"))
	assert_eq(SaveManager.get_best_stars("w1_l1"), 2)
	assert_eq(SaveManager.get_best_moves("w1_l1"), 8)


func test_multiple_completions_emit_each_time_lp5() -> void:
	_init_standard()
	_sr.rating_computed.emit("w1_l1", 1, 15)
	_sr.rating_computed.emit("w1_l1", 3, 5)
	assert_eq(
		_record_saved_log.size(), 2,
		"LP-5: level_record_saved fires every completion, not just first."
	)


# —————————————————————————————————————————————
# Section 5 — Next level unlocked signal (AC: LP-6)
# —————————————————————————————————————————————

func test_next_level_unlocked_emitted_on_first_completion_lp6() -> void:
	_init_standard()
	_sr.rating_computed.emit("w1_l1", 2, 8)
	assert_eq(
		_next_unlocked_log.size(), 1,
		"LP-6: next_level_unlocked must emit on first completion."
	)
	assert_eq(_next_unlocked_log[0].level_id, "w1_l2")


func test_next_level_unlocked_not_emitted_on_replay_lp6() -> void:
	_init_standard()
	_complete_level("w1_l1") # Pre-mark as completed
	_sr.rating_computed.emit("w1_l1", 3, 5) # Replay with better score
	assert_eq(
		_next_unlocked_log.size(), 0,
		"LP-6: next_level_unlocked must NOT emit if already unlocked."
	)


func test_next_level_unlocked_cross_world_lp6() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_complete_level("w1_l2")
	# Complete last level of world 1 → should unlock w2_l1
	_sr.rating_computed.emit("w1_l3", 1, 12)
	assert_eq(_next_unlocked_log.size(), 1)
	assert_eq(
		_next_unlocked_log[0].level_id, "w2_l1",
		"LP-6: Cross-world unlock should emit with first level of next world."
	)


func test_no_unlock_signal_on_last_level_completion() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_complete_level("w1_l2")
	_complete_level("w1_l3")
	_complete_level("w2_l1")
	# Complete the very last level in the game
	_sr.rating_computed.emit("w2_l2", 3, 5)
	assert_eq(
		_next_unlocked_log.size(), 0,
		"No unlock signal when completing the final level in the game."
	)


# —————————————————————————————————————————————
# Section 6 — World completed signal (AC: LP-7)
# —————————————————————————————————————————————

func test_world_completed_emitted_when_last_level_done_lp7() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_complete_level("w1_l2")
	# Complete last level of world 1
	_sr.rating_computed.emit("w1_l3", 2, 9)
	assert_eq(
		_world_completed_log.size(), 1,
		"LP-7: world_completed must emit when last level of world is done."
	)
	assert_eq(_world_completed_log[0], 1)


func test_world_completed_not_emitted_if_already_done_lp7() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_complete_level("w1_l2")
	_complete_level("w1_l3") # World already complete
	_sr.rating_computed.emit("w1_l3", 3, 5) # Replay
	assert_eq(
		_world_completed_log.size(), 0,
		"LP-7: world_completed must NOT re-emit on replay."
	)


func test_world_completed_not_emitted_for_partial() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_sr.rating_computed.emit("w1_l2", 1, 14)
	assert_eq(
		_world_completed_log.size(), 0,
		"LP-7: world_completed must not emit until ALL levels in world are done."
	)


func test_world_completed_for_second_world() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_complete_level("w1_l2")
	_complete_level("w1_l3")
	_complete_level("w2_l1")
	_sr.rating_computed.emit("w2_l2", 3, 5)
	assert_eq(_world_completed_log.size(), 1)
	assert_eq(_world_completed_log[0], 2)


# —————————————————————————————————————————————
# Section 7 — Sentinel handling (AC: LP-8)
# —————————————————————————————————————————————

func test_sentinel_minus_one_stars_treated_as_zero_lp8() -> void:
	_init_standard()
	_sr.rating_computed.emit("w1_l1", -1, 20)
	assert_true(
		SaveManager.is_level_completed("w1_l1"),
		"LP-8: stars == -1 sentinel must still mark level as completed."
	)
	assert_eq(
		SaveManager.get_best_stars("w1_l1"), 0,
		"LP-8: stars == -1 sentinel must be stored as 0."
	)


func test_sentinel_still_emits_record_saved_lp8() -> void:
	_init_standard()
	_sr.rating_computed.emit("w1_l1", -1, 20)
	assert_eq(_record_saved_log.size(), 1)
	assert_eq(
		_record_saved_log[0]["stars"], 0,
		"LP-8: level_record_saved signal should emit effective_stars (0), not raw (-1)."
	)


func test_sentinel_completion_unlocks_next_level_lp8() -> void:
	_init_standard()
	_sr.rating_computed.emit("w1_l1", -1, 20)
	assert_true(
		_lp.is_level_unlocked("w1_l2"),
		"LP-8: Sentinel completion (0 effective stars) unlocks next level."
	)


# —————————————————————————————————————————————
# Section 8 — Duplicate level_id detection (AC: LP-10)
# —————————————————————————————————————————————

func test_duplicate_level_id_logged_and_skipped_lp10() -> void:
	var cat: LevelCatalogue = LevelCatalogue.new()
	cat.levels.append(_make_level("dup", 1, 1))
	cat.levels.append(_make_level("dup", 1, 2)) # Same level_id!
	cat.levels.append(_make_level("w1_l3", 1, 3))

	_lp.initialize(cat, _sr)

	assert_eq(
		_lp.get_level_count(), 2,
		"LP-10: Duplicate level_id should be removed from catalogue, leaving 2."
	)


func test_duplicate_does_not_break_unlock_chain() -> void:
	var cat: LevelCatalogue = LevelCatalogue.new()
	cat.levels.append(_make_level("w1_l1", 1, 1))
	cat.levels.append(_make_level("w1_l1", 1, 2)) # Duplicate
	cat.levels.append(_make_level("w1_l3", 1, 3))

	_lp.initialize(cat, _sr)

	# w1_l1 is always unlocked (first)
	assert_true(_lp.is_level_unlocked("w1_l1"))
	# After completing w1_l1, w1_l3 should unlock (duplicate skipped)
	_complete_level("w1_l1")
	assert_true(
		_lp.is_level_unlocked("w1_l3"),
		"LP-10: After skipping duplicate, chain continues."
	)


# —————————————————————————————————————————————
# Section 9 — get_next_level edge cases
# —————————————————————————————————————————————

func test_get_next_level_returns_correct_level() -> void:
	_init_standard()
	var next: LevelData = _lp.get_next_level("w1_l1")
	assert_not_null(next)
	assert_eq(next.level_id, "w1_l2")


func test_get_next_level_returns_null_for_last() -> void:
	_init_standard()
	var next: LevelData = _lp.get_next_level("w2_l2")
	assert_null(next, "Last level in game has no next level.")


func test_get_next_level_returns_null_for_unknown_id() -> void:
	_init_standard()
	var next: LevelData = _lp.get_next_level("nonexistent")
	assert_null(next)


# —————————————————————————————————————————————
# Section 10 — is_world_completed edge cases
# —————————————————————————————————————————————

func test_is_world_completed_false_initially() -> void:
	_init_standard()
	assert_false(_lp.is_world_completed(1))


func test_is_world_completed_true_when_all_done() -> void:
	_init_standard()
	_complete_level("w1_l1")
	_complete_level("w1_l2")
	_complete_level("w1_l3")
	assert_true(_lp.is_world_completed(1))


func test_is_world_completed_false_for_unknown_world() -> void:
	_init_standard()
	assert_false(_lp.is_world_completed(99))


# —————————————————————————————————————————————
# Section 11 — Delegate methods (is_level_completed, get_best_stars)
# —————————————————————————————————————————————

func test_is_level_completed_delegates_to_save_manager() -> void:
	_init_standard()
	assert_false(_lp.is_level_completed("w1_l1"))
	_complete_level("w1_l1")
	assert_true(_lp.is_level_completed("w1_l1"))


func test_get_best_stars_delegates_to_save_manager() -> void:
	_init_standard()
	assert_eq(_lp.get_best_stars("w1_l1"), 0)
	_complete_level("w1_l1", 3, 5)
	assert_eq(_lp.get_best_stars("w1_l1"), 3)


# —————————————————————————————————————————————
# Section 12 — Re-initialization safety
# —————————————————————————————————————————————

func test_reinitialize_does_not_double_connect() -> void:
	_init_standard()
	var cat2: LevelCatalogue = _make_standard_catalogue()
	_lp.initialize(cat2, _sr)

	_sr.rating_computed.emit("w1_l1", 2, 8)
	assert_eq(
		_record_saved_log.size(), 1,
		"Re-initialization must disconnect old signal before reconnecting."
	)


func test_reinitialize_with_different_catalogue() -> void:
	_init_standard()
	# Second catalogue with only 2 levels
	var cat2: LevelCatalogue = LevelCatalogue.new()
	cat2.levels.append(_make_level("x1", 1, 1))
	cat2.levels.append(_make_level("x2", 1, 2))
	_lp.initialize(cat2, _sr)

	assert_eq(_lp.get_level_count(), 2)
	assert_true(_lp.is_level_unlocked("x1"))
	assert_false(_lp.is_level_unlocked("w1_l1")) # Old catalogue not accessible


# —————————————————————————————————————————————
# Section 13 — Single-level catalogue
# —————————————————————————————————————————————

func test_single_level_game() -> void:
	var cat: LevelCatalogue = LevelCatalogue.new()
	cat.levels.append(_make_level("only", 1, 1))
	_lp.initialize(cat, _sr)

	assert_true(_lp.is_level_unlocked("only"))
	assert_eq(_lp.get_next_level("only"), null)

	_sr.rating_computed.emit("only", 3, 5)
	assert_eq(_record_saved_log.size(), 1)
	assert_eq(_next_unlocked_log.size(), 0, "No next level to unlock.")
	assert_eq(_world_completed_log.size(), 1, "Single-level world complete.")


# —————————————————————————————————————————————
# Section 14 — Empty catalogue
# —————————————————————————————————————————————

func test_empty_catalogue_initializes_safely() -> void:
	var cat: LevelCatalogue = LevelCatalogue.new()
	_lp.initialize(cat, _sr)
	assert_true(_lp.is_initialized())
	assert_eq(_lp.get_level_count(), 0)
	assert_eq(_lp.get_world_count(), 0)


# —————————————————————————————————————————————
# Section 15 — Unknown level_id guard (regression)
# —————————————————————————————————————————————

func test_unknown_level_id_in_rating_computed_does_not_write() -> void:
	_init_standard()
	_sr.rating_computed.emit("nonexistent_level", 3, 5)
	assert_false(
		SaveManager.is_level_completed("nonexistent_level"),
		"Unknown level_id must not create phantom record in SaveManager."
	)
	assert_eq(
		_record_saved_log.size(), 0,
		"level_record_saved must not fire for unknown level_id."
	)


func test_unknown_level_id_does_not_emit_unlock_or_world_signals() -> void:
	_init_standard()
	_sr.rating_computed.emit("ghost", 2, 10)
	assert_eq(_next_unlocked_log.size(), 0)
	assert_eq(_world_completed_log.size(), 0)


func test_get_current_level_returns_set_value() -> void:
	_init_standard()
	var ld := _make_level("w1_l1", 1, 1)
	_lp.set_current_level(ld)
	assert_eq(_lp.get_current_level().level_id, "w1_l1")


func test_get_current_level_null_by_default() -> void:
	_init_standard()
	assert_null(_lp.get_current_level())


# —————————————————————————————————————————————
# Section 16 — Full progression sequence
# —————————————————————————————————————————————

func test_full_game_walkthrough() -> void:
	_init_standard()

	# Play through all 5 levels sequentially
	# w1_l1
	assert_true(_lp.is_level_unlocked("w1_l1"))
	_sr.rating_computed.emit("w1_l1", 3, 5)
	assert_true(_lp.is_level_unlocked("w1_l2"))
	assert_eq(_next_unlocked_log.size(), 1)

	# w1_l2
	_sr.rating_computed.emit("w1_l2", 2, 8)
	assert_true(_lp.is_level_unlocked("w1_l3"))
	assert_eq(_next_unlocked_log.size(), 2)

	# w1_l3 — completes world 1, unlocks w2_l1
	_sr.rating_computed.emit("w1_l3", 1, 14)
	assert_true(_lp.is_level_unlocked("w2_l1"))
	assert_eq(_next_unlocked_log.size(), 3)
	assert_eq(_world_completed_log.size(), 1)
	assert_eq(_world_completed_log[0], 1)

	# w2_l1
	_sr.rating_computed.emit("w2_l1", 3, 5)
	assert_true(_lp.is_level_unlocked("w2_l2"))
	assert_eq(_next_unlocked_log.size(), 4)

	# w2_l2 — final level, completes world 2
	_sr.rating_computed.emit("w2_l2", 3, 5)
	assert_eq(_next_unlocked_log.size(), 4, "No unlock for final level.")
	assert_eq(_world_completed_log.size(), 2)
	assert_eq(_world_completed_log[1], 2)

	# All 5 levels should be recorded
	assert_eq(_record_saved_log.size(), 5)
