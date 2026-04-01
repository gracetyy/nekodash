## InputSystem — autoload that translates touch/keyboard input into cardinal
## direction signals for the Sliding Movement system.
## Implements: design/gdd/input-system.md
## Task: S1-02
##
## The Input System is the single contact point between player gestures and
## game logic. It detects swipe direction on mobile and WASD/arrow keys on
## desktop, then emits a direction_input signal. It never modifies game state.
##
## Usage:
##   InputSystem.direction_input.connect(_on_direction_input)
##   InputSystem.set_accepting_input(true)
##   InputSystem.set_accepting_input(false)
extends Node


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when a valid swipe or keypress resolves to a cardinal direction.
## direction is one of: Vector2i(0,-1), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0).
signal direction_input(direction: Vector2i)


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Cardinal direction vectors for readability.
const DIR_UP := Vector2i(0, -1)
const DIR_DOWN := Vector2i(0, 1)
const DIR_LEFT := Vector2i(-1, 0)
const DIR_RIGHT := Vector2i(1, 0)


# —————————————————————————————————————————————
# Tuning knobs (exported for editor tuning)
# —————————————————————————————————————————————

## Minimum drag distance in pixels for a swipe to register.
@export var min_swipe_distance_px: float = 40.0

## Maximum swipe duration in milliseconds. Slower drags are rejected.
@export var max_swipe_duration_ms: float = 400.0

## Minimum key-hold duration in ms before a key event fires direction_input.
## Prevents key-bounce from double-firing on a single physical press.
@export var min_key_hold_ms: float = 25.0


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

## When false, all input is silently discarded. Controlled externally by
## Sliding Movement and Scene Manager.
var _accepting_input: bool = true

## Touch tracking — first finger only (multi-touch guard).
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_time_ms: float = 0.0
var _is_touching: bool = false
var _active_touch_index: int = -1

## Keyboard tracking — tracks press time per key for min_key_hold_ms.
var _key_press_times: Dictionary = {} # Dictionary[int, float]


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Sets whether the Input System accepts and processes input.
## Called by Sliding Movement (false during slide, true on completion)
## and Scene Manager (false during non-PLAYING states).
##
## Usage:
##   InputSystem.set_accepting_input(false)
func set_accepting_input(value: bool) -> void:
	_accepting_input = value


## Returns whether the Input System is currently accepting input.
##
## Usage:
##   if InputSystem.is_accepting_input():
func is_accepting_input() -> bool:
	return _accepting_input


# —————————————————————————————————————————————
# Input processing
# —————————————————————————————————————————————

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventKey:
		_handle_key(event)


# —————————————————————————————————————————————
# Touch (mobile swipe)
# —————————————————————————————————————————————

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only track the first finger; ignore additional touches.
		if _is_touching:
			return
		_touch_start_pos = event.position
		_touch_start_time_ms = Time.get_ticks_msec()
		_is_touching = true
		_active_touch_index = event.index
	else:
		# Release — only process if it's the tracked finger.
		if not _is_touching or event.index != _active_touch_index:
			return
		_evaluate_swipe(event.position)
		_is_touching = false
		_active_touch_index = -1


func _evaluate_swipe(end_pos: Vector2) -> void:
	if not _accepting_input:
		return

	var delta: Vector2 = end_pos - _touch_start_pos
	var distance: float = delta.length()
	var duration_ms: float = Time.get_ticks_msec() - _touch_start_time_ms

	# Reject short gestures (taps, micro-drags).
	if distance < min_swipe_distance_px:
		return

	# Reject slow drags (scrolls, holds).
	if duration_ms > max_swipe_duration_ms:
		return

	# Guard against zero-length delta (degenerate case).
	if is_zero_approx(delta.x) and is_zero_approx(delta.y):
		return

	# Resolve cardinal direction — vertical wins on tie (GDD edge case).
	var dir: Vector2i
	if absf(delta.x) > absf(delta.y):
		dir = DIR_RIGHT if delta.x > 0.0 else DIR_LEFT
	else:
		dir = DIR_DOWN if delta.y > 0.0 else DIR_UP

	direction_input.emit(dir)


# —————————————————————————————————————————————
# Keyboard (WASD + arrows)
# —————————————————————————————————————————————

func _handle_key(event: InputEventKey) -> void:
	if event.pressed:
		# Record press time (only on initial press, not echo/repeat).
		if not event.is_echo():
			_key_press_times[event.keycode] = Time.get_ticks_msec()
		else:
			# Key repeat — treat like a fresh valid press if accepting input.
			_try_emit_key_direction(event.keycode)
	else:
		# Key released — check hold duration and emit.
		_try_emit_key_direction(event.keycode)
		_key_press_times.erase(event.keycode)


func _try_emit_key_direction(keycode: int) -> void:
	if not _accepting_input:
		return

	# Check min hold duration (only on release, not on repeat).
	if _key_press_times.has(keycode):
		var held_ms: float = Time.get_ticks_msec() - _key_press_times[keycode]
		if held_ms < min_key_hold_ms:
			return

	var dir: Vector2i = _keycode_to_direction(keycode)
	if dir != Vector2i.ZERO:
		direction_input.emit(dir)


func _keycode_to_direction(keycode: int) -> Vector2i:
	match keycode:
		KEY_W, KEY_UP:
			return DIR_UP
		KEY_S, KEY_DOWN:
			return DIR_DOWN
		KEY_A, KEY_LEFT:
			return DIR_LEFT
		KEY_D, KEY_RIGHT:
			return DIR_RIGHT
		_:
			return Vector2i.ZERO
