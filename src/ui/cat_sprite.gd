@tool
## CatSprite — gameplay-specialized cat part rig.
##
## Uses CatPartRig for shared part assembly, then adds directional head tilt
## hooks from the SlidingMovement parent node.
extends "res://src/ui/cat_part_rig.gd"


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

@export_category("Slide Head Tilt")
## Max head tilt applied during horizontal slides.
@export_range(0.0, 30.0, 0.1, "or_greater")
var head_slide_tilt_degrees: float = 6.0

## Time to lean the head into the slide direction.
@export_range(0.0, 1.0, 0.01, "or_greater")
var head_tilt_in_sec: float = 0.08

## Time to return head tilt back to neutral.
@export_range(0.0, 1.0, 0.01, "or_greater")
var head_tilt_out_sec: float = 0.12


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_connect_parent_slide_signals()


func _exit_tree() -> void:
	_disconnect_parent_slide_signals()


# —————————————————————————————————————————————
# Parent slide hooks
# —————————————————————————————————————————————

func _connect_parent_slide_signals() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var on_started: Callable = Callable(self , "_on_parent_slide_started")
	if parent_node.has_signal("slide_started") and not parent_node.is_connected("slide_started", on_started):
		parent_node.connect("slide_started", on_started)

	var on_completed: Callable = Callable(self , "_on_parent_slide_completed")
	if parent_node.has_signal("slide_completed") and not parent_node.is_connected("slide_completed", on_completed):
		parent_node.connect("slide_completed", on_completed)

	var on_blocked: Callable = Callable(self , "_on_parent_slide_blocked")
	if parent_node.has_signal("slide_blocked") and not parent_node.is_connected("slide_blocked", on_blocked):
		parent_node.connect("slide_blocked", on_blocked)


func _disconnect_parent_slide_signals() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var on_started: Callable = Callable(self , "_on_parent_slide_started")
	if parent_node.has_signal("slide_started") and parent_node.is_connected("slide_started", on_started):
		parent_node.disconnect("slide_started", on_started)

	var on_completed: Callable = Callable(self , "_on_parent_slide_completed")
	if parent_node.has_signal("slide_completed") and parent_node.is_connected("slide_completed", on_completed):
		parent_node.disconnect("slide_completed", on_completed)

	var on_blocked: Callable = Callable(self , "_on_parent_slide_blocked")
	if parent_node.has_signal("slide_blocked") and parent_node.is_connected("slide_blocked", on_blocked):
		parent_node.disconnect("slide_blocked", on_blocked)


func _on_parent_slide_started(_from: Vector2i, _to: Vector2i, direction: Vector2i) -> void:
	if _is_reduce_motion_enabled():
		set_head_tilt_immediate(0.0)
		return

	if direction.x == 0:
		tween_head_tilt(0.0, head_tilt_in_sec)
		return

	var target_deg: float = float(direction.x) * head_slide_tilt_degrees
	tween_head_tilt(target_deg, head_tilt_in_sec)


func _on_parent_slide_completed(_from: Vector2i, _to: Vector2i, _direction: Vector2i, _tiles: Array[Vector2i]) -> void:
	tween_head_tilt(0.0, head_tilt_out_sec)


func _on_parent_slide_blocked(_pos: Vector2i, _direction: Vector2i) -> void:
	tween_head_tilt(0.0, head_tilt_out_sec)
