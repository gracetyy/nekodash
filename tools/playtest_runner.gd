## PlaytestRunner — automated playtest script for all World 1 levels.
##
## Runs as a one-shot autoload. On _ready(), waits for the level to load,
## then plays through the optimal solution for each level, capturing
## screenshots at each step via PlaytestCapture.
##
## Usage: Add as autoload AFTER PlaytestCapture in project.godot, or
##        run via command: godot --path . scenes/gameplay/gameplay.tscn
##        (with this script temporarily added as autoload)
extends Node

var _running: bool = false
var _visited_levels: Dictionary = {}

const MOVE_STEP_WAIT_SEC: float = 0.6
const SCREENSHOT_WAIT_SEC: float = 0.25
const LEVEL_SETTLE_WAIT_SEC: float = 1.0

# Move sequences for each level (optimal solutions)
var _level_solutions: Dictionary = {
	"w1_l1": ["right"],
	"w1_l2": ["right", "down", "left"],
	"w1_l3": ["right", "down", "left", "up"],
}

func _ready() -> void:
	# Wait for the scene to fully load
	await get_tree().create_timer(1.0).timeout
	_run_playtest()


func _run_playtest() -> void:
	_running = true
	print("[PlaytestRunner] === STARTING AUTOMATED PLAYTEST ===")

	# Find coordinator
	var coordinator: Node = _find_coordinator()
	if coordinator == null:
		print("[PlaytestRunner] ERROR: No LevelCoordinator found!")
		_finish()
		return

	# Walk through all reachable levels via LevelProgression.get_next_level().
	while true:
		var level_data: Resource = coordinator.get_current_level_data()
		if level_data == null:
			print("[PlaytestRunner] ERROR: No LevelData loaded!")
			break

		var level_id: String = level_data.level_id
		if _visited_levels.has(level_id):
			print("[PlaytestRunner] WARNING: Level loop detected at %s; aborting." % level_id)
			break
		_visited_levels[level_id] = true

		await _play_single_level(coordinator, level_data)

		# Move to next level if available.
		var level_progression: Node = coordinator.get_node_or_null("LevelProgression")
		if level_progression == null:
			print("[PlaytestRunner] ERROR: Missing LevelProgression node.")
			break

		var next_level: LevelData = level_progression.get_next_level(level_id)
		if next_level == null:
			print("[PlaytestRunner] No next level after %s. Playtest sequence complete." % level_id)
			break

		if coordinator.has_method("_on_overlay_next"):
			coordinator.call("_on_overlay_next", next_level)
			print("[PlaytestRunner] Advanced to next level: %s" % next_level.level_id)
			await get_tree().create_timer(LEVEL_SETTLE_WAIT_SEC).timeout
		else:
			print("[PlaytestRunner] ERROR: Coordinator missing _on_overlay_next(next_level).")
			break

	# Print event log
	PlaytestCapture.print_event_log()

	print("[PlaytestRunner] === PLAYTEST COMPLETE ===")
	print("[PlaytestRunner] Screenshot dir: %s" % PlaytestCapture.get_screenshot_dir())
	_finish()


func _play_single_level(coordinator: Node, level_data: Resource) -> void:
	var level_id: String = level_data.level_id
	print("[PlaytestRunner] Level: %s (%s)" % [level_data.display_name, level_id])

	# Capture initial state
	PlaytestCapture.capture("playtest_initial_%s" % level_id)
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	# Validate grid visuals
	_validate_grid_state(coordinator)

	# Get solution moves
	var moves: Array = _level_solutions.get(level_id, [])
	if moves.is_empty():
		print("[PlaytestRunner] WARNING: No solution defined for %s" % level_id)
		return

	# Play through moves
	for i: int in range(moves.size()):
		var move: String = moves[i]
		print("[PlaytestRunner] Move %d/%d: %s" % [i + 1, moves.size(), move])

		# Send input
		var dir: Vector2i = _direction_from_string(move)
		InputSystem.direction_input.emit(dir)

		# Wait for slide animation to complete
		await get_tree().create_timer(MOVE_STEP_WAIT_SEC).timeout

		# Capture screenshot after move
		PlaytestCapture.capture("playtest_%s_move%d_%s" % [level_id, i + 1, move])
		await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

		# Log state
		_validate_after_move(coordinator, i + 1)

	# Wait for level-complete chain to fire and overlay to appear
	await get_tree().create_timer(LEVEL_SETTLE_WAIT_SEC).timeout
	PlaytestCapture.capture("playtest_%s_final" % level_id)
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	# Check if level completed
	var state: int = coordinator.get_state()
	print("[PlaytestRunner] Final state: %d (TRANSITIONING=3)" % state)

	if state == 3: # State.TRANSITIONING
		print("[PlaytestRunner] PASS: Level %s completed successfully!" % level_id)
	else:
		print("[PlaytestRunner] FAIL: Level %s did NOT complete (state=%d)" % [level_id, state])

	PlaytestCapture.capture("playtest_%s_overlay" % level_id)


func _validate_grid_state(coordinator: Node) -> void:
	var w: int = GridSystem.get_width()
	var h: int = GridSystem.get_height()
	print("[PlaytestRunner] Grid: %dx%d" % [w, h])

	var walkable: Array[Vector2i] = GridSystem.get_all_walkable_tiles()
	print("[PlaytestRunner] Walkable tiles: %d — %s" % [walkable.size(), str(walkable)])

	var sm: Node2D = coordinator.get_node("SlidingMovement")
	print("[PlaytestRunner] Cat position: %s" % str(sm.get_cat_pos()))
	print("[PlaytestRunner] Cat pixel: %s" % str(sm.position))

	# Check grid renderer position
	var gr: Node2D = coordinator.get_node("GridRenderer")
	print("[PlaytestRunner] GridRenderer position: %s" % str(gr.position))
	print("[PlaytestRunner] Coordinator position: %s" % str(coordinator.position))


func _validate_after_move(coordinator: Node, move_num: int) -> void:
	var sm: Node2D = coordinator.get_node("SlidingMovement")
	var mc: Node = coordinator.get_node("MoveCounter")
	var ct: Node = coordinator.get_node("CoverageTracking")

	print("[PlaytestRunner] After move %d: cat=%s, moves=%d, coverage=%d/%d" % [
		move_num,
		str(sm.get_cat_pos()),
		mc.get_current_moves(),
		ct.get_covered_count(),
		ct.get_total_walkable(),
	])


func _direction_from_string(dir_str: String) -> Vector2i:
	match dir_str.to_lower():
		"up": return Vector2i(0, -1)
		"down": return Vector2i(0, 1)
		"left": return Vector2i(-1, 0)
		"right": return Vector2i(1, 0)
		_: return Vector2i.ZERO


func _find_coordinator() -> Node:
	return _find_in_children(get_tree().root, "level_coordinator")


func _find_in_children(node: Node, script_name: String) -> Node:
	if node.get_script() != null:
		var path: String = (node.get_script() as Script).resource_path
		if path.ends_with("/%s.gd" % script_name):
			return node
	for child: Node in node.get_children():
		var found: Node = _find_in_children(child, script_name)
		if found != null:
			return found
	return null


func _finish() -> void:
	_running = false
	# Auto-quit after playtest
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
