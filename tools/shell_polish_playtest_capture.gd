extends SceneTree

var _scene_manager: Node
var _playtest_capture: Node
var _frame: int = 0
var _step: int = -1
var _pending_capture_name: String = ""
var _pending_capture_frame: int = 0


func _initialize() -> void:
	_scene_manager = _find_root_child("SceneManager")
	_playtest_capture = _find_root_child("PlaytestCapture")
	if _scene_manager == null:
		push_error("[ShellPolishCapture] SceneManager autoload not found.")
		quit(1)
		return
	if _playtest_capture == null:
		push_error("[ShellPolishCapture] PlaytestCapture autoload not found.")
		quit(1)
		return

	print("[ShellPolishCapture] Starting screenshot smoke capture.")


func _process(_delta: float) -> bool:
	_frame += 1

	if _pending_capture_name != "" and _frame >= _pending_capture_frame:
		_capture_marker(_pending_capture_name)
		_pending_capture_name = ""

	match _step:
		-1:
			if _frame >= 2:
				_scene_manager.go_to(_scene_manager.Screen.MAIN_MENU)
				_schedule_capture("shell_main_menu", 18)
				_advance_step()
		0:
			if _frame >= 24:
				_scene_manager.show_overlay(_scene_manager.Overlay.OPTIONS, {
					"title": "Options",
					"pause_tree": false,
				})
				_schedule_capture("shell_options", 2)
				_advance_step()
		1:
			if _frame >= 6:
				_scene_manager.hide_overlay()
				_scene_manager.go_to(_scene_manager.Screen.WORLD_MAP, {
					"highlight_world_id": 1,
				})
				_schedule_capture("shell_world_map", 2)
				_advance_step()
		2:
			if _frame >= 6:
				var level_data: LevelData = _get_level_data(0) as LevelData
				if level_data == null:
					push_error("[ShellPolishCapture] Could not load level for gameplay capture.")
					quit(1)
					return true
				_scene_manager.go_to_level(level_data)
				_schedule_capture("shell_gameplay", 8)
				_advance_step()
		3:
			if _frame >= 10:
				_scene_manager.show_overlay(_scene_manager.Overlay.PAUSE, {
					"pause_tree": false,
				})
				_schedule_capture("shell_pause", 2)
				_advance_step()
		4:
			if _frame >= 6:
				_scene_manager.show_overlay(_scene_manager.Overlay.OPTIONS, {
					"title": "Paused Options",
					"return_overlay": int(_scene_manager.Overlay.PAUSE),
					"pause_tree": false,
				})
				_schedule_capture("shell_paused_options", 2)
				_advance_step()
		5:
			if _frame >= 6:
				_scene_manager.hide_overlay()
				_trigger_level_complete_overlay()
				_schedule_capture("shell_level_complete", 6)
				_advance_step()
		6:
			if _frame >= 10:
				print("[ShellPolishCapture] Capture complete.")
				quit(0)
				return true

	return false


func _schedule_capture(event_name: String, frame_delay: int) -> void:
	_pending_capture_name = event_name
	_pending_capture_frame = frame_delay


func _advance_step() -> void:
	_step += 1
	_frame = 0


func _capture_marker(event_name: String) -> void:
	print("[ShellPolishCapture] Marker %s at local_step_frame=%d" % [event_name, _frame])
	if _playtest_capture != null and _playtest_capture.has_method("capture"):
		_playtest_capture.capture(event_name)


func _trigger_level_complete_overlay() -> void:
	var level_data: LevelData = _get_level_data(0) as LevelData
	var next_level_data: LevelData = _get_level_data(1) as LevelData
	if level_data == null:
		push_warning("[ShellPolishCapture] Missing level_data for level complete capture.")
		return

	_scene_manager.show_overlay(_scene_manager.Overlay.LEVEL_COMPLETE, {
		"pause_tree": false,
		"level_data": level_data,
		"stars": 3,
		"final_moves": max(level_data.minimum_moves, 1),
		"prev_best_moves": max(level_data.minimum_moves + 2, 3),
		"was_previously_completed": true,
		"next_level_data": next_level_data,
	})


func _get_level_data(index: int) -> Resource:
	var catalogue: Resource = load("res://data/level_catalogue.tres")
	if catalogue == null or not ("levels" in catalogue):
		return null
	var levels: Array = catalogue.levels
	if index < 0 or index >= levels.size():
		return null
	return levels[index]


func _find_root_child(node_name: String) -> Node:
	for child: Node in root.get_children():
		if child.name == node_name:
			return child
	return null
