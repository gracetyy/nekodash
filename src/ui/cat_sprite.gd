## CatSprite — kawaii cat visual for the player on the grid.
## Task: S2-05 (visual layer)
##
## Pure display node. Attached as a child of SlidingMovement so it inherits
## position and tween animation automatically. Draws a cute kawaii-style cat
## with expressive features. Owns no game state.
extends Node2D


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const BODY_RADIUS: float = 22.0
const BODY_COLOR: Color = Color(1.0, 0.65, 0.25) # Warm orange
const BODY_OUTLINE: Color = Color(0.85, 0.45, 0.1) # Darker orange outline
const EAR_COLOR: Color = Color(1.0, 0.65, 0.25) # Same as body
const EAR_INNER: Color = Color(1.0, 0.75, 0.8) # Pink inner ear
const EYE_WHITE: Color = Color(1.0, 1.0, 1.0) # White sclera
const EYE_PUPIL: Color = Color(0.15, 0.15, 0.15) # Dark pupil
const EYE_SHINE: Color = Color(1.0, 1.0, 1.0, 0.9) # Highlight
const NOSE_COLOR: Color = Color(1.0, 0.55, 0.6) # Pink nose
const MOUTH_COLOR: Color = Color(0.5, 0.35, 0.25) # Warm brown
const CHEEK_COLOR: Color = Color(1.0, 0.6, 0.65, 0.4) # Rosy cheeks
const WHISKER_COLOR: Color = Color(0.6, 0.45, 0.3, 0.6) # Subtle whiskers


# —————————————————————————————————————————————
# Drawing
# —————————————————————————————————————————————

const DEBUG_DRAW: bool = false
const TEXTURE_TAIL_UP_PATH: String = "res://assets/art/cats/cat_default_idle_tail_up.png"
const TEXTURE_IDLE_PATH: String = "res://assets/art/cats/cat_default_idle.png"
const TEXTURE_TAIL_DOWN_PATH: String = "res://assets/art/cats/cat_default_idle_tail_down.png"
const IDLE_BLEND_PERIOD_SEC: float = 1.45
const TEXTURE_DRAW_SIZE: Vector2 = Vector2(92, 92)
const TEXTURE_DRAW_OFFSET_Y: float = -16.0

var _texture: Texture2D
var _idle_frames: Array[Texture2D] = []
var _idle_blend_time_sec: float = 0.0

func _ready() -> void:
	if not DEBUG_DRAW:
		var frame_paths: Array[String] = [
			TEXTURE_TAIL_UP_PATH,
			TEXTURE_IDLE_PATH,
			TEXTURE_TAIL_DOWN_PATH,
		]
		for path: String in frame_paths:
			if not ResourceLoader.exists(path):
				continue
			var frame: Texture2D = load(path) as Texture2D
			if frame != null:
				_idle_frames.append(frame)
		if _idle_frames.is_empty() and ResourceLoader.exists("res://assets/art/cats/cat_default_idle.png"):
			var fallback_texture: Texture2D = load("res://assets/art/cats/cat_default_idle.png") as Texture2D
			if fallback_texture != null:
				_idle_frames.append(fallback_texture)
		if not _idle_frames.is_empty():
			_texture = _idle_frames[1] if _idle_frames.size() >= 2 else _idle_frames[0]
	set_process(_idle_frames.size() > 1)


func _process(delta: float) -> void:
	if DEBUG_DRAW or _idle_frames.size() < 2:
		return
	if AppSettings != null and AppSettings.get_reduce_motion():
		if _idle_blend_time_sec != 0.0:
			_idle_blend_time_sec = 0.0
			_texture = _idle_frames[1] if _idle_frames.size() >= 2 else _idle_frames[0]
			queue_redraw()
		return

	_idle_blend_time_sec += delta
	queue_redraw()

func _draw() -> void:
	if not DEBUG_DRAW and _texture != null:
		var texture_rect: Rect2 = Rect2(
			- TEXTURE_DRAW_SIZE.x * 0.5,
			- TEXTURE_DRAW_SIZE.y * 0.5 + TEXTURE_DRAW_OFFSET_Y,
			TEXTURE_DRAW_SIZE.x,
			TEXTURE_DRAW_SIZE.y
		)
		if _idle_frames.size() >= 3 and not (AppSettings != null and AppSettings.get_reduce_motion()):
			draw_texture_rect(_idle_frames[1], texture_rect, false, Color.WHITE)
			var cycle: float = fposmod(_idle_blend_time_sec / IDLE_BLEND_PERIOD_SEC, 1.0) * 4.0
			var segment: int = int(floor(cycle))
			var local: float = cycle - float(segment)
			var smooth: float = local * local * (3.0 - (2.0 * local))
			var overlay_texture: Texture2D = null
			var overlay_alpha: float = 0.0
			match segment:
				0:
					overlay_texture = _idle_frames[0]
					overlay_alpha = 1.0 - smooth
				1:
					overlay_texture = _idle_frames[2]
					overlay_alpha = smooth
				2:
					overlay_texture = _idle_frames[2]
					overlay_alpha = 1.0 - smooth
				_:
					overlay_texture = _idle_frames[0]
					overlay_alpha = smooth
			if overlay_texture != null and overlay_alpha > 0.0:
				draw_texture_rect(overlay_texture, texture_rect, false, Color(1.0, 1.0, 1.0, overlay_alpha))
			return
		if _idle_frames.size() >= 2 and not (AppSettings != null and AppSettings.get_reduce_motion()):
			var phase: float = 0.5 + 0.5 * sin((_idle_blend_time_sec / IDLE_BLEND_PERIOD_SEC) * TAU)
			var two_frame_blend: float = phase * phase * (3.0 - (2.0 * phase))
			draw_texture_rect(_idle_frames[0], texture_rect, false, Color(1.0, 1.0, 1.0, 1.0 - two_frame_blend))
			draw_texture_rect(_idle_frames[1], texture_rect, false, Color(1.0, 1.0, 1.0, two_frame_blend))
			return
		draw_texture_rect(
			_texture,
			texture_rect,
			false
		)
		return
	# === Ears (behind body) ===
	# Left ear outer
	draw_polygon(
		PackedVector2Array([Vector2(-18, -10), Vector2(-14, -30), Vector2(-4, -14)]),
		PackedColorArray([EAR_COLOR])
	)
	# Left ear inner
	draw_polygon(
		PackedVector2Array([Vector2(-15, -13), Vector2(-13, -25), Vector2(-7, -15)]),
		PackedColorArray([EAR_INNER])
	)
	# Right ear outer
	draw_polygon(
		PackedVector2Array([Vector2(4, -14), Vector2(14, -30), Vector2(18, -10)]),
		PackedColorArray([EAR_COLOR])
	)
	# Right ear inner
	draw_polygon(
		PackedVector2Array([Vector2(7, -15), Vector2(13, -25), Vector2(15, -13)]),
		PackedColorArray([EAR_INNER])
	)

	# === Body ===
	draw_circle(Vector2.ZERO, BODY_RADIUS + 1.5, BODY_OUTLINE)
	draw_circle(Vector2.ZERO, BODY_RADIUS, BODY_COLOR)

	# === Eyes ===
	# Left eye
	draw_circle(Vector2(-8, -4), 5.5, EYE_WHITE)
	draw_circle(Vector2(-7, -3), 3.5, EYE_PUPIL)
	draw_circle(Vector2(-8.5, -5.5), 1.5, EYE_SHINE)
	# Right eye
	draw_circle(Vector2(8, -4), 5.5, EYE_WHITE)
	draw_circle(Vector2(9, -3), 3.5, EYE_PUPIL)
	draw_circle(Vector2(7.5, -5.5), 1.5, EYE_SHINE)

	# === Nose ===
	draw_polygon(
		PackedVector2Array([Vector2(-2.5, 2), Vector2(2.5, 2), Vector2(0, 4.5)]),
		PackedColorArray([NOSE_COLOR])
	)

	# === Mouth (cat "w" shape) ===
	# Left curve
	draw_line(Vector2(0, 4.5), Vector2(-5, 7), MOUTH_COLOR, 1.5, true)
	# Right curve
	draw_line(Vector2(0, 4.5), Vector2(5, 7), MOUTH_COLOR, 1.5, true)

	# === Cheeks (blush spots) ===
	draw_circle(Vector2(-14, 3), 4.5, CHEEK_COLOR)
	draw_circle(Vector2(14, 3), 4.5, CHEEK_COLOR)

	# === Whiskers ===
	# Left whiskers
	draw_line(Vector2(-12, 1), Vector2(-24, -2), WHISKER_COLOR, 1.0, true)
	draw_line(Vector2(-12, 3), Vector2(-24, 4), WHISKER_COLOR, 1.0, true)
	# Right whiskers
	draw_line(Vector2(12, 1), Vector2(24, -2), WHISKER_COLOR, 1.0, true)
	draw_line(Vector2(12, 3), Vector2(24, 4), WHISKER_COLOR, 1.0, true)
