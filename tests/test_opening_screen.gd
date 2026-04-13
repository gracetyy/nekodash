## Integration tests for the Opening screen shell route.
extends GutTest

var _opening: Node


func before_each() -> void:
	_opening = load("res://scenes/ui/opening.tscn").instantiate()
	add_child_autofree(_opening)


func test_continue_button_navigates_to_main_menu() -> void:
	var continue_btn: Button = _opening.find_child("ContinueBtn", true, false) as Button
	continue_btn.pressed.emit()
	assert_eq(SceneManager.get_current_screen(), SceneManager.Screen.MAIN_MENU)
