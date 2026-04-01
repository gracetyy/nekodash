## StarRatingSystem — computes 0–3 star rating at level completion.
## Implements: design/gdd/star-rating-system.md
## Task: S2-02
##
## Pure computation node: caches star thresholds from LevelData at init,
## reads final move count from MoveCounter on level_completed, applies the
## locked formula, and emits rating_computed exactly once per attempt.
##
## Star Rating does NOT write to SaveManager — it fires rating_computed and
## is done. Level Progression subscribes and handles persistence.
##
## Usage:
##   star_rating.initialize_level(level_data, move_counter_ref)
##   # Level Coordinator connects coverage_tracking.level_completed →
##   #   star_rating.on_level_completed
extends Node


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted once per attempt after level_completed triggers computation.
## Downstream: LevelProgression, LevelCompleteScreen.
signal rating_computed(level_id: String, stars: int, final_moves: int)


# —————————————————————————————————————————————
# Private state
# —————————————————————————————————————————————

## Thresholds cached from LevelData at initialize_level().
var _star_3_moves: int = 0
var _star_2_moves: int = 0
var _star_1_moves: int = 0
var _minimum_moves: int = 0
var _level_id: String = ""

## Reference to MoveCounter for final move count read.
var _move_counter: Node

## Rating for the current attempt: 0–3, or -1 if not yet computed / sentinel.
var _current_rating: int = -1

## Guard: rating_computed fires at most once per attempt.
var _has_fired: bool = false


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Caches thresholds and move counter reference. Called by Level Coordinator
## at level load and on retry.
func initialize_level(level_data: LevelData, move_counter_ref: Node) -> void:
	if level_data == null:
		push_error("StarRatingSystem: initialize_level() called with null LevelData.")
		return
	if move_counter_ref == null:
		push_error("StarRatingSystem: initialize_level() called with null move_counter_ref.")
		return

	_level_id = level_data.level_id
	_minimum_moves = level_data.minimum_moves
	_star_3_moves = level_data.star_3_moves
	_star_2_moves = level_data.star_2_moves
	_star_1_moves = level_data.star_1_moves
	_move_counter = move_counter_ref
	_current_rating = -1
	_has_fired = false


## Returns the rating computed this attempt: 0–3, or -1 if not yet computed
## or sentinel (unsolved level).
func get_current_rating() -> int:
	return _current_rating


## Returns the cached 3-star threshold.
func get_star_3_moves() -> int:
	return _star_3_moves


## Returns the cached 2-star threshold.
func get_star_2_moves() -> int:
	return _star_2_moves


## Returns the cached 1-star threshold.
func get_star_1_moves() -> int:
	return _star_1_moves


# —————————————————————————————————————————————
# Signal handlers (public for Level Coordinator wiring)
# —————————————————————————————————————————————

## Handles level_completed from CoverageTracking. Computes the star rating
## from MoveCounter's final count and emits rating_computed exactly once.
func on_level_completed() -> void:
	if _has_fired:
		return
	if _move_counter == null:
		push_error("StarRatingSystem: on_level_completed() with no move_counter reference.")
		return

	var final_moves: int = _move_counter.get_final_move_count()

	# Graceful degradation for unsolved / in-development levels
	if _minimum_moves == 0:
		_current_rating = -1
		_has_fired = true
		rating_computed.emit(_level_id, -1, final_moves)
		return

	# Locked formula per GDD
	if final_moves <= _star_3_moves:
		_current_rating = 3
	elif final_moves <= _star_2_moves:
		_current_rating = 2
	elif final_moves <= _star_1_moves:
		_current_rating = 1
	else:
		_current_rating = 0

	_has_fired = true
	rating_computed.emit(_level_id, _current_rating, final_moves)
