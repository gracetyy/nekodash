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


func test_menu_cat_is_centered_after_layout_settles() -> void:
	var cat_illustration: TextureRect = _menu.find_child("CatIllustration", true, false) as TextureRect
	var menu_cat_rig: Node2D = _menu.find_child("MenuCatRig", true, false) as Node2D
	assert_not_null(cat_illustration)
	assert_not_null(menu_cat_rig)

	await get_tree().process_frame
	await get_tree().process_frame

	var expected_x: float = cat_illustration.size.x * 0.5
	var expected_y: float = cat_illustration.size.y * _menu.menu_cat_vertical_anchor_ratio
	assert_almost_eq(menu_cat_rig.position.x, expected_x, 0.5)
	assert_almost_eq(menu_cat_rig.position.y, expected_y, 0.5)
