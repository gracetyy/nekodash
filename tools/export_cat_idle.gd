extends SceneTree

## Tool to export the cat idle breathing animation as a PNG sequence with transparency.
##
## Usage:
## godot_console.exe --headless --write-movie export/cat_idle/frame.png --fixed-fps 60 --quit-after 132 --script tools/export_cat_idle.gd

func _initialize() -> void:
	# Enable transparency
	root.transparent_bg = true
	
	# Set a square resolution for the export
	var export_size := 512
	DisplayServer.window_set_size(Vector2i(export_size, export_size))
	
	# Create a container to center the cat
	var container := CenterContainer.new()
	container.custom_minimum_size = Vector2(export_size, export_size)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(container)
	
	# Instance the CatRig
	var cat_rig_scene: PackedScene = load("res://scenes/ui/components/cat_rig.tscn")
	if cat_rig_scene == null:
		push_error("FAILED: Could not load res://scenes/ui/components/cat_rig.tscn")
		quit(1)
		return
		
	var cat_rig = cat_rig_scene.instantiate()
	cat_rig.name = "CatRig"
	
	# Configure the cat
	cat_rig.display_size_px = 320.0 # Fit well within 512px
	cat_rig.idle_enabled = true
	
	# Force a specific skin if requested via CLI or just use default
	# cat_rig.skin_id_override = "cat_default"
	
	container.add_child(cat_rig)
	
	# In Godot 4, for MovieWriter to work correctly with transparency,
	# we sometimes need to ensure the Clear Color has 0 alpha.
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))

	print("--- Cat Idle Export Started ---")
	print("Target: 132 frames (2.2s @ 60fps)")
	print("Resolution: %dx%d" % [export_size, export_size])
	print("Skin: %s" % (cat_rig.skin_id_override if not cat_rig.skin_id_override.is_empty() else "default"))
	
	# MovieWriter will handle the quitting via --quit-after
