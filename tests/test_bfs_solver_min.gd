## Tests for LevelSolver (BFS Minimum Solver).
## Implements: design/gdd/bfs-minimum-solver.md — Acceptance Criteria
## Task: S1-09
extends GutTest


# —————————————————————————————————————————————
# Helper: build a LevelData resource in-memory
# —————————————————————————————————————————————

func _make_level(
	width: int,
	height: int,
	walkability: PackedInt32Array,
	cat_start: Vector2i,
	level_id: String = "test"
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = level_id
	ld.grid_width = width
	ld.grid_height = height
	ld.walkability_tiles = walkability
	ld.obstacle_tiles = PackedInt32Array()
	ld.obstacle_tiles.resize(walkability.size())
	ld.cat_start = cat_start
	return ld


# —————————————————————————————————————————————
# AC-2: Known 3×3 level — hand-verified minimum
# —————————————————————————————————————————————

func test_solver_l_shape_returns_2_moves() -> void:
	# Layout (0=WALKABLE, 1=BLOCKING):
	#   B W B       row 0
	#   B W B       row 1
	#   B W W       row 2
	# Walkable: (1,0),(1,1),(1,2),(2,2) — 4 tiles
	# Cat at (1,0): slide down → (1,2), covers (1,0),(1,1),(1,2). Then right → (2,2). 2 moves.
	var walk := PackedInt32Array([1, 0, 1, 1, 0, 1, 1, 0, 0])
	var ld := _make_level(3, 3, walk, Vector2i(1, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 2, "L-shape 3×3 should take exactly 2 moves")
	assert_eq(result.error, "", "Should have no error")


func test_solver_3x3_ring_returns_4_moves() -> void:
	# Ring around a center wall:
	#   W W W       row 0
	#   W B W       row 1
	#   W W W       row 2
	# Walkable: 8 tiles, center blocked. Cat at (0,0).
	# right→(2,0), down→(2,2), left→(0,2), up→(0,0) — covers all 8. 4 moves.
	var walk := PackedInt32Array([0, 0, 0, 0, 1, 0, 0, 0, 0])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 4, "3×3 ring from corner should take 4 moves")


# —————————————————————————————————————————————
# AC-4: Deterministic — same input → same output
# —————————————————————————————————————————————

func test_solver_repeated_solve_returns_same_result() -> void:
	var walk := PackedInt32Array([0, 0, 0, 0, 1, 0, 0, 0, 0])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var r1 := solver.solve(ld)
	var r2 := solver.solve(ld)
	assert_eq(r1.minimum_moves, r2.minimum_moves, "Solver must be deterministic")


# —————————————————————————————————————————————
# Trivial levels
# —————————————————————————————————————————————

func test_solver_single_tile_returns_zero_moves() -> void:
	# 3×3 grid, only center walkable.
	var walk := PackedInt32Array([1, 1, 1, 1, 0, 1, 1, 1, 1])
	var ld := _make_level(3, 3, walk, Vector2i(1, 1))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 0, "Single tile = 0 moves")
	assert_eq(result.error, "")


func test_solver_two_adjacent_tiles_returns_one_move() -> void:
	# 3×3 grid, two horizontally adjacent walkable tiles.
	var walk := PackedInt32Array([1, 1, 1, 1, 0, 0, 1, 1, 1])
	var ld := _make_level(3, 3, walk, Vector2i(1, 1))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 1, "Two adjacent tiles = 1 move")


# —————————————————————————————————————————————
# AC-3: Unsolvable level returns -1
# —————————————————————————————————————————————

func test_solver_isolated_tile_returns_unsolvable() -> void:
	# Two disconnected walkable regions:
	#   W B W       row 0
	#   B B B       row 1
	#   B B B       row 2
	# Walkable: (0,0) and (2,0), separated by a wall. Cat starts at (0,0).
	# The cat can never reach (2,0) because it slides into a wall immediately.
	var walk := PackedInt32Array([0, 1, 0, 1, 1, 1, 1, 1, 1])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, -1, "Isolated tile should be unsolvable")
	assert_string_contains(result.error, "unsolvable")


# —————————————————————————————————————————————
# AC-6: > 63 walkable tiles → error, no BFS
# —————————————————————————————————————————————

func test_solver_over_63_tiles_aborts_with_error() -> void:
	# 10×10 grid, all walkable = 100 tiles > 63
	var walk := PackedInt32Array()
	walk.resize(100)
	walk.fill(0) # All WALKABLE
	var ld := _make_level(10, 10, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, -1, "Should not attempt BFS with >63 tiles")
	assert_string_contains(result.error, "max")


# —————————————————————————————————————————————
# Edge case: zero walkable tiles → error
# —————————————————————————————————————————————

func test_solver_zero_walkable_tiles_returns_error() -> void:
	var walk := PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
	var ld := _make_level(3, 3, walk, Vector2i(1, 1))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, -1)
	assert_string_contains(result.error, "0 walkable")


func test_solver_null_level_data_returns_error() -> void:
	var solver := LevelSolver.new()
	var result := solver.solve(null)
	assert_eq(result.minimum_moves, -1)
	assert_string_contains(result.error, "null")


# —————————————————————————————————————————————
# Edge case: cat_start not walkable → fallback
# —————————————————————————————————————————————

func test_solver_invalid_start_uses_fallback_position() -> void:
	# Cat starts on a BLOCKING tile; solver should fall back to first WALKABLE.
	#   B W B       row 0
	#   B W B       row 1
	#   B B B       row 2
	# Walkable: (1,0) and (1,1). cat_start=(0,0) which is BLOCKING.
	# Fallback → (1,0), slide down to (1,1). 1 move.
	var walk := PackedInt32Array([1, 0, 1, 1, 0, 1, 1, 1, 1])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 1, "Should use fallback start and solve in 1 move")


# —————————————————————————————————————————————
# Verify against shipped levels (AC-1)
# —————————————————————————————————————————————

func test_solver_w1_l1_returns_4_moves() -> void:
	var ld: LevelData = load("res://data/levels/world1/w1_l1.tres")
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 4, "w1_l1 should be solvable in 4 moves")


func test_solver_w1_l2_returns_5_moves() -> void:
	var ld: LevelData = load("res://data/levels/world1/w1_l2.tres")
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 5, "w1_l2 should be solvable in 5 moves")


func test_solver_w1_l3_returns_6_moves() -> void:
	var ld: LevelData = load("res://data/levels/world1/w1_l3.tres")
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 6, "w1_l3 should be solvable in 6 moves")


# —————————————————————————————————————————————
# AC-5: Performance — ≤ 28 tiles completes fast
# —————————————————————————————————————————————

func test_solver_medium_level_completes_under_5_seconds() -> void:
	# Use w1_l3 (8 walkable tiles) — known solvable shipped level.
	# AC-5 says ≤ 28 tiles should complete in < 5 seconds.
	var ld: LevelData = load("res://data/levels/world1/w1_l3.tres")
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_gt(result.minimum_moves, 0, "Shipped level should be solvable")
	assert_lt(result.solve_time_msec, 5000, "AC-5: ≤ 28 tiles should complete in < 5 seconds")


# —————————————————————————————————————————————
# States explored is tracked
# —————————————————————————————————————————————

func test_solver_states_explored_is_positive() -> void:
	var walk := PackedInt32Array([0, 0, 0, 0, 1, 0, 0, 0, 0])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_gt(result.states_explored, 0, "Should explore at least 1 state")


# —————————————————————————————————————————————
# Slide covers intermediate tiles, not just landing
# —————————————————————————————————————————————

func test_solver_corridor_slide_covers_all_intermediate_tiles() -> void:
	# 5×3 grid, one horizontal corridor:
	#   B B B B B    row 0
	#   B W W W B    row 1
	#   B B B B B    row 2
	# 3 walkable tiles. Cat at (1,1), slides right → (3,1). Covers all 3. 1 move.
	var walk := PackedInt32Array([1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1])
	var ld := _make_level(5, 3, walk, Vector2i(1, 1))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, 1, "Straight corridor = 1 slide covers all")


# —————————————————————————————————————————————
# Empty walkability array → error
# —————————————————————————————————————————————

func test_solver_empty_walkability_returns_error() -> void:
	var ld := LevelData.new()
	ld.grid_width = 3
	ld.grid_height = 3
	ld.walkability_tiles = PackedInt32Array()
	ld.cat_start = Vector2i(0, 0)
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.minimum_moves, -1)
	assert_string_contains(result.error, "empty")


# —————————————————————————————————————————————
# Solve time tracked
# —————————————————————————————————————————————

func test_solver_solve_time_is_non_negative() -> void:
	var walk := PackedInt32Array([0, 0, 0, 0, 1, 0, 0, 0, 0])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_gte(result.solve_time_msec, 0, "Solve time should be non-negative")


# —————————————————————————————————————————————
# Instance reuse — state doesn't leak between solves
# —————————————————————————————————————————————

func test_solver_reuse_across_different_levels_returns_correct_results() -> void:
	# Solve two different levels with the same LevelSolver instance.
	# Verifies _reset_state() prevents stale data from leaking.
	var solver := LevelSolver.new()

	# First: 3×3 ring (8 tiles, 4 moves)
	var walk_ring := PackedInt32Array([0, 0, 0, 0, 1, 0, 0, 0, 0])
	var ld_ring := _make_level(3, 3, walk_ring, Vector2i(0, 0), "ring")
	var r1 := solver.solve(ld_ring)
	assert_eq(r1.minimum_moves, 4, "Ring level should take 4 moves")

	# Second: simple 2-tile corridor (1 move)
	var walk_pair := PackedInt32Array([1, 1, 1, 1, 0, 0, 1, 1, 1])
	var ld_pair := _make_level(3, 3, walk_pair, Vector2i(1, 1), "pair")
	var r2 := solver.solve(ld_pair)
	assert_eq(r2.minimum_moves, 1, "Pair level should take 1 move")

	# Third: null — should error cleanly, not use stale state
	var r3 := solver.solve(null)
	assert_eq(r3.minimum_moves, -1, "Null should return -1 after previous valid solves")
	assert_string_contains(r3.error, "null")


# —————————————————————————————————————————————
# Path reconstruction — result.path matches move count
# —————————————————————————————————————————————

func test_solver_path_length_matches_minimum_moves() -> void:
	# 3×3 ring: 4 moves expected.
	var walk := PackedInt32Array([0, 0, 0, 0, 1, 0, 0, 0, 0])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.path.size(), result.minimum_moves,
		"Path length should equal minimum_moves")


func test_solver_path_contains_valid_directions() -> void:
	var walk := PackedInt32Array([0, 0, 0, 0, 1, 0, 0, 0, 0])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	var valid_dirs: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
	]
	for dir: Vector2i in result.path:
		assert_has(valid_dirs, dir, "Each path direction must be a cardinal direction")


func test_solver_single_tile_path_is_empty() -> void:
	# 0 moves → empty path.
	var walk := PackedInt32Array([1, 1, 1, 1, 0, 1, 1, 1, 1])
	var ld := _make_level(3, 3, walk, Vector2i(1, 1))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.path.size(), 0, "Trivial level should have empty path")


func test_solver_unsolvable_path_is_empty() -> void:
	var walk := PackedInt32Array([0, 1, 0, 1, 1, 1, 1, 1, 1])
	var ld := _make_level(3, 3, walk, Vector2i(0, 0))
	var solver := LevelSolver.new()
	var result := solver.solve(ld)
	assert_eq(result.path.size(), 0, "Unsolvable level should have empty path")


# —————————————————————————————————————————————
# WASD conversion helpers
# —————————————————————————————————————————————

func test_dir_to_wasd_maps_all_four_directions() -> void:
	assert_eq(LevelSolver.dir_to_wasd(Vector2i(0, -1)), "W")
	assert_eq(LevelSolver.dir_to_wasd(Vector2i(0, 1)), "S")
	assert_eq(LevelSolver.dir_to_wasd(Vector2i(-1, 0)), "A")
	assert_eq(LevelSolver.dir_to_wasd(Vector2i(1, 0)), "D")


func test_dir_to_wasd_unknown_returns_question_mark() -> void:
	assert_eq(LevelSolver.dir_to_wasd(Vector2i(1, 1)), "?")


func test_path_to_wasd_formats_correctly() -> void:
	var path: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1),
	]
	assert_eq(LevelSolver.path_to_wasd(path), "D S A W")


func test_path_to_wasd_empty_returns_empty_string() -> void:
	var path: Array[Vector2i] = []
	assert_eq(LevelSolver.path_to_wasd(path), "")