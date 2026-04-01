## Unit tests for SceneManager autoload stub.
## Task: S1-03
## Covers: screen tracking, go_to, go_back, transition guard, signals, change_scene alias.
extends GutTest

var _scene_mgr: Node


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_scene_mgr = load("res://src/core/scene_manager.gd").new()
	add_child_autofree(_scene_mgr)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Shorthand for Screen enum access.
var Screen: Dictionary:
	get:
		return _scene_mgr.Screen


# —————————————————————————————————————————————
# Default State
# —————————————————————————————————————————————

func test_initial_screen_is_none() -> void:
	assert_eq(_scene_mgr.get_current_screen(), -1) # Screen.NONE


func test_initial_previous_screen_is_none() -> void:
	assert_eq(_scene_mgr.get_previous_screen(), -1) # Screen.NONE


func test_not_transitioning_initially() -> void:
	assert_false(_scene_mgr.is_transitioning())


# —————————————————————————————————————————————
# go_to — Screen Tracking
# —————————————————————————————————————————————

func test_go_to_updates_current_screen() -> void:
	_scene_mgr.go_to(_scene_mgr.Screen.MAIN_MENU)
	assert_eq(_scene_mgr.get_current_screen(), _scene_mgr.Screen.MAIN_MENU)


func test_go_to_updates_previous_screen() -> void:
	_scene_mgr.go_to(_scene_mgr.Screen.MAIN_MENU)
	_scene_mgr.go_to(_scene_mgr.Screen.WORLD_MAP)
	assert_eq(_scene_mgr.get_previous_screen(), _scene_mgr.Screen.MAIN_MENU)


func test_go_to_sequential_navigation() -> void:
	_scene_mgr.go_to(_scene_mgr.Screen.MAIN_MENU)
	_scene_mgr.go_to(_scene_mgr.Screen.WORLD_MAP)
	_scene_mgr.go_to(_scene_mgr.Screen.GAMEPLAY)
	assert_eq(_scene_mgr.get_current_screen(), _scene_mgr.Screen.GAMEPLAY)
	assert_eq(_scene_mgr.get_previous_screen(), _scene_mgr.Screen.WORLD_MAP)


# —————————————————————————————————————————————
# go_to — Signals
# —————————————————————————————————————————————

func test_go_to_emits_transition_started() -> void:
	watch_signals(_scene_mgr)
	_scene_mgr.go_to(_scene_mgr.Screen.MAIN_MENU)
	assert_signal_emitted(_scene_mgr, "transition_started")


func test_go_to_emits_transition_completed() -> void:
	watch_signals(_scene_mgr)
	_scene_mgr.go_to(_scene_mgr.Screen.MAIN_MENU)
	assert_signal_emitted(_scene_mgr, "transition_completed")


func test_go_to_transition_started_params() -> void:
	_scene_mgr.go_to(_scene_mgr.Screen.MAIN_MENU)
	watch_signals(_scene_mgr)
	_scene_mgr.go_to(_scene_mgr.Screen.WORLD_MAP)
	var params: Array = get_signal_parameters(_scene_mgr, "transition_started")
	assert_eq(params[0], _scene_mgr.Screen.MAIN_MENU, "from_screen should be MAIN_MENU")
	assert_eq(params[1], _scene_mgr.Screen.WORLD_MAP, "to_screen should be WORLD_MAP")


# —————————————————————————————————————————————
# go_back
# —————————————————————————————————————————————

func test_go_back_returns_to_previous_screen() -> void:
	_scene_mgr.go_to(_scene_mgr.Screen.MAIN_MENU)
	_scene_mgr.go_to(_scene_mgr.Screen.WORLD_MAP)
	_scene_mgr.go_back()
	assert_eq(_scene_mgr.get_current_screen(), _scene_mgr.Screen.MAIN_MENU)


func test_go_back_noop_when_no_previous() -> void:
	watch_signals(_scene_mgr)
	_scene_mgr.go_back()
	assert_signal_not_emitted(_scene_mgr, "transition_started")
	assert_eq(_scene_mgr.get_current_screen(), _scene_mgr.Screen.NONE)


# —————————————————————————————————————————————
# go_to_level
# —————————————————————————————————————————————

func test_go_to_level_navigates_to_gameplay() -> void:
	var fake_level: Resource = Resource.new()
	_scene_mgr.go_to_level(fake_level)
	assert_eq(_scene_mgr.get_current_screen(), _scene_mgr.Screen.GAMEPLAY)


# —————————————————————————————————————————————
# change_scene alias
# —————————————————————————————————————————————

func test_change_scene_works_as_alias() -> void:
	_scene_mgr.change_scene(_scene_mgr.Screen.SKIN_SELECT)
	assert_eq(_scene_mgr.get_current_screen(), _scene_mgr.Screen.SKIN_SELECT)


# —————————————————————————————————————————————
# Not transitioning after go_to completes (stub is synchronous)
# —————————————————————————————————————————————

func test_not_transitioning_after_go_to() -> void:
	_scene_mgr.go_to(_scene_mgr.Screen.MAIN_MENU)
	assert_false(_scene_mgr.is_transitioning())
