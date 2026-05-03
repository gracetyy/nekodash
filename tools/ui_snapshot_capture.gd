## UI Snapshot Capture Tool
##
## Captures screenshots of all UI screens at both mobile (540x960) and desktop (1280x720) resolutions.
## This ensures visual regression testing works correctly for both platforms.
##
## Usage: godot --path . --script tools/ui_snapshot_capture.gd
## Output: user://playtest_screenshots/ui_verify/
##
## Fixes:
## - Correct mobile viewport size (540x960 matches project.godot, not 540x940)
## - Captures both mobile and desktop layouts
## - Proper settle times for animations and scene initialization
## - Includes gameplay HUD capture
##
extends SceneTree

const OUTPUT_DIR: String = "user://playtest_screenshots/ui_verify"
const MOBILE_SIZE: Vector2i = Vector2i(540, 960) # Match project.godot viewport size
const DESKTOP_SIZE: Vector2i = Vector2i(1280, 720) # 16:9 desktop aspect


func _initialize() -> void:
	print("Starting UI snapshot capture...")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	
	# Capture mobile versions (540x960)
	print("=== Capturing Mobile Versions (540x960) ===")
	DisplayServer.window_set_size(MOBILE_SIZE)
	await process_frame
	await process_frame
	
	await _capture_scene("res://scenes/ui/main_menu.tscn", "main_menu_mobile")
	await _capture_scene("res://scenes/ui/world_map.tscn", "world_map_mobile")
	await _capture_scene("res://scenes/ui/skin_select.tscn", "skin_select_mobile")
	await _capture_scene("res://scenes/ui/options_overlay.tscn", "options_mobile")
	await _capture_scene("res://scenes/ui/pause_overlay.tscn", "pause_mobile")
	await _capture_scene("res://scenes/ui/level_complete.tscn", "level_complete_plain_mobile")
	await _capture_level_complete("level_complete_mobile")
	await _capture_level_complete_perfect("level_complete_perfect_mobile")
	await _capture_level_complete_overlay("level_complete_overlay_mobile")
	await _capture_gameplay("gameplay_hud_mobile")
	
	# Capture desktop versions (1280x720)
	print("=== Capturing Desktop Versions (1280x720) ===")
	DisplayServer.window_set_size(DESKTOP_SIZE)
	await process_frame
	await process_frame
	
	await _capture_scene("res://scenes/ui/main_menu.tscn", "main_menu_desktop")
	await _capture_scene("res://scenes/ui/world_map.tscn", "world_map_desktop")
	await _capture_scene("res://scenes/ui/skin_select.tscn", "skin_select_desktop")
	await _capture_scene("res://scenes/ui/options_overlay.tscn", "options_desktop")
	await _capture_scene("res://scenes/ui/pause_overlay.tscn", "pause_desktop")
	await _capture_scene("res://scenes/ui/level_complete.tscn", "level_complete_plain_desktop")
	await _capture_level_complete("level_complete_desktop")
	await _capture_level_complete_perfect("level_complete_perfect_desktop")
	await _capture_level_complete_overlay("level_complete_overlay_desktop")
	await _capture_gameplay("gameplay_hud_desktop")
	
	print("=== UI Snapshot Capture Complete ===")
	quit(0)


func _capture_scene(scene_path: String, output_name: String) -> void:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("Failed to load scene: " + scene_path)
		return
	var instance: Node = scene.instantiate()
	root.add_child(instance)
	
	# Wait for scene to initialize and settle
	var settle_frames: int = 3
	if scene_path == "res://scenes/ui/world_map.tscn":
		settle_frames = 35 # World map needs more time to populate level cards
	
	for i: int in range(settle_frames):
		await process_frame
	
	_save_viewport(output_name)
	instance.queue_free()
	await process_frame


func _capture_gameplay(output_name: String) -> void:
	# Load a simple level for HUD display
	var level_data: Resource = load("res://data/levels/world1/w1_l1.tres")
	if level_data == null:
		push_error("Failed to load level data for gameplay capture")
		return
	
	var scene: PackedScene = load("res://scenes/gameplay/gameplay.tscn")
	if scene == null:
		push_error("Failed to load gameplay scene")
		return
	
	var gameplay: Node = scene.instantiate()
	if gameplay.has_method("receive_scene_params"):
		gameplay.receive_scene_params({"level_data": level_data})
	
	root.add_child(gameplay)
	
	# Wait for gameplay to initialize
	for i: int in range(10):
		await process_frame
	
	_save_viewport(output_name)
	gameplay.queue_free()
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
	# Wait for animations to settle
	for i: int in range(20):
		await process_frame
	_save_viewport(output_name)
	screen.queue_free()
	await process_frame

func _capture_level_complete_perfect(output_name: String) -> void:
	var scene: PackedScene = load("res://scenes/ui/level_complete.tscn")
	if scene == null:
		push_error("Failed to load level complete scene")
		return
	var screen: Node = scene.instantiate()
	if screen.has_method("receive_scene_params"):
		var level_data: Resource = load("res://data/levels/world1/w1_l1.tres")
		var next_level_data: Resource = load("res://data/levels/world1/w1_l2.tres")
		var perfect_moves: int = int(level_data.get("minimum_moves"))
		screen.receive_scene_params({
			"level_data": level_data,
			"stars": 3,
			"final_moves": perfect_moves,
			"prev_best_moves": perfect_moves + 1,
			"was_previously_completed": true,
			"next_level_data": next_level_data,
		})
	root.add_child(screen)
	await process_frame
	await process_frame
	if screen.has_method("populate_results"):
		screen.populate_results()
	# Wait for animations to settle
	for i: int in range(20):
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
	# Wait for overlay to show and settle
	for i: int in range(5):
		await process_frame
	_save_viewport(output_name)
	overlay.queue_free()
	await process_frame


func _save_viewport(output_name: String) -> void:
	var tex = root.get_texture()
	if tex == null:
		push_warning("Skipped screenshot '%s' (Viewport texture is null)" % output_name)
		return
	var image: Image = tex.get_image()
	if image == null or image.is_empty():
		push_warning("Skipped screenshot '%s' (Image is null or empty, typical in headless mode)" % output_name)
		return
		
	var absolute_path: String = ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, output_name])
	var error: Error = image.save_png(absolute_path)
	if error != OK:
		push_error("Failed to save screenshot '%s': %s" % [output_name, absolute_path])
		return
	print("✓ Saved %dx%d screenshot: %s" % [image.get_width(), image.get_height(), output_name])
