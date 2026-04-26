extends SceneTree

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(540, 940))
	var scene = load("res://scenes/gameplay/gameplay.tscn").instantiate()
	root.add_child(scene)
	
	# Load level 1
	var l1 = load("res://data/levels/world1/w1_l1.tres")
	scene.receive_scene_params({"level_data": l1})
	
	for i in range(60):
		await process_frame
		
	var image: Image = root.get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png("c:/Users/Grace/Dev/nekodash/tutorial_test.png")
		print("Screenshot saved to c:/Users/Grace/Dev/nekodash/tutorial_test.png")
	else:
		print("Failed to capture image")
		
	quit(0)
