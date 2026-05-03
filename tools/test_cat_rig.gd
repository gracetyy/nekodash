extends SceneTree

func _initialize() -> void:
	print("Instancing CatRig...")
	var cat_rig_scene: PackedScene = load("res://scenes/ui/components/cat_rig.tscn")
	var cat_rig = cat_rig_scene.instantiate()
	root.add_child(cat_rig)
	print("Success!")
	quit(0)
