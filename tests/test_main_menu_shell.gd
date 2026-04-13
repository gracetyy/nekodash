## Integration tests for the upgraded shell MainMenu.
## Covers: options overlay access and credits navigation.
extends GutTest

var _menu: MainMenu


func before_each() -> void:
	SceneManager.hide_overlay()
	get_tree().paused = false
	_menu = load("res://scenes/ui/main_menu.tscn").instantiate() as MainMenu
	add_child_autofree(_menu)


func after_each() -> void:
	SceneManager.hide_overlay()
	get_tree().paused = false


func test_main_menu_has_options_button() -> void:
	assert_not_null(_menu.find_child("OptionsBtn", true, false))


func test_main_menu_has_credits_button() -> void:
	assert_not_null(_menu.find_child("CreditsBtn", true, false))


func test_options_button_opens_options_overlay() -> void:
	var options_btn: Button = _menu.find_child("OptionsBtn", true, false) as Button
	options_btn.pressed.emit()
	assert_eq(SceneManager.get_active_overlay(), SceneManager.Overlay.OPTIONS)


func test_credits_button_navigates_to_credits() -> void:
	var credits_btn: Button = _menu.find_child("CreditsBtn", true, false) as Button
	credits_btn.pressed.emit()
	assert_eq(SceneManager.get_current_screen(), SceneManager.Screen.CREDITS)
