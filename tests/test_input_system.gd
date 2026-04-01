## Unit tests for InputSystem autoload.
## Task: S1-02
## Covers: direction_input signal emission, swipe validation, keyboard mapping,
##         blocking, multi-touch guard, edge cases.
extends GutTest

var _input: Node
var _received_directions: Array[Vector2i] = []


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_input = load("res://src/core/input_system.gd").new()
	add_child_autofree(_input)
	_received_directions.clear()
	_input.direction_input.connect(_on_direction_input)


func _on_direction_input(dir: Vector2i) -> void:
	_received_directions.append(dir)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

## Simulates a touch press at pos with given finger index.
func _make_touch_press(pos: Vector2, index: int = 0) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	ev.position = pos
	ev.index = index
	return ev


## Simulates a touch release at pos with given finger index.
func _make_touch_release(pos: Vector2, index: int = 0) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.pressed = false
	ev.position = pos
	ev.index = index
	return ev


## Simulates a key press event.
func _make_key_press(keycode: int, echo: bool = false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = keycode
	ev.echo = echo
	return ev


## Simulates a key release event.
func _make_key_release(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.pressed = false
	ev.keycode = keycode
	return ev


# —————————————————————————————————————————————
# Tests: Keyboard — cardinal directions
# —————————————————————————————————————————————

func test_input_system_key_w_emits_up() -> void:
	# Arrange — press W, record time, then release
	_input._handle_key(_make_key_press(KEY_W))
	# Simulate enough hold time
	_input._key_press_times[KEY_W] = Time.get_ticks_msec() - 50.0

	# Act
	_input._handle_key(_make_key_release(KEY_W))

	# Assert
	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(0, -1))


func test_input_system_key_s_emits_down() -> void:
	_input._handle_key(_make_key_press(KEY_S))
	_input._key_press_times[KEY_S] = Time.get_ticks_msec() - 50.0
	_input._handle_key(_make_key_release(KEY_S))

	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(0, 1))


func test_input_system_key_a_emits_left() -> void:
	_input._handle_key(_make_key_press(KEY_A))
	_input._key_press_times[KEY_A] = Time.get_ticks_msec() - 50.0
	_input._handle_key(_make_key_release(KEY_A))

	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(-1, 0))


func test_input_system_key_d_emits_right() -> void:
	_input._handle_key(_make_key_press(KEY_D))
	_input._key_press_times[KEY_D] = Time.get_ticks_msec() - 50.0
	_input._handle_key(_make_key_release(KEY_D))

	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(1, 0))


func test_input_system_arrow_up_emits_up() -> void:
	_input._handle_key(_make_key_press(KEY_UP))
	_input._key_press_times[KEY_UP] = Time.get_ticks_msec() - 50.0
	_input._handle_key(_make_key_release(KEY_UP))

	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(0, -1))


func test_input_system_arrow_right_emits_right() -> void:
	_input._handle_key(_make_key_press(KEY_RIGHT))
	_input._key_press_times[KEY_RIGHT] = Time.get_ticks_msec() - 50.0
	_input._handle_key(_make_key_release(KEY_RIGHT))

	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(1, 0))


# —————————————————————————————————————————————
# Tests: Keyboard — blocking
# —————————————————————————————————————————————

func test_input_system_key_blocked_emits_nothing() -> void:
	# Arrange
	_input.set_accepting_input(false)
	_input._handle_key(_make_key_press(KEY_W))
	_input._key_press_times[KEY_W] = Time.get_ticks_msec() - 50.0

	# Act
	_input._handle_key(_make_key_release(KEY_W))

	# Assert
	assert_eq(_received_directions.size(), 0)


# —————————————————————————————————————————————
# Tests: Keyboard — key repeat (echo)
# —————————————————————————————————————————————

func test_input_system_key_repeat_emits_direction() -> void:
	# Arrange — initial press
	_input._handle_key(_make_key_press(KEY_D))
	_input._key_press_times[KEY_D] = Time.get_ticks_msec() - 50.0

	# Act — echo (key repeat)
	_input._handle_key(_make_key_press(KEY_D, true))

	# Assert — repeat should fire
	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(1, 0))


# —————————————————————————————————————————————
# Tests: Keyboard — non-movement key
# —————————————————————————————————————————————

func test_input_system_non_movement_key_emits_nothing() -> void:
	_input._handle_key(_make_key_press(KEY_SPACE))
	_input._key_press_times[KEY_SPACE] = Time.get_ticks_msec() - 50.0
	_input._handle_key(_make_key_release(KEY_SPACE))

	assert_eq(_received_directions.size(), 0)


# —————————————————————————————————————————————
# Tests: Keyboard — min hold duration
# —————————————————————————————————————————————

func test_input_system_key_too_short_hold_emits_nothing() -> void:
	# Arrange — press and release instantly (0ms hold, below 25ms threshold)
	_input._handle_key(_make_key_press(KEY_W))
	# Don't modify press time → it was just recorded at "now", so hold ≈ 0ms

	# Act
	_input._handle_key(_make_key_release(KEY_W))

	# Assert — too short, rejected
	assert_eq(_received_directions.size(), 0)


# —————————————————————————————————————————————
# Tests: Touch — valid swipe
# —————————————————————————————————————————————

func test_input_system_swipe_right_emits_right() -> void:
	# Arrange — swipe 100px to the right
	_input._handle_touch(_make_touch_press(Vector2(100, 200)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0 # 100ms ago

	# Act
	_input._handle_touch(_make_touch_release(Vector2(200, 200)))

	# Assert
	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(1, 0))


func test_input_system_swipe_left_emits_left() -> void:
	_input._handle_touch(_make_touch_press(Vector2(200, 200)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0

	_input._handle_touch(_make_touch_release(Vector2(100, 200)))

	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(-1, 0))


func test_input_system_swipe_down_emits_down() -> void:
	_input._handle_touch(_make_touch_press(Vector2(200, 100)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0

	_input._handle_touch(_make_touch_release(Vector2(200, 200)))

	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(0, 1))


func test_input_system_swipe_up_emits_up() -> void:
	_input._handle_touch(_make_touch_press(Vector2(200, 200)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0

	_input._handle_touch(_make_touch_release(Vector2(200, 100)))

	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(0, -1))


# —————————————————————————————————————————————
# Tests: Touch — rejected swipes
# —————————————————————————————————————————————

func test_input_system_tap_too_short_emits_nothing() -> void:
	# Arrange — drag only 10px (below 40px threshold)
	_input._handle_touch(_make_touch_press(Vector2(100, 200)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0

	# Act
	_input._handle_touch(_make_touch_release(Vector2(110, 200)))

	# Assert
	assert_eq(_received_directions.size(), 0)


func test_input_system_slow_drag_emits_nothing() -> void:
	# Arrange — swipe 100px but over 600ms (exceeds 400ms threshold)
	_input._handle_touch(_make_touch_press(Vector2(100, 200)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 600.0

	# Act
	_input._handle_touch(_make_touch_release(Vector2(200, 200)))

	# Assert
	assert_eq(_received_directions.size(), 0)


# —————————————————————————————————————————————
# Tests: Touch — diagonal tie-breaking
# —————————————————————————————————————————————

func test_input_system_diagonal_tie_resolves_vertical() -> void:
	# Arrange — 50px right and 50px down (perfect diagonal)
	_input._handle_touch(_make_touch_press(Vector2(100, 100)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0

	# Act
	_input._handle_touch(_make_touch_release(Vector2(150, 150)))

	# Assert — vertical wins on tie per GDD
	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(0, 1))


# —————————————————————————————————————————————
# Tests: Touch — blocking
# —————————————————————————————————————————————

func test_input_system_swipe_blocked_emits_nothing() -> void:
	# Arrange
	_input.set_accepting_input(false)
	_input._handle_touch(_make_touch_press(Vector2(100, 200)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0

	# Act
	_input._handle_touch(_make_touch_release(Vector2(200, 200)))

	# Assert
	assert_eq(_received_directions.size(), 0)


# —————————————————————————————————————————————
# Tests: Touch — multi-touch guard
# —————————————————————————————————————————————

func test_input_system_second_finger_ignored() -> void:
	# Arrange — first finger down
	_input._handle_touch(_make_touch_press(Vector2(100, 200), 0))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0

	# Act — second finger down (should be ignored)
	_input._handle_touch(_make_touch_press(Vector2(300, 200), 1))
	# Release second finger
	_input._handle_touch(_make_touch_release(Vector2(400, 200), 1))
	# Release first finger — valid swipe right
	_input._handle_touch(_make_touch_release(Vector2(200, 200), 0))

	# Assert — only first finger's swipe counts
	assert_eq(_received_directions.size(), 1)
	assert_eq(_received_directions[0], Vector2i(1, 0))


# —————————————————————————————————————————————
# Tests: set_accepting_input / is_accepting_input
# —————————————————————————————————————————————

func test_input_system_accepting_input_default_true() -> void:
	assert_true(_input.is_accepting_input())


func test_input_system_set_accepting_input_toggles() -> void:
	_input.set_accepting_input(false)
	assert_false(_input.is_accepting_input())

	_input.set_accepting_input(true)
	assert_true(_input.is_accepting_input())


# —————————————————————————————————————————————
# Tests: Touch — zero-length delta guard
# —————————————————————————————————————————————

func test_input_system_zero_delta_emits_nothing() -> void:
	# Arrange — press and release at same position
	_input._handle_touch(_make_touch_press(Vector2(100, 200)))
	_input._touch_start_time_ms = Time.get_ticks_msec() - 100.0

	# Act
	_input._handle_touch(_make_touch_release(Vector2(100, 200)))

	# Assert
	assert_eq(_received_directions.size(), 0)
