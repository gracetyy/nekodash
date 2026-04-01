## Unit tests for HUD gameplay UI node.
## Task: S2-03
## Covers: initialize, signal-driven updates, button forwarding, level complete
##         lock, minimum_moves == 0 display, undo button state, edge cases.
##
## Acceptance criteria cross-ref: design/gdd/hud.md
extends GutTest

var _hud: Node  # HUD instance under test

# Mock systems
var _mc: Node   # Mock MoveCounter
var _ur: Node   # Mock UndoRestart
var _ct: Node   # Mock CoverageTracking

# Mock UI nodes
var _level_name_label: Label
var _move_label: Label
var _coverage_label: Label
var _undo_btn: Button
var _restart_btn: Button

# Signal tracking
var _undo_pressed_count: int = 0
var _restart_pressed_count: int = 0

# Mock UndoRestart tracking
var _ur_undo_count: int = 0
var _ur_restart_count: int = 0


# —————————————————————————————————————————————
# Mock classes
# —————————————————————————————————————————————

## Minimal mock of MoveCounter with the signals HUD connects to.
class MockMoveCounter extends Node:
	var _current: int = 0
	var _minimum: int = 0

	signal move_count_changed(current: int, minimum: int)

	func get_current_moves() -> int:
		return _current

	func set_test_state(current: int, minimum: int) -> void:
		_current = current
		_minimum = minimum

	func emit_move_count_changed() -> void:
		move_count_changed.emit(_current, _minimum)


## Minimal mock of UndoRestart with the signals and API the HUD needs.
class MockUndoRestart extends Node:
	var test_ref  # reference to test instance for logging
	var _can_undo: bool = false

	signal undo_applied(moves_in_history: int)
	signal level_restarted

	func can_undo() -> bool:
		return _can_undo

	func set_can_undo(val: bool) -> void:
		_can_undo = val

	func undo() -> void:
		test_ref._ur_undo_count += 1

	func restart() -> void:
		test_ref._ur_restart_count += 1


## Minimal mock of CoverageTracking with the signals HUD connects to.
class MockCoverageTracking extends Node:
	var _covered: int = 0
	var _total: int = 0

	signal coverage_updated(covered: int, total: int)
	signal level_completed

	func get_covered_count() -> int:
		return _covered

	func get_total_walkable() -> int:
		return _total

	func set_test_state(covered: int, total: int) -> void:
		_covered = covered
		_total = total

	func emit_coverage_updated() -> void:
		coverage_updated.emit(_covered, _total)


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_hud = load("res://src/ui/hud.gd").new()
	add_child_autofree(_hud)

	# Create mock systems
	_mc = MockMoveCounter.new()
	add_child_autofree(_mc)

	_ur = MockUndoRestart.new()
	_ur.test_ref = self
	add_child_autofree(_ur)

	_ct = MockCoverageTracking.new()
	add_child_autofree(_ct)

	# Create mock UI nodes
	_level_name_label = Label.new()
	add_child_autofree(_level_name_label)

	_move_label = Label.new()
	add_child_autofree(_move_label)

	_coverage_label = Label.new()
	add_child_autofree(_coverage_label)

	_undo_btn = Button.new()
	add_child_autofree(_undo_btn)

	_restart_btn = Button.new()
	add_child_autofree(_restart_btn)

	# Inject UI nodes into HUD
	_hud.set_ui_nodes(
		_level_name_label,
		_move_label,
		_coverage_label,
		_undo_btn,
		_restart_btn,
	)

	# Reset tracking
	_undo_pressed_count = 0
	_restart_pressed_count = 0
	_ur_undo_count = 0
	_ur_restart_count = 0

	_hud.undo_pressed.connect(_on_undo_pressed)
	_hud.restart_pressed.connect(_on_restart_pressed)


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_undo_pressed() -> void:
	_undo_pressed_count += 1


func _on_restart_pressed() -> void:
	_restart_pressed_count += 1


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

func _make_level_data(
	display_name: String = "Test Level",
	minimum_moves: int = 8,
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = "test_l1"
	ld.display_name = display_name
	ld.minimum_moves = minimum_moves
	ld.grid_width = 3
	ld.grid_height = 3
	ld.star_3_moves = minimum_moves
	ld.star_2_moves = minimum_moves + 2 if minimum_moves > 0 else 0
	ld.star_1_moves = minimum_moves + 4 if minimum_moves > 0 else 0
	return ld


func _init_hud(ld: LevelData = null) -> void:
	if ld == null:
		ld = _make_level_data()
	_hud.initialize(ld, _mc, _ur, _ct)


# —————————————————————————————————————————————
# Initialization Tests
# —————————————————————————————————————————————

func test_initialize_sets_initialized_flag() -> void:
	_init_hud()
	assert_true(_hud.is_initialized())


func test_initialize_not_initialized_by_default() -> void:
	assert_false(_hud.is_initialized())


func test_initialize_sets_level_name() -> void:
	_init_hud(_make_level_data("Sunny Fields"))
	assert_eq(_level_name_label.text, "Sunny Fields")


func test_initialize_sets_move_display_with_minimum() -> void:
	_mc.set_test_state(0, 8)
	_init_hud(_make_level_data("Test", 8))
	assert_eq(_move_label.text, "0 / 8")


func test_initialize_sets_move_display_without_minimum() -> void:
	_mc.set_test_state(0, 0)
	_init_hud(_make_level_data("Test", 0))
	assert_eq(_move_label.text, "0")


func test_initialize_sets_coverage_display() -> void:
	_ct.set_test_state(1, 20)
	_init_hud()
	assert_eq(_coverage_label.text, "1 / 20")


func test_initialize_undo_button_disabled() -> void:
	_init_hud()
	assert_true(_undo_btn.disabled)


func test_initialize_undo_button_visible() -> void:
	_init_hud()
	assert_true(_undo_btn.visible)


func test_initialize_restart_button_visible() -> void:
	_init_hud()
	assert_true(_restart_btn.visible)


func test_initialize_level_complete_false() -> void:
	_init_hud()
	assert_false(_hud.is_level_complete())


func test_initialize_null_level_data_returns_early() -> void:
	_hud.initialize(null, _mc, _ur, _ct)
	assert_false(_hud.is_initialized())


func test_initialize_null_move_counter_returns_early() -> void:
	_hud.initialize(_make_level_data(), null, _ur, _ct)
	assert_false(_hud.is_initialized())


func test_initialize_null_undo_restart_returns_early() -> void:
	_hud.initialize(_make_level_data(), _mc, null, _ct)
	assert_false(_hud.is_initialized())


func test_initialize_null_coverage_tracking_returns_early() -> void:
	_hud.initialize(_make_level_data(), _mc, _ur, null)
	assert_false(_hud.is_initialized())


# —————————————————————————————————————————————
# Move Count Signal Tests
# —————————————————————————————————————————————

func test_move_count_changed_updates_display_with_minimum() -> void:
	_init_hud(_make_level_data("Test", 10))
	_mc.set_test_state(3, 10)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "3 / 10")


func test_move_count_changed_updates_display_without_minimum() -> void:
	_init_hud(_make_level_data("Test", 0))
	_mc.set_test_state(5, 0)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "5")


func test_move_count_changed_multiple_updates() -> void:
	_init_hud(_make_level_data("Test", 8))
	_mc.set_test_state(1, 8)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "1 / 8")
	_mc.set_test_state(4, 8)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "4 / 8")
	_mc.set_test_state(8, 8)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "8 / 8")


func test_move_count_changed_exceeds_minimum() -> void:
	_init_hud(_make_level_data("Test", 5))
	_mc.set_test_state(7, 5)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "7 / 5")


# —————————————————————————————————————————————
# Coverage Signal Tests
# —————————————————————————————————————————————

func test_coverage_updated_updates_display() -> void:
	_init_hud()
	_ct.set_test_state(5, 20)
	_ct.emit_coverage_updated()
	assert_eq(_coverage_label.text, "5 / 20")


func test_coverage_updated_full_coverage() -> void:
	_init_hud()
	_ct.set_test_state(20, 20)
	_ct.emit_coverage_updated()
	assert_eq(_coverage_label.text, "20 / 20")


func test_coverage_updated_zero() -> void:
	_init_hud()
	_ct.set_test_state(0, 15)
	_ct.emit_coverage_updated()
	assert_eq(_coverage_label.text, "0 / 15")


# —————————————————————————————————————————————
# Undo Button State Tests
# —————————————————————————————————————————————

func test_undo_applied_enables_undo_button_when_history_exists() -> void:
	_init_hud()
	_ur.set_can_undo(true)
	_ur.undo_applied.emit(2)
	assert_false(_undo_btn.disabled)


func test_undo_applied_disables_undo_button_when_history_empty() -> void:
	_init_hud()
	_ur.set_can_undo(false)
	_ur.undo_applied.emit(0)
	assert_true(_undo_btn.disabled)


func test_undo_applied_sequence_enable_then_disable() -> void:
	_init_hud()
	# After a few moves, undo available
	_ur.set_can_undo(true)
	_ur.undo_applied.emit(2)
	assert_false(_undo_btn.disabled)
	# After undoing all moves, undo unavailable
	_ur.set_can_undo(false)
	_ur.undo_applied.emit(0)
	assert_true(_undo_btn.disabled)


# —————————————————————————————————————————————
# Level Restarted Signal Tests
# —————————————————————————————————————————————

func test_level_restarted_resets_move_display() -> void:
	_init_hud(_make_level_data("Test", 8))
	_mc.set_test_state(5, 8)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "5 / 8")
	# Simulate reset that occurs before level_restarted fires
	_mc.set_test_state(0, 8)
	_ur.level_restarted.emit()
	assert_eq(_move_label.text, "0 / 8")


func test_level_restarted_resets_coverage_display() -> void:
	_init_hud()
	_ct.set_test_state(10, 20)
	_ct.emit_coverage_updated()
	assert_eq(_coverage_label.text, "10 / 20")
	# After restart: spawn tile pre-covered → 1/20
	_ct.set_test_state(1, 20)
	_ur.level_restarted.emit()
	assert_eq(_coverage_label.text, "1 / 20")


func test_level_restarted_disables_undo_button() -> void:
	_init_hud()
	_ur.set_can_undo(true)
	_ur.undo_applied.emit(1)
	assert_false(_undo_btn.disabled)
	_ur.level_restarted.emit()
	assert_true(_undo_btn.disabled)


func test_level_restarted_shows_buttons() -> void:
	_init_hud()
	# Simulate level complete hiding buttons
	_ct.level_completed.emit()
	assert_false(_undo_btn.visible)
	assert_false(_restart_btn.visible)
	# Restart restores them
	_ur.level_restarted.emit()
	assert_true(_undo_btn.visible)
	assert_true(_restart_btn.visible)


func test_level_restarted_clears_level_complete_flag() -> void:
	_init_hud()
	_ct.level_completed.emit()
	assert_true(_hud.is_level_complete())
	_ur.level_restarted.emit()
	assert_false(_hud.is_level_complete())


# —————————————————————————————————————————————
# Level Completed Signal Tests
# —————————————————————————————————————————————

func test_level_completed_hides_undo_button() -> void:
	_init_hud()
	_ct.level_completed.emit()
	assert_false(_undo_btn.visible)


func test_level_completed_hides_restart_button() -> void:
	_init_hud()
	_ct.level_completed.emit()
	assert_false(_restart_btn.visible)


func test_level_completed_sets_flag() -> void:
	_init_hud()
	_ct.level_completed.emit()
	assert_true(_hud.is_level_complete())


# —————————————————————————————————————————————
# Button Press Tests
# —————————————————————————————————————————————

func test_undo_btn_pressed_calls_undo_restart() -> void:
	_init_hud()
	_hud.on_undo_btn_pressed()
	assert_eq(_ur_undo_count, 1)


func test_undo_btn_pressed_emits_signal() -> void:
	_init_hud()
	_hud.on_undo_btn_pressed()
	assert_eq(_undo_pressed_count, 1)


func test_restart_btn_pressed_calls_undo_restart() -> void:
	_init_hud()
	_hud.on_restart_btn_pressed()
	assert_eq(_ur_restart_count, 1)


func test_restart_btn_pressed_emits_signal() -> void:
	_init_hud()
	_hud.on_restart_btn_pressed()
	assert_eq(_restart_pressed_count, 1)


func test_undo_btn_noop_after_level_complete() -> void:
	_init_hud()
	_ct.level_completed.emit()
	_hud.on_undo_btn_pressed()
	assert_eq(_ur_undo_count, 0)
	assert_eq(_undo_pressed_count, 0)


func test_restart_btn_noop_after_level_complete() -> void:
	_init_hud()
	_ct.level_completed.emit()
	_hud.on_restart_btn_pressed()
	assert_eq(_ur_restart_count, 0)
	assert_eq(_restart_pressed_count, 0)


func test_undo_btn_noop_without_initialize() -> void:
	_hud.on_undo_btn_pressed()
	assert_eq(_ur_undo_count, 0)
	assert_eq(_undo_pressed_count, 0)


func test_restart_btn_noop_without_initialize() -> void:
	_hud.on_restart_btn_pressed()
	assert_eq(_ur_restart_count, 0)
	assert_eq(_restart_pressed_count, 0)


func test_multiple_undo_presses() -> void:
	_init_hud()
	_hud.on_undo_btn_pressed()
	_hud.on_undo_btn_pressed()
	_hud.on_undo_btn_pressed()
	assert_eq(_ur_undo_count, 3)
	assert_eq(_undo_pressed_count, 3)


# —————————————————————————————————————————————
# Edge Cases
# —————————————————————————————————————————————

func test_set_ui_nodes_before_initialize() -> void:
	# Verify UI nodes are available before init
	assert_eq(_level_name_label.text, "")
	_init_hud(_make_level_data("Edge Case"))
	assert_eq(_level_name_label.text, "Edge Case")


func test_signals_not_connected_before_initialize() -> void:
	# Emit signals before initialize — should not crash
	_mc.set_test_state(5, 10)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "")  # unchanged from default


func test_initialize_with_nonzero_coverage() -> void:
	# Level has coverage from spawn tile pre-covering
	_ct.set_test_state(1, 20)
	_init_hud()
	assert_eq(_coverage_label.text, "1 / 20")


func test_initialize_with_large_values() -> void:
	_mc.set_test_state(0, 999)
	_ct.set_test_state(0, 225)
	_init_hud(_make_level_data("Big Level", 999))
	assert_eq(_move_label.text, "0 / 999")
	assert_eq(_coverage_label.text, "0 / 225")


func test_move_display_zero_minimum_never_shows_denominator() -> void:
	_init_hud(_make_level_data("Dev Level", 0))
	# Even with multiple updates, no denominator
	_mc.set_test_state(1, 0)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "1")
	_mc.set_test_state(10, 0)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "10")


func test_initialize_twice_no_double_signal_handling() -> void:
	_init_hud(_make_level_data("Test", 8))
	# Initialize again (simulates re-entering a level)
	_init_hud(_make_level_data("Test", 8))
	# Signal should fire handler exactly once, not twice
	_mc.set_test_state(3, 8)
	_mc.emit_move_count_changed()
	assert_eq(_move_label.text, "3 / 8")
	# Verify coverage also single-fires
	_ct.set_test_state(5, 20)
	_ct.emit_coverage_updated()
	assert_eq(_coverage_label.text, "5 / 20")
