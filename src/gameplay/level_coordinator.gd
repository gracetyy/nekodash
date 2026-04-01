## LevelCoordinator — root node of the gameplay scene.
## Implements: design/gdd/level-coordinator.md
## Task: S2-05
##
## Owns initialization order, enforces the critical slide_completed signal
## connection order (UndoRestart FIRST, MoveCounter SECOND, CoverageTracking
## THIRD), snapshots previous-best data at level load, freezes systems on
## completion, computes stars via StarRatingSystem, saves via LevelProgression,
## and orchestrates the transition to Level Complete Screen.
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
@onready var _undo_restart: Node = $UndoRestart
@onready var _star_rating_system: Node = $StarRatingSystem
@onready var _level_progression: Node = $LevelProgression
@onready var _hud: HUD = $HUD
@onready var _grid_renderer: Node2D = $GridRenderer


# —————————————————————————————————————————————
# Exports
# —————————————————————————————————————————————

## The level catalogue resource — injected from the scene inspector.
@export var level_catalogue: LevelCatalogue


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
	# Fallback for direct scene launch (no SceneManager call)
	if _current_level_data == null and level_catalogue != null and level_catalogue.levels.size() > 0:
		_current_level_data = level_catalogue.levels[0]

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


## Initializes GridSystem, CoverageTracking, MoveCounter, and all S2 systems.
## Does NOT call sliding_movement.initialize_level() — that is done after
## _connect_signals() so that spawn_position_set is properly received.
func _initialize_systems() -> void:
	GridSystem.load_grid(_current_level_data)
	_coverage_tracking.initialize_level()
	_move_counter.initialize_level(_current_level_data)

	# StarRatingSystem: cache thresholds + move counter reference
	_star_rating_system.initialize_level(_current_level_data, _move_counter)

	# LevelProgression: load catalogue + connect to rating_computed signal
	if level_catalogue != null:
		_level_progression.initialize(level_catalogue, _star_rating_system)
	_level_progression.set_current_level(_current_level_data)

	# UndoRestart: set spawn, inject sibling references, clear history
	_undo_restart.initialize(
		_current_level_data.cat_start,
		_sliding_movement,
		_coverage_tracking,
		_move_counter,
	)

	# HUD: inject display data and system references
	_hud.initialize(
		_current_level_data,
		_move_counter,
		_undo_restart,
		_coverage_tracking,
	)

	# GridRenderer: redraw grid from current GridSystem state + compute centering
	if _grid_renderer != null:
		_grid_renderer.render_grid()
		# Move the coordinator root (Node2D) so the grid is centered on screen.
		# GridRenderer and SlidingMovement both draw relative to parent, so
		# this single offset aligns everything. HUD is a CanvasLayer and ignores
		# parent transforms.
		position = _grid_renderer.get_grid_offset()


## Wires all inter-system signals. Order is critical — see
## design/gdd/level-coordinator.md "Signal Connection Order".
func _connect_signals() -> void:
	# slide_completed order:
	#   1. UndoRestart FIRST  — snapshot pre-mutation state
	#   2. MoveCounter SECOND — increment count
	#   3. CoverageTracking THIRD — mark tiles + check 100% → level_completed
	_sliding_movement.slide_completed.connect(_undo_restart.on_slide_completed)
	_sliding_movement.slide_completed.connect(_move_counter.on_slide_completed)
	_sliding_movement.slide_completed.connect(_coverage_tracking.on_slide_completed)

	# spawn_position_set → CoverageTracking pre-covers starting tile
	_sliding_movement.spawn_position_set.connect(
		_coverage_tracking.on_spawn_position_set
	)

	# Blocked slide → coordinator → HUD / audio
	_sliding_movement.slide_blocked.connect(_on_slide_blocked)

	# Level complete chain:
	#   CoverageTracking.level_completed → coordinator (freeze + star compute)
	#   CoverageTracking.level_completed → UndoRestart (freeze history)
	#   CoverageTracking.level_completed → StarRatingSystem (compute stars)
	_coverage_tracking.level_completed.connect(_on_level_completed)
	_coverage_tracking.level_completed.connect(_undo_restart.on_level_completed)
	_coverage_tracking.level_completed.connect(_star_rating_system.on_level_completed)

	# StarRatingSystem.rating_computed → LevelProgression (via its internal connection)
	# LevelProgression.level_record_saved → coordinator → scene transition
	_level_progression.level_record_saved.connect(_on_level_record_saved)

	# Move counter updates (no longer forwarded — HUD subscribes directly)
	_move_counter.move_count_changed.connect(_on_move_count_changed)

	# Coverage updates
	_coverage_tracking.coverage_updated.connect(_on_coverage_updated)
	_coverage_tracking.tile_covered.connect(_on_tile_covered)


## Disconnects all inter-system signals. Called before restart.
func _disconnect_signals() -> void:
	# slide_completed
	if _sliding_movement.slide_completed.is_connected(_undo_restart.on_slide_completed):
		_sliding_movement.slide_completed.disconnect(_undo_restart.on_slide_completed)
	if _sliding_movement.slide_completed.is_connected(_move_counter.on_slide_completed):
		_sliding_movement.slide_completed.disconnect(_move_counter.on_slide_completed)
	if _sliding_movement.slide_completed.is_connected(_coverage_tracking.on_slide_completed):
		_sliding_movement.slide_completed.disconnect(_coverage_tracking.on_slide_completed)

	# spawn_position_set
	if _sliding_movement.spawn_position_set.is_connected(_coverage_tracking.on_spawn_position_set):
		_sliding_movement.spawn_position_set.disconnect(_coverage_tracking.on_spawn_position_set)

	# slide_blocked
	if _sliding_movement.slide_blocked.is_connected(_on_slide_blocked):
		_sliding_movement.slide_blocked.disconnect(_on_slide_blocked)

	# level_completed
	if _coverage_tracking.level_completed.is_connected(_on_level_completed):
		_coverage_tracking.level_completed.disconnect(_on_level_completed)
	if _coverage_tracking.level_completed.is_connected(_undo_restart.on_level_completed):
		_coverage_tracking.level_completed.disconnect(_undo_restart.on_level_completed)
	if _coverage_tracking.level_completed.is_connected(_star_rating_system.on_level_completed):
		_coverage_tracking.level_completed.disconnect(_star_rating_system.on_level_completed)

	# level_record_saved
	if _level_progression.level_record_saved.is_connected(_on_level_record_saved):
		_level_progression.level_record_saved.disconnect(_on_level_record_saved)

	# move_count_changed
	if _move_counter.move_count_changed.is_connected(_on_move_count_changed):
		_move_counter.move_count_changed.disconnect(_on_move_count_changed)

	# coverage_updated / tile_covered
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

	# StarRatingSystem.on_level_completed() computes stars and emits
	# rating_computed → LevelProgression writes to SaveManager and emits
	# level_record_saved → _on_level_record_saved triggers scene transition.
	# All of this is wired via _connect_signals() — nothing more needed here.


func _on_level_record_saved(level_id: String, stars: int, final_moves: int) -> void:
	var next_level: LevelData = _level_progression.get_next_level(level_id)

	var params: Dictionary = {
		"level_data": _current_level_data,
		"stars": stars,
		"final_moves": final_moves,
		"prev_best_moves": _prev_best_moves,
		"was_previously_completed": _was_previously_completed,
		"next_level_data": next_level,
	}

	# Show inline level-complete overlay (temporary until level_complete.tscn exists)
	_show_level_complete_overlay(params)

	# Track state in SceneManager (go_to is a stub but tests verify state)
	SceneManager.go_to(SceneManager.Screen.LEVEL_COMPLETE, params)


func _on_slide_blocked(pos: Vector2i, direction: Vector2i) -> void:
	# SlidingMovement already plays bump animation.
	# Re-emit for HUD/audio subscribers.
	blocked_slide.emit(pos, direction)


func _on_move_count_changed(_current_moves: int, _minimum_moves: int) -> void:
	# HUD subscribes directly to MoveCounter.move_count_changed via its own
	# _connect_signals(). Coordinator retains this connection for future use
	# (e.g., audio cues on move thresholds).
	pass


func _on_coverage_updated(_covered: int, _total: int) -> void:
	# HUD subscribes directly to CoverageTracking.coverage_updated via its own
	# _connect_signals(). Coordinator retains for future use (audio/VFX).
	pass


func _on_tile_covered(coord: Vector2i) -> void:
	if _grid_renderer != null:
		_grid_renderer.mark_covered(coord)


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Restarts the current level without reloading the scene. Delegates to
## UndoRestart which handles reset order. (AC: LC-8)
func restart_level() -> void:
	if _current_level_data == null:
		return

	_snapshot_previous_bests()
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


# —————————————————————————————————————————————
# Level complete overlay (temporary until level_complete.tscn exists)
# —————————————————————————————————————————————
var _overlay: CanvasLayer

func _show_level_complete_overlay(params: Dictionary) -> void:
	if _overlay != null:
		_overlay.queue_free()

	_overlay = CanvasLayer.new()
	_overlay.layer = 10
	add_child(_overlay)

	# Semi-transparent background
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(bg)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	# Opaque result card so gameplay does not bleed through text.
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 240)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.09, 0.12, 0.96)
	card_style.border_color = Color(0.18, 0.2, 0.28, 1.0)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_right = 10
	card_style.corner_radius_bottom_left = 10
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 24)
	card_margin.add_theme_constant_override("margin_top", 20)
	card_margin.add_theme_constant_override("margin_right", 24)
	card_margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(card_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card_margin.add_child(vbox)

	# Stars
	var stars: int = params.get("stars", 0)
	var star_label := Label.new()
	var star_text: String = ""
	for i: int in range(3):
		star_text += "★ " if i < stars else "☆ "
	star_label.text = star_text.strip_edges()
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_font_size_override("font_size", 48)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(star_label)

	# Title
	var title := Label.new()
	title.text = "Level Complete!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.97, 0.97, 0.97))
	vbox.add_child(title)

	# Moves
	var moves_label := Label.new()
	var final_m: int = params.get("final_moves", 0)
	var level_d: LevelData = params.get("level_data")
	var min_m: int = level_d.minimum_moves if level_d else 0
	moves_label.text = "Moves: %d / %d" % [final_m, min_m]
	moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_label.add_theme_font_size_override("font_size", 20)
	moves_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.96))
	vbox.add_child(moves_label)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	# Retry button
	var retry_btn := Button.new()
	retry_btn.text = "Retry"
	retry_btn.custom_minimum_size = Vector2(100, 44)
	retry_btn.pressed.connect(_on_overlay_retry)
	btn_row.add_child(retry_btn)

	# Next Level button (only if there is a next level)
	var next_level_data: LevelData = params.get("next_level_data")
	if next_level_data != null:
		var next_btn := Button.new()
		next_btn.text = "Next Level"
		next_btn.custom_minimum_size = Vector2(120, 44)
		next_btn.pressed.connect(_on_overlay_next.bind(next_level_data))
		btn_row.add_child(next_btn)


func _on_overlay_retry() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
	restart_level()


func _on_overlay_next(next_level: LevelData) -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
	_current_level_data = next_level
	_disconnect_signals()
	_initialize_systems()
	_connect_signals()
	_sliding_movement.initialize_level(_current_level_data.cat_start)
	_state = State.PLAYING
	print("[LevelCoordinator] Loaded next level: " + _current_level_data.display_name)
