## PlaytestCapture — autoload for automated playtesting with screenshots.
##
## When loaded, captures screenshots at key game events and logs game state
## to the console. Screenshots are saved to user://playtest_screenshots/.
##
## Usage (add as autoload or attach to scene):
##   PlaytestCapture is auto-connected to all relevant signals.
##   Screenshots: user://playtest_screenshots/YYYYMMDD_HHMMSS_eventname.png
##
## To trigger manual capture from console or MCP:
##   PlaytestCapture.capture("manual_note")
extends Node


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const SCREENSHOT_DIR: String = "user://playtest_screenshots"
const AUTO_CAPTURE_DELAY_SEC: float = 0.15 # Small delay to let frame render


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _capture_count: int = 0
var _session_id: String = ""
var _event_log: Array[String] = []


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_session_id = Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")

	# Ensure screenshot directory exists
	DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)

	# Connect to autoload signals if available
	_connect_game_signals()

	_log_event("SESSION_START", "Playtest session started")
	print("[PlaytestCapture] Ready — screenshots → %s" % SCREENSHOT_DIR)


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Captures a screenshot with an event tag. Call from anywhere.
func capture(event_name: String = "manual") -> void:
	# Wait one frame so the current draw call completes
	await get_tree().process_frame
	await get_tree().process_frame

	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		push_warning("[PlaytestCapture] Failed to capture viewport image.")
		return

	_capture_count += 1
	var filename: String = "%s/%s_%03d_%s.png" % [
		SCREENSHOT_DIR, _session_id, _capture_count, event_name
	]
	var err: Error = img.save_png(filename)
	if err == OK:
		print("[PlaytestCapture] Screenshot saved: %s" % filename)
	else:
		push_warning("[PlaytestCapture] Failed to save screenshot: %s (error %d)" % [filename, err])


## Simulates a directional input (for automated playtesting).
func simulate_input(direction: String) -> void:
	var dir_map: Dictionary = {
		"up": Vector2i(0, -1),
		"down": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0),
	}
	var dir: Vector2i = dir_map.get(direction.to_lower(), Vector2i.ZERO)
	if dir == Vector2i.ZERO:
		push_warning("[PlaytestCapture] Invalid direction: %s" % direction)
		return

	_log_event("INPUT", "Simulated %s input" % direction)
	InputSystem.direction_input.emit(dir)

	# Auto-capture after the slide completes
	await get_tree().create_timer(0.5).timeout
	capture("after_%s" % direction)


## Runs a sequence of moves with captures between each.
func run_sequence(moves: Array[String]) -> void:
	_log_event("SEQUENCE_START", "Running %d moves: %s" % [moves.size(), str(moves)])
	capture("sequence_start")

	for move: String in moves:
		await simulate_input(move)
		await get_tree().create_timer(0.3).timeout

	_log_event("SEQUENCE_END", "Sequence complete")
	capture("sequence_end")


## Prints the full event log to console (readable by MCP get_debug_output).
func print_event_log() -> void:
	print("[PlaytestCapture] === EVENT LOG ===")
	for entry: String in _event_log:
		print("  %s" % entry)
	print("[PlaytestCapture] === END LOG (%d events, %d screenshots) ===" % [
		_event_log.size(), _capture_count
	])


## Returns the screenshot directory path.
func get_screenshot_dir() -> String:
	return ProjectSettings.globalize_path(SCREENSHOT_DIR)


# —————————————————————————————————————————————
# Signal connections
# —————————————————————————————————————————————

func _connect_game_signals() -> void:
	# Wait for tree to be ready
	await get_tree().process_frame

	# Find LevelCoordinator in the scene
	var coordinator: Node = _find_node_by_script("level_coordinator")
	if coordinator == null:
		print("[PlaytestCapture] No LevelCoordinator found — auto-capture disabled.")
		return

	# Connect to coordinator signals
	if coordinator.has_signal("level_restarted"):
		coordinator.level_restarted.connect(_on_level_restarted)

	# Find child systems
	var coverage: Node = coordinator.get_node_or_null("CoverageTracking")
	if coverage != null:
		if coverage.has_signal("level_completed"):
			coverage.level_completed.connect(_on_level_completed)
		if coverage.has_signal("tile_covered"):
			coverage.tile_covered.connect(_on_tile_covered)

	var sliding: Node = coordinator.get_node_or_null("SlidingMovement")
	if sliding != null:
		if sliding.has_signal("slide_completed"):
			sliding.slide_completed.connect(_on_slide_completed)
		if sliding.has_signal("slide_blocked"):
			sliding.slide_blocked.connect(_on_slide_blocked)

	# Initial state capture
	capture("level_loaded")
	print("[PlaytestCapture] Auto-capture connected to gameplay signals.")


# —————————————————————————————————————————————
# Event handlers
# —————————————————————————————————————————————

func _on_slide_completed(from: Vector2i, to: Vector2i, dir: Vector2i, _tiles: Array[Vector2i]) -> void:
	_log_event("SLIDE", "from %s to %s dir %s" % [from, to, dir])


func _on_slide_blocked(pos: Vector2i, dir: Vector2i) -> void:
	_log_event("BLOCKED", "at %s dir %s" % [pos, dir])
	capture("blocked")


func _on_tile_covered(coord: Vector2i) -> void:
	_log_event("TILE_COVERED", str(coord))


func _on_level_completed() -> void:
	_log_event("LEVEL_COMPLETE", "All tiles covered!")
	capture("level_complete")


func _on_level_restarted() -> void:
	_log_event("RESTART", "Level restarted")
	capture("after_restart")


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

func _log_event(event_type: String, detail: String) -> void:
	var timestamp: String = Time.get_time_string_from_system()
	var entry: String = "[%s] %s: %s" % [timestamp, event_type, detail]
	_event_log.append(entry)
	print("[PlaytestCapture] %s" % entry)


func _find_node_by_script(script_name: String) -> Node:
	return _find_in_children(get_tree().root, script_name)


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
