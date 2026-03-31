# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does slide-until-wall movement feel satisfying on mobile touch input?
# Date: 2026-03-31
#
# Input handler: swipe detection (mobile) + keyboard (desktop).
# Emits direction to cat controller. Reads is_accepting_input from cat state.

extends Node

const MIN_SWIPE_DISTANCE_PX: float = 40.0
const MAX_SWIPE_DURATION_MS: float = 500.0

var _cat: Node2D # proto_cat.gd
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_time: float = 0.0
var _is_touching: bool = false
var _touch_index: int = -1

# Stats
var _swipe_count: int = 0
var _key_count: int = 0
var _rejected_swipes: int = 0


func _ready() -> void:
	_cat = get_parent().get_node("ProtoCat")


func _unhandled_input(event: InputEvent) -> void:
	# Keyboard input
	if event is InputEventKey and event.pressed and not event.echo:
		var dir: Vector2i = Vector2i.ZERO
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			dir = Vector2i(0, -1)
		elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
			dir = Vector2i(0, 1)
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			dir = Vector2i(-1, 0)
		elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			dir = Vector2i(1, 0)
		elif event.keycode == KEY_R:
			# Restart
			_cat.initialize(Vector2i(1, 1))
			print("[Proto] Restarted! Press R to restart anytime.")
			return

		if dir != Vector2i.ZERO:
			_key_count += 1
			_cat.try_slide(dir)

	# Touch input — start
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_pos = event.position
			_touch_start_time = Time.get_ticks_msec()
			_is_touching = true
			_touch_index = event.index
		elif not event.pressed and _is_touching and event.index == _touch_index:
			# Touch released — evaluate swipe
			_evaluate_swipe(event.position)
			_is_touching = false
			_touch_index = -1


func _evaluate_swipe(end_pos: Vector2) -> void:
	var delta: Vector2 = end_pos - _touch_start_pos
	var distance: float = delta.length()
	var duration_ms: float = Time.get_ticks_msec() - _touch_start_time

	if distance < MIN_SWIPE_DISTANCE_PX:
		_rejected_swipes += 1
		print("[Proto] Swipe rejected: too short (", snapped(distance, 0.1), "px < ", MIN_SWIPE_DISTANCE_PX, "px)")
		return

	if duration_ms > MAX_SWIPE_DURATION_MS:
		_rejected_swipes += 1
		print("[Proto] Swipe rejected: too slow (", snapped(duration_ms, 1), "ms > ", MAX_SWIPE_DURATION_MS, "ms)")
		return

	# Resolve cardinal direction
	var dir: Vector2i
	if absf(delta.x) > absf(delta.y):
		dir = Vector2i(1, 0) if delta.x > 0 else Vector2i(-1, 0)
	else:
		dir = Vector2i(0, 1) if delta.y > 0 else Vector2i(0, -1)

	_swipe_count += 1
	print("[Proto] Swipe: ", dir, " (", snapped(distance, 0.1), "px, ", snapped(duration_ms, 1), "ms)")
	_cat.try_slide(dir)
