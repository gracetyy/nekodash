@tool
## CatSprite — gameplay-specialized cat part rig.
##
## Uses CatPartRig for shared part assembly, then adds directional head tilt
## hooks from the SlidingMovement parent node.
extends "res://src/ui/cat_part_rig.gd"


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const HEAD_SLIDE_TILT_DEGREES: float = 6.0
const HEAD_TILT_IN_SEC: float = 0.08
const HEAD_TILT_OUT_SEC: float = 0.12


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	super._ready()
	_connect_parent_slide_signals()


func _exit_tree() -> void:
	_disconnect_parent_slide_signals()
	super._exit_tree()


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
		tween_head_tilt(0.0, HEAD_TILT_IN_SEC)
		return

	var target_deg: float = float(direction.x) * HEAD_SLIDE_TILT_DEGREES
	tween_head_tilt(target_deg, HEAD_TILT_IN_SEC)


func _on_parent_slide_completed(_from: Vector2i, _to: Vector2i, _direction: Vector2i, _tiles: Array[Vector2i]) -> void:
	tween_head_tilt(0.0, HEAD_TILT_OUT_SEC)


func _on_parent_slide_blocked(_pos: Vector2i, _direction: Vector2i) -> void:
	tween_head_tilt(0.0, HEAD_TILT_OUT_SEC)
