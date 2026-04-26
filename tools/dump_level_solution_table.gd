## Dumps solver metadata for every production level as a markdown table.
## Run: godot --headless -s tools/dump_level_solution_table.gd
extends SceneTree

const LEVEL_SOLVER_SCRIPT: Script = preload("res://tools/level_solver.gd")

const LEVEL_DIRS: Array[String] = [
	"res://data/levels/world1",
	"res://data/levels/world2",
	"res://data/levels/world3",
	"res://data/levels/special",
]

const DIR_DISPLAY_ORDER: Dictionary = {
	"res://data/levels/world1": 1,
	"res://data/levels/world2": 2,
	"res://data/levels/world3": 3,
	"res://data/levels/special": 99,
}

var _solver: LevelSolver


func _init() -> void:
	_solver = LEVEL_SOLVER_SCRIPT.new() as LevelSolver

	var levels: Array[LevelData] = []
	for dir_path in LEVEL_DIRS:
		levels.append_array(_load_levels(dir_path))

	levels.sort_custom(func(a: LevelData, b: LevelData) -> bool:
		if a.world_id != b.world_id:
			return a.world_id < b.world_id
		return a.level_index < b.level_index
	)

	print("| Level | Width | Height | Walkable Tiles | Minimum Moves | Solution | Star Thresholds |")
	print("| ----- | ----- | ------ | -------------- | ------------- | -------- | --------------- |")
	for level in levels:
		var solve_result: LevelSolver.SolveResult = _solver.solve(level)
		var solution: String = _path_to_string(solve_result.path)
		var walkable_tiles: int = _count_walkable(level)
		print("| %s | %d | %d | %d | %d | %s | %d, %d, %d |" % [
			level.level_id,
			level.grid_width,
			level.grid_height,
			walkable_tiles,
			level.minimum_moves,
			solution,
			level.star_3_moves,
			level.star_2_moves,
			level.star_1_moves,
		])

	quit(0)


func _load_levels(dir_path: String) -> Array[LevelData]:
	var result: Array[LevelData] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_error("Could not open %s" % dir_path)
		return result

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var level: LevelData = load("%s/%s" % [dir_path, file_name]) as LevelData
			if level != null:
				result.append(level)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


func _count_walkable(level: LevelData) -> int:
	var count: int = 0
	for value in level.walkability_tiles:
		if int(value) == 1:
			count += 1
	return count


func _path_to_string(path: Array[Vector2i]) -> String:
	if path.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for dir in path:
		parts.append(_direction_to_letter(dir))
	return " ".join(parts)


func _direction_to_letter(dir: Vector2i) -> String:
	if dir == Vector2i(0, -1):
		return "W"
	if dir == Vector2i(0, 1):
		return "S"
	if dir == Vector2i(-1, 0):
		return "A"
	if dir == Vector2i(1, 0):
		return "D"
	return "?"