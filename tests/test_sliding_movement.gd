## Unit tests for SlidingMovement gameplay node.
## Task: S1-05
## Covers: resolve_slide, compute_tiles_covered, state machine, signals,
##         initialize_level, set_grid_position_instant, blocked slides,
##         bump/squish feedback, platform-adaptive speed, edge cases.
extends GutTest

var _sm: Node2D

# Signal tracking
var _slide_started_log: Array = []
var _slide_completed_log: Array = []
var _slide_blocked_log: Array = []
var _spawn_position_log: Array = []


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	# Load a standard 5×5 bordered grid on the real autoload
	GridSystem.load_grid(_make_5x5_bordered())

	# Ensure InputSystem starts in accepting state
	InputSystem.set_accepting_input(true)

	# Create the SlidingMovement node under test
	# (_ready connects to InputSystem autoload)
	_sm = load("res://src/gameplay/sliding_movement.gd").new()
	add_child_autofree(_sm)

	# Connect signals for tracking
	_slide_started_log.clear()
	_slide_completed_log.clear()
	_slide_blocked_log.clear()
	_spawn_position_log.clear()

	_sm.slide_started.connect(_on_slide_started)
	_sm.slide_completed.connect(_on_slide_completed)
	_sm.slide_blocked.connect(_on_slide_blocked)
	_sm.spawn_position_set.connect(_on_spawn_position_set)


func after_each() -> void:
	# Reset InputSystem to prevent test pollution if a slide was in-flight
	InputSystem.set_accepting_input(true)


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_slide_started(from: Vector2i, to: Vector2i, dir: Vector2i) -> void:
	_slide_started_log.append({"from": from, "to": to, "dir": dir})

func _on_slide_completed(from: Vector2i, to: Vector2i, dir: Vector2i, tiles: Array[Vector2i]) -> void:
	_slide_completed_log.append({"from": from, "to": to, "dir": dir, "tiles": tiles})

func _on_slide_blocked(pos: Vector2i, dir: Vector2i) -> void:
	_slide_blocked_log.append({"pos": pos, "dir": dir})

func _on_spawn_position_set(pos: Vector2i) -> void:
	_spawn_position_log.append(pos)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Builds a minimal LevelData for a width×height grid.
func _make_level(
	width: int,
	height: int,
	walkability: PackedInt32Array,
	obstacles: PackedInt32Array = PackedInt32Array()
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = "test_level"
	ld.grid_width = width
	ld.grid_height = height
	ld.walkability_tiles = walkability
	if obstacles.is_empty():
		obstacles.resize(walkability.size())
		obstacles.fill(0)
	ld.obstacle_tiles = obstacles
	ld.cat_start = Vector2i(1, 1)
	return ld


## Builds a 5×5 grid: border walls (BLOCKING=1), interior walkable (WALKABLE=0).
## Interior positions: (1,1) (2,1) (3,1) (1,2) (2,2) (3,2) (1,3) (2,3) (3,3)
func _make_5x5_bordered() -> LevelData:
	var w: int = 5
	var h: int = 5
	var walk := PackedInt32Array()
	walk.resize(w * h)
	for row in range(h):
		for col in range(w):
			var is_border: bool = (row == 0 or row == h - 1 or col == 0 or col == w - 1)
			walk[col + row * w] = 1 if is_border else 0
	var obs := PackedInt32Array()
	obs.resize(w * h)
	obs.fill(0)
	return _make_level(w, h, walk, obs)


## Builds a 5×5 grid with a wall in the center at (2,2).
func _make_5x5_center_wall() -> LevelData:
	var w: int = 5
	var h: int = 5
	var walk := PackedInt32Array()
	walk.resize(w * h)
	for row in range(h):
		for col in range(w):
			var is_border: bool = (row == 0 or row == h - 1 or col == 0 or col == w - 1)
			var is_center: bool = (row == 2 and col == 2)
			walk[col + row * w] = 1 if (is_border or is_center) else 0
	var obs := PackedInt32Array()
	obs.resize(w * h)
	obs.fill(0)
	obs[2 + 2 * w] = 1 # STATIC_WALL at center
	return _make_level(w, h, walk, obs)


## Returns expected pixel center for a grid coordinate.
func _expected_pixel(coord: Vector2i) -> Vector2:
	var tile_size: float = 64.0
	return Vector2(coord) * tile_size + Vector2.ONE * (tile_size * 0.5)


# —————————————————————————————————————————————
# Tests — resolve_slide
# —————————————————————————————————————————————

func test_sliding_movement_resolve_slide_right_slides_to_wall() -> void:
	# Arrange — 5×5 bordered, cat at (1,1)
	# Act — slide right: (1,1) → (3,1) (stops before border at col 4)
	var landing: Vector2i = _sm.resolve_slide(Vector2i(1, 1), Vector2i(1, 0))
	# Assert
	assert_eq(landing, Vector2i(3, 1))


func test_sliding_movement_resolve_slide_left_slides_to_wall() -> void:
	var landing: Vector2i = _sm.resolve_slide(Vector2i(3, 1), Vector2i(-1, 0))
	assert_eq(landing, Vector2i(1, 1))


func test_sliding_movement_resolve_slide_down_slides_to_wall() -> void:
	var landing: Vector2i = _sm.resolve_slide(Vector2i(1, 1), Vector2i(0, 1))
	assert_eq(landing, Vector2i(1, 3))


func test_sliding_movement_resolve_slide_up_slides_to_wall() -> void:
	var landing: Vector2i = _sm.resolve_slide(Vector2i(1, 3), Vector2i(0, -1))
	assert_eq(landing, Vector2i(1, 1))


func test_sliding_movement_resolve_slide_blocked_returns_start() -> void:
	# Cat at (1,1), slide left — col 0 is border → immediately blocked
	var landing: Vector2i = _sm.resolve_slide(Vector2i(1, 1), Vector2i(-1, 0))
	assert_eq(landing, Vector2i(1, 1))


func test_sliding_movement_resolve_slide_with_center_wall() -> void:
	# Arrange — grid with wall at (2,2)
	GridSystem.load_grid(_make_5x5_center_wall())
	# Cat at (1,2), slide right — should stop at (1,2) because (2,2) is wall
	var landing: Vector2i = _sm.resolve_slide(Vector2i(1, 2), Vector2i(1, 0))
	assert_eq(landing, Vector2i(1, 2))


func test_sliding_movement_resolve_slide_past_center_wall() -> void:
	# Arrange — grid with wall at (2,2)
	GridSystem.load_grid(_make_5x5_center_wall())
	# Cat at (1,1), slide right — (2,1) and (3,1) are walkable
	var landing: Vector2i = _sm.resolve_slide(Vector2i(1, 1), Vector2i(1, 0))
	assert_eq(landing, Vector2i(3, 1))


# —————————————————————————————————————————————
# Tests — compute_tiles_covered
# —————————————————————————————————————————————

func test_sliding_movement_tiles_covered_single_tile() -> void:
	# Arrange — slide 1 tile: (1,1) → (2,1) right
	var tiles: Array[Vector2i] = _sm.compute_tiles_covered(
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 0)
	)
	# Assert — should include only (2,1)
	assert_eq(tiles.size(), 1)
	assert_eq(tiles[0], Vector2i(2, 1))


func test_sliding_movement_tiles_covered_multi_tile() -> void:
	# Arrange — slide 2 tiles: (1,1) → (3,1) right
	var tiles: Array[Vector2i] = _sm.compute_tiles_covered(
		Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0)
	)
	# Assert — should include (2,1) and (3,1), not (1,1)
	assert_eq(tiles.size(), 2)
	assert_eq(tiles[0], Vector2i(2, 1))
	assert_eq(tiles[1], Vector2i(3, 1))


func test_sliding_movement_tiles_covered_vertical() -> void:
	# Arrange — slide down from (1,1) → (1,3)
	var tiles: Array[Vector2i] = _sm.compute_tiles_covered(
		Vector2i(1, 1), Vector2i(1, 3), Vector2i(0, 1)
	)
	# Assert
	assert_eq(tiles.size(), 2)
	assert_eq(tiles[0], Vector2i(1, 2))
	assert_eq(tiles[1], Vector2i(1, 3))


func test_sliding_movement_tiles_covered_excludes_start() -> void:
	# Starting tile should never appear in tiles_covered
	var tiles: Array[Vector2i] = _sm.compute_tiles_covered(
		Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 0)
	)
	assert_false(tiles.has(Vector2i(1, 1)))


# —————————————————————————————————————————————
# Tests — initialize_level
# —————————————————————————————————————————————

func test_sliding_movement_initialize_level_sets_cat_pos() -> void:
	# Arrange / Act
	_sm.initialize_level(Vector2i(2, 2))
	# Assert
	assert_eq(_sm.get_cat_pos(), Vector2i(2, 2))


func test_sliding_movement_initialize_level_sets_pixel_position() -> void:
	_sm.initialize_level(Vector2i(2, 2))
	var expected: Vector2 = _expected_pixel(Vector2i(2, 2))
	assert_almost_eq(_sm.position.x, expected.x, 1.0)
	assert_almost_eq(_sm.position.y, expected.y, 1.0)


func test_sliding_movement_initialize_level_emits_spawn_signal() -> void:
	_sm.initialize_level(Vector2i(3, 3))
	assert_eq(_spawn_position_log.size(), 1)
	assert_eq(_spawn_position_log[0], Vector2i(3, 3))


func test_sliding_movement_initialize_level_resets_state_to_idle() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	assert_eq(_sm.get_state(), 0) # State.IDLE = 0


func test_sliding_movement_initialize_level_resets_scale() -> void:
	_sm.scale = Vector2(1.2, 0.85) # Simulating post-squish
	_sm.initialize_level(Vector2i(1, 1))
	assert_eq(_sm.scale, Vector2.ONE)


# —————————————————————————————————————————————
# Tests — set_grid_position_instant
# —————————————————————————————————————————————

func test_sliding_movement_instant_position_sets_cat_pos() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm.set_grid_position_instant(Vector2i(3, 3))
	assert_eq(_sm.get_cat_pos(), Vector2i(3, 3))


func test_sliding_movement_instant_position_sets_pixel() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm.set_grid_position_instant(Vector2i(3, 3))
	var expected: Vector2 = _expected_pixel(Vector2i(3, 3))
	assert_almost_eq(_sm.position.x, expected.x, 1.0)
	assert_almost_eq(_sm.position.y, expected.y, 1.0)


func test_sliding_movement_instant_position_resets_to_idle() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm.set_grid_position_instant(Vector2i(3, 3))
	assert_eq(_sm.get_state(), 0) # IDLE


func test_sliding_movement_instant_position_no_signals() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_spawn_position_log.clear() # Clear the init signal
	_sm.set_grid_position_instant(Vector2i(3, 3))
	# No slide or spawn signals emitted
	assert_eq(_slide_started_log.size(), 0)
	assert_eq(_slide_completed_log.size(), 0)
	assert_eq(_spawn_position_log.size(), 0)


# —————————————————————————————————————————————
# Tests — blocked slide (signal + no state change)
# —————————————————————————————————————————————

func test_sliding_movement_blocked_slide_emits_blocked_signal() -> void:
	# Arrange — cat at (1,1), left is border
	_sm.initialize_level(Vector2i(1, 1))
	# Act — trigger slide left via direct call
	_sm._on_direction_input(Vector2i(-1, 0))
	# Assert
	assert_eq(_slide_blocked_log.size(), 1)
	assert_eq(_slide_blocked_log[0]["pos"], Vector2i(1, 1))
	assert_eq(_slide_blocked_log[0]["dir"], Vector2i(-1, 0))


func test_sliding_movement_blocked_slide_no_started_signal() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(-1, 0))
	assert_eq(_slide_started_log.size(), 0)


func test_sliding_movement_blocked_slide_no_completed_signal() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(-1, 0))
	assert_eq(_slide_completed_log.size(), 0)


func test_sliding_movement_blocked_slide_cat_pos_unchanged() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(-1, 0))
	assert_eq(_sm.get_cat_pos(), Vector2i(1, 1))


func test_sliding_movement_blocked_slide_stays_idle() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(-1, 0))
	assert_true(_sm.is_accepting_input())


# —————————————————————————————————————————————
# Tests — valid slide (state machine + signals)
# —————————————————————————————————————————————

func test_sliding_movement_valid_slide_emits_started() -> void:
	# Arrange
	_sm.initialize_level(Vector2i(1, 1))
	# Act — slide right: (1,1) → (3,1)
	_sm._on_direction_input(Vector2i(1, 0))
	# Assert
	assert_eq(_slide_started_log.size(), 1)
	assert_eq(_slide_started_log[0]["from"], Vector2i(1, 1))
	assert_eq(_slide_started_log[0]["to"], Vector2i(3, 1))
	assert_eq(_slide_started_log[0]["dir"], Vector2i(1, 0))


func test_sliding_movement_valid_slide_enters_sliding_state() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(1, 0))
	# During tween: state should be SLIDING
	assert_eq(_sm.get_state(), 1) # State.SLIDING = 1
	assert_false(_sm.is_accepting_input())
	# InputSystem must also be gated per GDD
	assert_false(InputSystem.is_accepting_input())


func test_sliding_movement_valid_slide_updates_cat_pos_immediately() -> void:
	# cat_pos is updated synchronously before tween starts (per GDD)
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(1, 0))
	assert_eq(_sm.get_cat_pos(), Vector2i(3, 1))


func test_sliding_movement_input_ignored_during_sliding() -> void:
	# Arrange
	_sm.initialize_level(Vector2i(1, 1))
	# Act — start a valid slide, then send another input
	_sm._on_direction_input(Vector2i(1, 0))
	_sm._on_direction_input(Vector2i(0, 1)) # Should be ignored
	# Assert — only one slide started
	assert_eq(_slide_started_log.size(), 1)


# —————————————————————————————————————————————
# Tests — lock / unlock
# —————————————————————————————————————————————

func test_sliding_movement_lock_enters_locked_state() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm.lock()
	assert_eq(_sm.get_state(), 2) # State.LOCKED = 2
	assert_false(_sm.is_accepting_input())
	# InputSystem must also be gated during LOCKED
	assert_false(InputSystem.is_accepting_input())


func test_sliding_movement_locked_ignores_input() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm.lock()
	_sm._on_direction_input(Vector2i(1, 0))
	assert_eq(_slide_started_log.size(), 0)
	assert_eq(_slide_blocked_log.size(), 0)


func test_sliding_movement_unlock_returns_to_idle() -> void:
	_sm.initialize_level(Vector2i(1, 1))
	_sm.lock()
	_sm.unlock()
	assert_eq(_sm.get_state(), 0) # State.IDLE
	assert_true(_sm.is_accepting_input())
	assert_true(InputSystem.is_accepting_input())


# —————————————————————————————————————————————
# Tests — slide duration formula
# —————————————————————————————————————————————

func test_sliding_movement_duration_short_slide_uses_minimum() -> void:
	# 1 tile at 15 t/s = 0.067s → clamped to min 0.10s
	var duration: float = _sm._compute_slide_duration(1)
	assert_almost_eq(duration, 0.10, 0.001)


func test_sliding_movement_duration_long_slide_uses_velocity() -> void:
	# 5 tiles at 15 t/s = 0.333s → exceeds min
	var duration: float = _sm._compute_slide_duration(5)
	var expected: float = 5.0 / _sm._slide_velocity
	assert_almost_eq(duration, expected, 0.001)


# —————————————————————————————————————————————
# Tests — edge cases
# —————————————————————————————————————————————

func test_sliding_movement_all_four_directions_blocked() -> void:
	# Use a grid where (2,2) is the only walkable tile surrounded by walls
	var w: int = 3
	var h: int = 3
	var walk := PackedInt32Array()
	walk.resize(w * h)
	walk.fill(1) # All blocking
	walk[1 + 1 * w] = 0 # Only (1,1) is walkable
	GridSystem.load_grid(_make_level(w, h, walk))

	_sm.initialize_level(Vector2i(1, 1))

	for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var landing: Vector2i = _sm.resolve_slide(Vector2i(1, 1), dir)
		assert_eq(landing, Vector2i(1, 1), "Direction %s should be blocked" % str(dir))


func test_sliding_movement_instant_position_during_slide() -> void:
	# Restart mid-slide should kill tween and reset to IDLE
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(1, 0)) # Start sliding
	assert_eq(_sm.get_state(), 1) # SLIDING
	assert_false(InputSystem.is_accepting_input())

	_sm.set_grid_position_instant(Vector2i(2, 2))
	assert_eq(_sm.get_state(), 0) # IDLE
	assert_eq(_sm.get_cat_pos(), Vector2i(2, 2))
	assert_true(_sm.is_accepting_input())
	assert_true(InputSystem.is_accepting_input())


func test_sliding_movement_initialize_during_slide() -> void:
	# Level load during slide should also reset cleanly
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(1, 0)) # Start sliding
	_sm.initialize_level(Vector2i(2, 2))
	assert_eq(_sm.get_state(), 0)
	assert_eq(_sm.get_cat_pos(), Vector2i(2, 2))


func test_sliding_movement_slide_right_on_bordered_grid() -> void:
	# Full integration: slide from (1,1) right to (3,1) on 5×5 bordered
	_sm.initialize_level(Vector2i(1, 1))
	_sm._on_direction_input(Vector2i(1, 0))
	# Verify cat_pos updated
	assert_eq(_sm.get_cat_pos(), Vector2i(3, 1))
	# Verify slide_started signal
	assert_eq(_slide_started_log.size(), 1)
	assert_eq(_slide_started_log[0]["from"], Vector2i(1, 1))
	assert_eq(_slide_started_log[0]["to"], Vector2i(3, 1))


func test_sliding_movement_blocked_at_grid_edge() -> void:
	# Cat at edge (3,1), slide right — col 4 is border
	_sm.initialize_level(Vector2i(3, 1))
	_sm._on_direction_input(Vector2i(1, 0))
	assert_eq(_slide_blocked_log.size(), 1)
	assert_eq(_sm.get_cat_pos(), Vector2i(3, 1))


func test_sliding_movement_double_initialize() -> void:
	# Calling initialize_level twice should work cleanly
	_sm.initialize_level(Vector2i(1, 1))
	_sm.initialize_level(Vector2i(3, 3))
	assert_eq(_sm.get_cat_pos(), Vector2i(3, 3))
	assert_eq(_spawn_position_log.size(), 2)
