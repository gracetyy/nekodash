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

func _draw() -> void:
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
