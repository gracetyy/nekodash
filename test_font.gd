extends SceneTree

func _init():
	var font = load("res://assets/fonts/Fredoka-Variable.ttf")
	var size = font.get_multiline_string_size("This is a visited tile.", 1, 167, 16)
	print("SIZE: ", size)
	quit()
