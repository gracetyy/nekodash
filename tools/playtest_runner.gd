## PlaytestRunner — automated playtest across all World 1 levels.
##
## Persistent autoload. Hooks into SceneManager.transition_completed so it
## survives scene swaps. On each GAMEPLAY scene it plays the optimal solution
## for that level; on each LEVEL_COMPLETE scene it presses Next Level to
## advance. Captures screenshots and logs via PlaytestCapture at every step.
##
## Usage:
##   1. Add "PlaytestRunner" to [autoload] in project.godot AFTER PlaytestCapture.
##   2. Launch res://scenes/gameplay/gameplay.tscn.
##   3. After all 6 levels, runner prints PASS/FAIL summary and quits.
##   4. Remove the autoload entry from project.godot after the run.
extends Node


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const MOVE_STEP_WAIT_SEC: float = 0.6      # Time for slide animation to settle
const SCREENSHOT_WAIT_SEC: float = 0.25    # Frame settle before screenshot
const LEVEL_SETTLE_WAIT_SEC: float = 1.0   # Wait after last move before checking state
const SCENE_SETTLE_WAIT_SEC: float = 0.5   # Wait after scene loads before acting

## Optimal (minimum-move) solutions for every World 1 level.
## Verified against level_data.minimum_moves; all achieve 3-star.
const LEVEL_SOLUTIONS: Dictionary = {
	# w1_l1 "First Steps"   4×3  — min 1  — cat (1,1), 2 walkable tiles
	"w1_l1": ["right"],
	# w1_l2 "Turn the Corner" 4×4 — min 3  — cat (1,1), 4 walkable tiles
	"w1_l2": ["right", "down", "left"],
	# w1_l3 "Central Wall"  5×5  — min 4  — cat (1,1), 8 walkable tiles
	"w1_l3": ["right", "down", "left", "up"],
	# w1_l4 "Side Step"     5×4  — min 4  — cat (1,1), 5 walkable tiles
	#   down→(1,2) | up→(1,1) | right→(3,1) | down→(3,2)
	"w1_l4": ["down", "up", "right", "down"],
	# w1_l5 "Double S"      6×6  — min 5  — cat (1,1), 8 walkable tiles
	#   right→(3,1) | down→(3,3) | left→(2,3) | down→(2,4) | left→(1,4)
	"w1_l5": ["right", "down", "left", "down", "left"],
	# w1_l6 "Three Turn"    6×7  — min 6  — cat (1,1), 14 walkable tiles
	#   right→(4,1) | left→(1,1) | down→(1,3) | right→(4,3) | down→(4,5) | left→(1,5)
	"w1_l6": ["right", "left", "down", "right", "down", "left"],
}

## Total expected levels in the run.
const TOTAL_LEVELS: int = 6


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _results: Array[Dictionary] = []   # per-level PASS/FAIL records
var _visited_level_ids: Array[String] = []
## Set to the level_id currently being played; cleared when the level-complete
## screen records the result. Prevents double-recording the same level.
var _awaiting_result_for: String = ""


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	SceneManager.transition_completed.connect(_on_transition_completed)
	print("[PlaytestRunner] Ready — hooked into SceneManager.transition_completed.")
	print("[PlaytestRunner] === AUTOMATED PLAYTEST START: %d levels ===" % TOTAL_LEVELS)

	# The runner is added before the first scene loads; gameplay.tscn is the
	# launch scene, so transition_completed will fire for GAMEPLAY imminently.
	# Also handle the case where the scene is already loaded (e.g. direct launch).
	await get_tree().process_frame
	var coordinator: Node = _find_node_by_script("level_coordinator")
	if coordinator != null:
		_handle_gameplay_scene.call_deferred()


# —————————————————————————————————————————————
# SceneManager hook
# —————————————————————————————————————————————

func _on_transition_completed(screen: int) -> void:
	match screen:
		SceneManager.Screen.GAMEPLAY:
			await get_tree().create_timer(SCENE_SETTLE_WAIT_SEC).timeout
			await _handle_gameplay_scene()

		SceneManager.Screen.LEVEL_COMPLETE:
			await get_tree().create_timer(SCENE_SETTLE_WAIT_SEC).timeout
			await _handle_level_complete_scene()


# —————————————————————————————————————————————
# Phase handlers
# —————————————————————————————————————————————

func _handle_gameplay_scene() -> void:
	var coordinator: Node = _find_node_by_script("level_coordinator")
	if coordinator == null:
		print("[PlaytestRunner] ERROR: GAMEPLAY scene has no LevelCoordinator!")
		_finish()
		return

	var level_data: Resource = coordinator.get_current_level_data()
	if level_data == null:
		print("[PlaytestRunner] ERROR: LevelCoordinator has no LevelData!")
		_finish()
		return

	var level_id: String = level_data.level_id

	# Guard against level loops (e.g. if last level has no next)
	if level_id in _visited_level_ids:
		print("[PlaytestRunner] WARNING: Already visited %s — stopping." % level_id)
		_finish()
		return
	_visited_level_ids.append(level_id)

	await _play_level(coordinator, level_data)


func _handle_level_complete_scene() -> void:
	var screen_node: Node = _find_node_by_script("level_complete_screen")

	if screen_node == null:
		print("[PlaytestRunner] WARNING: LevelCompleteScreen node not found — cannot advance.")
		_finish()
		return

	var level_id: String = ""
	var display_name: String = ""
	if screen_node.get_level_data() != null:
		level_id = screen_node.get_level_data().level_id
		display_name = screen_node.get_level_data().display_name

	PlaytestCapture.capture("level_complete_screen_%s" % level_id)
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	var stars: int = screen_node.get_stars()
	var final_moves: int = screen_node.get_final_moves()
	print("[PlaytestRunner] LevelCompleteScreen: stars=%d, moves=%d, level=%s" % [
		stars, final_moves, level_id,
	])

	# Record result here — the LevelCompleteScreen only appears on successful completion.
	# stars=3 means optimal; stars>=1 means correct. The expected solution achieves 3.
	if _awaiting_result_for == level_id:
		var passed: bool = stars == 3
		var note: String = "3-star OK" if passed else ("stars=%d (expected 3)" % stars)
		# Estimate total walkable from level_data.minimum_moves context — use stars as proxy.
		# We cannot query GridSystem here (new scene has reloaded it for the next level).
		_record_result(level_id, display_name, passed, note, final_moves, -1)
		_awaiting_result_for = ""

	# Check if there's a next level
	var next_data: LevelData = screen_node.get_next_level_data()
	if next_data == null:
		print("[PlaytestRunner] No next level after %s — all levels complete!" % level_id)
		await get_tree().create_timer(0.5).timeout
		_finish()
		return

	# Advance to next level by pressing the Next button
	print("[PlaytestRunner] Advancing to next level: %s" % next_data.level_id)
	screen_node.on_next_btn_pressed()


# —————————————————————————————————————————————
# Level execution
# —————————————————————————————————————————————

func _play_level(coordinator: Node, level_data: Resource) -> void:
	var level_id: String = level_data.level_id
	var display_name: String = level_data.display_name

	print("[PlaytestRunner] ─────────────────────────────────────")
	print("[PlaytestRunner] Playing: %s (%s)" % [display_name, level_id])

	# Validate and capture initial state
	_log_grid_state(coordinator)
	PlaytestCapture.capture("initial_%s" % level_id)
	await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

	# Look up solution
	var moves: Array = LEVEL_SOLUTIONS.get(level_id, [])
	if moves.is_empty():
		print("[PlaytestRunner] FAIL: No solution defined for %s" % level_id)
		_record_result(level_id, display_name, false, "no solution defined", 0, 0)
		return

	print("[PlaytestRunner] Solution: %s (%d moves)" % [str(moves), moves.size()])

	# Mark that we expect a result for this level from the LEVEL_COMPLETE screen.
	_awaiting_result_for = level_id

	# Execute moves one at a time
	for i: int in range(moves.size()):
		var move: String = moves[i]
		var dir: Vector2i = _dir(move)

		print("[PlaytestRunner] Move %d/%d: %s" % [i + 1, moves.size(), move])
		InputSystem.direction_input.emit(dir)
		await get_tree().create_timer(MOVE_STEP_WAIT_SEC).timeout

		# After any await the coordinator may be freed (if the level completed and
		# SceneManager transitioned during the wait). Guard all subsequent accesses.
		if not is_instance_valid(coordinator):
			print("[PlaytestRunner]   (coordinator freed after move %d — level completed)" % (i + 1))
			PlaytestCapture.capture("%s_move%02d_%s" % [level_id, i + 1, move])
			return

		PlaytestCapture.capture("%s_move%02d_%s" % [level_id, i + 1, move])
		await get_tree().create_timer(SCREENSHOT_WAIT_SEC).timeout

		if not is_instance_valid(coordinator):
			return

		_log_move_state(coordinator, i + 1)

	# Wait for level-complete chain (StarRating → LevelProgression → SceneManager)
	await get_tree().create_timer(LEVEL_SETTLE_WAIT_SEC).timeout

	if not is_instance_valid(coordinator):
		# Level completed and transitioned; result will be recorded by the LEVEL_COMPLETE handler.
		return

	# Verify outcome — coordinator is still alive (e.g. last level or slow chain)
	var ct: Node = coordinator.get_node_or_null("CoverageTracking")
	var covered: int = ct.get_covered_count() if ct != null else -1
	var total: int = ct.get_total_walkable() if ct != null else -1
	var state: int = coordinator.get_state()
	var completed: bool = (state == 3)

	if completed:
		print("[PlaytestRunner] Coordinator still live but in TRANSITIONING — awaiting scene swap.")
		# Result will come from _handle_level_complete_scene
	else:
		# Level did NOT complete — record FAIL immediately
		print("[PlaytestRunner] FAIL: %s — coverage %d/%d, state=%d" % [
			level_id, covered, total, state,
		])
		_record_result(level_id, display_name, false,
			"coverage=%d/%d state=%d" % [covered, total, state], covered, total)
		_awaiting_result_for = ""

	PlaytestCapture.capture("post_complete_%s" % level_id)


# —————————————————————————————————————————————
# Logging helpers
# —————————————————————————————————————————————

func _log_grid_state(coordinator: Node) -> void:
	var sm: Node2D = coordinator.get_node("SlidingMovement")
	var ct: Node = coordinator.get_node("CoverageTracking")
	var gr: Node2D = coordinator.get_node_or_null("GridRenderer")

	print("[PlaytestRunner]   Grid:     %dx%d  walkable=%d" % [
		GridSystem.get_width(), GridSystem.get_height(),
		GridSystem.get_all_walkable_tiles().size(),
	])
	print("[PlaytestRunner]   Cat:      grid=%s  pixel=%s" % [
		str(sm.get_cat_pos()), str(sm.position),
	])
	print("[PlaytestRunner]   Coverage: %d/%d" % [
		ct.get_covered_count(), ct.get_total_walkable(),
	])
	if gr != null:
		print("[PlaytestRunner]   GridRenderer offset:  %s" % str(gr.position))
		print("[PlaytestRunner]   Coordinator position: %s" % str(coordinator.position))

	# Visual layer check: CoverageVisualizer initialized?
	var cv: Node = coordinator.get_node_or_null("CoverageVisualizer")
	if cv != null:
		print("[PlaytestRunner]   CoverageVisualizer: initialized=%s  covered_tiles=%d" % [
			str(cv.is_initialized()), cv.get_covered_tile_count(),
		])


func _log_move_state(coordinator: Node, move_num: int) -> void:
	var sm: Node2D = coordinator.get_node("SlidingMovement")
	var mc: Node = coordinator.get_node("MoveCounter")
	var ct: Node = coordinator.get_node("CoverageTracking")

	print("[PlaytestRunner]   After move %d: cat=%s  moves=%d  coverage=%d/%d" % [
		move_num,
		str(sm.get_cat_pos()),
		mc.get_current_moves(),
		ct.get_covered_count(),
		ct.get_total_walkable(),
	])


# —————————————————————————————————————————————
# Result tracking
# —————————————————————————————————————————————

func _record_result(
	level_id: String,
	display_name: String,
	passed: bool,
	note: String,
	covered: int,
	total: int,
) -> void:
	_results.append({
		"level_id": level_id,
		"display_name": display_name,
		"pass": passed,
		"note": note,
		"covered": covered,
		"total": total,
	})


func _finish() -> void:
	print("[PlaytestRunner] ─────────────────────────────────────")
	print("[PlaytestRunner] === PLAYTEST SUMMARY ===")

	var pass_count: int = 0
	for r: Dictionary in _results:
		var status: String = "PASS" if r["pass"] else "FAIL"
		var coverage_str: String = "%d/%d" % [r["covered"], r["total"]] if r["total"] >= 0 else "n/a"
		print("[PlaytestRunner]   %s  %-20s  moves=%s  coverage=%s  %s" % [
			status, r["level_id"], str(r["covered"]), coverage_str, r["note"],
		])
		if r["pass"]:
			pass_count += 1

	print("[PlaytestRunner] Result: %d/%d levels PASSED" % [pass_count, _results.size()])
	print("[PlaytestRunner] Screenshots: %s" % PlaytestCapture.get_screenshot_dir())
	PlaytestCapture.print_event_log()

	await get_tree().create_timer(1.5).timeout
	get_tree().quit()


# —————————————————————————————————————————————
# Utilities
# —————————————————————————————————————————————

func _dir(name: String) -> Vector2i:
	match name.to_lower():
		"up":    return Vector2i(0, -1)
		"down":  return Vector2i(0, 1)
		"left":  return Vector2i(-1, 0)
		"right": return Vector2i(1, 0)
	return Vector2i.ZERO


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
