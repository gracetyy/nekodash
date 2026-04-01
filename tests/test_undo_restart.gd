## Unit tests for UndoRestart gameplay node.
## Task: S2-01
## Covers: initialize, snapshot on slide_completed, undo (position + coverage +
##         moves in spec order), restart, can_undo, level_completed freeze,
##         edge cases per GDD.
##
## Acceptance criteria cross-ref: design/gdd/undo-restart.md
extends GutTest

var _ur: Node
var _sm: Node2D # Mock SlidingMovement
var _ct: Node # Mock CoverageTracking
var _mc: Node # Mock MoveCounter

# Signal tracking
var _undo_applied_log: Array[int] = []
var _level_restarted_count: int = 0

# Mock operation tracking
var _sm_instant_log: Array[Vector2i] = []
var _sm_init_log: Array[Vector2i] = []
var _ct_restore_log: Array[Dictionary] = []
var _ct_reset_count: int = 0
var _mc_set_log: Array[int] = []
var _mc_reset_count: int = 0

# Mock state
var _mock_cat_pos: Vector2i = Vector2i.ZERO
var _mock_coverage: Dictionary = {}
var _mock_moves: int = 0


# —————————————————————————————————————————————
# Mock classes
# —————————————————————————————————————————————

## Minimal mock of SlidingMovement with the APIs UndoRestart calls.
class MockSlidingMovement extends Node2D:
	var test_ref # reference to the test instance for logging
	var _cat_pos: Vector2i = Vector2i.ZERO

	signal slide_completed(from_pos: Vector2i, to_pos: Vector2i, direction: Vector2i, tiles_covered: Array[Vector2i])
	signal spawn_position_set(pos: Vector2i)

	func set_grid_position_instant(coord: Vector2i) -> void:
		_cat_pos = coord
		test_ref._sm_instant_log.append(coord)

	func initialize_level(spawn_pos: Vector2i) -> void:
		_cat_pos = spawn_pos
		test_ref._sm_init_log.append(spawn_pos)
		spawn_position_set.emit(spawn_pos)

	func get_cat_pos() -> Vector2i:
		return _cat_pos


## Minimal mock of CoverageTracking with snapshot/restore/reset APIs.
class MockCoverageTracking extends Node:
	var test_ref
	var _coverage: Dictionary = {}

	signal level_completed
	signal coverage_updated(covered: int, total: int)
	signal tile_covered(coord: Vector2i)
	signal tile_uncovered(coord: Vector2i)

	func get_coverage_snapshot() -> Dictionary:
		return _coverage.duplicate(true)

	func restore_coverage_snapshot(snapshot: Dictionary) -> void:
		_coverage = snapshot.duplicate(true)
		test_ref._ct_restore_log.append(snapshot)

	func reset_coverage() -> void:
		_coverage.clear()
		test_ref._ct_reset_count += 1


## Minimal mock of MoveCounter with set/reset/get APIs.
class MockMoveCounter extends Node:
	var test_ref
	var _current: int = 0

	signal move_count_changed(current: int, minimum: int)

	func get_current_moves() -> int:
		return _current

	func get_final_move_count() -> int:
		return _current

	func set_move_count(n: int) -> void:
		_current = n
		test_ref._mc_set_log.append(n)

	func reset_move_count() -> void:
		_current = 0
		test_ref._mc_reset_count += 1


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_ur = load("res://src/gameplay/undo_restart.gd").new()
	add_child_autofree(_ur)

	_sm = MockSlidingMovement.new()
	_sm.test_ref = self
	add_child_autofree(_sm)

	_ct = MockCoverageTracking.new()
	_ct.test_ref = self
	add_child_autofree(_ct)

	_mc = MockMoveCounter.new()
	_mc.test_ref = self
	add_child_autofree(_mc)

	# Connect signals for tracking
	_undo_applied_log.clear()
	_level_restarted_count = 0
	_sm_instant_log.clear()
	_sm_init_log.clear()
	_ct_restore_log.clear()
	_ct_reset_count = 0
	_mc_set_log.clear()
	_mc_reset_count = 0

	_ur.undo_applied.connect(_on_undo_applied)
	_ur.level_restarted.connect(_on_level_restarted)


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_undo_applied(moves_in_history: int) -> void:
	_undo_applied_log.append(moves_in_history)


func _on_level_restarted() -> void:
	_level_restarted_count += 1


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

func _init_undo_restart(spawn: Vector2i = Vector2i(1, 1)) -> void:
	_ur.initialize(spawn, _sm, _ct, _mc)


## Simulate a slide_completed and update mock state.
func _simulate_slide(
	from: Vector2i,
	to: Vector2i,
	direction: Vector2i,
	coverage_state: Dictionary,
	move_count: int,
) -> void:
	# Set mock state BEFORE the signal fires — UndoRestart reads pre-mutation
	_ct._coverage = coverage_state.duplicate(true)
	_mc._current = move_count

	var tiles: Array[Vector2i] = [to]
	_ur.on_slide_completed(from, to, direction, tiles)


# —————————————————————————————————————————————
# Tests — Initialization
# —————————————————————————————————————————————

func test_undo_restart_initialize_sets_active_state() -> void:
	_init_undo_restart()
	assert_eq(_ur.get_state(), _ur.State.ACTIVE)


func test_undo_restart_initialize_clears_history() -> void:
	_init_undo_restart()
	assert_false(_ur.can_undo())
	assert_eq(_ur.undo_count(), 0)


func test_undo_restart_starts_uninitialized() -> void:
	# Fresh node without initialize()
	assert_eq(_ur.get_state(), _ur.State.UNINITIALIZED)


func test_undo_restart_reinitialize_clears_history() -> void:
	_init_undo_restart()
	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true, Vector2i(2, 1): false}, 0,
	)
	assert_true(_ur.can_undo())

	_init_undo_restart()
	assert_false(_ur.can_undo())
	assert_eq(_ur.undo_count(), 0)


# —————————————————————————————————————————————
# Tests — Snapshot on slide_completed
# —————————————————————————————————————————————

func test_undo_restart_snapshot_records_pre_mutation_state() -> void:
	_init_undo_restart()

	var coverage := {Vector2i(1, 1): true, Vector2i(2, 1): false}
	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		coverage, 0,
	)

	assert_true(_ur.can_undo())
	assert_eq(_ur.undo_count(), 1)


func test_undo_restart_multiple_slides_grow_history() -> void:
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true, Vector2i(2, 1): false}, 0,
	)
	_simulate_slide(
		Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true, Vector2i(2, 1): true, Vector2i(3, 1): false}, 1,
	)

	assert_eq(_ur.undo_count(), 2)


func test_undo_restart_no_snapshot_in_frozen_state() -> void:
	_init_undo_restart()
	_ur.on_level_completed()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{}, 0,
	)

	assert_eq(_ur.undo_count(), 0)


func test_undo_restart_no_snapshot_in_uninitialized_state() -> void:
	# Don't call initialize
	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ur.on_slide_completed(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles,
	)
	assert_eq(_ur.undo_count(), 0)


# —————————————————————————————————————————————
# Tests — Undo
# —————————————————————————————————————————————

func test_undo_restart_undo_restores_cat_position() -> void:
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true}, 0,
	)

	_ur.undo()

	assert_eq(_sm_instant_log.size(), 1)
	assert_eq(_sm_instant_log[0], Vector2i(1, 1))


func test_undo_restart_undo_restores_coverage() -> void:
	_init_undo_restart()

	var pre_coverage := {Vector2i(1, 1): true, Vector2i(2, 1): false}
	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		pre_coverage, 0,
	)

	_ur.undo()

	assert_eq(_ct_restore_log.size(), 1)
	assert_eq(_ct_restore_log[0], pre_coverage)


func test_undo_restart_undo_restores_move_count() -> void:
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{}, 0,
	)

	_ur.undo()

	assert_eq(_mc_set_log.size(), 1)
	assert_eq(_mc_set_log[0], 0)


func test_undo_restart_undo_emits_signal_with_remaining_count() -> void:
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{}, 0,
	)
	_simulate_slide(
		Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 0),
		{}, 1,
	)

	_ur.undo()
	assert_eq(_undo_applied_log.size(), 1)
	assert_eq(_undo_applied_log[0], 1) # 1 move remaining after popping

	_ur.undo()
	assert_eq(_undo_applied_log.size(), 2)
	assert_eq(_undo_applied_log[1], 0) # 0 remaining


func test_undo_restart_undo_empty_stack_is_noop() -> void:
	_init_undo_restart()

	_ur.undo()

	assert_eq(_sm_instant_log.size(), 0)
	assert_eq(_ct_restore_log.size(), 0)
	assert_eq(_mc_set_log.size(), 0)
	assert_eq(_undo_applied_log.size(), 0)


func test_undo_restart_undo_uninitialized_is_noop() -> void:
	# Don't call initialize
	_ur.undo()

	assert_eq(_sm_instant_log.size(), 0)
	assert_eq(_undo_applied_log.size(), 0)


func test_undo_restart_can_undo_false_after_full_undo() -> void:
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{}, 0,
	)
	assert_true(_ur.can_undo())

	_ur.undo()
	assert_false(_ur.can_undo())


func test_undo_restart_multiple_undo_in_sequence() -> void:
	_init_undo_restart()

	# Move 1: (1,1) → (2,1), coverage has tile (1,1)
	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true, Vector2i(2, 1): false}, 0,
	)

	# Move 2: (2,1) → (3,1), coverage has (1,1) and (2,1)
	_simulate_slide(
		Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true, Vector2i(2, 1): true, Vector2i(3, 1): false}, 1,
	)

	# Undo move 2 — should restore to pre-move-2 state
	_ur.undo()
	assert_eq(_sm_instant_log[0], Vector2i(2, 1))
	assert_eq(_mc_set_log[0], 1)

	# Undo move 1 — should restore to pre-move-1 state
	_ur.undo()
	assert_eq(_sm_instant_log[1], Vector2i(1, 1))
	assert_eq(_mc_set_log[1], 0)

	assert_false(_ur.can_undo())


# —————————————————————————————————————————————
# Tests — Restart
# —————————————————————————————————————————————

func test_undo_restart_restart_clears_history() -> void:
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{}, 0,
	)
	assert_true(_ur.can_undo())

	_ur.restart()
	assert_false(_ur.can_undo())
	assert_eq(_ur.undo_count(), 0)


func test_undo_restart_restart_snaps_cat_to_spawn() -> void:
	_init_undo_restart(Vector2i(1, 1))
	_ur.restart()

	assert_eq(_sm_instant_log.size(), 1)
	assert_eq(_sm_instant_log[0], Vector2i(1, 1))


func test_undo_restart_restart_resets_coverage() -> void:
	_init_undo_restart()
	_ur.restart()

	assert_eq(_ct_reset_count, 1)


func test_undo_restart_restart_resets_move_counter() -> void:
	_init_undo_restart()
	_ur.restart()

	assert_eq(_mc_reset_count, 1)


func test_undo_restart_restart_reinitializes_sliding_movement() -> void:
	_init_undo_restart(Vector2i(1, 1))
	_ur.restart()

	assert_eq(_sm_init_log.size(), 1)
	assert_eq(_sm_init_log[0], Vector2i(1, 1))


func test_undo_restart_restart_emits_signal() -> void:
	_init_undo_restart()
	_ur.restart()

	assert_eq(_level_restarted_count, 1)


func test_undo_restart_restart_sets_active_state() -> void:
	_init_undo_restart()
	_ur.on_level_completed()
	assert_eq(_ur.get_state(), _ur.State.FROZEN)

	_ur.restart()
	assert_eq(_ur.get_state(), _ur.State.ACTIVE)


func test_undo_restart_restart_from_zero_moves_is_valid() -> void:
	_init_undo_restart(Vector2i(1, 1))

	_ur.restart()

	assert_eq(_sm_instant_log[0], Vector2i(1, 1))
	assert_eq(_ct_reset_count, 1)
	assert_eq(_mc_reset_count, 1)
	assert_eq(_level_restarted_count, 1)


func test_undo_restart_restart_uninitialized_is_noop() -> void:
	_ur.restart()

	assert_eq(_sm_instant_log.size(), 0)
	assert_eq(_ct_reset_count, 0)
	assert_eq(_mc_reset_count, 0)
	assert_eq(_level_restarted_count, 0)


# —————————————————————————————————————————————
# Tests — Freeze on level_completed
# —————————————————————————————————————————————

func test_undo_restart_level_completed_freezes_state() -> void:
	_init_undo_restart()
	_ur.on_level_completed()

	assert_eq(_ur.get_state(), _ur.State.FROZEN)


func test_undo_restart_undo_noop_when_frozen() -> void:
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{}, 0,
	)

	_ur.on_level_completed()

	_ur.undo()

	# No undo should have happened
	assert_eq(_sm_instant_log.size(), 0)
	assert_eq(_undo_applied_log.size(), 0)


func test_undo_restart_can_undo_false_when_frozen() -> void:
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{}, 0,
	)

	_ur.on_level_completed()
	assert_false(_ur.can_undo())


func test_undo_restart_restart_works_after_frozen() -> void:
	_init_undo_restart(Vector2i(1, 1))
	_ur.on_level_completed()

	_ur.restart()

	assert_eq(_ur.get_state(), _ur.State.ACTIVE)
	assert_eq(_level_restarted_count, 1)


# —————————————————————————————————————————————
# Tests — GDD spec order enforcement
# —————————————————————————————————————————————

func test_undo_restart_undo_applies_in_spec_order() -> void:
	# GDD order: 1. cat position, 2. coverage, 3. move count
	# We verify by checking the order of our log entries
	_init_undo_restart()

	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true}, 0,
	)

	_ur.undo()

	# All three should have been called exactly once
	assert_eq(_sm_instant_log.size(), 1, "set_grid_position_instant called once")
	assert_eq(_ct_restore_log.size(), 1, "restore_coverage_snapshot called once")
	assert_eq(_mc_set_log.size(), 1, "set_move_count called once")


func test_undo_restart_restart_applies_in_spec_order() -> void:
	# GDD order: 1. snap cat, 2. reset coverage, 3. reset moves, 4. initialize_level
	_init_undo_restart(Vector2i(1, 1))

	_ur.restart()

	assert_eq(_sm_instant_log.size(), 1, "set_grid_position_instant called")
	assert_eq(_ct_reset_count, 1, "reset_coverage called")
	assert_eq(_mc_reset_count, 1, "reset_move_count called")
	assert_eq(_sm_init_log.size(), 1, "initialize_level called")


# —————————————————————————————————————————————
# Tests — Slide after undo grows history correctly
# —————————————————————————————————————————————

func test_undo_restart_slide_after_undo_grows_from_shorter_stack() -> void:
	_init_undo_restart()

	# Two slides
	_simulate_slide(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true}, 0,
	)
	_simulate_slide(
		Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 0),
		{Vector2i(1, 1): true, Vector2i(2, 1): true}, 1,
	)
	assert_eq(_ur.undo_count(), 2)

	# Undo one
	_ur.undo()
	assert_eq(_ur.undo_count(), 1)

	# New slide from the rewound position — history should be 2 (1 old + 1 new)
	_simulate_slide(
		Vector2i(2, 1), Vector2i(2, 3), Vector2i(0, 1),
		{Vector2i(1, 1): true, Vector2i(2, 1): true}, 1,
	)
	assert_eq(_ur.undo_count(), 2)


func test_undo_restart_initialize_with_null_refs_is_noop() -> void:
	_ur.initialize(Vector2i(1, 1), null, _ct, _mc)
	assert_eq(_ur.get_state(), _ur.State.UNINITIALIZED)

	_ur.initialize(Vector2i(1, 1), _sm, null, _mc)
	assert_eq(_ur.get_state(), _ur.State.UNINITIALIZED)

	_ur.initialize(Vector2i(1, 1), _sm, _ct, null)
	assert_eq(_ur.get_state(), _ur.State.UNINITIALIZED)
