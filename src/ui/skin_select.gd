## SkinSelect — placeholder skin selection screen.
## Navigates back to Main Menu via SceneManager.go_back().
class_name SkinSelect
extends Control


func _ready() -> void:
	var back_btn: BaseButton = find_child("BackBtn", true, false) as BaseButton
	if back_btn != null:
		back_btn.pressed.connect(_on_back_btn_pressed)


func _on_back_btn_pressed() -> void:
	SceneManager.go_back()
