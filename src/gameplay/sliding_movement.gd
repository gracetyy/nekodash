## SlidingMovement — core verb node: slides the cat across the grid until it
## hits a wall or boundary.
## Implements: design/gdd/sliding-movement.md
## Task: S1-05
##
## Owns cat logical position, slide resolution math, tween animation, bump/
## squish feedback, and the is_accepting_input flag that gates InputSystem.
##
## Usage:
##   # Add as child of gameplay scene. At level load:
##   sliding_movement.initialize_level(level_data.cat_start)
##
##   # To rewind (Undo/Restart):
##   sliding_movement.set_grid_position_instant(saved_coord)
extends Node2D

const CAT_RIG_NODE_PATH: NodePath = ^"CatSprite"


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when a valid slide begins (landing ≠ current position).
signal slide_started(from_pos: Vector2i, to_pos: Vector2i, direction: Vector2i)

## Emitted when the slide tween finishes. tiles_covered includes every tile
## from (from_pos + direction) to to_pos inclusive.
signal slide_completed(from_pos: Vector2i, to_pos: Vector2i, direction: Vector2i, tiles_covered: Array[Vector2i])

## Emitted as the cat reaches each traversed tile during slide animation.
## Used by CoverageVisualizer to keep trail timing in sync with movement.
signal slide_tile_reached(coord: Vector2i)

## Emitted when a slide is immediately blocked (landing == current position).
signal slide_blocked(pos: Vector2i, direction: Vector2i)

## Emitted once during initialize_level(). Coverage Tracking uses this to
## mark the starting tile as pre-covered.
signal spawn_position_set(pos: Vector2i)


# —————————————————————————————————————————————
# Enums
# —————————————————————————————————————————————

## Three-state machine: IDLE accepts input, SLIDING animates, LOCKED is
## controlled externally by Scene Manager.
enum State {IDLE, SLIDING, LOCKED}


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Safety guard for malformed level data — no realistic slide exceeds this.
const MAX_SLIDE_DISTANCE: int = 20


# —————————————————————————————————————————————
# Tuning knobs (@export for editor tweaking)
# —————————————————————————————————————————————

## Slide speed on desktop (tiles per second).
@export var slide_velocity_desktop: float = 15.0

## Slide speed on mobile (tiles per second). Higher because the grid is
## physically smaller on a phone screen.
@export var slide_velocity_mobile: float = 25.0

## Minimum animation time regardless of tile count.
@export var min_slide_duration_sec: float = 0.10

## Tile count after which long-slide speedup starts applying.
@export var long_slide_speedup_start_tiles: int = 4

## Additional speed multiplier per tile after long_slide_speedup_start_tiles.
@export var long_slide_extra_speed_per_tile: float = 0.08

## Upper bound for long-slide speed multiplier.
@export var long_slide_max_speed_multiplier: float = 1.6

## Pixels the cat nudges toward a wall on a blocked slide.
@export var blocked_bump_offset_px: float = 6.0

## Total duration of the bump animation (nudge + return).
@export var blocked_bump_duration_sec: float = 0.12

## Landing squish scale (width, height) before springing back to (1, 1).
@export var squish_scale: Vector2 = Vector2(1.2, 0.85)

## Duration of the squish-in phase (scale → squish_scale).
@export var squish_duration_sec: float = 0.08

## Duration of the squish-recover phase (squish_scale → Vector2.ONE).
@export var squish_recover_sec: float = 0.10

## Parent stretch target while sliding horizontally.
@export var slide_travel_scale_horizontal: Vector2 = Vector2(1.07, 0.94)

## Parent stretch target while sliding vertically.
@export var slide_travel_scale_vertical: Vector2 = Vector2(0.95, 1.06)

## Duration of the slide-travel squish-in phase.
@export var slide_travel_in_sec: float = 0.05

@export_category("Cat Rig Host")
## If true, gameplay host exports override global CatRigProfile defaults.
@export var cat_override_global_defaults: bool = false

## Display size for gameplay cat rig in pixels when host override is enabled.
@export_range(16.0, 512.0, 1.0, "or_greater")
var cat_display_size_px: float = 92.0

## Global offset applied to gameplay cat rig when host override is enabled.
@export var cat_display_offset: Vector2 = Vector2(0.0, -16.0)

## Face variant used by gameplay cat rig when host override is enabled.
@export_enum("idle", "blink", "excited", "relax", "smile")
var cat_face_variant: String = "idle"

## Idle tail sway amplitude in degrees when host override is enabled.
@export_range(0.0, 60.0, 0.1, "or_greater")
var cat_idle_tail_swing_degrees: float = 10.0

## Idle tail sway cycle duration in seconds when host override is enabled.
@export_range(0.0, 10.0, 0.01, "or_greater")
var cat_idle_tail_swing_period_sec: float = 1.45


## State
# —————————————————————————————————————————————

## Current state machine state.
var _state: State = State.IDLE

## Real SFX stream for slide movement.
var _sfx_slide_move: AudioStream = preload("res://assets/audio/sfx/gameplay/slide_move.wav")
var _sfx_wall_bump: AudioStream = preload("res://assets/audio/sfx/gameplay/wall_bump.wav")

## Cat's logical grid coordinate — single source of truth for position.
var _cat_pos: Vector2i = Vector2i.ZERO

## Active slide velocity (selected once in _ready based on platform).
var _slide_velocity: float = 15.0

## Tweens — tracked so they can be killed on instant-position resets.
var _slide_tween: Tween
var _bump_tween: Tween
var _squish_tween: Tween
var _travel_tween: Tween
var _tile_reveal_tween: Tween
## If set to non-zero, only this input direction is accepted. Used by Tutorial.
var forced_direction: Vector2i = Vector2i.ZERO
var _cat_rig: Node


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_slide_velocity = slide_velocity_mobile if DisplayServer.is_touchscreen_available() else slide_velocity_desktop
	InputSystem.direction_input.connect(_on_direction_input)
	_cache_cat_rig()
	_apply_cat_host_overrides()


func _cache_cat_rig() -> void:
	var candidate: Node = get_node_or_null(CAT_RIG_NODE_PATH)
	if _is_cat_rig_node(candidate):
		_cat_rig = candidate
		return
	_cat_rig = null


func _is_cat_rig_node(candidate: Node) -> bool:
	if candidate == null:
		return false
	if not candidate.has_method("refresh_rig"):
		return false
	if not candidate.has_method("set_head_tilt_immediate"):
		return false
	return true


func _apply_cat_host_overrides() -> void:
	if _cat_rig == null:
		return

	_cat_rig.set("override_display_locally", cat_override_global_defaults)
	_cat_rig.set("override_idle_locally", cat_override_global_defaults)
	_cat_rig.set("override_face_locally", cat_override_global_defaults)
	_cat_rig.set("display_size_px", cat_display_size_px)
	_cat_rig.set("display_offset", cat_display_offset)
	_cat_rig.set("face_variant", cat_face_variant)
	_cat_rig.set("idle_tail_swing_degrees", cat_idle_tail_swing_degrees)
	_cat_rig.set("idle_tail_swing_period_sec", cat_idle_tail_swing_period_sec)
	_cat_rig.call("refresh_rig")


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Returns whether external systems should accept input. True in IDLE,
## false in SLIDING, determined by Scene Manager in LOCKED.
func is_accepting_input() -> bool:
	return _state == State.IDLE


## Returns the cat's current logical grid coordinate.
func get_cat_pos() -> Vector2i:
	return _cat_pos


## Returns the current state.
func get_state() -> State:
	return _state


## Sets the cat rig size dynamically based on current tile size.
func refresh_visual_size() -> void:
	if _cat_rig == null:
		_cache_cat_rig()
	if _cat_rig == null:
		return
	
	var tile_size: int = GridSystem.get_tile_size()
	# Default was 112px for 72px tiles -> ~1.55 ratio
	var target_cat_size: float = float(tile_size) * 1.55
	# Bump offset ratio: 6px for 72px tiles -> ~0.083 ratio
	blocked_bump_offset_px = float(tile_size) * 0.083
	
	cat_display_size_px = target_cat_size
	_cat_rig.set("display_size_px", cat_display_size_px)
	if _cat_rig.has_method("refresh_rig"):
		_cat_rig.call("refresh_rig")


## Called once at level load. Snaps cat to spawn_pos, resets state to IDLE,
## and emits spawn_position_set for Coverage Tracking.
func initialize_level(spawn_pos: Vector2i) -> void:
	_kill_all_tweens()
	refresh_visual_size()
	_cat_pos = spawn_pos
	position = _grid_to_pixel(spawn_pos)
	scale = Vector2.ONE
	_state = State.IDLE
	InputSystem.set_accepting_input(true)
	spawn_position_set.emit(spawn_pos)


## Instantly repositions the cat without animation or signals.
## Used by Undo/Restart to rewind position. Kills any in-flight tweens.
func set_grid_position_instant(coord: Vector2i) -> void:
	_kill_all_tweens()
	_cat_pos = coord
	position = _grid_to_pixel(coord)
	scale = Vector2.ONE
	_state = State.IDLE
	InputSystem.set_accepting_input(true)


## Enters LOCKED state. Called by Scene Manager for non-PLAYING states.
func lock() -> void:
	_kill_all_tweens()
	_state = State.LOCKED
	InputSystem.set_accepting_input(false)


## Exits LOCKED state back to IDLE. Called by Scene Manager when returning
## to PLAYING state.
func unlock() -> void:
	_state = State.IDLE
	InputSystem.set_accepting_input(true)


# —————————————————————————————————————————————
# Slide resolution
# —————————————————————————————————————————————

## Walks from start in direction until the next tile is non-walkable.
## Returns the final valid position (may equal start if immediately blocked).
func resolve_slide(start: Vector2i, direction: Vector2i) -> Vector2i:
	var pos: Vector2i = start
	var iterations: int = 0
	while GridSystem.is_walkable(pos + direction) and iterations < MAX_SLIDE_DISTANCE:
		pos += direction
		iterations += 1
	if iterations >= MAX_SLIDE_DISTANCE:
		push_error("SlidingMovement: Slide exceeded MAX_SLIDE_DISTANCE — possible malformed level")
	return pos


## Returns all tiles from (start + direction) to landing inclusive.
## The starting tile is excluded — it was covered previously.
func compute_tiles_covered(start: Vector2i, landing: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var step: Vector2i = start + direction
	var end: Vector2i = landing + direction
	while step != end:
		tiles.append(step)
		step += direction
	return tiles


# —————————————————————————————————————————————
# Input handling
# —————————————————————————————————————————————

func _on_direction_input(direction: Vector2i) -> void:
	if _state != State.IDLE:
		return
		
	if forced_direction != Vector2i.ZERO and direction != forced_direction:
		return

	# Kill any cosmetic bump tween so it doesn't interfere
	if _bump_tween and _bump_tween.is_valid():
		_bump_tween.kill()
		position = _grid_to_pixel(_cat_pos)
		scale = Vector2.ONE

	var landing: Vector2i = resolve_slide(_cat_pos, direction)

	if landing == _cat_pos:
		_play_bump(direction)
		return

	_play_slide(_cat_pos, landing, direction)


# —————————————————————————————————————————————
# Animation — slide
# —————————————————————————————————————————————

func _play_slide(from: Vector2i, to: Vector2i, direction: Vector2i) -> void:
	_state = State.SLIDING
	InputSystem.set_accepting_input(false)
	var old_pos: Vector2i = _cat_pos
	_cat_pos = to

	var tile_count: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	var duration: float = _compute_slide_duration(tile_count)

	var target_pixel: Vector2 = _grid_to_pixel(to)
	var tiles_for_timing: Array[Vector2i] = compute_tiles_covered(from, to, direction)
	_play_slide_travel_squish(direction, duration)
	_queue_tile_reveal_events(tiles_for_timing, duration)

	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()

	_slide_tween = create_tween()
	_slide_tween.tween_property(self , "position", target_pixel, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_slide_tween.tween_callback(_on_slide_finished.bind(old_pos, to, direction))

	slide_started.emit(old_pos, to, direction)
	SfxManager.play(_sfx_slide_move, SfxManager.SfxBus.SFX, 1.0, 1.5)


func _on_slide_finished(from: Vector2i, to: Vector2i, direction: Vector2i) -> void:
	if _travel_tween and _travel_tween.is_valid():
		_travel_tween.kill()
	scale = Vector2.ONE
	_play_squish()

	var tiles: Array[Vector2i] = compute_tiles_covered(from, to, direction)

	_state = State.IDLE
	slide_completed.emit(from, to, direction, tiles)
	InputSystem.set_accepting_input(true)


# —————————————————————————————————————————————
# Animation — squish (landing feedback)
# —————————————————————————————————————————————

func _play_slide_travel_squish(direction: Vector2i, duration_sec: float) -> void:
	if _is_reduce_motion_enabled():
		scale = Vector2.ONE
		return

	if _travel_tween and _travel_tween.is_valid():
		_travel_tween.kill()

	var target_scale: Vector2 = slide_travel_scale_horizontal if direction.x != 0 else slide_travel_scale_vertical
	var in_sec: float = minf(slide_travel_in_sec, duration_sec)
	var out_sec: float = maxf(0.0, duration_sec - in_sec)

	_travel_tween = create_tween()
	_travel_tween.tween_property(self , "scale", target_scale, in_sec) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if out_sec > 0.0:
		_travel_tween.tween_property(self , "scale", Vector2.ONE, out_sec) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		scale = Vector2.ONE

func _play_squish() -> void:
	if _is_reduce_motion_enabled():
		scale = Vector2.ONE
		return

	if _squish_tween and _squish_tween.is_valid():
		_squish_tween.kill()
	if _travel_tween and _travel_tween.is_valid():
		_travel_tween.kill()

	_squish_tween = create_tween()
	_squish_tween.tween_property(self , "scale", squish_scale, squish_duration_sec) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_squish_tween.tween_property(self , "scale", Vector2.ONE, squish_recover_sec) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


# —————————————————————————————————————————————
# Animation — bump (blocked feedback)
# —————————————————————————————————————————————

func _play_bump(direction: Vector2i) -> void:
	var bump_offset: Vector2 = Vector2(direction) * blocked_bump_offset_px
	var home_pixel: Vector2 = _grid_to_pixel(_cat_pos)
	
	SfxManager.play(_sfx_wall_bump, SfxManager.SfxBus.SFX, 1.0, 0.75)

	if _is_reduce_motion_enabled():
		position = home_pixel
		slide_blocked.emit(_cat_pos, direction)
		return

	if _bump_tween and _bump_tween.is_valid():
		_bump_tween.kill()

	_bump_tween = create_tween()
	_bump_tween.tween_property(self , "position", home_pixel + bump_offset, blocked_bump_duration_sec * 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_bump_tween.tween_property(self , "position", home_pixel, blocked_bump_duration_sec * 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	slide_blocked.emit(_cat_pos, direction)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

func _grid_to_pixel(coord: Vector2i) -> Vector2:
	return GridSystem.grid_to_pixel(coord)


func _compute_slide_duration(tile_count: int) -> float:
	if _is_reduce_motion_enabled():
		return 0.02
	if tile_count <= 0:
		return min_slide_duration_sec

	var speed_multiplier: float = 1.0
	if tile_count > long_slide_speedup_start_tiles:
		var extra_tiles: int = tile_count - long_slide_speedup_start_tiles
		speed_multiplier += float(extra_tiles) * long_slide_extra_speed_per_tile
		speed_multiplier = minf(speed_multiplier, long_slide_max_speed_multiplier)

	var effective_velocity: float = _slide_velocity * speed_multiplier
	return maxf(min_slide_duration_sec, float(tile_count) / effective_velocity)


func _queue_tile_reveal_events(tiles_covered: Array[Vector2i], slide_duration_sec: float) -> void:
	if _tile_reveal_tween and _tile_reveal_tween.is_valid():
		_tile_reveal_tween.kill()

	if tiles_covered.is_empty():
		return

	if _is_reduce_motion_enabled():
		for coord: Vector2i in tiles_covered:
			slide_tile_reached.emit(coord)
		return

	var per_tile_duration: float = slide_duration_sec / float(tiles_covered.size())
	_tile_reveal_tween = create_tween()
	for coord: Vector2i in tiles_covered:
		_tile_reveal_tween.tween_interval(per_tile_duration)
		_tile_reveal_tween.tween_callback(_emit_slide_tile_reached.bind(coord))


func _emit_slide_tile_reached(coord: Vector2i) -> void:
	slide_tile_reached.emit(coord)


func _kill_all_tweens() -> void:
	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()
	if _bump_tween and _bump_tween.is_valid():
		_bump_tween.kill()
	if _squish_tween and _squish_tween.is_valid():
		_squish_tween.kill()
	if _travel_tween and _travel_tween.is_valid():
		_travel_tween.kill()
	if _tile_reveal_tween and _tile_reveal_tween.is_valid():
		_tile_reveal_tween.kill()


func _is_reduce_motion_enabled() -> bool:
	return AppSettings != null and AppSettings.get_reduce_motion()
