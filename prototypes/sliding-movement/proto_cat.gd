# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does slide-until-wall movement feel satisfying on mobile touch input?
# Date: 2026-03-31
#
# Cat controller: handles slide resolution, tween animation, bump feedback.
# Reads grid for walkability, receives direction from input handler.

extends Node2D

# Tuning knobs from GDD
const SLIDE_VELOCITY_TILES_PER_SEC: float = 15.0
const MIN_SLIDE_DURATION_SEC: float = 0.10
const BLOCKED_BUMP_OFFSET_PX: float = 6.0
const BLOCKED_BUMP_DURATION_SEC: float = 0.12
const MAX_SLIDE_DISTANCE: int = 20
const TILE_SIZE: float = 64.0

# Landing squish parameters
const SQUISH_SCALE_X: float = 1.2
const SQUISH_SCALE_Y: float = 0.8
const SQUISH_DURATION_SEC: float = 0.08
const SQUISH_RECOVER_SEC: float = 0.10

enum State {IDLE, SLIDING, BUMPING}

var _state: State = State.IDLE
var _cat_pos: Vector2i = Vector2i(1, 1)
var _grid: Node2D # proto_grid.gd
var _slide_tween: Tween
var _bump_tween: Tween

# Stats for prototype report
var _total_slides: int = 0
var _total_blocked: int = 0
var _slide_distances: Array[int] = []

# Signals
signal slide_completed(from_pos: Vector2i, to_pos: Vector2i, direction: Vector2i, tiles_covered: Array[Vector2i])
signal slide_blocked(pos: Vector2i, direction: Vector2i)


func _ready() -> void:
	_grid = get_parent().get_node("ProtoGrid")
	initialize(Vector2i(1, 1))


func initialize(spawn_pos: Vector2i) -> void:
	_cat_pos = spawn_pos
	position = _grid.position + _grid.grid_to_pixel(_cat_pos)
	_state = State.IDLE
	scale = Vector2.ONE
	_grid.reset_coverage()
	_grid.mark_covered(_cat_pos)

	# Reset stats
	_total_slides = 0
	_total_blocked = 0
	_slide_distances.clear()

	print("[Proto] Cat spawned at ", _cat_pos)


func try_slide(direction: Vector2i) -> void:
	if _state == State.SLIDING:
		return

	# Kill any bump tween
	if _bump_tween and _bump_tween.is_valid():
		_bump_tween.kill()
		position = _grid.position + _grid.grid_to_pixel(_cat_pos)
		scale = Vector2.ONE

	var landing: Vector2i = _resolve_slide(_cat_pos, direction)

	if landing == _cat_pos:
		_play_bump(direction)
		return

	_play_slide(_cat_pos, landing, direction)


func _resolve_slide(start: Vector2i, direction: Vector2i) -> Vector2i:
	var pos: Vector2i = start
	var iterations: int = 0
	while _grid.is_walkable(pos + direction) and iterations < MAX_SLIDE_DISTANCE:
		pos += direction
		iterations += 1
	return pos


func _compute_tiles_covered(start: Vector2i, landing: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var step: Vector2i = start + direction
	var end: Vector2i = landing + direction
	while step != end:
		tiles.append(step)
		step += direction
	return tiles


func _play_slide(from: Vector2i, to: Vector2i, direction: Vector2i) -> void:
	_state = State.SLIDING
	var old_pos: Vector2i = _cat_pos
	_cat_pos = to

	var tile_count: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	var duration: float = maxf(MIN_SLIDE_DURATION_SEC, tile_count / SLIDE_VELOCITY_TILES_PER_SEC)

	var target_pixel: Vector2 = _grid.position + _grid.grid_to_pixel(to)

	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()

	_slide_tween = create_tween()
	_slide_tween.tween_property(self , "position", target_pixel, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_slide_tween.tween_callback(_on_slide_finished.bind(old_pos, to, direction))

	# Stats
	_total_slides += 1
	_slide_distances.append(tile_count)

	print("[Proto] Slide: ", from, " → ", to, " (", tile_count, " tiles, ", snapped(duration, 0.001), "s)")


func _on_slide_finished(from: Vector2i, to: Vector2i, direction: Vector2i) -> void:
	# Landing squish
	_play_squish()

	# Mark tiles covered
	var tiles: Array[Vector2i] = _compute_tiles_covered(from, to, direction)
	_grid.mark_tiles_covered(tiles)

	_state = State.IDLE
	slide_completed.emit(from, to, direction, tiles)

	# Check coverage
	var all_walkable: Array[Vector2i] = _grid.get_all_walkable()
	var covered_count: int = 0
	for t: Vector2i in all_walkable:
		if _grid._covered_tiles.has(t):
			covered_count += 1
	print("[Proto] Coverage: ", covered_count, "/", all_walkable.size())
	if covered_count == all_walkable.size():
		print("[Proto] ★ LEVEL COMPLETE! Total slides: ", _total_slides, " | Blocked attempts: ", _total_blocked)


func _play_squish() -> void:
	var squish_tween: Tween = create_tween()
	squish_tween.tween_property(self , "scale", Vector2(SQUISH_SCALE_X, SQUISH_SCALE_Y), SQUISH_DURATION_SEC) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	squish_tween.tween_property(self , "scale", Vector2.ONE, SQUISH_RECOVER_SEC) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func _play_bump(direction: Vector2i) -> void:
	_state = State.BUMPING
	_total_blocked += 1

	var bump_offset: Vector2 = Vector2(direction) * BLOCKED_BUMP_OFFSET_PX
	var home_pixel: Vector2 = _grid.position + _grid.grid_to_pixel(_cat_pos)

	_bump_tween = create_tween()
	_bump_tween.tween_property(self , "position", home_pixel + bump_offset, BLOCKED_BUMP_DURATION_SEC * 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_bump_tween.tween_property(self , "position", home_pixel, BLOCKED_BUMP_DURATION_SEC * 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	_bump_tween.tween_callback(func() -> void: _state = State.IDLE)

	slide_blocked.emit(_cat_pos, direction)
	print("[Proto] Blocked at ", _cat_pos, " direction ", direction)


func _draw() -> void:
	# Draw cat as a colored rounded rect
	var half: float = TILE_SIZE * 0.4
	var cat_rect := Rect2(-half, -half, half * 2, half * 2)
	draw_rect(cat_rect, Color(0.95, 0.55, 0.25), true) # orange cat
	# Simple face
	draw_circle(Vector2(-8, -6), 3.0, Color.BLACK) # left eye
	draw_circle(Vector2(8, -6), 3.0, Color.BLACK) # right eye
	draw_circle(Vector2(0, 2), 2.0, Color(0.85, 0.4, 0.35)) # nose
