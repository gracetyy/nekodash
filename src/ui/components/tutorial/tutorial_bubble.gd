class_name TutorialBubble
extends Panel

signal close_pressed

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

@export_multiline var bubble_text: String = "Swipe to slide!"

@onready var _label: Label = $Label


func _ready() -> void:
	var style = ShellThemeUtil.make_rounded_style(Color.WHITE, ShellThemeUtil.PLUM, 20, 4)
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
	add_theme_stylebox_override("panel", style)
	
	if _label != null:
		ShellThemeUtil.apply_body(_label, ShellThemeUtil.PLUM, 16)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if _label.text == "" or _label.text == "Swipe to slide!":
			apply_text(bubble_text)


func apply_text(text_val: String) -> void:
	bubble_text = text_val
	if _label == null:
		return
		
	_label.text = text_val
	
	var content_width = 180.0
	var font = _label.get_theme_font("font")
	var font_size = _label.get_theme_font_size("font_size")
	
	if font == null:
		font = ThemeDB.fallback_font
	if font_size <= 0:
		font_size = 16
		
	var text_size = font.get_multiline_string_size(text_val, HORIZONTAL_ALIGNMENT_CENTER, content_width, font_size)
	
	var required_height = text_size.y + 32.0
	
	custom_minimum_size = Vector2(220.0, required_height)
	size = Vector2(220.0, required_height)
	
	_label.position = Vector2(20, 16)
	_label.size = Vector2(content_width, text_size.y)


func add_close_button() -> void:
	var close_btn = TextureButton.new()
	
	# Load specific assets
	var tex_normal = load("res://assets/art/ui/buttons/circular/btn_circle_close_normal.png")
	var tex_hover = load("res://assets/art/ui/buttons/circular/btn_circle_close_hover.png")
	var tex_pressed = load("res://assets/art/ui/buttons/circular/btn_circle_close_pressed.png")
	
	close_btn.texture_normal = tex_normal
	close_btn.texture_hover = tex_hover
	close_btn.texture_pressed = tex_pressed
	
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.size = Vector2(32, 32)
	
	# Position at top right
	close_btn.position = Vector2(size.x - 24, -12)
	
	add_child(close_btn)
	close_btn.pressed.connect(_on_close_btn_pressed)


func _on_close_btn_pressed() -> void:
	close_pressed.emit()
