## LevelCoordinator — root node of the gameplay scene.
## Implements: design/gdd/level-coordinator.md
## Task: S2-05
##
## Owns initialization order, receives slide_completed once, dispatches
## process_move() in deterministic order (UndoRestart.record_snapshot,
## MoveCounter.increment, CoverageTracking.apply_tiles_covered), snapshots
## previous-best data at level load, freezes systems on completion, computes
## stars via StarRatingSystem, saves via LevelProgression, and orchestrates
## the transition to Level Complete Screen.
##
## Usage:
##   SceneManager calls receive_scene_params({"level_data": level_data}) before
##   _ready(). The coordinator then initializes all child systems in _ready().
extends Node2D

const ConfirmNavigationModalScene: PackedScene = preload("res://scenes/ui/components/panels/ConfirmNavigationModal.tscn")


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
@onready var _grid_renderer: Node = $GridRenderer
@onready var _coverage_visualizer: CoverageVisualizer = $CoverageVisualizer


# —————————————————————————————————————————————
# Exports
# —————————————————————————————————————————————

## The level catalogue resource — injected from the scene inspector.
## Canonical path: res://data/level_catalogue.tres (shared with WorldMap).
@export var level_catalogue: LevelCatalogue


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _state: State = State.LOADING
var _current_level_data: LevelData
var _prev_best_moves: int = 0
var _was_previously_completed: bool = false
var _entry_fade_layer: CanvasLayer
var _entry_fade_rect: ColorRect
var _entry_fade_tween: Tween
var _confirm_modal: ConfirmNavigationModal
const LEVEL_COMPLETE_MODAL_DELAY_SEC: float = 0.34

## Stub SFX stream for level completion (replace with real audio asset later).
var _sfx_level_complete: AudioStream = AudioStreamWAV.new()


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
	_connect_app_settings_signal()
	
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	# 4. Initialize sliding movement (emits spawn_position_set → CoverageTracking)
	_sliding_movement.initialize_level(_current_level_data.cat_start)

	if has_node("TutorialSystem"):
		$TutorialSystem.initialize(self , _current_level_data)
	_ensure_confirm_modal()

	_state = State.PLAYING

	print("[LevelCoordinator] Level '%s' ready — %d walkable tiles, %d minimum moves" % [
		_current_level_data.level_id,
		_coverage_tracking.get_total_walkable(),
		_current_level_data.minimum_moves,
	])

	if OS.is_debug_build():
		var solver_script: GDScript = load("res://tools/level_solver.gd")
		if solver_script != null:
			var solver: RefCounted = solver_script.new()
			var solve_result: RefCounted = solver.solve(_current_level_data)
			var wasd: String = solver_script.path_to_wasd(solve_result.path)
			print("[LevelCoordinator] Optimal solution (%d moves): %s" % [
				solve_result.minimum_moves,
				wasd if wasd != "" else "(trivial/unsolvable)",
			])

	_play_level_entry_transition()


func _exit_tree() -> void:
	_disconnect_app_settings_signal()


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
	_refresh_grid_visuals()

	# CoverageVisualizer: reset visual state for the new level
	if _coverage_visualizer != null:
		_coverage_visualizer.initialize_level(
			GridSystem.get_width(),
			GridSystem.get_height(),
			_current_level_data,
		)


## Wires all inter-system signals. Move processing is centralized through
## _on_slide_completed() -> process_move() to avoid fragile ordering-by-connect.
func _connect_signals() -> void:
	# Single slide_completed subscription. Coordinator dispatches in explicit order:
	#   1. UndoRestart.record_snapshot()      (pre-mutation snapshot)
	#   2. MoveCounter.increment()            (count this move)
	#   3. CoverageTracking.apply_tiles_covered() (coverage + completion check)
	_sliding_movement.slide_completed.connect(_on_slide_completed)

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
	_coverage_tracking.tile_uncovered.connect(_on_tile_uncovered)

	# HUD exit button → abandon level (no save)
	_hud.exit_pressed.connect(_on_exit_pressed)
	_hud.pause_pressed.connect(_on_pause_pressed)

	# CoverageVisualizer: visual overlay driven by coverage signals
	if _coverage_visualizer != null:
		_coverage_tracking.tile_covered.connect(_coverage_visualizer.on_tile_covered)
		_coverage_tracking.tile_uncovered.connect(_coverage_visualizer.on_tile_uncovered)
		_sliding_movement.spawn_position_set.connect(_coverage_visualizer.on_spawn_position_set)
		_sliding_movement.slide_tile_reached.connect(_coverage_visualizer.on_tile_covered)


## Disconnects all inter-system signals. Called before restart.
func _disconnect_signals() -> void:
	# slide_completed
	if _sliding_movement.slide_completed.is_connected(_on_slide_completed):
		_sliding_movement.slide_completed.disconnect(_on_slide_completed)

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

	# coverage_updated / tile_covered / tile_uncovered
	if _coverage_tracking.coverage_updated.is_connected(_on_coverage_updated):
		_coverage_tracking.coverage_updated.disconnect(_on_coverage_updated)
	if _coverage_tracking.tile_covered.is_connected(_on_tile_covered):
		_coverage_tracking.tile_covered.disconnect(_on_tile_covered)
	if _coverage_tracking.tile_uncovered.is_connected(_on_tile_uncovered):
		_coverage_tracking.tile_uncovered.disconnect(_on_tile_uncovered)

	# HUD exit
	if _hud.exit_pressed.is_connected(_on_exit_pressed):
		_hud.exit_pressed.disconnect(_on_exit_pressed)
	if _hud.pause_pressed.is_connected(_on_pause_pressed):
		_hud.pause_pressed.disconnect(_on_pause_pressed)

	# CoverageVisualizer
	if _coverage_visualizer != null:
		if _coverage_tracking.tile_covered.is_connected(_coverage_visualizer.on_tile_covered):
			_coverage_tracking.tile_covered.disconnect(_coverage_visualizer.on_tile_covered)
		if _coverage_tracking.tile_uncovered.is_connected(_coverage_visualizer.on_tile_uncovered):
			_coverage_tracking.tile_uncovered.disconnect(_coverage_visualizer.on_tile_uncovered)
		if _sliding_movement.spawn_position_set.is_connected(_coverage_visualizer.on_spawn_position_set):
			_sliding_movement.spawn_position_set.disconnect(_coverage_visualizer.on_spawn_position_set)
		if _sliding_movement.slide_tile_reached.is_connected(_coverage_visualizer.on_tile_covered):
			_sliding_movement.slide_tile_reached.disconnect(_coverage_visualizer.on_tile_covered)


# —————————————————————————————————————————————
# Signal handlers
# —————————————————————————————————————————————

func _on_slide_completed(
	from_pos: Vector2i,
	to_pos: Vector2i,
	direction: Vector2i,
	tiles_covered: Array[Vector2i],
) -> void:
	process_move(from_pos, to_pos, direction, tiles_covered)


## Deterministic move pipeline owned by the coordinator.
## This replaces reliance on signal connection timing across sibling systems.
func process_move(
	from_pos: Vector2i,
	to_pos: Vector2i,
	direction: Vector2i,
	tiles_covered: Array[Vector2i],
) -> void:
	_undo_restart.record_snapshot(from_pos, to_pos, direction, tiles_covered)
	_move_counter.increment(from_pos, to_pos, direction, tiles_covered)
	_coverage_tracking.apply_tiles_covered(from_pos, to_pos, direction, tiles_covered)

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
	SfxManager.play(_sfx_level_complete, SfxManager.SfxBus.SFX)

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
	await get_tree().create_timer(LEVEL_COMPLETE_MODAL_DELAY_SEC).timeout
	if not is_inside_tree() or _state != State.TRANSITIONING:
		return
	_show_level_complete_overlay(params)


func _show_level_complete_overlay(params: Dictionary) -> void:
	# Keep gameplay visible and show the completion modal above it.
	SceneManager.show_overlay(SceneManager.Overlay.LEVEL_COMPLETE, {
		"pause_tree": true,
		"level_data": params["level_data"],
		"stars": params["stars"],
		"final_moves": params["final_moves"],
		"prev_best_moves": params["prev_best_moves"],
		"was_previously_completed": params["was_previously_completed"],
		"next_level_data": params["next_level_data"],
	})


func _on_slide_blocked(pos: Vector2i, direction: Vector2i) -> void:
	# SlidingMovement already plays bump animation.
	# Re-emit for HUD/audio subscribers.
	blocked_slide.emit(pos, direction)


## Navigates to World Map without saving. Called when the player taps Exit
## mid-level. No save write is performed — progress is discarded.
func _on_exit_pressed() -> void:
	if _state != State.PLAYING:
		return
	_prompt_level_select_confirmation()


func _ensure_confirm_modal() -> void:
	if _confirm_modal != null and is_instance_valid(_confirm_modal):
		return
	var modal_instance: Node = ConfirmNavigationModalScene.instantiate()
	if not modal_instance is ConfirmNavigationModal:
		push_error("LevelCoordinator: ConfirmNavigationModal scene failed to instantiate.")
		return
	_confirm_modal = modal_instance as ConfirmNavigationModal
	_confirm_modal.confirmed.connect(_on_confirm_modal_confirmed)
	_confirm_modal.canceled.connect(_on_confirm_modal_canceled)
	if _hud != null:
		_hud.add_child(_confirm_modal)
	else:
		add_child(_confirm_modal)


func _prompt_level_select_confirmation() -> void:
	_ensure_confirm_modal()
	if _confirm_modal == null:
		return
	if _sliding_movement != null:
		_sliding_movement.lock()
	_set_tutorial_overlay_visible(false)
	_confirm_modal.show_modal(
		"Return to Level Select",
		"Leave this level and return to level select? Progress in this run will not be saved.",
	)


func _on_confirm_modal_confirmed() -> void:
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP)


func _on_confirm_modal_canceled() -> void:
	if _state == State.PLAYING and _sliding_movement != null:
		_sliding_movement.unlock()
	_set_tutorial_overlay_visible(true)


func _set_tutorial_overlay_visible(visible_flag: bool) -> void:
	if not has_node("TutorialSystem"):
		return
	var tutorial_node: CanvasLayer = get_node("TutorialSystem") as CanvasLayer
	if tutorial_node == null:
		return
	tutorial_node.visible = visible_flag


func _on_pause_pressed() -> void:
	if _state != State.PLAYING:
		return
	if SceneManager.has_active_overlay():
		return
	SceneManager.show_overlay(SceneManager.Overlay.PAUSE, {
		"pause_tree": true,
	})


func _on_move_count_changed(_current_moves: int, _minimum_moves: int) -> void:
	# HUD subscribes directly to MoveCounter.move_count_changed via its own
	# _connect_signals(). Coordinator retains this connection for future use
	# (e.g., audio cues on move thresholds).
	pass


func _on_coverage_updated(_covered: int, _total: int) -> void:
	# HUD subscribes directly to CoverageTracking.coverage_updated via its own
	# _connect_signals(). Coordinator retains for future use (audio/VFX).
	pass


func _on_tile_covered(_coord: Vector2i) -> void:
	# CoverageVisualizer is wired directly to tile_covered.
	# Coordinator retains this connection for future use (audio/VFX).
	pass


func _on_tile_uncovered(_coord: Vector2i) -> void:
	# CoverageVisualizer is wired directly to tile_uncovered.
	# Coordinator retains this connection for future use (audio/VFX).
	pass


func _play_level_entry_transition() -> void:
	if _is_reduce_motion_enabled():
		return
	if _entry_fade_layer != null and is_instance_valid(_entry_fade_layer):
		_entry_fade_layer.queue_free()

	_entry_fade_layer = CanvasLayer.new()
	_entry_fade_layer.layer = 22
	add_child(_entry_fade_layer)

	_entry_fade_rect = ColorRect.new()
	_entry_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_entry_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_fade_rect.color = Color(1.0, 0.984, 0.929, 0.95)
	_entry_fade_layer.add_child(_entry_fade_rect)

	if _entry_fade_tween != null and _entry_fade_tween.is_valid():
		_entry_fade_tween.kill()
	_entry_fade_tween = create_tween()
	_entry_fade_tween.tween_property(_entry_fade_rect, "color:a", 0.0, 0.32) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_entry_fade_tween.tween_callback(_clear_level_entry_transition)


func _clear_level_entry_transition() -> void:
	if _entry_fade_layer != null and is_instance_valid(_entry_fade_layer):
		_entry_fade_layer.queue_free()
	_entry_fade_layer = null
	_entry_fade_rect = null
	_entry_fade_tween = null


func _is_reduce_motion_enabled() -> bool:
	return AppSettings != null and AppSettings.get_reduce_motion()


func _refresh_grid_visuals() -> void:
	if _grid_renderer != null:
		_grid_renderer.render_grid(_current_level_data)
		# GridRenderer and SlidingMovement both draw relative to parent, so one
		# coordinator offset keeps the board aligned under the HUD.
		position = _grid_renderer.get_grid_offset()
	if _coverage_visualizer != null:
		_coverage_visualizer.refresh_theme(_current_level_data)


func _connect_app_settings_signal() -> void:
	if AppSettings == null or not AppSettings.has_signal("setting_changed"):
		return
	var changed_callable: Callable = Callable(self , "_on_app_setting_changed")
	if not AppSettings.is_connected("setting_changed", changed_callable):
		AppSettings.connect("setting_changed", changed_callable)


func _disconnect_app_settings_signal() -> void:
	if AppSettings == null or not AppSettings.has_signal("setting_changed"):
		return
	var changed_callable: Callable = Callable(self , "_on_app_setting_changed")
	if AppSettings.is_connected("setting_changed", changed_callable):
		AppSettings.disconnect("setting_changed", changed_callable)


func _on_viewport_size_changed() -> void:
	_refresh_grid_visuals()


func _on_app_setting_changed(section: String, key: String, _value: Variant) -> void:
	if section == AppSettings.SECTION_DISPLAY:
		if key == AppSettings.KEY_SIMPLE_UI or key == AppSettings.KEY_FULLSCREEN:
			_refresh_grid_visuals()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Restarts the current level without reloading the scene. Delegates to
## UndoRestart which handles reset order. (AC: LC-8)
func restart_level() -> void:
	if _current_level_data == null:
		return

	if SceneManager.has_active_overlay():
		SceneManager.hide_overlay()
	elif get_tree().paused:
		get_tree().paused = false

	_snapshot_previous_bests()
	_disconnect_signals()
	_initialize_systems()
	_connect_signals()
	_sliding_movement.initialize_level(_current_level_data.cat_start)
	if has_node("TutorialSystem"):
		$TutorialSystem.initialize(self , _current_level_data)
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


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.PLAYING:
		return
	if SceneManager.has_active_overlay():
		return
	if event.is_action_pressed("ui_cancel"):
		_on_pause_pressed()
		get_viewport().set_input_as_handled()
