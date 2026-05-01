## Solve All Levels — verifies minimum_moves for all production levels.
## Run: godot --headless -s tools/solve_all_levels.gd
extends SceneTree


func _init() -> void:
	var solver := LevelSolver.new()
	var base_dir := "res://data/levels/"
	var worlds := ["world1/", "world2/", "world3/", "special/"]

	print("=== NekoDash Level Solver — All Levels ===")
	
	for world_path: String in worlds:
		var levels_dir: String = base_dir + world_path
		var dir: DirAccess = DirAccess.open(levels_dir)
		if dir == null:
			print("ERROR: Cannot open %s" % levels_dir)
			continue

		var files: Array[String] = []
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		files.sort()

		for f: String in files:
			var level: LevelData = load(levels_dir + f)
			if level == null:
				print("  SKIP: %s (failed to load)" % f)
				continue
			var result: LevelSolver.SolveResult = solver.solve(level)
			var status: String = "OK" if result.minimum_moves == level.minimum_moves else "MISMATCH"
			if result.minimum_moves == -1:
				status = "UNSOLVABLE"
			print("  %s: BFS=%d  file=%d  [%s]  (%d states, %dms)" % [
				level.level_id, result.minimum_moves, level.minimum_moves,
				status, result.states_explored, result.solve_time_msec
			])
	
	print("=== Done ===")
	quit()
