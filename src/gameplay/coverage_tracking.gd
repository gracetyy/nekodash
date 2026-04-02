## CoverageTracking — pure state tracker for tile coverage.
## Implements: design/gdd/coverage-tracking.md
## Task: S1-07
##
## Tracks which walkable tiles have been visited during the current level
## attempt. Subscribes to SlidingMovement's spawn_position_set and
## slide_completed signals to mark newly covered tiles. Emits tile_covered
## per new tile, coverage_updated per event, and level_completed at 100%.
##
## Coverage is monotonically increasing within a single attempt: tiles once
## covered cannot be uncovered except by Undo or Restart (via snapshot API).
##
## Usage:
##   coverage_tracking.initialize_level()
##   coverage_tracking.bind_sliding_movement(sliding_movement_node)
extends Node


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted once per newly covered tile.
signal tile_covered(coord: Vector2i)

## Emitted per tile reverting to uncovered (undo / restore_coverage_snapshot).
signal tile_uncovered(coord: Vector2i)

## Emitted after each spawn_position_set, slide_completed, or
## restore_coverage_snapshot. Downstream: HUD.
signal coverage_updated(covered: int, total: int)

## Emitted when covered_count == total_walkable. Downstream: Level Coordinator.
signal level_completed


# —————————————————————————————————————————————
# Enums
# —————————————————————————————————————————————

## Three states matching the GDD state table.
enum State {
	UNINITIALIZED, ## Before initialize_level(); all queries return 0.
	TRACKING, ## Processing spawn + slide events.
	COMPLETE, ## All tiles covered; level_completed emitted; frozen.
}


# —————————————————————————————————————————————
# Private state
# —————————————————————————————————————————————

## Current tracking state.
var _state: State = State.UNINITIALIZED

## Per-tile coverage state. Keys: Vector2i, Values: bool.
var _coverage_map: Dictionary = {}

## Running count of covered tiles.
var _covered_count: int = 0

## Total walkable tiles to cover. Cached from GridSystem at initialize_level().
var _total_walkable: int = 0


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Builds the coverage target set from GridSystem. Must be called after
## GridSystem.load_grid(). Resets all coverage to uncovered.
func initialize_level() -> void:
	_coverage_map.clear()
	_covered_count = 0

	var walkable: Array[Vector2i] = GridSystem.get_all_walkable_tiles()
	_total_walkable = walkable.size()

	if _total_walkable == 0:
		push_error("CoverageTracking: Level has zero walkable tiles — level_completed will never fire.")

	for tile in walkable:
		_coverage_map[tile] = false

	_state = State.TRACKING


## Reinitializes coverage from GridSystem, clearing all progress. No-op if
## UNINITIALIZED (defensive for error recovery paths). Emits tile_uncovered
## for every currently-covered tile so visual subscribers (CoverageVisualizer)
## can clear themselves before spawn_position_set fires.
func reset_coverage() -> void:
	if _state == State.UNINITIALIZED:
		return
	for coord: Vector2i in _coverage_map:
		if _coverage_map[coord]:
			tile_uncovered.emit(coord)
	initialize_level()


## Returns coverage percentage: 0.0–100.0. 0.0 if total_walkable == 0.
func get_coverage_percent() -> float:
	if _total_walkable == 0:
		return 0.0
	return float(_covered_count) / float(_total_walkable) * 100.0


## Returns the current count of covered tiles.
func get_covered_count() -> int:
	return _covered_count


## Returns the total number of walkable tiles to cover.
func get_total_walkable() -> int:
	return _total_walkable


## Returns whether a specific tile has been covered.
func is_tile_covered(coord: Vector2i) -> bool:
	return _coverage_map.get(coord, false)


## Returns the current tracking state.
func get_state() -> State:
	return _state


## Returns a deep copy of the coverage map for Undo/Restart snapshots.
func get_coverage_snapshot() -> Dictionary:
	return _coverage_map.duplicate(true)


## Restores coverage from a deep-copied snapshot. Emits tile_uncovered for
## tiles that transition from covered to uncovered, then coverage_updated.
## Undo/Restart owns calling this at the right time.
func restore_coverage_snapshot(snapshot: Dictionary) -> void:
	# Emit tile_uncovered for tiles going from covered → uncovered
	for coord: Vector2i in _coverage_map:
		if _coverage_map[coord] and not snapshot.get(coord, false):
			tile_uncovered.emit(coord)

	_coverage_map = snapshot.duplicate(true)
	_covered_count = 0
	for val: bool in _coverage_map.values():
		if val:
			_covered_count += 1

	if _covered_count == _total_walkable and _total_walkable > 0:
		_state = State.COMPLETE
	else:
		_state = State.TRACKING

	coverage_updated.emit(_covered_count, _total_walkable)


## Connects this tracker to a SlidingMovement node's signals.
## Guards against double-binding — safe to call repeatedly on the same node.
func bind_sliding_movement(sm: Node) -> void:
	if not sm.spawn_position_set.is_connected(on_spawn_position_set):
		sm.spawn_position_set.connect(on_spawn_position_set)
	if not sm.slide_completed.is_connected(on_slide_completed):
		sm.slide_completed.connect(on_slide_completed)


## Disconnects from a SlidingMovement node's signals.
func unbind_sliding_movement(sm: Node) -> void:
	if sm.spawn_position_set.is_connected(on_spawn_position_set):
		sm.spawn_position_set.disconnect(on_spawn_position_set)
	if sm.slide_completed.is_connected(on_slide_completed):
		sm.slide_completed.disconnect(on_slide_completed)


# —————————————————————————————————————————————
# Signal handlers (public for testability + external wiring)
# —————————————————————————————————————————————

## Handles spawn_position_set — marks the starting tile as pre-covered.
func on_spawn_position_set(pos: Vector2i) -> void:
	if _state == State.UNINITIALIZED:
		push_warning("CoverageTracking: spawn_position_set received before initialize_level().")
		return

	_mark_tile_covered(pos)

	coverage_updated.emit(_covered_count, _total_walkable)

	# Degenerate 1-tile level: complete immediately at spawn
	if _covered_count == _total_walkable and _total_walkable > 0 and _state != State.COMPLETE:
		_state = State.COMPLETE
		level_completed.emit()


## Handles slide_completed — marks all traversed tiles and checks completion.
func on_slide_completed(
	_from_pos: Vector2i,
	_to_pos: Vector2i,
	_direction: Vector2i,
	tiles_covered: Array[Vector2i],
) -> void:
	if _state == State.COMPLETE:
		return
	if _state == State.UNINITIALIZED:
		push_warning("CoverageTracking: slide_completed received before initialize_level().")
		return

	for tile: Vector2i in tiles_covered:
		_mark_tile_covered(tile)

	coverage_updated.emit(_covered_count, _total_walkable)

	if _covered_count == _total_walkable and _total_walkable > 0:
		_state = State.COMPLETE
		level_completed.emit()


# —————————————————————————————————————————————
# Private helpers
# —————————————————————————————————————————————

## Marks a single tile as covered if it exists and is uncovered. Emits
## tile_covered for newly covered tiles. Silently skips already-covered tiles.
func _mark_tile_covered(coord: Vector2i) -> void:
	if not _coverage_map.has(coord):
		push_error(
			"CoverageTracking: Tile %s not in coverage_map — possible grid inconsistency."
			% str(coord)
		)
		return
	if _coverage_map[coord]:
		return # Already covered — idempotent
	_coverage_map[coord] = true
	_covered_count += 1
	tile_covered.emit(coord)
