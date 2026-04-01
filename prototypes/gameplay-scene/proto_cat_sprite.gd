# PROTOTYPE - NOT FOR PRODUCTION
# Question: Minimal visual representation of the cat on the grid.
# Date: 2026-04-01
#
# Draws a colored circle at the SlidingMovement node's position.
# Attached as a child of SlidingMovement so it inherits position/scale.
extends Node2D

const CAT_RADIUS: float = 24.0
const CAT_COLOR: Color = Color(1.0, 0.6, 0.2)
const EYE_COLOR: Color = Color(0.1, 0.1, 0.1)


func _draw() -> void:
	# Body
	draw_circle(Vector2.ZERO, CAT_RADIUS, CAT_COLOR)

	# Eyes
	draw_circle(Vector2(-8, -6), 4.0, EYE_COLOR)
	draw_circle(Vector2(8, -6), 4.0, EYE_COLOR)

	# Ears (triangles)
	var ear_color: Color = Color(0.9, 0.45, 0.1)
	draw_polygon(
		PackedVector2Array([Vector2(-18, -14), Vector2(-10, -26), Vector2(-4, -14)]),
		PackedColorArray([ear_color])
	)
	draw_polygon(
		PackedVector2Array([Vector2(4, -14), Vector2(10, -26), Vector2(18, -14)]),
		PackedColorArray([ear_color])
	)
