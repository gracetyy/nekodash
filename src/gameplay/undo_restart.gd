## UndoRestart — history stack for move undo and full level restart.
## Implements: design/gdd/undo-restart.md
## Task: S2-01
##
## Owns a history stack of MoveSnapshots. On each slide_completed (connected
## FIRST by Level Coordinator), captures pre-mutation state. undo() pops the
## top snapshot and applies it in spec order. restart() clears the stack and
## re-initializes the level.
##
## Usage:
##   undo_restart.initialize(spawn_pos, sliding_movement, coverage_tracking, move_counter)
##   # Level Coordinator connects undo_restart.on_slide_completed FIRST
##   undo_restart.undo()    # rewinds one move
##   undo_restart.restart() # full level reset
extends Node


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted after a successful undo. HUD checks can_undo() to update button.
signal undo_applied(moves_in_history: int)

## Emitted after restart completes. HUD and other systems reset displays.
signal level_restarted


# —————————————————————————————————————————————
# Inner class — MoveSnapshot
# —————————————————————————————————————————————

## Captures pre-move state for all three stateful components.
class MoveSnapshot:
	var cat_pos_before: Vector2i
	var coverage_before: Dictionary
	var move_count_before: int

	func _init(
		cat_pos: Vector2i,
		coverage: Dictionary,
		move_count: int,
	) -> void:
		cat_pos_before = cat_pos
		coverage_before = coverage
		move_count_before = move_count


# —————————————————————————————————————————————
# Enums
# —————————————————————————————————————————————

## Three states matching the GDD state table.
enum State {
	UNINITIALIZED, ## initialize() not yet called.
	ACTIVE, ## Level in progress; recording history; undo/restart work.
	FROZEN, ## level_completed received; undo is no-op; restart still works.
}


# —————————————————————————————————————————————
# Dependencies (set via initialize)
# —————————————————————————————————————————————

## References to sibling systems — set by initialize().
var _sliding_movement: Node2D
var _coverage_tracking: Node
var _move_counter: Node


# —————————————————————————————————————————————
# Private state
# —————————————————————————————————————————————

## Current state.
var _state: State = State.UNINITIALIZED

## Spawn position cached from initialize() — used by restart().
var _spawn_pos: Vector2i = Vector2i.ZERO

## History stack — most recent snapshot at the end.
var _history: Array[MoveSnapshot] = []


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Initializes the undo/restart system for a new level. Called by the Level
## Coordinator at level load and on retry. Clears all history.
func initialize(
	spawn_pos: Vector2i,
	sliding_movement_ref: Node2D,
	coverage_tracking_ref: Node,
	move_counter_ref: Node,
) -> void:
	if sliding_movement_ref == null:
		push_error("UndoRestart: initialize() called with null sliding_movement_ref.")
		return
	if coverage_tracking_ref == null:
		push_error("UndoRestart: initialize() called with null coverage_tracking_ref.")
		return
	if move_counter_ref == null:
		push_error("UndoRestart: initialize() called with null move_counter_ref.")
		return

	_spawn_pos = spawn_pos
	_sliding_movement = sliding_movement_ref
	_coverage_tracking = coverage_tracking_ref
	_move_counter = move_counter_ref
	_history.clear()
	_state = State.ACTIVE


## Returns true when at least one move can be undone.
func can_undo() -> bool:
	return not _history.is_empty() and _state == State.ACTIVE


## Returns the number of undoable moves in the history stack.
func undo_count() -> int:
	return _history.size()


## Returns the current state.
func get_state() -> State:
	return _state


## Undoes the most recent move. No-op if history is empty or state is
## FROZEN / UNINITIALIZED.
func undo() -> void:
	if _state == State.UNINITIALIZED:
		push_warning("UndoRestart: undo() called before initialize().")
		return
	if _state == State.FROZEN:
		return
	if _history.is_empty():
		push_warning("UndoRestart: undo() called with empty history.")
		return

	var snapshot: MoveSnapshot = _history.pop_back()

	# Apply in GDD-specified order:
	# 1. Cat position (kills tween, snaps)
	_sliding_movement.set_grid_position_instant(snapshot.cat_pos_before)
	# 2. Coverage state
	_coverage_tracking.restore_coverage_snapshot(snapshot.coverage_before)
	# 3. Move count
	_move_counter.set_move_count(snapshot.move_count_before)

	undo_applied.emit(_history.size())


## Restarts the level without a scene reload. Clears history and re-
## initializes all systems in GDD-specified order.
func restart() -> void:
	if _state == State.UNINITIALIZED:
		push_warning("UndoRestart: restart() called before initialize().")
		return

	_history.clear()

	# Apply in GDD-specified order:
	# 1. Snap cat to spawn
	_sliding_movement.set_grid_position_instant(_spawn_pos)
	# 2. Clear coverage
	_coverage_tracking.reset_coverage()
	# 3. Reset move counter
	_move_counter.reset_move_count()
	# 4. Re-initialize sliding movement (re-emits spawn_position_set →
	#    CoverageTracking pre-covers starting tile)
	_sliding_movement.initialize_level(_spawn_pos)

	_state = State.ACTIVE
	level_restarted.emit()


# —————————————————————————————————————————————
# Signal handlers (public for Level Coordinator wiring)
# —————————————————————————————————————————————

## Handles slide_completed — captures pre-mutation snapshot. MUST be connected
## FIRST (before MoveCounter and CoverageTracking) so it reads pre-mutation state.
func on_slide_completed(
	from_pos: Vector2i,
	_to_pos: Vector2i,
	_direction: Vector2i,
	_tiles_covered: Array[Vector2i],
) -> void:
	if _state != State.ACTIVE:
		return

	var snapshot := MoveSnapshot.new(
		from_pos,
		_coverage_tracking.get_coverage_snapshot(),
		_move_counter.get_current_moves(),
	)
	_history.push_back(snapshot)


## Handles level_completed — freezes the history stack. Undo becomes no-op.
func on_level_completed() -> void:
	_state = State.FROZEN
	_history.clear()
