extends SceneTree

const OUTPUT_DIR: String = "user://playtest_screenshots/ui_verify"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DisplayServer.window_set_size(Vector2i(540, 940))
	await process_frame
	await process_frame

	await _capture_scene("res://scenes/ui/world_map.tscn", "world_map_current")
	await _capture_scene("res://scenes/ui/level_complete.tscn", "level_complete_plain_current")
	await _capture_scene("res://scenes/ui/options_overlay.tscn", "options_current")
	await _capture_scene("res://scenes/ui/pause_overlay.tscn", "pause_current")
	await _capture_level_complete("level_complete_current")
	await _capture_level_complete_overlay("level_complete_overlay_current")
	quit(0)


func _capture_scene(scene_path: String, output_name: String) -> void:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("Failed to load scene: " + scene_path)
		return
	var instance: Node = scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	_save_viewport(output_name)
	instance.queue_free()
	await process_frame


func _capture_level_complete(output_name: String) -> void:
	var scene: PackedScene = load("res://scenes/ui/level_complete.tscn")
	if scene == null:
		push_error("Failed to load level complete scene")
		return
	var screen: Node = scene.instantiate()
	if screen.has_method("receive_scene_params"):
		var level_data: Resource = load("res://data/levels/world1/w1_l1.tres")
		var next_level_data: Resource = load("res://data/levels/world1/w1_l2.tres")
		screen.receive_scene_params({
			"level_data": level_data,
			"stars": 3,
			"final_moves": 8,
			"prev_best_moves": 9,
			"was_previously_completed": true,
			"next_level_data": next_level_data,
		})
	root.add_child(screen)
	await process_frame
	await process_frame
	if screen.has_method("populate_results"):
		screen.populate_results()
	await process_frame
	await process_frame
	_save_viewport(output_name)
	screen.queue_free()
	await process_frame


func _capture_level_complete_overlay(output_name: String) -> void:
	var scene: PackedScene = load("res://scenes/ui/level_complete_overlay.tscn")
	if scene == null:
		push_error("Failed to load level complete overlay scene")
		return
	var overlay: Node = scene.instantiate()
	if overlay.has_method("receive_scene_params"):
		var level_data: Resource = load("res://data/levels/world1/w1_l1.tres")
		var next_level_data: Resource = load("res://data/levels/world1/w1_l2.tres")
		overlay.receive_scene_params({
			"level_data": level_data,
			"stars": 3,
			"final_moves": 8,
			"prev_best_moves": 9,
			"was_previously_completed": true,
			"next_level_data": next_level_data,
		})
	root.add_child(overlay)
	await process_frame
	await process_frame
	await process_frame
	_save_viewport(output_name)
	overlay.queue_free()
	await process_frame


func _save_viewport(output_name: String) -> void:
	var image: Image = root.get_texture().get_image()
	var absolute_path: String = ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, output_name])
	var error: Error = image.save_png(absolute_path)
	if error != OK:
		push_error("Failed to save screenshot: " + absolute_path)
		return
	print("Saved screenshot: ", absolute_path)
