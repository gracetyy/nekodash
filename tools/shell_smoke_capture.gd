extends SceneTree

var _scene_manager: Node
var _frame: int = 0
var _step: int = 0
var _pending_marker_name: String = ""
var _pending_marker_frame: int = 2


func _initialize() -> void:
	_scene_manager = _find_root_child("SceneManager")
	if _scene_manager == null:
		push_error("[ShellSmoke] SceneManager autoload not found.")
		quit(1)
		return

	print("[ShellSmoke] Starting marker-driven shell smoke capture.")
	_scene_manager.go_to(_scene_manager.Screen.OPENING)
	_pending_marker_name = "01-opening"
	_pending_marker_frame = 6


func _process(_delta: float) -> bool:
	_frame += 1

	if _pending_marker_name != "" and _frame >= _pending_marker_frame:
		_capture_marker(_pending_marker_name)
		_pending_marker_name = ""

	match _step:
		0:
			if _frame >= 9:
				_log_focus("opening")
				_scene_manager.go_to(_scene_manager.Screen.MAIN_MENU)
				_pending_marker_name = "02-main-menu"
				_pending_marker_frame = 2
				_advance_step()
		1:
			if _frame >= 5:
				_log_focus("main_menu")
				_scene_manager.show_overlay(_scene_manager.Overlay.OPTIONS, {
					"title": "Options",
					"pause_tree": false,
				})
				_pending_marker_name = "03-options"
				_pending_marker_frame = 2
				_advance_step()
		2:
			if _frame >= 5:
				_log_focus("options_overlay")
				_scene_manager.hide_overlay()
				_scene_manager.go_to(_scene_manager.Screen.CREDITS)
				_pending_marker_name = "04-credits"
				_pending_marker_frame = 2
				_advance_step()
		3:
			if _frame >= 5:
				_log_focus("credits")
				_scene_manager.go_to(_scene_manager.Screen.WORLD_MAP, {
					"highlight_world_id": 2,
				})
				_pending_marker_name = "05-world-map"
				_pending_marker_frame = 2
				_advance_step()
		4:
			if _frame >= 5:
				_log_focus("world_map")
				var level_data: Resource = _first_level_data()
				if level_data == null:
					push_error("[ShellSmoke] Could not load a level for gameplay smoke.")
					quit(1)
					return true
				_scene_manager.go_to_with_loading(_scene_manager.Screen.GAMEPLAY, {
					"level_data": level_data,
				})
				_pending_marker_name = "06-loading"
				_pending_marker_frame = 2
				_advance_step()
		5:
			if _frame >= 5:
				_pending_marker_name = "07-gameplay"
				_pending_marker_frame = 2
				_advance_step()
		6:
			if _frame >= 5:
				_scene_manager.show_overlay(_scene_manager.Overlay.PAUSE, {
					"pause_tree": false,
				})
				_pending_marker_name = "08-pause"
				_pending_marker_frame = 2
				_advance_step()
		7:
			if _frame >= 5:
				_scene_manager.show_overlay(_scene_manager.Overlay.OPTIONS, {
					"title": "Paused Options",
					"return_overlay": int(_scene_manager.Overlay.PAUSE),
					"pause_tree": false,
				})
				_pending_marker_name = "09-paused-options"
				_pending_marker_frame = 2
				_advance_step()
		8:
			if _frame >= 5:
				_log_focus("paused_options")
				print("[ShellSmoke] Capture complete.")
				quit(0)
				return true

	return false


func _advance_step() -> void:
	_step += 1
	_frame = 0


func _capture_marker(name: String) -> void:
	print("[ShellSmoke] Marker %s at local_step_frame=%d" % [name, _frame])


func _log_focus(label: String) -> void:
	var focus_owner: Control = root.gui_get_focus_owner()
	if focus_owner == null:
		print("[ShellSmoke] Focus %s: <none>" % label)
		return
	print("[ShellSmoke] Focus %s: %s" % [label, focus_owner.get_path()])


func _find_root_child(node_name: String) -> Node:
	for child: Node in root.get_children():
		if child.name == node_name:
			return child
	return null


func _first_level_data() -> Resource:
	var catalogue: Resource = load("res://data/level_catalogue.tres")
	if catalogue == null or not ("levels" in catalogue):
		return null
	var levels: Array = catalogue.levels
	if levels.is_empty():
		return null
	return levels[0]
