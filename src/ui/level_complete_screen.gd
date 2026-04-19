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

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const ICON_ARROW_RIGHT: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_arrow_right.png")
const ICON_RETRY: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_retry.png")
const ICON_HOME: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_home.png")
const CAT_CURIOUS_TEXTURE: Texture2D = preload("res://assets/art/cats/cat_default_curious.png")
const CAT_SMILE_TEXTURE: Texture2D = preload("res://assets/art/cats/cat_default_smile.png")
const CAT_EXCITED_TEXTURE: Texture2D = preload("res://assets/art/cats/cat_default_excited.png")

# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Gold color for earned stars — star-filled #F5C842.
const STAR_EARNED_COLOR: Color = Color(0.961, 0.784, 0.259, 1.0)

## Lavender-grey for unearned stars — star-empty #C8C4D0.
const STAR_UNEARNED_COLOR: Color = Color(0.784, 0.769, 0.816, 1.0)


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
var _min_label: Control # Label
var _prompt_label: Control # Label
var _new_best_badge: Control # Label / TextureRect
var _next_btn: Control # Button
var _retry_btn: Control # Button
var _world_map_btn: Control # Button
var _panel: PanelContainer
var _cat_illustration: TextureRect

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
var _use_internal_navigation: bool = true
var _star_pose_refresh_pending: bool = false

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
	_apply_visual_style()
	_apply_default_star_pose()
	_schedule_star_pose_refresh()
	# Self-connect navigation only when running in the real scene (auto-discover
	# found buttons). Tests use set_ui_nodes() after _ready(), so _next_btn is
	# still null here and these connections are skipped.
	if _next_btn != null and _use_internal_navigation:
		_connect_navigation()
	if _params_received:
		populate_results()


func _apply_default_star_pose() -> void:
	for i: int in range(_star_nodes.size()):
		var node: Control = _star_nodes[i]
		if node == null:
			continue
		node.pivot_offset = node.size * 0.5
		node.rotation_degrees = _star_rotation_for_index(i)


func _schedule_star_pose_refresh() -> void:
	if _star_pose_refresh_pending:
		return
	_star_pose_refresh_pending = true
	call_deferred("_refresh_star_pose_next_frame")


func _refresh_star_pose_next_frame() -> void:
	await get_tree().process_frame
	_star_pose_refresh_pending = false
	_apply_default_star_pose()


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
	_use_internal_navigation = params.get("internal_navigation", true) as bool
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
		var display_name: String = _current_level_data.display_name.strip_edges()
		if display_name != "":
			_level_name_label.text = display_name
		else:
			_level_name_label.text = "LEVEL COMPLETE!"

	# Stars
	_show_stars(_stars)

	# Move count
	_update_moves_label(_final_moves, _current_level_data.minimum_moves)

	# New best badge
	_update_new_best_badge()
	_update_cat_illustration(_stars, _final_moves, _current_level_data.minimum_moves)

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
	min_label: Control = null,
	prompt_label: Control = null,
) -> void:
	_level_name_label = level_name_label
	_moves_label = moves_label
	_min_label = min_label
	_prompt_label = prompt_label
	_new_best_badge = new_best_badge
	_next_btn = next_btn
	_retry_btn = retry_btn
	_world_map_btn = world_map_btn
	_star_nodes = star_nodes
	_star_sentinel_label = star_sentinel_label
	_apply_visual_style()


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
		var node: Control = _star_nodes[i]
		node.visible = true
		node.pivot_offset = node.size * 0.5
		node.rotation_degrees = _star_rotation_for_index(i)
		if node is TextureRect:
			var star_rect: TextureRect = node as TextureRect
			star_rect.texture = ShellThemeUtil.STAR_LARGE_FILLED_TEXTURE if i < stars else ShellThemeUtil.STAR_LARGE_EMPTY_TEXTURE
			star_rect.modulate = Color.WHITE
		elif i < stars:
			node.modulate = STAR_EARNED_COLOR
		else:
			node.modulate = STAR_UNEARNED_COLOR

	if stars > 0:
		SfxManager.play(_sfx_star_earned, SfxManager.SfxBus.SFX)
	_animate_star_reveal(stars)
	_schedule_star_pose_refresh()


## Updates the move count label. Handles minimum_moves == 0.
func _update_moves_label(final_moves: int, minimum_moves: int) -> void:
	if _moves_label != null:
		if _min_label == null:
			if minimum_moves == 0:
				_moves_label.text = str(final_moves)
			else:
				_moves_label.text = "%d / %d" % [final_moves, minimum_moves]
		else:
			_moves_label.text = "Moves: %d" % final_moves

	if _min_label != null:
		_min_label.visible = false
		_min_label.text = ""

	if _prompt_label != null:
		if minimum_moves == 0 or _is_perfect_result(final_moves, minimum_moves):
			_prompt_label.text = ""
		else:
			_prompt_label.text = "Can you do that in %d?" % minimum_moves


func _is_perfect_result(final_moves: int, minimum_moves: int) -> bool:
	return minimum_moves > 0 and final_moves <= minimum_moves


## Shows or hides the new best badge.
func _update_new_best_badge() -> void:
	if _new_best_badge == null:
		return
	var show_badge: bool = is_new_best()
	_new_best_badge.visible = show_badge
	if not show_badge or _is_reduce_motion_enabled():
		if _new_best_badge is Control:
			(_new_best_badge as Control).scale = Vector2.ONE
		return
	if _new_best_badge is Control:
		var badge: Control = _new_best_badge as Control
		badge.pivot_offset = badge.size * 0.5
		badge.scale = Vector2(0.72, 0.72)
		var tween: Tween = create_tween()
		tween.tween_property(badge, "scale", Vector2.ONE, 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_cat_illustration(stars: int, final_moves: int, minimum_moves: int) -> void:
	if _cat_illustration == null:
		return
	if _is_perfect_result(final_moves, minimum_moves):
		_cat_illustration.texture = CAT_SMILE_TEXTURE
	elif stars >= 3:
		_cat_illustration.texture = CAT_EXCITED_TEXTURE
	else:
		_cat_illustration.texture = CAT_CURIOUS_TEXTURE


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
	if _panel == null:
		_panel = get_node_or_null("MarginContainer/ResultsCard") as PanelContainer
	if _level_name_label == null:
		_level_name_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/Ribbon/LevelNameLabel")
		if _level_name_label == null:
			_level_name_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/LevelNameLabel")
	if _moves_label == null:
		_moves_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ScoreColumn/MovesLabel")
	if _min_label == null:
		_min_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ScoreColumn/MinLabel")
	if _prompt_label == null:
		_prompt_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ScoreColumn/PromptLabel")
	if _cat_illustration == null:
		_cat_illustration = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/CatIllustration") as TextureRect
	if _new_best_badge == null:
		_new_best_badge = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/Ribbon/NewBestBadge")
		if _new_best_badge == null:
			_new_best_badge = get_node_or_null("MarginContainer/ResultsCard/NewBestBadge")
		if _new_best_badge == null:
			_new_best_badge = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/NewBestBadge")
		if _new_best_badge == null:
			_new_best_badge = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ScoreColumn/NewBestBadge")

	if _star_nodes.is_empty():
		var s1: Control = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star1")
		var s2: Control = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star2")
		var s3: Control = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/Star3")
		if s1 != null and s2 != null and s3 != null:
			_star_nodes = [s1, s2, s3]

	if _star_sentinel_label == null:
		_star_sentinel_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/StarRow/StarSentinel")

	if _next_btn == null:
		_next_btn = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ButtonRow/NextLevelBtn")
	if _next_btn != null and _next_btn is BaseButton:
		if not (_next_btn as BaseButton).pressed.is_connected(on_next_btn_pressed):
			(_next_btn as BaseButton).pressed.connect(on_next_btn_pressed)

	if _retry_btn == null:
		_retry_btn = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ButtonRow/RetryBtn")
	if _retry_btn != null and _retry_btn is BaseButton:
		if not (_retry_btn as BaseButton).pressed.is_connected(on_retry_btn_pressed):
			(_retry_btn as BaseButton).pressed.connect(on_retry_btn_pressed)

	if _world_map_btn == null:
		_world_map_btn = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ButtonRow/WorldMapBtn")
	if _world_map_btn != null and _world_map_btn is BaseButton:
		if not (_world_map_btn as BaseButton).pressed.is_connected(on_world_map_btn_pressed):
			(_world_map_btn as BaseButton).pressed.connect(on_world_map_btn_pressed)


func _apply_visual_style() -> void:
	if _panel != null:
		ShellThemeUtil.apply_panel(_panel)
	if _level_name_label != null and _level_name_label is Label:
		var title_label: Label = _level_name_label as Label
		title_label.add_theme_font_override("font", ShellThemeUtil.FONT_DISPLAY)
		title_label.add_theme_font_size_override("font_size", ShellThemeUtil._scaled_font_size(40))
		title_label.add_theme_color_override("font_color", Color(1.0, 0.984, 0.957, 1.0))
	if _moves_label != null and _moves_label is Label:
		ShellThemeUtil.apply_title(_moves_label as Label, 40)
	if _min_label != null and _min_label is Label:
		(_min_label as Label).visible = false
	if _prompt_label != null and _prompt_label is Label:
		ShellThemeUtil.apply_body(_prompt_label as Label, Color(0.651, 0.537, 0.424, 1.0), 28)
	if _next_btn != null and _next_btn is BaseButton:
		ShellThemeUtil.apply_pill_button(_next_btn as BaseButton, ShellThemeUtil.MINT, ShellThemeUtil.MINT_PRESSED)
		if _next_btn is Button:
			(_next_btn as Button).icon = ICON_ARROW_RIGHT
			(_next_btn as Button).icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			(_next_btn as Button).expand_icon = false
	if _retry_btn != null and _retry_btn is BaseButton:
		ShellThemeUtil.apply_pill_button(_retry_btn as BaseButton, ShellThemeUtil.GOLD, ShellThemeUtil.GOLD_PRESSED)
		if _retry_btn is Button:
			(_retry_btn as Button).icon = ICON_RETRY
			(_retry_btn as Button).icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			(_retry_btn as Button).expand_icon = false
	if _world_map_btn != null and _world_map_btn is BaseButton:
		ShellThemeUtil.apply_pill_button(_world_map_btn as BaseButton, ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED)
		if _world_map_btn is Button:
			(_world_map_btn as Button).icon = ICON_HOME
			(_world_map_btn as Button).icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			(_world_map_btn as Button).expand_icon = false
	if _new_best_badge != null:
		_new_best_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _new_best_badge is Control:
			(_new_best_badge as Control).z_index = 5


func _animate_star_reveal(stars: int) -> void:
	if _is_reduce_motion_enabled():
		for i: int in range(_star_nodes.size()):
			var node: Control = _star_nodes[i]
			node.pivot_offset = node.size * 0.5
			node.scale = Vector2.ONE
			node.rotation_degrees = _star_rotation_for_index(i)
		return
	for i: int in range(_star_nodes.size()):
		var node: Control = _star_nodes[i]
		if node == null or not node.visible:
			continue
		node.pivot_offset = node.size * 0.5
		node.rotation_degrees = _star_rotation_for_index(i)
		node.scale = Vector2(0.94, 0.94) if i < stars else Vector2.ONE
		var tween: Tween = create_tween()
		tween.tween_property(node, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _star_rotation_for_index(index: int) -> float:
	if index < 0:
		return 0.0
	if index == 0:
		return -26.0
	if index == 2:
		return 26.0
	return 0.0


func _is_reduce_motion_enabled() -> bool:
	return AppSettings != null and AppSettings.get_reduce_motion()
