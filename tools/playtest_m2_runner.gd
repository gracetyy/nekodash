## PlaytestM2Runner — M2 milestone automated playtest loop.
## Owner: qa-tester
## Task: S4-19
##
## Runs the full M2 navigation loop:
##   Main Menu → World Map (verify 8 levels) → w1_l7 → Level Complete
##   → World Map (verify star saved)
##
## Uses LevelSolver at runtime to compute the optimal solution for w1_l7
## so no hardcoded moves are required.
##
## Usage:
##   1. Add "PlaytestM2Runner" to [autoload] in project.godot (after PlaytestCapture).
##   2. Launch res://scenes/ui/main_menu.tscn.
##   3. Runner handles all navigation and quits when done.
##   4. Remove autoload entry from project.godot after the run.
extends Node


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const W1_L7_PATH: String = "res://data/levels/world1/w1_l7.tres"
const CATALOGUE_PATH: String = "res://data/level_catalogue.tres"
const EXPECTED_LEVEL_COUNT: int = 8

const SETTLE_SEC: float = 0.6
const MOVE_WAIT_SEC: float = 0.7
const SCREENSHOT_WAIT_SEC: float = 0.3

# —————————————————————————————————————————————
# Phase tracking
# —————————————————————————————————————————————

enum Phase {
	MAIN_MENU,
	WORLD_MAP_FIRST,
	GAMEPLAY,
	LEVEL_COMPLETE,
	WORLD_MAP_SECOND,
	DONE,
}

var _phase: Phase = Phase.MAIN_MENU
var _stars_before: int = 0
var _stars_after: int = 0
var _level_complete_stars: int = 0
var _issues: Array[String] = []


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	SceneManager.transition_completed.connect(_on_transition_completed)
	print("[PlaytestM2Runner] Ready — M2 loop starting.")
	print("[PlaytestM2Runner] === M2 AUTOMATED PLAYTEST START ===")

	# Handle initial scene already loaded (runner added after main_menu.tscn launched)
	await get_tree().process_frame
	var main_menu_node: Node = _find_node_by_script("main_menu")
	if main_menu_node != null:
		await get_tree().create_timer(SETTLE_SEC).timeout
		await _handle_main_menu()


# —————————————————————————————————————————————
# SceneManager hook
# —————————————————————————————————————————————

func _on_transition_completed(screen: int) -> void:
	match screen:
		SceneManager.Screen.MAIN_MENU:
			await get_tree().create_timer(SETTLE_SEC).timeout
			await _handle_main_menu()

		SceneManager.Screen.WORLD_MAP:
			await get_tree().create_timer(SETTLE_SEC).timeout
			if _phase == Phase.MAIN_MENU or _phase == Phase.WORLD_MAP_FIRST:
				await _handle_world_map_first()
			elif _phase == Phase.LEVEL_COMPLETE:
				await _handle_world_map_second()

		SceneManager.Screen.GAMEPLAY:
			await get_tree().create_timer(SETTLE_SEC).timeout
			await _handle_gameplay()

		SceneManager.Screen.LEVEL_COMPLETE:
			await get_tree().create_timer(SETTLE_SEC).timeout
			await _handle_level_complete()


# —————————————————————————————————————————————
# Phase handlers
# —————————————————————————————————————————————

func _handle_main_menu() -> void:
	if _phase != Phase.MAIN_MENU:
		return
	print("[PlaytestM2Runner] Phase: MAIN_MENU")
	PlaytestCapture.capture("main_menu")
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	# Verify Main Menu node exists
	var main_menu_node: Node = _find_node_by_script("main_menu")
	if main_menu_node == null:
		_record_issue("FAIL: MainMenu node not found in scene tree")
	else:
		print("[PlaytestM2Runner] PASS: MainMenu scene loaded")

	_phase = Phase.WORLD_MAP_FIRST

	# Navigate to World Map via SceneManager (same as pressing Play)
	print("[PlaytestM2Runner] Navigating to World Map...")
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP)


func _handle_world_map_first() -> void:
	if _phase != Phase.WORLD_MAP_FIRST:
		return
	print("[PlaytestM2Runner] Phase: WORLD_MAP_FIRST")
	PlaytestCapture.capture("world_map_before")
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	# Verify level count via catalogue
	var catalogue: LevelCatalogue = load(CATALOGUE_PATH) as LevelCatalogue
	if catalogue == null:
		_record_issue("FAIL: LevelCatalogue not found")
	else:
		var count: int = catalogue.levels.size()
		if count == EXPECTED_LEVEL_COUNT:
			print("[PlaytestM2Runner] PASS: LevelCatalogue contains %d levels (expected %d)" % [
				count, EXPECTED_LEVEL_COUNT,
			])
		else:
			_record_issue("FAIL: LevelCatalogue has %d levels, expected %d" % [
				count, EXPECTED_LEVEL_COUNT,
			])

	# Record w1_l7 stars BEFORE completion (should be 0)
	_stars_before = SaveManager.get_best_stars("w1_l7")
	print("[PlaytestM2Runner] w1_l7 stars before: %d" % _stars_before)

	_phase = Phase.GAMEPLAY

	# Navigate directly to w1_l7
	var level_data: LevelData = load(W1_L7_PATH) as LevelData
	if level_data == null:
		_record_issue("FAIL: w1_l7.tres failed to load")
		_finish()
		return

	print("[PlaytestM2Runner] Navigating to w1_l7...")
	SceneManager.go_to_level(level_data)


func _handle_gameplay() -> void:
	if _phase != Phase.GAMEPLAY:
		return
	print("[PlaytestM2Runner] Phase: GAMEPLAY (w1_l7)")

	# Find LevelCoordinator
	var coordinator: Node = _find_node_by_script("level_coordinator")
	if coordinator == null:
		_record_issue("FAIL: LevelCoordinator not found in gameplay scene")
		_finish()
		return

	var level_data: Resource = coordinator.get_current_level_data()
	if level_data == null:
		_record_issue("FAIL: LevelCoordinator has no current LevelData")
		_finish()
		return

	print("[PlaytestM2Runner] Level loaded: %s (%dx%d)" % [
		level_data.level_id,
		GridSystem.get_width(),
		GridSystem.get_height(),
	])

	PlaytestCapture.capture("gameplay_w1_l7_initial")
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	# Compute optimal solution with LevelSolver
	var solver: LevelSolver = LevelSolver.new()
	var result: LevelSolver.SolveResult = solver.solve(level_data)

	if result.minimum_moves < 0 or result.path.is_empty():
		_record_issue("FAIL: LevelSolver could not solve w1_l7 (error: %s)" % result.error)
		_finish()
		return

	print("[PlaytestM2Runner] Solver: %d moves, %d states explored" % [
		result.minimum_moves, result.states_explored,
	])

	_phase = Phase.LEVEL_COMPLETE

	# Execute moves
	for i: int in range(result.path.size()):
		var dir: Vector2i = result.path[i]
		var dir_name: String = _dir_name(dir)
		print("[PlaytestM2Runner] Move %d/%d: %s" % [i + 1, result.path.size(), dir_name])

		InputSystem.direction_input.emit(dir)
		await get_tree().create_timer(MOVE_WAIT_SEC).timeout

		if not is_instance_valid(coordinator):
			print("[PlaytestM2Runner]   Coordinator freed — level completed during move %d" % (i + 1))
			return


func _handle_level_complete() -> void:
	if _phase != Phase.LEVEL_COMPLETE:
		return
	print("[PlaytestM2Runner] Phase: LEVEL_COMPLETE")

	PlaytestCapture.capture("level_complete_w1_l7")
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	# Read star count from LevelCompleteScreen
	var screen_node: Node = _find_node_by_script("level_complete_screen")
	if screen_node == null:
		_record_issue("FAIL: LevelCompleteScreen not found")
	else:
		_level_complete_stars = screen_node.get_stars()
		var final_moves: int = screen_node.get_final_moves()
		print("[PlaytestM2Runner] LevelCompleteScreen: stars=%d, moves=%d" % [
			_level_complete_stars, final_moves,
		])
		if _level_complete_stars >= 1:
			print("[PlaytestM2Runner] PASS: Level completed with %d star(s)" % _level_complete_stars)
		else:
			_record_issue("FAIL: Level complete screen shows 0 stars")

	# Navigate back to World Map
	print("[PlaytestM2Runner] Returning to World Map...")
	if screen_node != null:
		screen_node.on_world_map_btn_pressed()
	else:
		SceneManager.go_to(SceneManager.Screen.WORLD_MAP)


func _handle_world_map_second() -> void:
	if _phase != Phase.LEVEL_COMPLETE and _phase != Phase.WORLD_MAP_SECOND:
		return
	_phase = Phase.WORLD_MAP_SECOND
	print("[PlaytestM2Runner] Phase: WORLD_MAP_SECOND (post-completion)")

	PlaytestCapture.capture("world_map_after")
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	# Verify World Map node loaded
	var world_map_node: Node = _find_node_by_script("world_map")
	if world_map_node == null:
		_record_issue("FAIL: WorldMap node not found on return")
	else:
		print("[PlaytestM2Runner] PASS: WorldMap reloaded after level complete")

	# Verify star was saved to SaveManager
	_stars_after = SaveManager.get_best_stars("w1_l7")
	print("[PlaytestM2Runner] w1_l7 stars after: %d (was: %d)" % [_stars_after, _stars_before])

	if _stars_after > _stars_before:
		print("[PlaytestM2Runner] PASS: w1_l7 star count updated in SaveManager (%d → %d)" % [
			_stars_before, _stars_after,
		])
	else:
		_record_issue("FAIL: w1_l7 star count not updated (before=%d, after=%d)" % [
			_stars_before, _stars_after,
		])

	_phase = Phase.DONE
	_finish()


# —————————————————————————————————————————————
# Result and summary
# —————————————————————————————————————————————

func _record_issue(msg: String) -> void:
	_issues.append(msg)
	push_warning("[PlaytestM2Runner] %s" % msg)


func _finish() -> void:
	print("[PlaytestM2Runner] ─────────────────────────────────────")
	print("[PlaytestM2Runner] === M2 PLAYTEST SUMMARY ===")
	print("[PlaytestM2Runner]   Phases completed:  %s" % Phase.keys()[_phase])
	print("[PlaytestM2Runner]   Screenshots saved: %s" % PlaytestCapture.get_screenshot_dir())
	print("[PlaytestM2Runner]   w1_l7 stars before: %d" % _stars_before)
	print("[PlaytestM2Runner]   w1_l7 stars after:  %d" % _stars_after)
	print("[PlaytestM2Runner]   Level Complete stars: %d" % _level_complete_stars)

	if _issues.is_empty():
		print("[PlaytestM2Runner] === RESULT: PASS — 0 issues ===")
	else:
		print("[PlaytestM2Runner] === RESULT: FAIL — %d issue(s) ===" % _issues.size())
		for issue: String in _issues:
			print("[PlaytestM2Runner]   • %s" % issue)

	PlaytestCapture.print_event_log()
	await get_tree().create_timer(1.5).timeout
	get_tree().quit()


# —————————————————————————————————————————————
# Utilities
# —————————————————————————————————————————————

func _dir_name(dir: Vector2i) -> String:
	match dir:
		Vector2i(0, -1): return "up"
		Vector2i(0, 1): return "down"
		Vector2i(-1, 0): return "left"
		Vector2i(1, 0): return "right"
	return "unknown"


func _find_node_by_script(script_filename: String) -> Node:
	return _search_tree(get_tree().root, script_filename)


func _search_tree(node: Node, script_filename: String) -> Node:
	if node.get_script() != null:
		var path: String = (node.get_script() as Script).resource_path
		if path.ends_with("/%s.gd" % script_filename):
			return node
	for child: Node in node.get_children():
		var found: Node = _search_tree(child, script_filename)
		if found != null:
			return found
	return null
