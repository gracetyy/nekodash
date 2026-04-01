## LevelCoordinator — root node of the gameplay scene.
## Implements: design/gdd/level-coordinator.md
##
## Owns initialization order, enforces the critical slide_completed signal
## connection order (MoveCounter before CoverageTracking), snapshots previous-
## best data at level load, freezes the counter on completion, and orchestrates
## the transition to Level Complete Screen.
##
## Usage:
##   SceneManager calls receive_scene_params({"level_data": level_data}) before
##   _ready(). The coordinator then initializes all child systems in _ready().
extends Node2D


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Re-emits SlidingMovement.slide_blocked for external listeners (HUD, audio).
signal blocked_slide(pos: Vector2i, direction: Vector2i)

## Emitted after restart_level() completes.
signal level_restarted


# —————————————————————————————————————————————
# Enums
# —————————————————————————————————————————————

## Level Coordinator state machine. See design/gdd/level-coordinator.md.
enum State {
	LOADING, ## Scene instantiated; receive_scene_params() not yet called.
	INITIALIZING, ## _ready() running; systems being set up.
	PLAYING, ## Active gameplay; player can move.
	TRANSITIONING, ## level_completed processed; scene change in progress.
}


# —————————————————————————————————————————————
# Child node references
# —————————————————————————————————————————————

@onready var _sliding_movement: Node2D = $SlidingMovement
@onready var _coverage_tracking: Node = $CoverageTracking
@onready var _move_counter: Node = $MoveCounter


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _state: State = State.LOADING
var _current_level_data: LevelData
var _prev_best_moves: int = 0
var _was_previously_completed: bool = false


# —————————————————————————————————————————————
# SceneManager contract
# —————————————————————————————————————————————

## Called by SceneManager before _ready(). Stores the LevelData for this
## session. Must be called exactly once.
func receive_scene_params(params: Dictionary) -> void:
	_current_level_data = params.get("level_data") as LevelData
	if _current_level_data == null:
		push_error("LevelCoordinator: receive_scene_params() missing 'level_data'.")


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	if _current_level_data == null:
		push_error("LevelCoordinator: _ready() with no LevelData — call receive_scene_params() first.")
		return

	_state = State.INITIALIZING

	# 1. Snapshot previous bests BEFORE any save write
	_snapshot_previous_bests()

	# 2. Initialize child systems (state reset, no events yet)
	_initialize_systems()

	# 3. Connect signals in correct order BEFORE sliding_movement init
	#    (spawn_position_set fires during initialize_level)
	_connect_signals()

	# 4. Initialize sliding movement (emits spawn_position_set → CoverageTracking)
	_sliding_movement.initialize_level(_current_level_data.cat_start)

	_state = State.PLAYING

	print("[LevelCoordinator] Level '%s' ready — %d walkable tiles, %d minimum moves" % [
		_current_level_data.display_name,
		_coverage_tracking.get_total_walkable(),
		_current_level_data.minimum_moves,
	])


# —————————————————————————————————————————————
# Initialization helpers
# —————————————————————————————————————————————

func _snapshot_previous_bests() -> void:
	var id: String = _current_level_data.level_id
	_prev_best_moves = SaveManager.get_best_moves(id)
	_was_previously_completed = SaveManager.is_level_completed(id)


## Initializes GridSystem, CoverageTracking, and MoveCounter. Does NOT call
## sliding_movement.initialize_level() — that is done after _connect_signals()
## so that spawn_position_set is properly received.
func _initialize_systems() -> void:
	GridSystem.load_grid(_current_level_data)
	_coverage_tracking.initialize_level()
	_move_counter.initialize_level(_current_level_data)

	# TODO (S2): _obstacle_system.initialize(_current_level_data, GridSystem)
	# TODO (S2): _coverage_visualizer.initialize_level(...)
	# TODO (S2): _star_rating_system.set_level_id(_current_level_data.level_id)
	# TODO (S2): _level_progression.set_current_level(_current_level_data)
	# TODO (S2): _undo_restart.initialize(_current_level_data, _current_level_data.cat_start)
	# TODO (S2): _hud.initialize(...)


## Wires all inter-system signals. Order is critical — see
## design/gdd/level-coordinator.md "Signal Connection Order".
func _connect_signals() -> void:
	# slide_completed order: MoveCounter FIRST, CoverageTracking SECOND.
	# MoveCounter must increment BEFORE CoverageTracking checks for 100%
	# coverage — otherwise level_completed fires with an off-by-one count.
	# TODO (S2): Insert UndoRestart._on_slide_completed as FIRST connection.
	_sliding_movement.slide_completed.connect(_move_counter.on_slide_completed)
	_sliding_movement.slide_completed.connect(_coverage_tracking.on_slide_completed)

	# spawn_position_set → CoverageTracking pre-covers starting tile
	_sliding_movement.spawn_position_set.connect(
		_coverage_tracking.on_spawn_position_set
	)

	# Blocked slide → coordinator → HUD / audio
	_sliding_movement.slide_blocked.connect(_on_slide_blocked)

	# Level complete chain
	_coverage_tracking.level_completed.connect(_on_level_completed)

	# Move counter updates
	_move_counter.move_count_changed.connect(_on_move_count_changed)

	# Coverage updates
	_coverage_tracking.coverage_updated.connect(_on_coverage_updated)
	_coverage_tracking.tile_covered.connect(_on_tile_covered)

	# TODO (S2): _star_rating_system.rating_computed → _level_progression._on_rating_computed
	# TODO (S2): _level_progression.level_record_saved → _on_level_record_saved
	# TODO (S2): _undo_restart signals → HUD


## Disconnects all inter-system signals. Called before restart.
func _disconnect_signals() -> void:
	if _sliding_movement.slide_completed.is_connected(_move_counter.on_slide_completed):
		_sliding_movement.slide_completed.disconnect(_move_counter.on_slide_completed)
	if _sliding_movement.slide_completed.is_connected(_coverage_tracking.on_slide_completed):
		_sliding_movement.slide_completed.disconnect(_coverage_tracking.on_slide_completed)
	if _sliding_movement.spawn_position_set.is_connected(_coverage_tracking.on_spawn_position_set):
		_sliding_movement.spawn_position_set.disconnect(_coverage_tracking.on_spawn_position_set)
	if _sliding_movement.slide_blocked.is_connected(_on_slide_blocked):
		_sliding_movement.slide_blocked.disconnect(_on_slide_blocked)
	if _coverage_tracking.level_completed.is_connected(_on_level_completed):
		_coverage_tracking.level_completed.disconnect(_on_level_completed)
	if _move_counter.move_count_changed.is_connected(_on_move_count_changed):
		_move_counter.move_count_changed.disconnect(_on_move_count_changed)
	if _coverage_tracking.coverage_updated.is_connected(_on_coverage_updated):
		_coverage_tracking.coverage_updated.disconnect(_on_coverage_updated)
	if _coverage_tracking.tile_covered.is_connected(_on_tile_covered):
		_coverage_tracking.tile_covered.disconnect(_on_tile_covered)


# —————————————————————————————————————————————
# Signal handlers
# —————————————————————————————————————————————

func _on_level_completed() -> void:
	if _state != State.PLAYING:
		return

	_state = State.TRANSITIONING
	_move_counter.freeze()
	_sliding_movement.lock()

	var final_moves: int = _move_counter.get_final_move_count()
	var minimum: int = _move_counter.get_minimum_moves()

	print("[LevelCoordinator] LEVEL COMPLETE — moves: %d / minimum: %d" % [
		final_moves, minimum,
	])

	# TODO (S2): StarRatingSystem computes stars, LevelProgression saves record,
	# then _on_level_record_saved triggers SceneManager.go_to(Screen.LEVEL_COMPLETE).


func _on_slide_blocked(pos: Vector2i, direction: Vector2i) -> void:
	# SlidingMovement already plays bump animation.
	# Re-emit for HUD/audio subscribers.
	blocked_slide.emit(pos, direction)

	# TODO (S2): Play blocked slide SFX via AudioManager


func _on_move_count_changed(current_moves: int, minimum_moves: int) -> void:
	# TODO (S2): Forwarded to HUD._on_move_count_changed
	pass


func _on_coverage_updated(covered: int, total: int) -> void:
	# TODO (S2): Forwarded to HUD._on_coverage_updated
	pass


func _on_tile_covered(coord: Vector2i) -> void:
	# TODO (S2): Forwarded to CoverageVisualizer._on_tile_covered
	pass


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Restarts the current level without reloading the scene. Resets all child
## systems to initial state. (AC: LC-8)
func restart_level() -> void:
	if _current_level_data == null:
		return

	_disconnect_signals()
	_initialize_systems()
	_connect_signals()
	_sliding_movement.initialize_level(_current_level_data.cat_start)
	_state = State.PLAYING

	level_restarted.emit()

	print("[LevelCoordinator] Restarted level: " + _current_level_data.display_name)


## Returns the coordinator's current state.
func get_state() -> State:
	return _state


## Returns the LevelData for this session.
func get_current_level_data() -> LevelData:
	return _current_level_data


## Returns the player's previous-best move count for this level. 0 if first attempt.
func get_prev_best_moves() -> int:
	return _prev_best_moves


## Returns whether the player has previously completed this level.
func was_previously_completed() -> bool:
	return _was_previously_completed
