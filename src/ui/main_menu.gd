## MainMenu — title screen with navigation to World Map.
## Task: S3-04 (bug fix — back button target)
##
## Simple title screen that lets the player start the game by navigating
## to the World Map. Acts as the landing screen and the back-button target
## from WorldMap.
class_name MainMenu
extends Control


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when the play button is pressed.
signal play_requested


# —————————————————————————————————————————————
# Child node references
# —————————————————————————————————————————————

var _play_btn: BaseButton


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_auto_discover_ui_nodes()
	_connect_signals()


# —————————————————————————————————————————————
# Private methods
# —————————————————————————————————————————————

func _auto_discover_ui_nodes() -> void:
	_play_btn = _find_child_safe("PlayBtn", "BaseButton") as BaseButton


func _find_child_safe(child_name: String, expected_type: String) -> Node:
	var node: Node = find_child(child_name, true, false)
	if node == null:
		push_warning("MainMenu: expected child '%s' (%s) not found." % [child_name, expected_type])
	return node


func _connect_signals() -> void:
	if _play_btn != null:
		_play_btn.pressed.connect(_on_play_btn_pressed)


func _on_play_btn_pressed() -> void:
	play_requested.emit()
	_navigate_to_world_map()


func _navigate_to_world_map() -> void:
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP)
