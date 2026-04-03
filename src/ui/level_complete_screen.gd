## LevelCompleteScreen — post-level results view.
## Implements: design/gdd/level-complete-screen.md
## Task: S2-06
##
## Shows star rating, final move count vs minimum, new personal best badge,
## and navigation buttons (Next Level, Retry, World Map). Receives all context
## via receive_scene_params() — owns no game state.
##
## Usage:
##   SceneManager calls receive_scene_params(params) before _ready().
##   The screen populates results in _ready() from the param data.
class_name LevelCompleteScreen
extends Control


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Gold color for earned stars.
const STAR_EARNED_COLOR: Color = Color(1.0, 0.85, 0.2, 1.0)

## Grey color for unearned stars.
const STAR_UNEARNED_COLOR: Color = Color(0.5, 0.5, 0.5, 1.0)


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when player presses Next Level.
signal next_level_requested(level_data: LevelData)

## Emitted when player presses Retry.
signal retry_requested(level_data: LevelData)

## Emitted when player presses World Map.
signal world_map_requested


# —————————————————————————————————————————————
# Child node references — set via set_ui_nodes() or @onready
# —————————————————————————————————————————————

var _level_name_label: Control # Label
var _moves_label: Control # Label
var _new_best_badge: Control # Label / TextureRect
var _next_btn: Control # Button
var _retry_btn: Control # Button
var _world_map_btn: Control # Button

## Star display nodes — array of 3 Controls (e.g. TextureRect or Label).
## Filled stars are visible; empty stars are dimmed or hidden.
var _star_nodes: Array[Control] = []

## Optional sentinel display for stars == -1.
var _star_sentinel_label: Control # Label showing "?" when unsolved


# —————————————————————————————————————————————
# Scene params (set via receive_scene_params)
# —————————————————————————————————————————————

var _current_level_data: LevelData
var _stars: int = 0
var _final_moves: int = 0
var _prev_best_moves: int = 0
var _was_previously_completed: bool = false
var _next_level_data: LevelData

## Whether params have been received.
var _params_received: bool = false

## Whether results have been populated.
var _populated: bool = false

## Stub SFX stream for star earned (replace with real audio asset later).
var _sfx_star_earned: AudioStream = AudioStreamWAV.new()


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_auto_discover_ui_nodes()
	# Self-connect navigation only when running in the real scene (auto-discover
	# found buttons). Tests use set_ui_nodes() after _ready(), so _next_btn is
	# still null here and these connections are skipped.
	if _next_btn != null:
		_connect_navigation()
	if _params_received:
		populate_results()


# —————————————————————————————————————————————
# SceneManager contract
# —————————————————————————————————————————————

## Called by SceneManager before _ready(). Stores all result data.
func receive_scene_params(params: Dictionary) -> void:
	_current_level_data = params.get("level_data") as LevelData
	_stars = params.get("stars", 0) as int
	_final_moves = params.get("final_moves", 0) as int
	_prev_best_moves = params.get("prev_best_moves", 0) as int
	_was_previously_completed = params.get("was_previously_completed", false) as bool
	_next_level_data = params.get("next_level_data") as LevelData
	_params_received = true


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Populates the results display. Called automatically from _ready() if params
## are received, or can be called manually for test setups.
func populate_results() -> void:
	if _current_level_data == null:
		push_error("LevelCompleteScreen: populate_results() with no level_data.")
		return

	# Level name
	if _level_name_label != null:
		_level_name_label.text = _current_level_data.display_name

	# Stars
	_show_stars(_stars)

	# Move count
	_update_moves_label(_final_moves, _current_level_data.minimum_moves)

	# New best badge
	_update_new_best_badge()

	# Next button visibility
	_update_next_button()

	_populated = true


## Returns whether params have been received.
func has_params() -> bool:
	return _params_received


## Returns whether results have been populated.
func is_populated() -> bool:
	return _populated


## Returns the stored star count.
func get_stars() -> int:
	return _stars


## Returns the stored final move count.
func get_final_moves() -> int:
	return _final_moves


## Returns the stored level data.
func get_level_data() -> LevelData:
	return _current_level_data


## Returns the stored next level data (null if last level).
func get_next_level_data() -> LevelData:
	return _next_level_data


## Returns whether this is a new best.
func is_new_best() -> bool:
	var is_first: bool = not _was_previously_completed
	var is_better: bool = _prev_best_moves > 0 and _final_moves < _prev_best_moves
	return is_first or is_better


## Assigns UI node references. Called by the scene or test setup before
## populate_results().
func set_ui_nodes(
	level_name_label: Control,
	moves_label: Control,
	new_best_badge: Control,
	next_btn: Control,
	retry_btn: Control,
	world_map_btn: Control,
	star_nodes: Array[Control],
	star_sentinel_label: Control = null,
) -> void:
	_level_name_label = level_name_label
	_moves_label = moves_label
	_new_best_badge = new_best_badge
	_next_btn = next_btn
	_retry_btn = retry_btn
	_world_map_btn = world_map_btn
	_star_nodes = star_nodes
	_star_sentinel_label = star_sentinel_label


# —————————————————————————————————————————————
# Button handlers (connect from scene or test)
# —————————————————————————————————————————————

## Called when the Next Level button is pressed.
func on_next_btn_pressed() -> void:
	if _next_level_data == null:
		return
	next_level_requested.emit(_next_level_data)


## Called when the Retry button is pressed.
func on_retry_btn_pressed() -> void:
	if _current_level_data == null:
		return
	retry_requested.emit(_current_level_data)


## Called when the World Map button is pressed.
func on_world_map_btn_pressed() -> void:
	world_map_requested.emit()


# —————————————————————————————————————————————
# Display helpers
# —————————————————————————————————————————————

## Shows 0–3 filled stars or sentinel for unsolved levels.
func _show_stars(stars: int) -> void:
	# Handle sentinel (-1) for unsolved levels
	if stars == -1:
		for node: Control in _star_nodes:
			node.visible = false
		if _star_sentinel_label != null:
			_star_sentinel_label.visible = true
			_star_sentinel_label.text = "?"
		return

	# Hide sentinel if present
	if _star_sentinel_label != null:
		_star_sentinel_label.visible = false

	# Normal star display: show filled for earned, dim for unearned
	for i: int in range(_star_nodes.size()):
		if i < stars:
			_star_nodes[i].visible = true
			_star_nodes[i].modulate = STAR_EARNED_COLOR
		else:
			_star_nodes[i].visible = true
			_star_nodes[i].modulate = STAR_UNEARNED_COLOR

	if stars > 0:
		SfxManager.play(_sfx_star_earned, SfxManager.SfxBus.SFX)


## Updates the move count label. Handles minimum_moves == 0.
func _update_moves_label(final_moves: int, minimum_moves: int) -> void:
	if _moves_label == null:
		return
	if minimum_moves == 0:
		_moves_label.text = str(final_moves)
	else:
		_moves_label.text = "%d / %d" % [final_moves, minimum_moves]


## Shows or hides the new best badge.
func _update_new_best_badge() -> void:
	if _new_best_badge == null:
		return
	_new_best_badge.visible = is_new_best()


## Shows or hides the next level button based on next_level_data availability.
func _update_next_button() -> void:
	if _next_btn == null:
		return
	_next_btn.visible = _next_level_data != null


## Connects screen signals to SceneManager navigation. Only called when
## running as a standalone scene (auto-discovered buttons present). Tests
## skip this because _next_btn is null at _ready() time.
func _connect_navigation() -> void:
	if not next_level_requested.is_connected(_navigate_to_next_level):
		next_level_requested.connect(_navigate_to_next_level)
	if not retry_requested.is_connected(_navigate_to_retry):
		retry_requested.connect(_navigate_to_retry)
	if not world_map_requested.is_connected(_navigate_to_world_map):
		world_map_requested.connect(_navigate_to_world_map)


func _navigate_to_next_level(level_data: LevelData) -> void:
	SceneManager.go_to_level(level_data)


func _navigate_to_retry(level_data: LevelData) -> void:
	SceneManager.go_to_level(level_data)


func _navigate_to_world_map() -> void:
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP)


## Discovers child UI nodes by path when running inside the .tscn scene.
## Skipped if set_ui_nodes() was already called (e.g. from tests).
func _auto_discover_ui_nodes() -> void:
	if _level_name_label == null:
		_level_name_label = get_node_or_null("MarginContainer/VBox/LevelNameLabel")
	if _moves_label == null:
		_moves_label = get_node_or_null("MarginContainer/VBox/ScoreRow/MovesLabel")
	if _new_best_badge == null:
		_new_best_badge = get_node_or_null("MarginContainer/VBox/ScoreRow/NewBestBadge")

	if _star_nodes.is_empty():
		var s1: Control = get_node_or_null("MarginContainer/VBox/StarRow/Star1")
		var s2: Control = get_node_or_null("MarginContainer/VBox/StarRow/Star2")
		var s3: Control = get_node_or_null("MarginContainer/VBox/StarRow/Star3")
		if s1 != null and s2 != null and s3 != null:
			_star_nodes = [s1, s2, s3]

	if _star_sentinel_label == null:
		_star_sentinel_label = get_node_or_null("MarginContainer/VBox/StarRow/StarSentinel")

	if _next_btn == null:
		_next_btn = get_node_or_null("MarginContainer/VBox/ButtonRow/NextLevelBtn")
	if _next_btn != null and _next_btn is BaseButton:
		if not (_next_btn as BaseButton).pressed.is_connected(on_next_btn_pressed):
			(_next_btn as BaseButton).pressed.connect(on_next_btn_pressed)

	if _retry_btn == null:
		_retry_btn = get_node_or_null("MarginContainer/VBox/ButtonRow/RetryBtn")
	if _retry_btn != null and _retry_btn is BaseButton:
		if not (_retry_btn as BaseButton).pressed.is_connected(on_retry_btn_pressed):
			(_retry_btn as BaseButton).pressed.connect(on_retry_btn_pressed)

	if _world_map_btn == null:
		_world_map_btn = get_node_or_null("MarginContainer/VBox/ButtonRow/WorldMapBtn")
	if _world_map_btn != null and _world_map_btn is BaseButton:
		if not (_world_map_btn as BaseButton).pressed.is_connected(on_world_map_btn_pressed):
			(_world_map_btn as BaseButton).pressed.connect(on_world_map_btn_pressed)
