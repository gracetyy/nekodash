extends SceneTree

var _scene_manager: Node
var _frame: int = 0
var _step: int = 0
var _pending_marker_name: String = ""
var _pending_marker_frame: int = 0


func _initialize() -> void:
	_scene_manager = _find_root_child("SceneManager")
	if _scene_manager == null:
		push_error("[ShellPolish] SceneManager autoload not found.")
		quit(1)
		return

	print("[ShellPolish] Starting overlay smoke capture.")
	_scene_manager.go_to(_scene_manager.Screen.MAIN_MENU)
	_pending_marker_name = "01-main-menu"
	_pending_marker_frame = 12


func _process(_delta: float) -> bool:
	_frame += 1

	if _pending_marker_name != "" and _frame >= _pending_marker_frame:
		_capture_marker(_pending_marker_name)
		_pending_marker_name = ""

	match _step:
		0:
			if _frame >= 16:
				_scene_manager.show_overlay(_scene_manager.Overlay.OPTIONS, {
					"title": "Options",
					"pause_tree": false,
				})
				_pending_marker_name = "02-settings"
				_pending_marker_frame = 2
				_advance_step()
		1:
			if _frame >= 6:
				_scene_manager.hide_overlay()
				_scene_manager.go_to(_scene_manager.Screen.WORLD_MAP, {
					"highlight_world_id": 1,
				})
				_pending_marker_name = "03-world-map"
				_pending_marker_frame = 2
				_advance_step()
		2:
			if _frame >= 6:
				var level_data: Resource = _get_level_data(0)
				if level_data == null:
					push_error("[ShellPolish] Could not load a level for gameplay smoke.")
					quit(1)
					return true
				_scene_manager.go_to_with_loading(_scene_manager.Screen.GAMEPLAY, {
					"level_data": level_data,
				})
				_pending_marker_name = "04-gameplay"
				_pending_marker_frame = 6
				_advance_step()
		3:
			if _frame >= 8:
				_scene_manager.show_overlay(_scene_manager.Overlay.PAUSE, {
					"pause_tree": false,
				})
				_pending_marker_name = "05-pause"
				_pending_marker_frame = 2
				_advance_step()
		4:
			if _frame >= 6:
				_scene_manager.show_overlay(_scene_manager.Overlay.OPTIONS, {
					"title": "Paused Options",
					"return_overlay": int(_scene_manager.Overlay.PAUSE),
					"pause_tree": false,
				})
				_pending_marker_name = "06-paused-settings"
				_pending_marker_frame = 2
				_advance_step()
		5:
			if _frame >= 6:
				_scene_manager.hide_overlay()
				_trigger_level_complete_overlay()
				_pending_marker_name = "07-level-complete"
				_pending_marker_frame = 4
				_advance_step()
		6:
			if _frame >= 7:
				print("[ShellPolish] Capture complete.")
				quit(0)
				return true

	return false


func _advance_step() -> void:
	_step += 1
	_frame = 0


func _capture_marker(name: String) -> void:
	print("[ShellPolish] Marker %s at local_step_frame=%d" % [name, _frame])


func _trigger_level_complete_overlay() -> void:
	var root_node: Node = root
	if root_node != null:
		var coverage_tracking: Node = root_node.find_child("CoverageTracking", true, false)
		if coverage_tracking != null and coverage_tracking.has_signal("level_completed"):
			coverage_tracking.level_completed.emit()
			return

	var level_data: LevelData = _get_level_data(0) as LevelData
	var next_level_data: LevelData = _get_level_data(1) as LevelData
	if level_data == null:
		push_warning("[ShellPolish] Missing level_data for level-complete capture.")
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