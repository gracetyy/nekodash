## Unit tests for SceneManager shell navigation additions.
## Covers: new screen enums, loading route, and overlay state/signals.
extends GutTest

var _scene_mgr: Node


func before_each() -> void:
	_scene_mgr = load("res://src/core/scene_manager.gd").new()
	add_child_autofree(_scene_mgr)


func test_screen_enum_has_opening() -> void:
	assert_true("OPENING" in _scene_mgr.Screen)


func test_screen_enum_has_credits() -> void:
	assert_true("CREDITS" in _scene_mgr.Screen)


func test_overlay_enum_has_pause_and_options() -> void:
	assert_true("PAUSE" in _scene_mgr.Overlay)
	assert_true("OPTIONS" in _scene_mgr.Overlay)


func test_no_active_overlay_by_default() -> void:
	assert_eq(_scene_mgr.get_active_overlay(), _scene_mgr.Overlay.NONE)
	assert_false(_scene_mgr.has_active_overlay())


func test_show_overlay_updates_state() -> void:
	_scene_mgr.show_overlay(_scene_mgr.Overlay.OPTIONS)
	assert_true(_scene_mgr.has_active_overlay())
	assert_eq(_scene_mgr.get_active_overlay(), _scene_mgr.Overlay.OPTIONS)


func test_show_overlay_emits_signal() -> void:
	watch_signals(_scene_mgr)
	_scene_mgr.show_overlay(_scene_mgr.Overlay.PAUSE)
	assert_signal_emitted_with_parameters(
		_scene_mgr,
		"overlay_opened",
		[_scene_mgr.Overlay.PAUSE]
	)


func test_hide_overlay_resets_state() -> void:
	_scene_mgr.show_overlay(_scene_mgr.Overlay.OPTIONS)
	_scene_mgr.hide_overlay()
	assert_false(_scene_mgr.has_active_overlay())
	assert_eq(_scene_mgr.get_active_overlay(), _scene_mgr.Overlay.NONE)


func test_hide_overlay_emits_signal() -> void:
	_scene_mgr.show_overlay(_scene_mgr.Overlay.PAUSE)
	watch_signals(_scene_mgr)
	_scene_mgr.hide_overlay()
	assert_signal_emitted_with_parameters(
		_scene_mgr,
		"overlay_closed",
		[_scene_mgr.Overlay.PAUSE]
	)


func test_go_to_with_loading_swaps_through_loading_scene() -> void:
	_scene_mgr.go_to_with_loading(_scene_mgr.Screen.MAIN_MENU)
	assert_eq(get_tree().current_scene.scene_file_path, "res://scenes/ui/loading.tscn")
	await get_tree().process_frame
	assert_eq(get_tree().current_scene.scene_file_path, "res://scenes/ui/main_menu.tscn")
