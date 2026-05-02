extends "res://addons/gut/test.gd"

var _sm: Node2D
var _coordinator: Node2D
var _level_data: LevelData

func before_each():
	_level_data = LevelData.new()
	_level_data.grid_width = 5
	_level_data.grid_height = 5
	_level_data.walkability_tiles = PackedInt32Array([
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0
	])
	_level_data.obstacle_tiles = PackedInt32Array([
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0
	])
	_level_data.special_tiles = PackedInt32Array([
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0
	])
	_level_data.cat_start = Vector2i(0, 0)
	
	GridSystem.load_grid(_level_data)
	
	_sm = load("res://src/gameplay/sliding_movement.gd").new()
	add_child(_sm)
	_sm.initialize_level(_level_data.cat_start)

func after_each():
	_sm.free()

func test_stop_tile():
	# Place stop tile at (2, 0)
	_level_data.special_tiles[2] = GridSystem.SpecialTileType.STOP_TILE
	GridSystem.load_grid(_level_data)
	
	var landing = _sm.resolve_slide(Vector2i(0, 0), Vector2i(1, 0))
	assert_eq(landing, Vector2i(2, 0), "Should stop on STOP_TILE")

func test_hazard_tile_resolve():
	# Place hazard at (2, 0)
	_level_data.special_tiles[2] = GridSystem.SpecialTileType.HAZARD
	GridSystem.load_grid(_level_data)
	
	var landing = _sm.resolve_slide(Vector2i(0, 0), Vector2i(1, 0))
	assert_eq(landing, Vector2i(2, 0), "Should land on HAZARD tile")

func test_hazard_tile_death_signal():
	# Place hazard at (2, 0)
	_level_data.special_tiles[2] = GridSystem.SpecialTileType.HAZARD
	GridSystem.load_grid(_level_data)
	
	watch_signals(_sm)
	_sm._on_direction_input(Vector2i(1, 0))
	
	# Wait for slide to complete
	await wait_for_signal(_sm.cat_died, 2.0)
	
	assert_signal_emitted(_sm, "cat_died", "Should emit cat_died when landing on HAZARD")

func test_one_way_tile_pass():
	# One-way UP at (1, 1). Cat at (1, 2) moving UP.
	_level_data.special_tiles[1 + 1*5] = GridSystem.SpecialTileType.ONE_WAY_UP
	GridSystem.load_grid(_level_data)
	
	var landing = _sm.resolve_slide(Vector2i(1, 2), Vector2i(0, -1))
	assert_eq(landing, Vector2i(1, 0), "Should pass through ONE_WAY_UP from bottom")

func test_one_way_tile_blocked():
	# One-way UP at (1, 1). Cat at (1, 0) moving DOWN.
	_level_data.special_tiles[1 + 1*5] = GridSystem.SpecialTileType.ONE_WAY_UP
	GridSystem.load_grid(_level_data)
	
	var landing = _sm.resolve_slide(Vector2i(1, 0), Vector2i(0, 1))
	assert_eq(landing, Vector2i(1, 0), "Should be blocked by ONE_WAY_UP from top")

func test_solver_with_hazard():
	# 5x5 grid with obstacles to make it solvable
	_level_data.grid_width = 5
	_level_data.grid_height = 5
	_level_data.walkability_tiles = PackedInt32Array([
		1, 1, 1, 1, 1,
		1, 0, 0, 0, 1,
		1, 0, 0, 0, 1,
		1, 0, 0, 0, 1,
		1, 1, 1, 1, 1
	])
	_level_data.obstacle_tiles = PackedInt32Array([
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 1, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0
	])
	_level_data.special_tiles = PackedInt32Array([
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 1, 0, 0, # Hazard at (2,3)
		0, 0, 0, 0, 0
	])
	_level_data.cat_start = Vector2i(1, 1)
	GridSystem.load_grid(_level_data)
	
	var solver = LevelSolver.new()
	var result = solver.solve(_level_data)
	
	print("Hazard solver result moves: ", result.minimum_moves)
	assert_true(result.minimum_moves > 0, "Should be solvable with obstacles and hazard")

func test_solver_with_stop_tile():
	_level_data.grid_width = 3
	_level_data.grid_height = 3
	_level_data.walkability_tiles = PackedInt32Array([0,0,0, 0,0,0, 0,0,0])
	_level_data.obstacle_tiles = PackedInt32Array([0,0,0, 0,0,0, 0,0,0])
	_level_data.special_tiles = PackedInt32Array([0,0,0, 0,1,0, 0,0,0]) # Stop at (1,1)
	GridSystem.load_grid(_level_data)
	
	var solver = LevelSolver.new()
	var result = solver.solve(_level_data)
	print("Stop tile solver result moves: ", result.minimum_moves)
	assert_true(result.minimum_moves > 0, "Should be solvable with stop tile")
