## Unit tests for StarRatingSystem gameplay node.
## Task: S2-02
## Covers: initialize_level, locked formula (3→2→1→0), sentinel (-1),
##         rating_computed fires once, edge cases per GDD.
##
## Acceptance criteria: SR-1 through SR-6 from design/gdd/star-rating-system.md
extends GutTest

var _sr: Node

# Signal tracking
var _rating_log: Array = []


# —————————————————————————————————————————————
# Mock — MoveCounter
# —————————————————————————————————————————————

class MockMoveCounter extends Node:
	var _final_moves: int = 0

	func get_final_move_count() -> int:
		return _final_moves

	func set_final(n: int) -> void:
		_final_moves = n


var _mock_mc: MockMoveCounter


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_sr = load("res://src/gameplay/star_rating_system.gd").new()
	add_child_autofree(_sr)

	_mock_mc = MockMoveCounter.new()
	add_child_autofree(_mock_mc)

	_rating_log.clear()
	_sr.rating_computed.connect(_on_rating_computed)


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_rating_computed(level_id: String, stars: int, final_moves: int) -> void:
	_rating_log.append({
		"level_id": level_id,
		"stars": stars,
		"final_moves": final_moves,
	})


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Builds a minimal LevelData with specified move thresholds.
func _make_level_data(
	min_moves: int = 8,
	star_3: int = 8,
	star_2: int = 10,
	star_1: int = 14,
	id: String = "test_sr",
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = id
	ld.world_id = 1
	ld.level_index = 1
	ld.display_name = "Test Level"
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


func _init_star_rating(ld: LevelData = null) -> void:
	if ld == null:
		ld = _make_level_data()
	_sr.initialize_level(ld, _mock_mc)


# —————————————————————————————————————————————
# Tests — SR-1: rating_computed fires exactly once
# —————————————————————————————————————————————

func test_star_rating_fires_once_per_attempt() -> void:
	_init_star_rating()
	_mock_mc.set_final(8)

	_sr.on_level_completed()
	_sr.on_level_completed() # duplicate call

	assert_eq(_rating_log.size(), 1, "rating_computed should fire exactly once")


func test_star_rating_fires_again_after_reinitialize() -> void:
	_init_star_rating()
	_mock_mc.set_final(8)
	_sr.on_level_completed()

	# Re-initialize for a new attempt
	_init_star_rating()
	_mock_mc.set_final(10)
	_sr.on_level_completed()

	assert_eq(_rating_log.size(), 2)
	assert_eq(_rating_log[0]["stars"], 3)
	assert_eq(_rating_log[1]["stars"], 2)


# —————————————————————————————————————————————
# Tests — SR-2: 3-star rating (optimal play)
# —————————————————————————————————————————————

func test_star_rating_3_stars_at_minimum() -> void:
	# star_3_moves = 8 (== minimum_moves)
	_init_star_rating(_make_level_data(8, 8, 10, 14))
	_mock_mc.set_final(8)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 3)
	assert_eq(_sr.get_current_rating(), 3)


func test_star_rating_3_stars_below_minimum() -> void:
	# Edge case: player somehow finishes below star_3 (shouldn't happen
	# normally, but formula should still award 3 stars)
	_init_star_rating(_make_level_data(8, 8, 10, 14))
	_mock_mc.set_final(7)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 3)


# —————————————————————————————————————————————
# Tests — SR-3: 2-star rating
# —————————————————————————————————————————————

func test_star_rating_2_stars_at_star_3_plus_one() -> void:
	# star_3 = 8, star_2 = 10 → 9 moves = 2 stars
	_init_star_rating(_make_level_data(8, 8, 10, 14))
	_mock_mc.set_final(9)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 2)


func test_star_rating_2_stars_at_star_2_boundary() -> void:
	# star_2 = 10 → exactly 10 moves = 2 stars
	_init_star_rating(_make_level_data(8, 8, 10, 14))
	_mock_mc.set_final(10)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 2)


# —————————————————————————————————————————————
# Tests — SR-4: 1-star rating
# —————————————————————————————————————————————

func test_star_rating_1_star_at_star_2_plus_one() -> void:
	# star_2 = 10, star_1 = 14 → 11 moves = 1 star
	_init_star_rating(_make_level_data(8, 8, 10, 14))
	_mock_mc.set_final(11)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 1)


func test_star_rating_1_star_at_star_1_boundary() -> void:
	# star_1 = 14 → exactly 14 moves = 1 star
	_init_star_rating(_make_level_data(8, 8, 10, 14))
	_mock_mc.set_final(14)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 1)


# —————————————————————————————————————————————
# Tests — SR-5: 0-star rating (completion above all thresholds)
# —————————————————————————————————————————————

func test_star_rating_0_stars_above_star_1() -> void:
	# star_1 = 14 → 15 moves = 0 stars
	_init_star_rating(_make_level_data(8, 8, 10, 14))
	_mock_mc.set_final(15)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 0)


func test_star_rating_0_stars_very_high_moves() -> void:
	_init_star_rating(_make_level_data(8, 8, 10, 14))
	_mock_mc.set_final(100)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 0)


# —————————————————————————————————————————————
# Tests — SR-6: Sentinel (-1) for unsolved levels
# —————————————————————————————————————————————

func test_star_rating_sentinel_when_minimum_zero() -> void:
	# minimum_moves = 0 → in-development level
	_init_star_rating(_make_level_data(0, 0, 0, 0))
	_mock_mc.set_final(5)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], -1)
	assert_eq(_rating_log[0]["final_moves"], 5)
	assert_eq(_sr.get_current_rating(), -1)


# —————————————————————————————————————————————
# Tests — Initialization
# —————————————————————————————————————————————

func test_star_rating_initialize_caches_thresholds() -> void:
	var ld := _make_level_data(8, 8, 10, 14)
	_sr.initialize_level(ld, _mock_mc)

	assert_eq(_sr.get_star_3_moves(), 8)
	assert_eq(_sr.get_star_2_moves(), 10)
	assert_eq(_sr.get_star_1_moves(), 14)


func test_star_rating_initialize_resets_current_rating() -> void:
	_init_star_rating()
	_mock_mc.set_final(8)
	_sr.on_level_completed()
	assert_eq(_sr.get_current_rating(), 3)

	_init_star_rating()
	assert_eq(_sr.get_current_rating(), -1)


func test_star_rating_emits_correct_level_id() -> void:
	_init_star_rating(_make_level_data(8, 8, 10, 14, "w2_l5"))
	_mock_mc.set_final(8)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["level_id"], "w2_l5")


func test_star_rating_emits_correct_final_moves() -> void:
	_init_star_rating()
	_mock_mc.set_final(12)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["final_moves"], 12)


# —————————————————————————————————————————————
# Tests — Edge cases
# —————————————————————————————————————————————

func test_star_rating_star_3_equals_star_2_boundary() -> void:
	# star_3 == star_2: only exact minimum gets 3 stars, one above gets 1
	var ld := _make_level_data(5, 5, 5, 8)
	_sr.initialize_level(ld, _mock_mc)
	_mock_mc.set_final(5)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 3)


func test_star_rating_star_3_equals_star_2_one_above() -> void:
	# star_3 == star_2 == 5: 6 moves falls through 3-star AND 2-star
	var ld := _make_level_data(5, 5, 5, 8)
	_sr.initialize_level(ld, _mock_mc)
	_mock_mc.set_final(6)

	_sr.on_level_completed()

	assert_eq(_rating_log[0]["stars"], 1)


func test_star_rating_no_fire_without_level_completed() -> void:
	_init_star_rating()
	_mock_mc.set_final(8)

	# Don't call on_level_completed
	assert_eq(_rating_log.size(), 0)
	assert_eq(_sr.get_current_rating(), -1)


func test_star_rating_on_level_completed_before_initialize_is_noop() -> void:
	# Don't call initialize_level — _move_counter is null
	_sr.on_level_completed()

	assert_eq(_rating_log.size(), 0)
	assert_eq(_sr.get_current_rating(), -1)


func test_star_rating_initialize_with_null_move_counter_is_noop() -> void:
	var ld := _make_level_data()
	_sr.initialize_level(ld, null)

	# Thresholds should NOT have been cached (early return)
	assert_eq(_sr.get_current_rating(), -1)
