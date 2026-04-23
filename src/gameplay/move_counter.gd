## MoveCounter — tracks the number of moves in the current level attempt.
## Implements: design/gdd/move-counter.md
## Task: S1-08
##
## Thin, deterministic counter. Increments by 1 on each coordinator-dispatched move.
## Exposes current_moves and minimum_moves to HUD via move_count_changed.
## Undo/Restart controls the count via set_move_count() / reset_move_count().
##
## Usage:
##   move_counter.initialize_level(level_data)
##   # Called by LevelCoordinator.process_move(...):
##   move_counter.increment(from_pos, to_pos, direction, tiles_covered)
extends Node


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted after every increment, undo rewind, or reset. Downstream: HUD.
signal move_count_changed(current_moves: int, minimum_moves: int)


# —————————————————————————————————————————————
# Private state
# —————————————————————————————————————————————

## Number of moves made in the current attempt.
var _current_moves: int = 0

## Minimum moves from LevelData — constant for the session.
var _minimum_moves: int = 0

## Star thresholds from LevelData — read-only accessors for Star Rating.
var _star_3_moves: int = 0
var _star_2_moves: int = 0
var _star_1_moves: int = 0

## Whether the counter is frozen (level complete). No more increments.
var _frozen: bool = false


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Initializes the counter from a LevelData resource. Sets current_moves = 0,
## caches minimum_moves and star thresholds, unfreezes, emits move_count_changed.
func initialize_level(level_data: LevelData) -> void:
	_current_moves = 0
	_frozen = false

	if level_data != null:
		_minimum_moves = level_data.minimum_moves
		_star_3_moves = level_data.star_3_moves
		_star_2_moves = level_data.star_2_moves
		_star_1_moves = level_data.star_1_moves
	else:
		push_warning("MoveCounter: initialize_level() called with null LevelData.")
		_minimum_moves = 0
		_star_3_moves = 0
		_star_2_moves = 0
		_star_1_moves = 0

	move_count_changed.emit(_current_moves, _minimum_moves)


## Resets current_moves to 0 and emits move_count_changed. Called by
## Undo/Restart on full level restart.
func reset_move_count() -> void:
	_current_moves = 0
	_frozen = false
	move_count_changed.emit(_current_moves, _minimum_moves)


## Sets current_moves to n. Called by Undo system to rewind. Logs a warning
## and clamps if n > current_moves (undo should never increase the count).
func set_move_count(n: int) -> void:
	if n < 0:
		push_warning(
			"MoveCounter: set_move_count(%d) is negative. Clamped to 0." % n
		)
		n = 0
	if n > _current_moves:
		push_warning(
			"MoveCounter: set_move_count(%d) exceeds current_moves (%d). Clamped."
			% [n, _current_moves]
		)
		return
	_current_moves = n
	_frozen = false
	move_count_changed.emit(_current_moves, _minimum_moves)


## Returns current move count. Same as get_final_move_count() — the count
## does not change after level_completed unless a restart occurs.
func get_current_moves() -> int:
	return _current_moves


## Returns the move count at level completion. Identical to get_current_moves()
## — the counter freezes at completion.
func get_final_move_count() -> int:
	return _current_moves


## Returns the minimum moves from LevelData. 0 if unsolved.
func get_minimum_moves() -> int:
	return _minimum_moves


## Returns the 3-star threshold from LevelData.
func get_star_3_moves() -> int:
	return _star_3_moves


## Returns the 2-star threshold from LevelData.
func get_star_2_moves() -> int:
	return _star_2_moves


## Returns the 1-star threshold from LevelData.
func get_star_1_moves() -> int:
	return _star_1_moves


## Returns whether the counter is frozen (level completed).
func is_frozen() -> bool:
	return _frozen


## Freezes the counter. Called when level_completed fires — no more increments.
func freeze() -> void:
	_frozen = true


## Increments current_moves by 1 for a completed move.
## Called by LevelCoordinator.process_move() as part of the deterministic
## move pipeline.
func increment(
	_from_pos: Vector2i,
	_to_pos: Vector2i,
	_direction: Vector2i,
	_tiles_covered: Array[Vector2i],
) -> void:
	if _frozen:
		return
	_current_moves += 1
	move_count_changed.emit(_current_moves, _minimum_moves)


## Backward-compat adapter for legacy direct signal tests/wiring.
func on_slide_completed(
	from_pos: Vector2i,
	to_pos: Vector2i,
	direction: Vector2i,
	tiles_covered: Array[Vector2i],
) -> void:
	increment(from_pos, to_pos, direction, tiles_covered)
