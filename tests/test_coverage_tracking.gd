## Unit tests for CoverageTracking gameplay node.
## Task: S1-07
## Covers: initialize_level, spawn marking, slide coverage, level_completed,
##         snapshot/restore, reset, state transitions, edge cases.
##
## Acceptance criteria: CT-1 through CT-9 from design/gdd/coverage-tracking.md
extends GutTest

var _ct: Node

# Signal tracking
var _tile_covered_log: Array[Vector2i] = []
var _tile_uncovered_log: Array[Vector2i] = []
var _coverage_updated_log: Array = []
var _level_completed_count: int = 0


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	# Default: load a 5×5 bordered grid (9 interior walkable tiles)
	GridSystem.load_grid(_make_5x5_bordered())

	_ct = load("res://src/gameplay/coverage_tracking.gd").new()
	add_child_autofree(_ct)

	_tile_covered_log.clear()
	_tile_uncovered_log.clear()
	_coverage_updated_log.clear()
	_level_completed_count = 0

	_ct.tile_covered.connect(_on_tile_covered)
	_ct.tile_uncovered.connect(_on_tile_uncovered)
	_ct.coverage_updated.connect(_on_coverage_updated)
	_ct.level_completed.connect(_on_level_completed)


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_tile_covered(coord: Vector2i) -> void:
	_tile_covered_log.append(coord)

func _on_tile_uncovered(coord: Vector2i) -> void:
	_tile_uncovered_log.append(coord)

func _on_coverage_updated(covered: int, total: int) -> void:
	_coverage_updated_log.append({"covered": covered, "total": total})

func _on_level_completed() -> void:
	_level_completed_count += 1


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Builds a minimal LevelData for a width×height grid.
func _make_level(
	width: int,
	height: int,
	walkability: PackedInt32Array,
	obstacles: PackedInt32Array = PackedInt32Array(),
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = "test_level"
	ld.grid_width = width
	ld.grid_height = height
	ld.walkability_tiles = walkability
	if obstacles.is_empty():
		obstacles.resize(walkability.size())
		obstacles.fill(0)
	ld.obstacle_tiles = obstacles
	ld.cat_start = Vector2i(1, 1)
	return ld


## 5×5 bordered grid: 9 interior walkable tiles.
## Walkable: (1,1) (2,1) (3,1) (1,2) (2,2) (3,2) (1,3) (2,3) (3,3)
func _make_5x5_bordered() -> LevelData:
	var w: int = 5
	var h: int = 5
	var walk := PackedInt32Array()
	walk.resize(w * h)
	for row in range(h):
		for col in range(w):
			var is_border: bool = (row == 0 or row == h - 1 or col == 0 or col == w - 1)
			walk[col + row * w] = 1 if is_border else 0
	var obs := PackedInt32Array()
	obs.resize(w * h)
	obs.fill(0)
	return _make_level(w, h, walk, obs)


## 4×3 grid with exactly 2 walkable tiles at (1,1) and (2,1).
func _make_2_tile_level() -> LevelData:
	var w: int = 4
	var h: int = 3
	var walk := PackedInt32Array()
	walk.resize(w * h)
	walk.fill(1) # All blocking
	walk[1 + 1 * w] = 0 # (1,1) walkable
	walk[2 + 1 * w] = 0 # (2,1) walkable
	var obs := PackedInt32Array()
	obs.resize(w * h)
	obs.fill(0)
	return _make_level(w, h, walk, obs)


## 3×3 grid with exactly 1 walkable tile at (1,1).
func _make_1_tile_level() -> LevelData:
	var w: int = 3
	var h: int = 3
	var walk := PackedInt32Array()
	walk.resize(w * h)
	walk.fill(1) # All blocking
	walk[1 + 1 * w] = 0 # Only (1,1) is walkable
	var obs := PackedInt32Array()
	obs.resize(w * h)
	obs.fill(0)
	return _make_level(w, h, walk, obs)


# —————————————————————————————————————————————
# Tests — CT-1: Initialization
# —————————————————————————————————————————————

func test_coverage_tracking_initialize_sets_all_tiles_uncovered() -> void:
	# Arrange (grid loaded in before_each)
	# Act
	_ct.initialize_level()
	# Assert
	assert_eq(_ct.get_covered_count(), 0)
	assert_eq(_ct.get_total_walkable(), 9)
	assert_eq(_ct.get_coverage_percent(), 0.0)
	assert_eq(_ct.get_state(), 1) # State.TRACKING


func test_coverage_tracking_initialize_coverage_map_matches_grid() -> void:
	_ct.initialize_level()
	var walkable: Array[Vector2i] = GridSystem.get_all_walkable_tiles()
	var snapshot: Dictionary = _ct.get_coverage_snapshot()
	# Every walkable tile should be in the map as false
	assert_eq(snapshot.size(), walkable.size())
	for tile in walkable:
		assert_true(snapshot.has(tile), "Tile %s should be in coverage_map" % str(tile))
		assert_false(snapshot[tile], "Tile %s should start uncovered" % str(tile))


func test_coverage_tracking_default_state_is_uninitialized() -> void:
	assert_eq(_ct.get_state(), 0) # State.UNINITIALIZED
	assert_eq(_ct.get_covered_count(), 0)
	assert_eq(_ct.get_total_walkable(), 0)
	assert_eq(_ct.get_coverage_percent(), 0.0)


# —————————————————————————————————————————————
# Tests — CT-2: Starting tile (spawn_position_set)
# —————————————————————————————————————————————

func test_coverage_tracking_spawn_marks_tile_covered() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	assert_eq(_ct.get_covered_count(), 1)
	assert_true(_ct.is_tile_covered(Vector2i(1, 1)))


func test_coverage_tracking_spawn_emits_tile_covered() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(2, 2))
	assert_eq(_tile_covered_log.size(), 1)
	assert_eq(_tile_covered_log[0], Vector2i(2, 2))


func test_coverage_tracking_spawn_emits_coverage_updated() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	assert_eq(_coverage_updated_log.size(), 1)
	assert_eq(_coverage_updated_log[0]["covered"], 1)
	assert_eq(_coverage_updated_log[0]["total"], 9)


# —————————————————————————————————————————————
# Tests — CT-3: Per-slide coverage (new tiles)
# —————————————————————————————————————————————

func test_coverage_tracking_slide_covers_new_tiles() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	_tile_covered_log.clear()
	_coverage_updated_log.clear()

	# Simulate slide right: (1,1) → (3,1) covering [2,1], [3,1]
	var tiles: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0), tiles)

	assert_eq(_ct.get_covered_count(), 3) # 1 spawn + 2 slide
	assert_eq(_tile_covered_log.size(), 2)
	assert_eq(_tile_covered_log[0], Vector2i(2, 1))
	assert_eq(_tile_covered_log[1], Vector2i(3, 1))


func test_coverage_tracking_slide_emits_one_coverage_updated() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	_coverage_updated_log.clear()

	var tiles: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0), tiles)

	# coverage_updated should fire once per slide_completed, not per tile
	assert_eq(_coverage_updated_log.size(), 1)
	assert_eq(_coverage_updated_log[0]["covered"], 3)
	assert_eq(_coverage_updated_log[0]["total"], 9)


func test_coverage_tracking_coverage_percent_correct() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	# 1/9 covered
	assert_almost_eq(_ct.get_coverage_percent(), 100.0 / 9.0, 0.01)

	var tiles: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0), tiles)
	# 3/9 covered
	assert_almost_eq(_ct.get_coverage_percent(), 300.0 / 9.0, 0.01)


# —————————————————————————————————————————————
# Tests — CT-4: Revisiting already-covered tiles (idempotent)
# —————————————————————————————————————————————

func test_coverage_tracking_revisit_does_not_double_count() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	_tile_covered_log.clear()

	# Slide covers (2,1), then a second slide also covers (2,1) again
	var tiles_1: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles_1)
	assert_eq(_ct.get_covered_count(), 2)

	_tile_covered_log.clear()
	var tiles_2: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(2, 1), Vector2i(2, 1), Vector2i(-1, 0), tiles_2)
	assert_eq(_ct.get_covered_count(), 2) # No increase
	assert_eq(_tile_covered_log.size(), 0) # No tile_covered emitted


func test_coverage_tracking_mixed_new_and_revisited_tiles() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	_tile_covered_log.clear()

	# Slide covers (2,1) — new
	var tiles_1: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles_1)
	assert_eq(_ct.get_covered_count(), 2)

	_tile_covered_log.clear()
	# Slide covers (1,1) old, (2,1) old, (3,1) new
	var tiles_2: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0), tiles_2)
	assert_eq(_ct.get_covered_count(), 3) # Only 1 new tile
	assert_eq(_tile_covered_log.size(), 1) # Only (3,1)
	assert_eq(_tile_covered_log[0], Vector2i(3, 1))


# —————————————————————————————————————————————
# Tests — CT-5: Level completion
# —————————————————————————————————————————————

func test_coverage_tracking_level_completed_at_100_percent() -> void:
	# Use 2-tile level for simple completion
	GridSystem.load_grid(_make_2_tile_level())
	_ct.initialize_level()
	assert_eq(_ct.get_total_walkable(), 2)

	_ct.on_spawn_position_set(Vector2i(1, 1))
	assert_eq(_level_completed_count, 0) # Not complete yet

	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)
	assert_eq(_ct.get_covered_count(), 2)
	assert_eq(_level_completed_count, 1)
	assert_eq(_ct.get_state(), 2) # State.COMPLETE


func test_coverage_tracking_level_completed_emits_exactly_once() -> void:
	GridSystem.load_grid(_make_2_tile_level())
	_ct.initialize_level()

	_ct.on_spawn_position_set(Vector2i(1, 1))
	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)
	assert_eq(_level_completed_count, 1)


# —————————————————————————————————————————————
# Tests — CT-6: No duplicate level_completed after completion
# —————————————————————————————————————————————

func test_coverage_tracking_no_reemit_after_complete() -> void:
	GridSystem.load_grid(_make_2_tile_level())
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))

	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)
	assert_eq(_level_completed_count, 1)

	# Send another slide — should be ignored (COMPLETE state)
	var tiles_2: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(2, 1), Vector2i(2, 1), Vector2i(-1, 0), tiles_2)
	assert_eq(_level_completed_count, 1) # Still 1


# —————————————————————————————————————————————
# Tests — CT-7: Snapshot is deep copy
# —————————————————————————————————————————————

func test_coverage_tracking_snapshot_is_deep_copy() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))

	var snapshot: Dictionary = _ct.get_coverage_snapshot()

	# Mutate the snapshot
	snapshot[Vector2i(2, 2)] = true

	# Live map should NOT be affected
	assert_false(_ct.is_tile_covered(Vector2i(2, 2)))


func test_coverage_tracking_snapshot_captures_current_state() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))

	var snapshot: Dictionary = _ct.get_coverage_snapshot()
	assert_true(snapshot[Vector2i(1, 1)])
	assert_false(snapshot[Vector2i(2, 2)])


# —————————————————————————————————————————————
# Tests — CT-8: restore_coverage_snapshot
# —————————————————————————————————————————————

func test_coverage_tracking_restore_snapshot_resets_to_saved_state() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))

	# Save state: 1 tile covered
	var snapshot: Dictionary = _ct.get_coverage_snapshot()

	# Advance coverage further
	var tiles: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0), tiles)
	assert_eq(_ct.get_covered_count(), 3)

	# Restore
	_ct.restore_coverage_snapshot(snapshot)
	assert_eq(_ct.get_covered_count(), 1)
	assert_true(_ct.is_tile_covered(Vector2i(1, 1)))
	assert_false(_ct.is_tile_covered(Vector2i(2, 1)))
	assert_false(_ct.is_tile_covered(Vector2i(3, 1)))


func test_coverage_tracking_restore_emits_tile_uncovered() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	var snapshot: Dictionary = _ct.get_coverage_snapshot()

	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)

	_tile_uncovered_log.clear()
	_ct.restore_coverage_snapshot(snapshot)

	assert_eq(_tile_uncovered_log.size(), 1)
	assert_eq(_tile_uncovered_log[0], Vector2i(2, 1))


func test_coverage_tracking_restore_emits_coverage_updated() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	var snapshot: Dictionary = _ct.get_coverage_snapshot()

	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)

	_coverage_updated_log.clear()
	_ct.restore_coverage_snapshot(snapshot)

	assert_eq(_coverage_updated_log.size(), 1)
	assert_eq(_coverage_updated_log[0]["covered"], 1)
	assert_eq(_coverage_updated_log[0]["total"], 9)


func test_coverage_tracking_restore_returns_state_to_tracking() -> void:
	# Complete a 2-tile level, then restore to 1-tile snapshot
	GridSystem.load_grid(_make_2_tile_level())
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	var snapshot: Dictionary = _ct.get_coverage_snapshot()

	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)
	assert_eq(_ct.get_state(), 2) # COMPLETE

	_ct.restore_coverage_snapshot(snapshot)
	assert_eq(_ct.get_state(), 1) # TRACKING — no longer complete


# —————————————————————————————————————————————
# Tests — CT-9: reset_coverage
# —————————————————————————————————————————————

func test_coverage_tracking_reset_clears_all_coverage() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	var tiles: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0), tiles)
	assert_eq(_ct.get_covered_count(), 3)

	_ct.reset_coverage()
	assert_eq(_ct.get_covered_count(), 0)
	assert_eq(_ct.get_total_walkable(), 9)
	assert_eq(_ct.get_state(), 1) # TRACKING

	var snapshot: Dictionary = _ct.get_coverage_snapshot()
	for val in snapshot.values():
		assert_false(val)


func test_coverage_tracking_reset_from_uninitialized_is_noop() -> void:
	# Should not crash or change state
	_ct.reset_coverage()
	assert_eq(_ct.get_state(), 0) # UNINITIALIZED
	assert_eq(_ct.get_covered_count(), 0)


# —————————————————————————————————————————————
# Tests — State transitions
# —————————————————————————————————————————————

func test_coverage_tracking_state_uninitialized_to_tracking() -> void:
	assert_eq(_ct.get_state(), 0) # UNINITIALIZED
	_ct.initialize_level()
	assert_eq(_ct.get_state(), 1) # TRACKING


func test_coverage_tracking_state_tracking_to_complete() -> void:
	GridSystem.load_grid(_make_2_tile_level())
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))

	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)
	assert_eq(_ct.get_state(), 2) # COMPLETE


func test_coverage_tracking_state_complete_to_tracking_via_reset() -> void:
	GridSystem.load_grid(_make_2_tile_level())
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)
	assert_eq(_ct.get_state(), 2) # COMPLETE

	_ct.reset_coverage()
	assert_eq(_ct.get_state(), 1) # TRACKING


# —————————————————————————————————————————————
# Tests — Edge cases
# —————————————————————————————————————————————

func test_coverage_tracking_1_tile_level_completes_at_spawn() -> void:
	GridSystem.load_grid(_make_1_tile_level())
	_ct.initialize_level()
	assert_eq(_ct.get_total_walkable(), 1)

	_ct.on_spawn_position_set(Vector2i(1, 1))
	assert_eq(_ct.get_state(), 2) # COMPLETE
	assert_eq(_level_completed_count, 1)
	assert_almost_eq(_ct.get_coverage_percent(), 100.0, 0.01)


func test_coverage_tracking_spawn_before_initialize_is_warning() -> void:
	# Should not crash; warning logged
	_ct.on_spawn_position_set(Vector2i(1, 1))
	assert_eq(_ct.get_covered_count(), 0)
	assert_eq(_tile_covered_log.size(), 0)


func test_coverage_tracking_slide_before_initialize_is_warning() -> void:
	var tiles: Array[Vector2i] = [Vector2i(1, 1)]
	_ct.on_slide_completed(Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0), tiles)
	assert_eq(_ct.get_covered_count(), 0)
	assert_eq(_tile_covered_log.size(), 0)


func test_coverage_tracking_slide_in_complete_state_ignored() -> void:
	GridSystem.load_grid(_make_2_tile_level())
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	_ct.on_slide_completed(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)
	assert_eq(_ct.get_state(), 2) # COMPLETE

	_tile_covered_log.clear()
	_coverage_updated_log.clear()

	# This should be silently ignored
	var tiles_2: Array[Vector2i] = [Vector2i(1, 1)]
	_ct.on_slide_completed(Vector2i(2, 1), Vector2i(1, 1), Vector2i(-1, 0), tiles_2)
	assert_eq(_tile_covered_log.size(), 0)


# —————————————————————————————————————————————
# Tests — bind/unbind integration (new: double-bind guard)
# —————————————————————————————————————————————

func test_coverage_tracking_double_bind_does_not_double_count() -> void:
	# Arrange
	_ct.initialize_level()

	var sm: Node2D = load("res://src/gameplay/sliding_movement.gd").new()
	add_child_autofree(sm)
	_ct.bind_sliding_movement(sm)
	_ct.bind_sliding_movement(sm) # Second bind — should be idempotent

	# Act
	sm.spawn_position_set.emit(Vector2i(1, 1))
	var tiles: Array[Vector2i] = [Vector2i(2, 1)]
	sm.slide_completed.emit(Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0), tiles)

	# Assert — should only count once, not twice
	assert_eq(_ct.get_covered_count(), 2)
	assert_eq(_tile_covered_log.size(), 2)
	assert_eq(_coverage_updated_log.size(), 2) # One per event, not doubled

	_ct.unbind_sliding_movement(sm)


func test_coverage_tracking_double_spawn_idempotent() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	_ct.on_spawn_position_set(Vector2i(1, 1))
	assert_eq(_ct.get_covered_count(), 1)
	# tile_covered only emitted once (second spawn on same tile is idempotent)
	assert_eq(_tile_covered_log.size(), 1)


func test_coverage_tracking_double_initialize_resets() -> void:
	_ct.initialize_level()
	_ct.on_spawn_position_set(Vector2i(1, 1))
	assert_eq(_ct.get_covered_count(), 1)

	_ct.initialize_level()
	assert_eq(_ct.get_covered_count(), 0)
	assert_eq(_ct.get_state(), 1) # TRACKING


func test_coverage_tracking_is_tile_covered_nonexistent_returns_false() -> void:
	_ct.initialize_level()
	# Out-of-bounds tile should return false, not crash
	assert_false(_ct.is_tile_covered(Vector2i(99, 99)))


# —————————————————————————————————————————————
# Tests — bind_sliding_movement integration
# —————————————————————————————————————————————

func test_coverage_tracking_bind_connects_signals() -> void:
	# Create a SlidingMovement node and bind
	var sm: Node2D = load("res://src/gameplay/sliding_movement.gd").new()
	add_child_autofree(sm)
	InputSystem.set_accepting_input(true)

	_ct.initialize_level()
	_ct.bind_sliding_movement(sm)

	# Initialize level on SlidingMovement — should trigger spawn_position_set
	sm.initialize_level(Vector2i(1, 1))
	assert_eq(_ct.get_covered_count(), 1)
	assert_true(_ct.is_tile_covered(Vector2i(1, 1)))

	# Cleanup
	_ct.unbind_sliding_movement(sm)
	InputSystem.set_accepting_input(true)


func test_coverage_tracking_unbind_disconnects_signals() -> void:
	var sm: Node2D = load("res://src/gameplay/sliding_movement.gd").new()
	add_child_autofree(sm)
	InputSystem.set_accepting_input(true)

	_ct.initialize_level()
	_ct.bind_sliding_movement(sm)
	_ct.unbind_sliding_movement(sm)

	# After unbinding, initialize_level on SM should NOT affect coverage
	sm.initialize_level(Vector2i(2, 2))
	assert_eq(_ct.get_covered_count(), 0)

	InputSystem.set_accepting_input(true)
