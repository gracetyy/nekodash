## Unit tests for PauseMenu shell overlay.
## Covers: button signaling and restart delegation to the active gameplay scene.
extends GutTest

var _menu: Node
var _gameplay_scene: MockGameplayScene


class MockGameplayScene extends Node:
	var restart_calls: int = 0

	func restart_level() -> void:
		restart_calls += 1


func before_each() -> void:
	SceneManager.hide_overlay()
	get_tree().paused = false

	_gameplay_scene = MockGameplayScene.new()
	get_tree().root.add_child(_gameplay_scene)
	get_tree().current_scene = _gameplay_scene

	_menu = load("res://scenes/ui/pause_overlay.tscn").instantiate()
	add_child_autofree(_menu)


func after_each() -> void:
	SceneManager.hide_overlay()
	get_tree().paused = false
	if get_tree().current_scene == _gameplay_scene:
		get_tree().current_scene = null
	if _gameplay_scene != null and is_instance_valid(_gameplay_scene):
		_gameplay_scene.queue_free()


func test_resume_button_emits_resume_requested() -> void:
	watch_signals(_menu)
	_menu.on_resume_btn_pressed()
	assert_signal_emitted(_menu, "resume_requested")


func test_restart_button_emits_restart_requested() -> void:
	watch_signals(_menu)
	_menu.on_restart_btn_pressed()
	assert_signal_emitted(_menu, "restart_requested")


func test_options_button_emits_options_requested() -> void:
	watch_signals(_menu)
	_menu.on_options_btn_pressed()
	assert_signal_emitted(_menu, "options_requested")


func test_main_menu_button_emits_main_menu_requested() -> void:
	watch_signals(_menu)
	_menu.on_main_menu_btn_pressed()
	assert_signal_emitted(_menu, "main_menu_requested")


func test_restart_requested_calls_restart_level_on_current_scene() -> void:
	_menu.on_restart_btn_pressed()
	assert_eq(_gameplay_scene.restart_calls, 1)
