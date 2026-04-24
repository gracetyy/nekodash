## HUD — in-level overlay displaying move count, coverage, and undo/restart buttons.
## Implements: design/gdd/hud.md
## Task: S2-04
##
## Pure display and input-forwarding layer. Reads from gameplay systems via
## signals and properties, forwards button presses to Undo/Restart, owns no
## game state. Lives as a child of the gameplay scene root alongside Level
## Coordinator.
##
## Usage:
##   hud.initialize(level_data, move_counter, undo_restart, coverage_tracking)
class_name HUD
extends CanvasLayer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when player presses the Undo button.
signal undo_pressed

## Emitted when player presses the Restart button.
signal restart_pressed

## Emitted when player presses the Exit button (abandon level, no save).
signal exit_pressed

## Emitted when player presses the Pause button.
signal pause_pressed


# —————————————————————————————————————————————
# Child node references
# —————————————————————————————————————————————

## Set via inspector wiring or test injection through set_ui_nodes().
@export var _move_label: Label
@export var _coverage_label: Label
@export var _undo_btn: BaseButton
@export var _restart_btn: BaseButton
@export var _exit_btn: BaseButton
@export var _pause_btn: BaseButton
@export var _chrome_panel: Control
@export var _moves_prefix_label: Label
@export var _star_strip: Control


# —————————————————————————————————————————————
# Dependencies (set via initialize)
# —————————————————————————————————————————————

## Reference to UndoRestart — needed for can_undo() checks and undo/restart calls.
var _undo_restart_ref: Node

## Reference to MoveCounter — needed for live reads on restart.
var _move_counter_ref: Node

## Reference to CoverageTracking — needed for live reads on restart.
var _coverage_tracking_ref: Node

## Cached minimum_moves from LevelData — used for display format.
var _minimum_moves: int = 0
var _star_3_moves: int = 0
var _star_2_moves: int = 0
var _star_1_moves: int = 0

## Whether the HUD has been initialized.
var _initialized: bool = false

## Whether the level is complete (buttons locked).
var _level_complete: bool = false

## Stub SFX stream for button taps (replace with real audio asset later).
var _sfx_button_tap: AudioStream = AudioStreamWAV.new()


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	if _move_label == null:
		_move_label = get_node_or_null("MarginContainer/TopRow/MoveCounter/MoveLabel")
	if _coverage_label == null:
		_coverage_label = get_node_or_null("MarginContainer/TopRow/CenterPill/CoverageLabel")
	if _undo_btn == null:
		_undo_btn = get_node_or_null("MarginContainer/TopRow/ButtonRow/UndoBtn")
	if _restart_btn == null:
		_restart_btn = get_node_or_null("MarginContainer/TopRow/ButtonRow/RestartBtn")
	if _exit_btn == null:
		_exit_btn = get_node_or_null("MarginContainer/TopRow/ButtonRow/ExitBtn")
	if _pause_btn == null:
		_pause_btn = get_node_or_null("MarginContainer/TopRow/ButtonRow/PauseBtn")
	if _chrome_panel == null:
		_chrome_panel = get_node_or_null("MarginContainer/TopRow/CenterPill")
	if _moves_prefix_label == null:
		_moves_prefix_label = get_node_or_null("MarginContainer/TopRow/MoveCounter/MovesPrefix")
	if _star_strip == null:
		_star_strip = get_node_or_null("MarginContainer/TopRow/CenterPill/StarStrip")
	assert(_move_label != null, "_move_label not assigned")
	assert(_undo_btn != null, "_undo_btn not assigned")
	assert(_restart_btn != null, "_restart_btn not assigned")
	assert(_exit_btn != null, "_exit_btn not assigned")
	assert(_pause_btn != null, "_pause_btn not assigned")
	assert(_chrome_panel != null, "_chrome_panel not assigned")
	assert(_moves_prefix_label != null, "_moves_prefix_label not assigned")
	assert(_star_strip != null, "_star_strip not assigned")
	_connect_button_signals()
	_apply_visual_style()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Initializes the HUD with references to gameplay systems and connects
## signals. Called by Level Coordinator after all gameplay nodes are ready.
func initialize(
	level_data: LevelData,
	move_counter: Node,
	undo_restart: Node,
	coverage_tracking: Node,
) -> void:
	if level_data == null:
		push_error("HUD: initialize() called with null LevelData.")
		return
	if move_counter == null:
		push_error("HUD: initialize() called with null move_counter.")
		return
	if undo_restart == null:
		push_error("HUD: initialize() called with null undo_restart.")
		return
	if coverage_tracking == null:
		push_error("HUD: initialize() called with null coverage_tracking.")
		return

	_undo_restart_ref = undo_restart
	_move_counter_ref = move_counter
	_coverage_tracking_ref = coverage_tracking
	_minimum_moves = level_data.minimum_moves
	_star_3_moves = level_data.star_3_moves
	_star_2_moves = level_data.star_2_moves
	_star_1_moves = level_data.star_1_moves
	_level_complete = false

	# Disconnect previous signals (safe re-initialize)
	_disconnect_signals()

	# Connect signals
	_connect_signals(move_counter, undo_restart, coverage_tracking)

	# Initial display state
	_refresh_all_displays(
		move_counter.get_current_moves(),
		coverage_tracking.get_covered_count(),
		coverage_tracking.get_total_walkable(),
	)

	# Undo button starts disabled (no history at level load)
	_set_undo_button_disabled(true)

	# Ensure buttons are visible
	_set_undo_button_visible(true)
	_set_restart_button_visible(true)
	_set_exit_button_visible(true)
	_set_pause_button_visible(true)
	if _coverage_label != null:
		_coverage_label.visible = false

	_initialized = true


## Returns whether the HUD has been initialized.
func is_initialized() -> bool:
	return _initialized


## Returns whether the level is complete (buttons locked).
func is_level_complete() -> bool:
	return _level_complete


## Assigns UI node references. Called by the scene or test setup to inject
## the actual Control nodes before initialize().
func set_ui_nodes(
	move_label: Control,
	coverage_label: Control,
	undo_btn: Control,
	restart_btn: Control,
	exit_btn: Control = null,
	pause_btn: Control = null,
) -> void:
	_move_label = move_label as Label
	_coverage_label = coverage_label as Label
	_undo_btn = undo_btn as BaseButton
	_restart_btn = restart_btn as BaseButton
	_exit_btn = exit_btn as BaseButton
	_pause_btn = pause_btn as BaseButton
	_connect_button_signals()
	_apply_visual_style()


# —————————————————————————————————————————————
# Signal connection
# —————————————————————————————————————————————

## Disconnects previously connected signals. Safe to call when no signals are
## connected. Prevents double-connect on re-initialize.
func _disconnect_signals() -> void:
	if _move_counter_ref != null:
		if _move_counter_ref.has_signal("move_count_changed") and _move_counter_ref.move_count_changed.is_connected(_on_move_count_changed):
			_move_counter_ref.move_count_changed.disconnect(_on_move_count_changed)
	if _coverage_tracking_ref != null:
		if _coverage_tracking_ref.has_signal("coverage_updated") and _coverage_tracking_ref.coverage_updated.is_connected(_on_coverage_updated):
			_coverage_tracking_ref.coverage_updated.disconnect(_on_coverage_updated)
		if _coverage_tracking_ref.has_signal("level_completed") and _coverage_tracking_ref.level_completed.is_connected(_on_level_completed):
			_coverage_tracking_ref.level_completed.disconnect(_on_level_completed)
	if _undo_restart_ref != null:
		if _undo_restart_ref.has_signal("undo_applied") and _undo_restart_ref.undo_applied.is_connected(_on_undo_applied):
			_undo_restart_ref.undo_applied.disconnect(_on_undo_applied)
		if _undo_restart_ref.has_signal("level_restarted") and _undo_restart_ref.level_restarted.is_connected(_on_level_restarted):
			_undo_restart_ref.level_restarted.disconnect(_on_level_restarted)


func _connect_signals(
	move_counter: Node,
	undo_restart: Node,
	coverage_tracking: Node,
) -> void:
	# MoveCounter → move display
	if move_counter.has_signal("move_count_changed"):
		move_counter.move_count_changed.connect(_on_move_count_changed)

	# CoverageTracking → coverage display + level complete lock
	if coverage_tracking.has_signal("coverage_updated"):
		coverage_tracking.coverage_updated.connect(_on_coverage_updated)
	if coverage_tracking.has_signal("level_completed"):
		coverage_tracking.level_completed.connect(_on_level_completed)

	# UndoRestart → undo button state + restart reset
	if undo_restart.has_signal("undo_applied"):
		undo_restart.undo_applied.connect(_on_undo_applied)
	if undo_restart.has_signal("level_restarted"):
		undo_restart.level_restarted.connect(_on_level_restarted)


# —————————————————————————————————————————————
# Signal handlers
# —————————————————————————————————————————————

## Updates the move display. Handles minimum_moves == 0 gracefully.
## Also refreshes undo button — UndoRestart has already pushed a snapshot by
## the time move_count_changed fires (connection order enforced by coordinator).
func _on_move_count_changed(current: int, _minimum: int) -> void:
	if _move_label == null:
		return
	_move_label.text = str(current)
	_update_star_strip(current)
	if _undo_restart_ref != null:
		_set_undo_button_disabled(not _undo_restart_ref.can_undo())


## Updates the coverage display in "X / Y" tile format.
func _on_coverage_updated(covered: int, total: int) -> void:
	if _coverage_label == null:
		return
	_coverage_label.text = "%d / %d" % [covered, total]


## Refreshes undo button disabled state after an undo.
func _on_undo_applied(_moves_remaining: int) -> void:
	if _undo_restart_ref == null:
		return
	_set_undo_button_disabled(not _undo_restart_ref.can_undo())


## Resets all displays to initial state after a restart. Reads live values
## from the systems (which have already processed their resets by the time
## level_restarted fires).
func _on_level_restarted() -> void:
	if _move_counter_ref != null and _coverage_tracking_ref != null:
		_refresh_all_displays(
			_move_counter_ref.get_current_moves(),
			_coverage_tracking_ref.get_covered_count(),
			_coverage_tracking_ref.get_total_walkable(),
		)
	_set_undo_button_disabled(true)
	_set_undo_button_visible(true)
	_set_restart_button_visible(true)
	_set_exit_button_visible(true)
	_set_pause_button_visible(true)
	_level_complete = false


## Locks interactive elements after level completion.
func _on_level_completed() -> void:
	_level_complete = true


# —————————————————————————————————————————————
# Button handlers (connect from scene or test)
# —————————————————————————————————————————————

## Called when the Undo button is pressed. Forwards to UndoRestart.
func on_undo_btn_pressed() -> void:
	if _undo_restart_ref == null:
		return
	if _level_complete:
		return
	_undo_restart_ref.undo()
	undo_pressed.emit()
	SfxManager.play(_sfx_button_tap, SfxManager.SfxBus.UI)


## Called when the Restart button is pressed. Forwards to UndoRestart.
func on_restart_btn_pressed() -> void:
	if _undo_restart_ref == null:
		return
	if _level_complete:
		return
	_undo_restart_ref.restart()
	restart_pressed.emit()
	SfxManager.play(_sfx_button_tap, SfxManager.SfxBus.UI)


## Called when the Exit button is pressed. Navigates to World Map without saving.
func on_exit_btn_pressed() -> void:
	if _level_complete:
		return
	exit_pressed.emit()
	SfxManager.play(_sfx_button_tap, SfxManager.SfxBus.UI)


## Called when the Pause button is pressed. The coordinator owns the pause
## transition; HUD only forwards the intent.
func on_pause_btn_pressed() -> void:
	if _level_complete:
		return
	pause_pressed.emit()
	SfxManager.play(_sfx_button_tap, SfxManager.SfxBus.UI)


# —————————————————————————————————————————————
# Display helpers
# —————————————————————————————————————————————

## Refreshes all display elements from current state.
func _refresh_all_displays(
	current_moves: int,
	covered: int,
	total: int,
) -> void:
	if _coverage_label != null:
		_coverage_label.visible = false
	_on_move_count_changed(current_moves, _minimum_moves)
	_on_coverage_updated(covered, total)


func _update_star_strip(current_moves: int) -> void:
	if _star_strip == null:
		return

	var star_3_threshold: int = _star_3_moves
	if star_3_threshold <= 0 and _minimum_moves > 0:
		star_3_threshold = _minimum_moves

	var star_2_threshold: int = _star_2_moves
	if star_2_threshold <= 0 and star_3_threshold > 0:
		star_2_threshold = star_3_threshold + 2

	var star_1_threshold: int = _star_1_moves
	if star_1_threshold <= 0 and star_2_threshold > 0:
		star_1_threshold = star_2_threshold + 2

	if star_2_threshold > 0 and star_2_threshold < star_3_threshold:
		star_2_threshold = star_3_threshold
	if star_1_threshold > 0 and star_1_threshold < star_2_threshold:
		star_1_threshold = star_2_threshold

	var stars: int = 0
	if star_3_threshold > 0:
		if current_moves <= star_3_threshold:
			stars = 3
		elif current_moves <= star_2_threshold:
			stars = 2
		elif current_moves <= star_1_threshold:
			stars = 1

	if _star_strip.has_method("configure"):
		_star_strip.call("configure", stars, 1, 0, 0, 4.0)


## Sets undo button disabled state with null safety.
func _set_undo_button_disabled(disabled: bool) -> void:
	if _undo_btn != null and _undo_btn is BaseButton:
		(_undo_btn as BaseButton).disabled = disabled


## Sets undo button visibility with null safety.
func _set_undo_button_visible(visible_flag: bool) -> void:
	if _undo_btn != null:
		_undo_btn.visible = visible_flag


## Sets restart button visibility with null safety.
func _set_restart_button_visible(visible_flag: bool) -> void:
	if _restart_btn != null:
		_restart_btn.visible = visible_flag


## Sets exit button visibility with null safety.
func _set_exit_button_visible(visible_flag: bool) -> void:
	if _exit_btn != null:
		_exit_btn.visible = visible_flag


## Sets pause button visibility with null safety.
func _set_pause_button_visible(visible_flag: bool) -> void:
	if _pause_btn != null:
		_pause_btn.visible = visible_flag


func _connect_button_signals() -> void:
	if _undo_btn != null and not _undo_btn.pressed.is_connected(on_undo_btn_pressed):
		_undo_btn.pressed.connect(on_undo_btn_pressed)
	if _restart_btn != null and not _restart_btn.pressed.is_connected(on_restart_btn_pressed):
		_restart_btn.pressed.connect(on_restart_btn_pressed)
	if _exit_btn != null and not _exit_btn.pressed.is_connected(on_exit_btn_pressed):
		_exit_btn.pressed.connect(on_exit_btn_pressed)
	if _pause_btn != null and not _pause_btn.pressed.is_connected(on_pause_btn_pressed):
		_pause_btn.pressed.connect(on_pause_btn_pressed)


func _apply_visual_style() -> void:
	if _moves_prefix_label != null:
		_moves_prefix_label.add_theme_color_override("font_color", Color(0.972, 0.922, 0.761, 1.0))
		_moves_prefix_label.add_theme_font_size_override("font_size", 21)
		_moves_prefix_label.add_theme_font_override("font", ShellThemeUtil.FONT_DISPLAY)
	if _move_label != null and _move_label is Label:
		(_move_label as Label).add_theme_color_override("font_color", Color(0.972, 0.922, 0.761, 1.0))
		(_move_label as Label).add_theme_font_size_override("font_size", 34)
		(_move_label as Label).add_theme_font_override("font", ShellThemeUtil.FONT_DISPLAY)
	if _coverage_label != null and _coverage_label is Label:
		(_coverage_label as Label).visible = false
