## OpeningScreen — first-run shell entry that hands off to Main Menu.
extends Control

@export var _continue_btn: BaseButton
@export var _prompt_label: Label


func _ready() -> void:
	if _continue_btn == null:
		_continue_btn = get_node_or_null("MarginContainer/HeroCard/CardMargin/CardBody/ContinueBtn")
	if _prompt_label == null:
		_prompt_label = get_node_or_null("MarginContainer/HeroCard/CardMargin/CardBody/Prompt")
	assert(_continue_btn != null, "_continue_btn not assigned")
	assert(_prompt_label != null, "_prompt_label not assigned")
	_refresh_prompt()
	if not _continue_btn.pressed.is_connected(_on_continue_btn_pressed):
		_continue_btn.pressed.connect(_on_continue_btn_pressed)
	_continue_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_go_to_main_menu()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_go_to_main_menu()
	elif event is InputEventScreenTouch and event.pressed:
		_go_to_main_menu()


func _on_continue_btn_pressed() -> void:
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)


func _refresh_prompt() -> void:
	if _prompt_label == null:
		return
	match AppSettings.get_effective_input_hint_mode():
		AppSettings.INPUT_HINT_TOUCH:
			_prompt_label.text = "Tap anywhere or use CONTINUE to enter the house."
		_:
			_prompt_label.text = "Press Enter or click CONTINUE to enter the house."
