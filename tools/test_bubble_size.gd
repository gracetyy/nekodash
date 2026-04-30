extends SceneTree

const TutorialBubbleScene = preload("res://scenes/ui/components/tutorial/TutorialBubble.tscn")

func _initialize() -> void:
	var bubble = TutorialBubbleScene.instantiate() as Control
	root.add_child(bubble)
	bubble.custom_minimum_size.x = 220
	bubble.size.x = 220
	if bubble.has_method("apply_text"):
		bubble.apply_text("Press D to move the cat!")
	
	# Force layout update
	bubble.reset_size()
	var b_size = bubble.get_combined_minimum_size()
	print("Calculated size: ", b_size)
	print("Bubble actual size: ", bubble.size)
	
	quit()
