extends SceneTree

func _init():
	var font = load("res://assets/fonts/Fredoka-Variable.ttf")
	var size = font.get_string_size("Cat slides continuously until it hits an obstacle or wall.", 0, 167, 16)
	var multi = font.get_multiline_string_size("Cat slides continuously until it hits an obstacle or wall.", 0, 167, 16)
	print("STRING_SIZE: ", size)
	print("MULTI_SIZE: ", multi)
	
	# Try using Label get_line_count
	var label = Label.new()
	label.text = "Cat slides continuously until it hits an obstacle or wall."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 167
	label.size.x = 167
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 16)
	
	var height = label.get_minimum_size().y
	print("LABEL_MIN_Y: ", height)
	
	quit()
