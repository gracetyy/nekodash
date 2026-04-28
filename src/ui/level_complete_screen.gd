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

# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

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

@export var _level_name_ribbon: RibbonHeader
@export var _moves_label: Label
@export var _min_label: Label
@export var _prompt_label: Label
@export var _new_best_badge: Control # Label / TextureRect
@export var _next_btn: BaseButton
@export var _retry_btn: BaseButton
@export var _world_map_btn: BaseButton
@export var _panel: PanelContainer
@export var _cat_illustration: CatRig

## Star display nodes — array of 3 Controls (e.g. TextureRect or Label).
## Filled stars are visible; empty stars are dimmed or hidden.
@export var _star_strip: Control


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
var _level_name_label: Label
var _legacy_star_nodes: Array[Control] = []
var _legacy_star_sentinel: Label
var _base_panel_width: float = 0.0
var _base_ribbon_offset_left: float = 0.0
var _base_ribbon_offset_right: float = 0.0

## Whether params have been received.
var _params_received: bool = false

## Whether results have been populated.
var _populated: bool = false

## Stub SFX stream for star earned (replace with real audio asset later).
var _sfx_star_earned: AudioStream = AudioStreamWAV.new()

const RIBBON_TITLE_LEVEL_COMPLETE: String = "Level Complete!"
const RIBBON_TITLE_PERFECT: String = "Perfect!"


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	if _panel == null:
		_panel = get_node_or_null("MarginContainer/ResultsCard")
	if _level_name_ribbon == null:
		_level_name_ribbon = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/RibbonSlot/Ribbon")
	if _moves_label == null:
		_moves_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ScoreColumn/MovesLabel")
	if _min_label == null:
		_min_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ScoreColumn/MinLabel")
	if _prompt_label == null:
		_prompt_label = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ScoreColumn/PromptLabel")
	if _cat_illustration == null:
		_cat_illustration = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/CatIllustration")
	if _new_best_badge == null:
		_new_best_badge = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/RibbonSlot/Ribbon/NewBestBadge")
	if _star_strip == null:
		_star_strip = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/StarRow")
	if _next_btn == null:
		_next_btn = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ButtonRow/NextLevelBtn")
	if _retry_btn == null:
		_retry_btn = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ButtonRow/RetryBtn")
	if _world_map_btn == null:
		_world_map_btn = get_node_or_null("MarginContainer/ResultsCard/CardMargin/VBox/ButtonRow/WorldMapBtn")
	assert(_panel != null, "_panel not assigned")
	assert(_level_name_ribbon != null, "_level_name_ribbon not assigned")
	assert(_moves_label != null, "_moves_label not assigned")
	assert(_min_label != null, "_min_label not assigned")
	assert(_prompt_label != null, "_prompt_label not assigned")
	assert(_cat_illustration != null, "_cat_illustration not assigned")
	assert(_new_best_badge != null, "_new_best_badge not assigned")
	assert(_star_strip != null, "_star_strip not assigned")
	assert(_next_btn != null, "_next_btn not assigned")
	assert(_retry_btn != null, "_retry_btn not assigned")
	assert(_world_map_btn != null, "_world_map_btn not assigned")
	_connect_button_signals()
	_apply_visual_style()
	if _panel != null and not _panel.resized.is_connected(_on_panel_resized):
		_panel.resized.connect(_on_panel_resized)
	_base_panel_width = _panel.size.x
	if _level_name_ribbon != null:
		_base_ribbon_offset_left = _level_name_ribbon.offset_left
		_base_ribbon_offset_right = _level_name_ribbon.offset_right
	_sync_ribbon_scale_with_panel()
	# Self-connect navigation only when running in the real scene (auto-discover
	# found buttons). Tests use set_ui_nodes() after _ready(), so _next_btn is
	# still null here and these connections are skipped.
	if _next_btn != null and _use_internal_navigation:
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

	var minimum_moves: int = _current_level_data.minimum_moves
	var is_perfect: bool = _is_perfect_result(_final_moves, minimum_moves)

	# Ribbon title (no level name): default completion or perfect result.
	if _level_name_ribbon != null:
		_level_name_ribbon.set_title(RIBBON_TITLE_PERFECT if is_perfect else RIBBON_TITLE_LEVEL_COMPLETE)
	elif _level_name_label != null:
		_level_name_label.text = RIBBON_TITLE_PERFECT if is_perfect else RIBBON_TITLE_LEVEL_COMPLETE

	# Stars
	_show_stars(_stars)

	# Move count
	_update_moves_label(_final_moves, minimum_moves)

	# New best badge
	_update_new_best_badge()
	_update_cat_illustration(_stars, _final_moves, minimum_moves)

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
	if level_name_label is RibbonHeader:
		_level_name_ribbon = level_name_label as RibbonHeader
		_level_name_label = null
	else:
		_level_name_label = level_name_label as Label
	_moves_label = moves_label as Label
	_min_label = min_label as Label
	_prompt_label = prompt_label as Label
	_new_best_badge = new_best_badge
	_next_btn = next_btn as BaseButton
	_retry_btn = retry_btn as BaseButton
	_world_map_btn = world_map_btn as BaseButton
	_legacy_star_nodes.clear()
	for node: Control in star_nodes:
		_legacy_star_nodes.append(node)
	_legacy_star_sentinel = star_sentinel_label as Label
	_star_strip = star_sentinel_label as Control
	if _star_strip == null and not star_nodes.is_empty() and star_nodes[0] is Control:
		_star_strip = star_nodes[0] as Control
	_connect_button_signals()
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
	if _star_strip == null:
		return
	if _star_strip.has_method("configure"):
		_star_strip.call("configure", stars, 2, 1, 0, 6.0)
	_apply_legacy_star_visuals(stars)

	if stars > 0:
		SfxManager.play(_sfx_star_earned, SfxManager.SfxBus.SFX)
	_animate_star_reveal(stars)


func _apply_legacy_star_visuals(stars: int) -> void:
	if _star_strip == null:
		return
	var star_nodes: Array[Control] = _legacy_star_nodes.duplicate()
	if star_nodes.is_empty():
		for star_name: String in ["Star1", "Star2", "Star3"]:
			var star_node: Control = _star_strip.get_node_or_null(star_name) as Control
			if star_node != null:
				star_nodes.append(star_node)
	if star_nodes.is_empty():
		for child: Node in _star_strip.get_children():
			if child is Control:
				star_nodes.append(child as Control)

	var sentinel: Label = _legacy_star_sentinel
	if sentinel == null:
		sentinel = _star_strip.get_node_or_null("StarSentinel") as Label
	if sentinel == null:
		sentinel = _star_strip as Label

	if stars < 0:
		for star: Control in star_nodes:
			star.visible = false
		if sentinel != null:
			sentinel.visible = true
			sentinel.text = "?"
		return

	for index: int in range(star_nodes.size()):
		var star: Control = star_nodes[index]
		star.visible = true
	if sentinel != null:
		sentinel.visible = false


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
		if minimum_moves == 0:
			_prompt_label.text = ""
		elif _is_perfect_result(final_moves, minimum_moves):
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
		_cat_illustration.pose_variant = "smile"
	elif stars >= 3:
		_cat_illustration.pose_variant = "happy"
	else:
		_cat_illustration.pose_variant = "curious"
	_cat_illustration.refresh_rig()


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


func _connect_button_signals() -> void:
	if _next_btn != null and not _next_btn.pressed.is_connected(on_next_btn_pressed):
		_next_btn.pressed.connect(on_next_btn_pressed)
	if _retry_btn != null and not _retry_btn.pressed.is_connected(on_retry_btn_pressed):
		_retry_btn.pressed.connect(on_retry_btn_pressed)
	if _world_map_btn != null and not _world_map_btn.pressed.is_connected(on_world_map_btn_pressed):
		_world_map_btn.pressed.connect(on_world_map_btn_pressed)


func _apply_visual_style() -> void:
	if _level_name_ribbon != null:
		_level_name_ribbon.title_font_size = 40
		_level_name_ribbon.title_color = Color(1.0, 0.984, 0.957, 1.0)
		_level_name_ribbon.refresh_style()
	if _moves_label != null and _moves_label is Label:
		if (_moves_label as Label).has_method("refresh_style"):
			(_moves_label as Label).call("refresh_style")
	if _min_label != null and _min_label is Label:
		(_min_label as Label).visible = false
	if _prompt_label != null and _prompt_label is Label:
		ShellThemeUtil.apply_body(_prompt_label as Label, Color(0.651, 0.537, 0.424, 1.0), 28)
	if _next_btn != null and _next_btn is Button:
		(_next_btn as Button).icon = ICON_ARROW_RIGHT
		(_next_btn as Button).icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		(_next_btn as Button).expand_icon = false
	if _retry_btn != null and _retry_btn is Button:
		(_retry_btn as Button).icon = ICON_RETRY
		(_retry_btn as Button).icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		(_retry_btn as Button).expand_icon = false
	if _world_map_btn != null and _world_map_btn is Button:
		(_world_map_btn as Button).icon = ICON_HOME
		(_world_map_btn as Button).icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		(_world_map_btn as Button).expand_icon = false
	if _new_best_badge != null:
		_new_best_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _new_best_badge is Control:
			(_new_best_badge as Control).z_index = 5


func _animate_star_reveal(stars: int) -> void:
	if _star_strip == null:
		return
	if _is_reduce_motion_enabled():
		_star_strip.pivot_offset = _star_strip.size * 0.5
		_star_strip.scale = Vector2.ONE
		return
	_star_strip.pivot_offset = _star_strip.size * 0.5
	_star_strip.scale = Vector2(0.94, 0.94) if stars > 0 else Vector2.ONE
	var tween: Tween = create_tween()
	tween.tween_property(_star_strip, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _is_reduce_motion_enabled() -> bool:
	return AppSettings != null and AppSettings.get_reduce_motion()


func _on_panel_resized() -> void:
	_sync_ribbon_scale_with_panel()


func _sync_ribbon_scale_with_panel() -> void:
	if _panel == null or _level_name_ribbon == null:
		return
	if _base_panel_width <= 0.0:
		_base_panel_width = _panel.size.x
	if _base_panel_width <= 0.0:
		return
	var width_ratio: float = _panel.size.x / _base_panel_width
	var ribbon_scale: float = clampf(width_ratio, 1.0, 1.35)
	_level_name_ribbon.offset_left = _base_ribbon_offset_left * ribbon_scale
	_level_name_ribbon.offset_right = _base_ribbon_offset_right * ribbon_scale
