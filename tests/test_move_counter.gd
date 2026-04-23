## Unit tests for MoveCounter gameplay node.
## Task: S1-08
## Covers: initialize_level, increment counting, set_move_count,
##         reset_move_count, freeze, explicit move-dispatch API, edge cases.
##
## Acceptance criteria: MC-1 through MC-9 from design/gdd/move-counter.md
extends GutTest

var _mc: Node

# Signal tracking
var _move_count_log: Array = []


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_mc = load("res://src/gameplay/move_counter.gd").new()
	add_child_autofree(_mc)

	_move_count_log.clear()
	_mc.move_count_changed.connect(_on_move_count_changed)


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_move_count_changed(current: int, minimum: int) -> void:
	_move_count_log.append({"current": current, "minimum": minimum})


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Builds a minimal LevelData with specified move thresholds.
func _make_level_data(
	min_moves: int = 8,
	star_3: int = 8,
	star_2: int = 10,
	star_1: int = 14,
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = "test_mc"
	ld.grid_width = 5
	ld.grid_height = 5
	ld.walkability_tiles = PackedInt32Array()
	ld.walkability_tiles.resize(25)
	ld.walkability_tiles.fill(0)
	ld.obstacle_tiles = PackedInt32Array()
	ld.obstacle_tiles.resize(25)
	ld.obstacle_tiles.fill(0)
	ld.cat_start = Vector2i(1, 1)
	ld.minimum_moves = min_moves
	ld.star_3_moves = star_3
	ld.star_2_moves = star_2
	ld.star_1_moves = star_1
	return ld


## Simulates a coordinator-dispatched move with dummy data.
func _simulate_slide() -> void:
	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_mc.increment(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles
	)


# —————————————————————————————————————————————
# Tests — MC-1: Initialization
# —————————————————————————————————————————————

func test_move_counter_initialize_sets_zero_moves() -> void:
	var ld := _make_level_data(8)
	_mc.initialize_level(ld)

	assert_eq(_mc.get_current_moves(), 0)
	assert_eq(_mc.get_minimum_moves(), 8)


func test_move_counter_initialize_caches_star_thresholds() -> void:
	var ld := _make_level_data(8, 8, 10, 14)
	_mc.initialize_level(ld)

	assert_eq(_mc.get_star_3_moves(), 8)
	assert_eq(_mc.get_star_2_moves(), 10)
	assert_eq(_mc.get_star_1_moves(), 14)


func test_move_counter_initialize_emits_signal() -> void:
	var ld := _make_level_data(8)
	_mc.initialize_level(ld)

	assert_eq(_move_count_log.size(), 1)
	assert_eq(_move_count_log[0]["current"], 0)
	assert_eq(_move_count_log[0]["minimum"], 8)


func test_move_counter_initialize_unfreezes() -> void:
	var ld := _make_level_data(8)
	_mc.initialize_level(ld)
	_mc.freeze()
	assert_true(_mc.is_frozen())

	_mc.initialize_level(ld)
	assert_false(_mc.is_frozen())


# —————————————————————————————————————————————
# Tests — MC-2: Slide counting
# —————————————————————————————————————————————

func test_move_counter_slide_increments_by_one() -> void:
	_mc.initialize_level(_make_level_data())
	_move_count_log.clear()

	_simulate_slide()
	assert_eq(_mc.get_current_moves(), 1)


func test_move_counter_slide_emits_signal() -> void:
	_mc.initialize_level(_make_level_data(8))
	_move_count_log.clear()

	_simulate_slide()
	assert_eq(_move_count_log.size(), 1)
	assert_eq(_move_count_log[0]["current"], 1)
	assert_eq(_move_count_log[0]["minimum"], 8)


func test_move_counter_multiple_slides_count_correctly() -> void:
	_mc.initialize_level(_make_level_data())
	_move_count_log.clear()

	_simulate_slide()
	_simulate_slide()
	_simulate_slide()

	assert_eq(_mc.get_current_moves(), 3)
	assert_eq(_move_count_log.size(), 3)
	assert_eq(_move_count_log[0]["current"], 1)
	assert_eq(_move_count_log[1]["current"], 2)
	assert_eq(_move_count_log[2]["current"], 3)


# —————————————————————————————————————————————
# Tests — MC-9: Signal fires exactly once per slide
# —————————————————————————————————————————————

func test_move_counter_signal_fires_exactly_once_per_slide() -> void:
	_mc.initialize_level(_make_level_data())
	_move_count_log.clear()

	_simulate_slide()
	assert_eq(_move_count_log.size(), 1)

	_simulate_slide()
	assert_eq(_move_count_log.size(), 2)


# —————————————————————————————————————————————
# Tests — MC-4: set_move_count (undo)
# —————————————————————————————————————————————

func test_move_counter_set_move_count_rewinds() -> void:
	_mc.initialize_level(_make_level_data(8))
	_simulate_slide()
	_simulate_slide()
	_simulate_slide()
	assert_eq(_mc.get_current_moves(), 3)

	_move_count_log.clear()
	_mc.set_move_count(1)
	assert_eq(_mc.get_current_moves(), 1)
	assert_eq(_move_count_log.size(), 1)
	assert_eq(_move_count_log[0]["current"], 1)
	assert_eq(_move_count_log[0]["minimum"], 8)


func test_move_counter_set_move_count_to_zero() -> void:
	_mc.initialize_level(_make_level_data())
	_simulate_slide()
	_simulate_slide()

	_mc.set_move_count(0)
	assert_eq(_mc.get_current_moves(), 0)


# —————————————————————————————————————————————
# Tests — MC-8: set_move_count with n > current clamps
# —————————————————————————————————————————————

func test_move_counter_set_above_current_clamps() -> void:
	_mc.initialize_level(_make_level_data())
	_simulate_slide()
	assert_eq(_mc.get_current_moves(), 1)

	_move_count_log.clear()
	_mc.set_move_count(5) # Should warn and not increase
	assert_eq(_mc.get_current_moves(), 1) # Unchanged
	assert_eq(_move_count_log.size(), 0) # No signal emitted


func test_move_counter_set_negative_clamps_to_zero() -> void:
	_mc.initialize_level(_make_level_data())
	_simulate_slide()
	_simulate_slide()
	assert_eq(_mc.get_current_moves(), 2)

	_move_count_log.clear()
	_mc.set_move_count(-1) # Should warn and clamp to 0
	assert_eq(_mc.get_current_moves(), 0)
	assert_eq(_move_count_log.size(), 1)
	assert_eq(_move_count_log[0]["current"], 0)


# —————————————————————————————————————————————
# Tests — MC-5: reset_move_count
# —————————————————————————————————————————————

func test_move_counter_reset_clears_count() -> void:
	_mc.initialize_level(_make_level_data(8))
	_simulate_slide()
	_simulate_slide()
	assert_eq(_mc.get_current_moves(), 2)

	_move_count_log.clear()
	_mc.reset_move_count()
	assert_eq(_mc.get_current_moves(), 0)
	assert_eq(_move_count_log.size(), 1)
	assert_eq(_move_count_log[0]["current"], 0)
	assert_eq(_move_count_log[0]["minimum"], 8)


func test_move_counter_reset_unfreezes() -> void:
	_mc.initialize_level(_make_level_data())
	_simulate_slide()
	_mc.freeze()
	assert_true(_mc.is_frozen())

	_mc.reset_move_count()
	assert_false(_mc.is_frozen())


# —————————————————————————————————————————————
# Tests — MC-6: get_final_move_count
# —————————————————————————————————————————————

func test_move_counter_final_count_equals_current() -> void:
	_mc.initialize_level(_make_level_data())
	_simulate_slide()
	_simulate_slide()
	_simulate_slide()

	assert_eq(_mc.get_final_move_count(), 3)
	assert_eq(_mc.get_final_move_count(), _mc.get_current_moves())


# —————————————————————————————————————————————
# Tests — MC-7: minimum_moves == 0 (unsolved level)
# —————————————————————————————————————————————

func test_move_counter_zero_minimum_moves_no_crash() -> void:
	var ld := _make_level_data(0, 0, 0, 0)
	_mc.initialize_level(ld)

	assert_eq(_mc.get_minimum_moves(), 0)
	assert_eq(_move_count_log[0]["minimum"], 0)


func test_move_counter_zero_minimum_slides_still_count() -> void:
	_mc.initialize_level(_make_level_data(0, 0, 0, 0))
	_move_count_log.clear()

	_simulate_slide()
	assert_eq(_mc.get_current_moves(), 1)
	assert_eq(_move_count_log[0]["minimum"], 0)


# —————————————————————————————————————————————
# Tests — Freeze (level_completed)
# —————————————————————————————————————————————

func test_move_counter_frozen_ignores_slides() -> void:
	_mc.initialize_level(_make_level_data())
	_simulate_slide()
	_simulate_slide()
	_mc.freeze()

	_move_count_log.clear()
	_simulate_slide() # Should be ignored

	assert_eq(_mc.get_current_moves(), 2) # Unchanged
	assert_eq(_move_count_log.size(), 0) # No signal


func test_move_counter_freeze_preserves_count() -> void:
	_mc.initialize_level(_make_level_data())
	_simulate_slide()
	_simulate_slide()
	_simulate_slide()
	_mc.freeze()

	assert_eq(_mc.get_final_move_count(), 3)
	assert_true(_mc.is_frozen())


# —————————————————————————————————————————————
# Tests — set_move_count unfreezes
# —————————————————————————————————————————————

func test_move_counter_set_move_count_unfreezes() -> void:
	_mc.initialize_level(_make_level_data())
	_simulate_slide()
	_simulate_slide()
	_mc.freeze()

	_mc.set_move_count(1)
	assert_false(_mc.is_frozen())

	_simulate_slide()
	assert_eq(_mc.get_current_moves(), 2)


# —————————————————————————————————————————————
# Tests — explicit move-dispatch API
# —————————————————————————————————————————————

func test_move_counter_increment_api_counts_once() -> void:
	_mc.initialize_level(_make_level_data())
	_move_count_log.clear()

	var tiles: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1)]
	_mc.increment(Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0), tiles)

	assert_eq(_mc.get_current_moves(), 1)
	assert_eq(_move_count_log.size(), 1)


func test_move_counter_increment_api_called_twice_counts_twice() -> void:
	_mc.initialize_level(_make_level_data())
	_move_count_log.clear()

	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_mc.increment(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)
	_mc.increment(Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 0), tiles)

	assert_eq(_mc.get_current_moves(), 2)
	assert_eq(_move_count_log.size(), 2)


func test_move_counter_increment_ignores_payload_shape() -> void:
	_mc.initialize_level(_make_level_data())
	_move_count_log.clear()

	# Empty tile list still represents one completed move for counting.
	var empty_tiles: Array[Vector2i] = []
	_mc.increment(Vector2i(1, 1), Vector2i(1, 1), Vector2i.ZERO, empty_tiles)
	assert_eq(_mc.get_current_moves(), 1)
	assert_eq(_move_count_log.size(), 1)


# —————————————————————————————————————————————
# Tests — Edge cases
# —————————————————————————————————————————————

func test_move_counter_default_state_before_initialize() -> void:
	assert_eq(_mc.get_current_moves(), 0)
	assert_eq(_mc.get_minimum_moves(), 0)
	assert_false(_mc.is_frozen())


func test_move_counter_null_level_data_no_crash() -> void:
	_mc.initialize_level(null)
	assert_eq(_mc.get_current_moves(), 0)
	assert_eq(_mc.get_minimum_moves(), 0)
	assert_eq(_move_count_log.size(), 1)


func test_move_counter_double_initialize_resets() -> void:
	_mc.initialize_level(_make_level_data(8))
	_simulate_slide()
	_simulate_slide()
	assert_eq(_mc.get_current_moves(), 2)

	_mc.initialize_level(_make_level_data(5, 5, 7, 10))
	assert_eq(_mc.get_current_moves(), 0)
	assert_eq(_mc.get_minimum_moves(), 5)


func test_move_counter_many_slides() -> void:
	_mc.initialize_level(_make_level_data())
	for i in range(50):
		_simulate_slide()
	assert_eq(_mc.get_current_moves(), 50)
