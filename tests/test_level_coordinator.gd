## Integration tests for LevelCoordinator.
## Implements: design/gdd/level-coordinator.md
##
## Covers: initialization order, deterministic move dispatch order (off-by-one fix),
## state transitions, restart, blocked-slide re-emission, freeze on complete.
##
## Acceptance criteria: LC-1 through LC-8 from design/gdd/level-coordinator.md
extends GutTest

var _lc: Node2D

# Signal tracking
var _blocked_slide_log: Array = []
var _level_restarted_count: int = 0
var _level_completed_count: int = 0
var _move_count_at_completion: int = -1


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_blocked_slide_log.clear()
	_level_restarted_count = 0
	_level_completed_count = 0
	_move_count_at_completion = -1
	SaveManager.reset_all_progress()
	SceneManager.hide_overlay()
	get_tree().paused = false


func after_each() -> void:
	if _lc and is_instance_valid(_lc) and _lc.is_inside_tree():
		_lc.queue_free()
		_lc = null
	SceneManager.hide_overlay()
	get_tree().paused = false


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_blocked_slide(pos: Vector2i, direction: Vector2i) -> void:
	_blocked_slide_log.append({"pos": pos, "direction": direction})

func _on_level_restarted() -> void:
	_level_restarted_count += 1


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Builds a LevelCoordinator with real child nodes, calls
## receive_scene_params, and adds to tree (triggers _ready).
func _build_coordinator(level_data: LevelData) -> Node2D:
	var lc: Node2D = load("res://src/gameplay/level_coordinator.gd").new()

	# Add required child nodes with expected names
	var sm: Node2D = load("res://src/gameplay/sliding_movement.gd").new()
	sm.name = "SlidingMovement"
	lc.add_child(sm)

	var ct: Node = load("res://src/gameplay/coverage_tracking.gd").new()
	ct.name = "CoverageTracking"
	lc.add_child(ct)

	var mc: Node = load("res://src/gameplay/move_counter.gd").new()
	mc.name = "MoveCounter"
	lc.add_child(mc)

	# S2 child nodes
	var ur: Node = load("res://src/gameplay/undo_restart.gd").new()
	ur.name = "UndoRestart"
	lc.add_child(ur)

	var srs: Node = load("res://src/gameplay/star_rating_system.gd").new()
	srs.name = "StarRatingSystem"
	lc.add_child(srs)

	var lp: Node = load("res://src/gameplay/level_progression.gd").new()
	lp.name = "LevelProgression"
	lc.add_child(lp)

	var hud_node: HUD = HUD.new()
	hud_node.name = "HUD"
	lc.add_child(hud_node)

	# Visual nodes (not tested directly but required by @onready)
	var gr: Node2D = load("res://src/ui/grid_renderer.gd").new()
	gr.name = "GridRenderer"
	lc.add_child(gr)

	var cv: CoverageVisualizer = CoverageVisualizer.new()
	cv.name = "CoverageVisualizer"
	lc.add_child(cv)

	# Inject a LevelCatalogue containing the test level
	var catalogue := LevelCatalogue.new()
	catalogue.levels = [level_data]
	lc.level_catalogue = catalogue

	# Deliver params (before _ready)
	lc.receive_scene_params({"level_data": level_data})

	# Connect coordinator signals for tracking
	lc.blocked_slide.connect(_on_blocked_slide)
	lc.level_restarted.connect(_on_level_restarted)

	# Add to tree — triggers _ready() and @onready resolution
	add_child_autofree(lc)

	return lc


## Builds a 4×4 level with a 2×2 walkable interior (4 walkable tiles).
## Cat starts at (1,1). Minimum 3 moves.
func _make_4x4_level() -> LevelData:
	var ld := LevelData.new()
	ld.level_id = "test_lc_4x4"
	ld.world_id = 1
	ld.level_index = 2
	ld.display_name = "Test 4x4"
	ld.grid_width = 4
	ld.grid_height = 4
	# row-major: 0=WALKABLE, 1=BLOCKING
	# Row 0: 1 1 1 1
	# Row 1: 1 0 0 1
	# Row 2: 1 0 0 1
	# Row 3: 1 1 1 1
	ld.walkability_tiles = PackedInt32Array([
		1, 1, 1, 1,
		1, 0, 0, 1,
		1, 0, 0, 1,
		1, 1, 1, 1,
	])
	ld.obstacle_tiles = PackedInt32Array()
	ld.obstacle_tiles.resize(16)
	ld.obstacle_tiles.fill(0)
	ld.cat_start = Vector2i(1, 1)
	ld.minimum_moves = 3
	ld.star_3_moves = 3
	ld.star_2_moves = 4
	ld.star_1_moves = 6
	return ld


## Builds a 3×3 level with 2 walkable tiles (cat at 1,1, one right at 2,1).
## Minimum 1 move. Completes with a single slide right.
func _make_2_tile_level() -> LevelData:
	var ld := LevelData.new()
	ld.level_id = "test_lc_2tile"
	ld.world_id = 1
	ld.level_index = 1
	ld.display_name = "Test 2-Tile"
	ld.grid_width = 4
	ld.grid_height = 3
	# Row 0: 1 1 1 1
	# Row 1: 1 0 0 1
	# Row 2: 1 1 1 1
	ld.walkability_tiles = PackedInt32Array([
		1, 1, 1, 1,
		1, 0, 0, 1,
		1, 1, 1, 1,
	])
	ld.obstacle_tiles = PackedInt32Array()
	ld.obstacle_tiles.resize(12)
	ld.obstacle_tiles.fill(0)
	ld.cat_start = Vector2i(1, 1)
	ld.minimum_moves = 1
	ld.star_3_moves = 1
	ld.star_2_moves = 2
	ld.star_1_moves = 3
	return ld


## Simulates a directional input via InputSystem signal.
func _send_input(direction: Vector2i) -> void:
	InputSystem.direction_input.emit(direction)


# —————————————————————————————————————————————
# Tests — LC-1: Initialization
# —————————————————————————————————————————————

func test_level_coordinator_ready_transitions_to_playing() -> void:
	# Arrange
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)

	# Act
	_lc = _build_coordinator(ld)

	# Assert
	assert_eq(_lc.get_state(), _lc.State.PLAYING)


func test_level_coordinator_ready_stores_level_data() -> void:
	# Arrange
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)

	# Act
	_lc = _build_coordinator(ld)

	# Assert
	assert_eq(_lc.get_current_level_data(), ld)


func test_level_coordinator_start_position_covered_on_init() -> void:
	# Arrange
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)

	# Act
	_lc = _build_coordinator(ld)

	# Assert
	var ct: Node = _lc.get_node("CoverageTracking")
	assert_true(ct.is_tile_covered(Vector2i(1, 1)))
	assert_eq(ct.get_covered_count(), 1)


# —————————————————————————————————————————————
# Tests — LC-3 / LC-4: Deterministic process_move order (off-by-one fix)
# —————————————————————————————————————————————

func test_level_coordinator_move_count_correct_at_completion() -> void:
	# Arrange — 2-tile level: one slide right completes it
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	var mc: Node = _lc.get_node("MoveCounter")

	# Track the move count at the instant level_completed fires
	var ct: Node = _lc.get_node("CoverageTracking")
	ct.level_completed.connect(
		func() -> void: _move_count_at_completion = mc.get_current_moves()
	)

	# Act — slide right to cover the only remaining tile
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert — MoveCounter should show 1, not 0 (verifies off-by-one fix)
	assert_eq(_move_count_at_completion, 1,
		"Move count should be 1 at completion, not 0 (off-by-one fix)")
	assert_eq(mc.get_final_move_count(), 1)


func test_level_coordinator_move_count_correct_at_completion_4x4() -> void:
	# Arrange — 4x4 level with 4 walkable tiles, 3 minimum moves
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	var mc: Node = _lc.get_node("MoveCounter")
	var ct: Node = _lc.get_node("CoverageTracking")
	ct.level_completed.connect(
		func() -> void: _move_count_at_completion = mc.get_current_moves()
	)

	# Act — complete 4x4 level: right, down, left
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout
	_send_input(Vector2i(0, 1))
	await get_tree().create_timer(0.5).timeout
	_send_input(Vector2i(-1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert — should be 3 at completion, not 2
	assert_eq(_move_count_at_completion, 3,
		"Move count should be 3 at completion, not 2 (off-by-one fix)")


# —————————————————————————————————————————————
# Tests — Level complete state
# —————————————————————————————————————————————

func test_level_coordinator_transitions_to_transitioning_on_complete() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert
	assert_eq(_lc.get_state(), _lc.State.TRANSITIONING)


func test_level_coordinator_freezes_move_counter_on_complete() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert
	var mc: Node = _lc.get_node("MoveCounter")
	assert_true(mc.is_frozen())


func test_level_coordinator_locks_sliding_on_complete() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert
	var sm: Node2D = _lc.get_node("SlidingMovement")
	assert_false(sm.is_accepting_input())


# —————————————————————————————————————————————
# Tests — Blocked slide (Priority 3)
# —————————————————————————————————————————————

func test_level_coordinator_reemits_blocked_slide() -> void:
	# Arrange — cat at (1,1) in 2-tile level, up is blocked
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act — try to slide up (blocked by wall)
	_send_input(Vector2i(0, -1))
	await get_tree().create_timer(0.3).timeout

	# Assert
	assert_eq(_blocked_slide_log.size(), 1)
	assert_eq(_blocked_slide_log[0]["pos"], Vector2i(1, 1))
	assert_eq(_blocked_slide_log[0]["direction"], Vector2i(0, -1))


# —————————————————————————————————————————————
# Tests — LC-8: Restart
# —————————————————————————————————————————————

func test_level_coordinator_restart_resets_state_to_playing() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Complete the level first
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout
	assert_eq(_lc.get_state(), _lc.State.TRANSITIONING)

	# Act
	_lc.restart_level()

	# Assert
	assert_eq(_lc.get_state(), _lc.State.PLAYING)


func test_level_coordinator_restart_resets_move_counter() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Act
	_lc.restart_level()

	# Assert
	var mc: Node = _lc.get_node("MoveCounter")
	assert_eq(mc.get_current_moves(), 0)
	assert_false(mc.is_frozen())


func test_level_coordinator_restart_resets_coverage() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Act
	_lc.restart_level()

	# Assert
	var ct: Node = _lc.get_node("CoverageTracking")
	assert_eq(ct.get_covered_count(), 1, "Only start tile should be covered after restart")
	assert_eq(ct.get_state(), ct.State.TRACKING)


func test_level_coordinator_restart_emits_signal() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act
	_lc.restart_level()

	# Assert
	assert_eq(_level_restarted_count, 1)


func test_level_coordinator_restart_allows_replay_to_completion() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Complete first
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout
	assert_eq(_lc.get_state(), _lc.State.TRANSITIONING)

	# Restart
	_lc.restart_level()
	assert_eq(_lc.get_state(), _lc.State.PLAYING)

	# Act — complete again
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert
	assert_eq(_lc.get_state(), _lc.State.TRANSITIONING)
	var mc: Node = _lc.get_node("MoveCounter")
	assert_eq(mc.get_final_move_count(), 1)


# —————————————————————————————————————————————
# Tests — LC-2: Previous best snapshot
# —————————————————————————————————————————————

func test_level_coordinator_snapshots_previous_bests() -> void:
	# Arrange — SaveManager is a stub, returns defaults
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)

	# Act
	_lc = _build_coordinator(ld)

	# Assert — stub SaveManager returns 0 / false
	assert_eq(_lc.get_prev_best_moves(), 0)
	assert_false(_lc.was_previously_completed())


# —————————————————————————————————————————————
# Tests — S2-05: Wiring integration
# —————————————————————————————————————————————

func test_undo_restart_captures_snapshot_on_slide() -> void:
	# Arrange — 4x4 level: make a move but don't complete
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act — slide right (does NOT complete; 4 walkable tiles)
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert — UndoRestart captured the snapshot (proves it was connected)
	var ur: Node = _lc.get_node("UndoRestart")
	assert_eq(ur.undo_count(), 1, "UndoRestart should have 1 snapshot after 1 slide")
	assert_true(ur.can_undo())


func test_star_rating_computed_on_level_complete() -> void:
	# Arrange — 2-tile level: 1 move → 3 stars
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	var srs: Node = _lc.get_node("StarRatingSystem")

	# Act
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert — StarRatingSystem should have fired and have a rating
	assert_eq(srs.get_current_rating(), 3, "1 move on a 1-min level = 3 stars")


func test_level_progression_saves_on_level_complete() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act — complete the level
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert — SaveManager should have the record (stub stores in memory)
	assert_true(SaveManager.is_level_completed(ld.level_id))
	assert_eq(SaveManager.get_best_stars(ld.level_id), 3)
	assert_eq(SaveManager.get_best_moves(ld.level_id), 1)


func test_level_complete_overlay_shown_on_level_complete() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(1.6).timeout

	# Assert — completion now opens a modal overlay over gameplay
	assert_eq(SceneManager.get_active_overlay(), SceneManager.Overlay.LEVEL_COMPLETE)
	assert_true(get_tree().paused)
	SceneManager.hide_overlay()
	get_tree().paused = false


func test_undo_works_through_coordinator() -> void:
	# Arrange — 4x4 level, make one move
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	var mc: Node = _lc.get_node("MoveCounter")
	var sm: Node2D = _lc.get_node("SlidingMovement")
	assert_eq(mc.get_current_moves(), 1)

	# Act — undo via UndoRestart
	var ur: Node = _lc.get_node("UndoRestart")
	ur.undo()

	# Assert
	assert_eq(mc.get_current_moves(), 0)
	assert_eq(sm.get_cat_pos(), Vector2i(1, 1))


func test_hud_initializes_on_coordinator_ready() -> void:
	# Arrange / Act
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Assert — HUD should report initialized
	var hud_node: HUD = _lc.get_node("HUD")
	assert_true(hud_node.is_initialized())


func test_undo_restart_freezes_on_level_complete() -> void:
	# Arrange
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	# Act
	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout

	# Assert — UndoRestart should be frozen (no undos possible)
	var ur: Node = _lc.get_node("UndoRestart")
	assert_false(ur.can_undo())


func test_restart_resets_undo_history() -> void:
	# Arrange
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout
	var ur: Node = _lc.get_node("UndoRestart")
	assert_eq(ur.undo_count(), 1)

	# Act — restart via coordinator
	_lc.restart_level()

	# Assert
	assert_eq(ur.undo_count(), 0)
	assert_false(ur.can_undo())


func test_restart_re_snapshots_previous_bests() -> void:
	# Arrange — complete a 2-tile level (writes to SaveManager)
	var ld := _make_2_tile_level()
	GridSystem.load_grid(ld)
	_lc = _build_coordinator(ld)

	assert_eq(_lc.get_prev_best_moves(), 0)
	assert_false(_lc.was_previously_completed())

	_send_input(Vector2i(1, 0))
	await get_tree().create_timer(0.5).timeout
	assert_eq(_lc.get_state(), _lc.State.TRANSITIONING)

	# Act — restart after completion
	_lc.restart_level()

	# Assert — previous bests should now reflect the completed attempt
	assert_true(_lc.was_previously_completed())
	assert_eq(_lc.get_prev_best_moves(), 1)


func test_pause_requested_shows_pause_overlay() -> void:
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)
	SceneManager.hide_overlay()
	get_tree().paused = false
	_lc = _build_coordinator(ld)

	_lc._on_pause_pressed()

	assert_eq(SceneManager.get_active_overlay(), SceneManager.Overlay.PAUSE)
	assert_true(get_tree().paused)
	SceneManager.hide_overlay()
	get_tree().paused = false


func test_ui_cancel_opens_pause_overlay_when_playing() -> void:
	var ld := _make_4x4_level()
	GridSystem.load_grid(ld)
	SceneManager.hide_overlay()
	get_tree().paused = false
	_lc = _build_coordinator(ld)

	var event: InputEventAction = InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	_lc._unhandled_input(event)

	assert_eq(SceneManager.get_active_overlay(), SceneManager.Overlay.PAUSE)
	SceneManager.hide_overlay()
	get_tree().paused = false
