## SceneManager — autoload singleton owning all screen-level navigation.
## Implements: design/gdd/scene-manager.md
## Task: S1-03
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
	OPENING = 6,
	CREDITS = 7,
}

enum Overlay {
	NONE = -1,
	OPTIONS = 0,
	PAUSE = 1,
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
	Screen.OPENING: "res://scenes/ui/opening.tscn",
	Screen.CREDITS: "res://scenes/ui/credits.tscn",
}

const OVERLAY_PATHS: Dictionary = {
	Overlay.OPTIONS: "res://scenes/ui/options_overlay.tscn",
	Overlay.PAUSE: "res://scenes/ui/pause_overlay.tscn",
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

## Fired when an overlay is displayed.
signal overlay_opened(overlay: Overlay)

## Fired when an overlay is closed.
signal overlay_closed(overlay: Overlay)


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _current_screen: Screen = Screen.NONE
var _previous_screen: Screen = Screen.NONE
var _transitioning: bool = false
var _pending_screen: Screen = Screen.NONE
var _pending_params: Dictionary = {}
var _active_overlay: Overlay = Overlay.NONE
var _overlay_instance: Node
var _overlay_paused_tree: bool = false


# —————————————————————————————————————————————
# Public API — Navigation
# —————————————————————————————————————————————

## The single public navigation method. Tracks state, emits signals, and
## swaps the active scene when a scene file exists for the target screen.
## Calls receive_scene_params() on the new scene root before _ready().
func go_to(screen: Screen, params: Dictionary = {}) -> void:
	if _transitioning:
		push_warning("SceneManager.go_to(): transition already in progress; call dropped.")
		return

	_begin_transition(screen)
	_swap_scene(screen, params)
	_finish_transition(screen, params)


## Navigates through the loading screen before swapping to the target screen.
func go_to_with_loading(screen: Screen, params: Dictionary = {}) -> void:
	if _transitioning:
		push_warning("SceneManager.go_to_with_loading(): transition already in progress; call dropped.")
		return

	_begin_transition(screen)
	_pending_screen = screen
	_pending_params = params.duplicate(true)
	var loading_params: Dictionary = {
		"target_screen_name": _screen_label(screen),
		"progress": 0.0,
	}
	var loading_swapped: bool = _swap_scene(Screen.LOADING, loading_params)
	if not loading_swapped:
		_finish_transition(screen, params)
		return
	call_deferred("_complete_loading_transition")


## Convenience wrapper for navigating to GAMEPLAY with a LevelData resource.
func go_to_level(level_data: Resource) -> void:
	go_to_with_loading(Screen.GAMEPLAY, {"level_data": level_data})


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


## Displays a shell overlay above the current scene without surrendering
## navigation ownership to the overlay itself.
func show_overlay(overlay: Overlay, params: Dictionary = {}) -> void:
	if overlay == Overlay.NONE:
		return

	var should_pause: bool = params.get("pause_tree", overlay == Overlay.PAUSE or _active_overlay == Overlay.PAUSE) as bool
	if _active_overlay != Overlay.NONE:
		_remove_overlay(false)

	if not OVERLAY_PATHS.has(overlay):
		push_warning("SceneManager.show_overlay(): Overlay %d has no OVERLAY_PATHS entry." % overlay)
		return

	var path: String = OVERLAY_PATHS[overlay]
	if not ResourceLoader.exists(path):
		push_warning("SceneManager.show_overlay(): no .tscn at '%s' for Overlay %d." % [path, overlay])
		return

	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("SceneManager.show_overlay(): failed to load overlay scene '%s'." % path)
		return

	var instance = packed.instantiate()
	_deliver_params(instance, params)
	if instance is Node:
		instance.process_mode = Node.PROCESS_MODE_ALWAYS

	var parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	parent.add_child(instance)

	_active_overlay = overlay
	_overlay_instance = instance
	_overlay_paused_tree = should_pause
	if should_pause:
		get_tree().paused = true

	overlay_opened.emit(overlay)


func hide_overlay() -> void:
	_remove_overlay(true)


func get_active_overlay() -> Overlay:
	return _active_overlay


func has_active_overlay() -> bool:
	return _active_overlay != Overlay.NONE


# —————————————————————————————————————————————
# Internal
# —————————————————————————————————————————————

## Calls receive_scene_params() on a scene root if it implements the method.
## Silently skips scenes that don't need params (SM-8).
func _deliver_params(scene_root: Node, params: Dictionary) -> void:
	if params.is_empty():
		return
	if scene_root.has_method("receive_scene_params"):
		scene_root.receive_scene_params(params)


func _begin_transition(screen: Screen) -> void:
	_transitioning = true
	var from: Screen = _current_screen
	transition_started.emit(from, screen)
	_previous_screen = from
	_current_screen = screen
	if has_active_overlay():
		_remove_overlay(true)


func _finish_transition(screen: Screen, params: Dictionary) -> void:
	if screen == Screen.GAMEPLAY and params.has("level_data"):
		var level_data: Resource = params["level_data"]
		if level_data and "world_id" in level_data:
			world_changed.emit(str(level_data.world_id))
	_transitioning = false
	transition_completed.emit(screen)


func _swap_scene(screen: Screen, params: Dictionary) -> bool:
	if not SCREEN_PATHS.has(screen):
		push_warning("SceneManager.go_to(): Screen %d has no SCREEN_PATHS entry." % screen)
		return false

	var path: String = SCREEN_PATHS[screen]
	if not ResourceLoader.exists(path):
		push_warning("SceneManager.go_to(): no .tscn at '%s' for Screen %d — stub route." % [path, screen])
		return false

	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("SceneManager.go_to(): failed to load '%s'." % path)
		return false

	var tree: SceneTree = get_tree()
	if tree == null:
		push_warning("SceneManager._swap_scene(): SceneTree unavailable during swap to %d." % screen)
		return false

	var new_root = packed.instantiate()
	_deliver_params(new_root, params)
	var old_scene: Node = tree.current_scene
	if old_scene != null:
		old_scene.queue_free()
	tree.root.add_child(new_root)
	tree.current_scene = new_root
	return true


func _complete_loading_transition() -> void:
	if get_tree() == null:
		return
	var target_screen: Screen = _pending_screen
	var target_params: Dictionary = _pending_params.duplicate(true)
	_pending_screen = Screen.NONE
	_pending_params = {}
	_swap_scene(target_screen, target_params)
	_finish_transition(target_screen, target_params)


func _screen_label(screen: Screen) -> String:
	for key: String in Screen.keys():
		if Screen[key] == screen:
			return key.capitalize()
	return "Loading"


func _remove_overlay(unpause_tree: bool) -> void:
	if _active_overlay == Overlay.NONE:
		return

	var closed_overlay: Overlay = _active_overlay
	if _overlay_instance != null and is_instance_valid(_overlay_instance):
		_overlay_instance.queue_free()
	_overlay_instance = null
	_active_overlay = Overlay.NONE

	if _overlay_paused_tree and unpause_tree:
		get_tree().paused = false
	_overlay_paused_tree = false

	overlay_closed.emit(closed_overlay)
