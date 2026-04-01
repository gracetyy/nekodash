## SceneManager — autoload singleton owning all screen-level navigation.
## Implements: design/gdd/scene-manager.md
## Task: S1-03 (stub)
##
## Maintains the current screen state, emits transition signals, and provides
## a parameter-handoff contract for incoming scenes. No other node should call
## get_tree().change_scene_to_file() directly.
##
## Usage:
##   SceneManager.go_to(SceneManager.Screen.WORLD_MAP)
##   SceneManager.go_to_level(level_data)
##   SceneManager.go_back()
##   SceneManager.get_current_screen()  # -> Screen enum value
extends Node


# —————————————————————————————————————————————
# Enums
# —————————————————————————————————————————————

## All named screens in NekoDash at MVP.
enum Screen {
	NONE = -1,
	MAIN_MENU = 0,
	WORLD_MAP = 1,
	GAMEPLAY = 2,
	LEVEL_COMPLETE = 3,
	SKIN_SELECT = 4,
	LOADING = 5,
}


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Maps Screen enum values to scene file paths (populated when scenes exist).
const SCREEN_PATHS: Dictionary = {
	Screen.MAIN_MENU: "res://scenes/ui/main_menu.tscn",
	Screen.WORLD_MAP: "res://scenes/ui/world_map.tscn",
	Screen.GAMEPLAY: "res://scenes/gameplay/gameplay.tscn",
	Screen.LEVEL_COMPLETE: "res://scenes/ui/level_complete.tscn",
	Screen.SKIN_SELECT: "res://scenes/ui/skin_select.tscn",
	Screen.LOADING: "res://scenes/ui/loading.tscn",
}


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Fired before scene swap begins. Duration is 0.0 at MVP.
signal transition_started(from_screen: Screen, to_screen: Screen)

## Fired after scene swap and param delivery complete.
signal transition_completed(to_screen: Screen)

## Fired when navigating to GAMEPLAY with a LevelData whose world_id differs.
signal world_changed(world_id: String)


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _current_screen: Screen = Screen.NONE
var _previous_screen: Screen = Screen.NONE
var _transitioning: bool = false


# —————————————————————————————————————————————
# Public API — Navigation
# —————————————————————————————————————————————

## The single public navigation method. Stub: tracks state and emits signals
## but does not actually swap scenes.
func go_to(screen: Screen, params: Dictionary = {}) -> void:
	if _transitioning:
		push_warning("SceneManager.go_to(): transition already in progress; call dropped.")
		return

	_transitioning = true
	var from: Screen = _current_screen

	transition_started.emit(from, screen)

	_previous_screen = from
	_current_screen = screen

	push_warning("SceneManager.go_to(%s): stub — scene swap not implemented." % Screen.keys()[Screen.values().find(screen)])

	# Emit world_changed when navigating to GAMEPLAY with level data.
	if screen == Screen.GAMEPLAY and params.has("level_data"):
		var level_data: Resource = params["level_data"]
		if level_data and "world_id" in level_data:
			world_changed.emit(str(level_data.world_id))

	_transitioning = false
	transition_completed.emit(screen)


## Convenience wrapper for navigating to GAMEPLAY with a LevelData resource.
func go_to_level(level_data: Resource) -> void:
	go_to(Screen.GAMEPLAY, {"level_data": level_data})


## Navigates to _previous_screen with no params. No-op if no previous screen.
func go_back() -> void:
	if _previous_screen == Screen.NONE:
		push_warning("SceneManager.go_back(): no previous screen set; ignoring.")
		return
	go_to(_previous_screen)


## Alias used by sprint acceptance criteria.
func change_scene(screen: Screen, params: Dictionary = {}) -> void:
	go_to(screen, params)


# —————————————————————————————————————————————
# Public API — Screen Queries
# —————————————————————————————————————————————

## Returns the current screen enum value.
func get_current_screen() -> Screen:
	return _current_screen


## Returns the previous screen enum value.
func get_previous_screen() -> Screen:
	return _previous_screen


## Returns true if a transition is currently in progress.
func is_transitioning() -> bool:
	return _transitioning
