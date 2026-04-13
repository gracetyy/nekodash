## Integration tests for the Credits screen shell route.
extends GutTest

var _credits: Node


func before_each() -> void:
	_credits = load("res://scenes/ui/credits.tscn").instantiate()
	add_child_autofree(_credits)


func test_back_button_navigates_to_main_menu() -> void:
	var back_btn: Button = _credits.find_child("BackBtn", true, false) as Button
	back_btn.pressed.emit()
	assert_eq(SceneManager.get_current_screen(), SceneManager.Screen.MAIN_MENU)
