## CreditsScreen — shell route listing project credits and returning to Main Menu.
extends Control

@export var _back_btn: BaseButton


func _ready() -> void:
	assert(_back_btn != null, "_back_btn not assigned")
	if not _back_btn.pressed.is_connected(_on_back_btn_pressed):
		_back_btn.pressed.connect(_on_back_btn_pressed)
	_back_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_to_main_menu()


func _on_back_btn_pressed() -> void:
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)
