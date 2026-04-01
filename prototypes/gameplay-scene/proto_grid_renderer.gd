# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can we render the grid visually using GridSystem data?
# Date: 2026-04-01
#
# Draws colored rectangles for each tile:
#   - Walkable floor: dark blue
#   - Blocking wall: dark gray
#   - Covered tile: green overlay
extends Node2D

const TILE_SIZE: int = 64

# Colors
const COLOR_FLOOR: Color = Color(0.15, 0.18, 0.35)
const COLOR_WALL: Color = Color(0.25, 0.25, 0.25)
const COLOR_COVERED: Color = Color(0.2, 0.7, 0.3, 0.6)
const COLOR_GRID_LINE: Color = Color(0.3, 0.3, 0.4, 0.4)

var _covered_tiles: Dictionary = {}


func render_grid() -> void:
	_covered_tiles.clear()
	queue_redraw()


func mark_covered(coord: Vector2i) -> void:
	_covered_tiles[coord] = true
	queue_redraw()


func _draw() -> void:
	var w: int = GridSystem.get_width()
	var h: int = GridSystem.get_height()

	if w == 0 or h == 0:
		return

	# Draw tile fills
	for row in range(h):
		for col in range(w):
			var coord := Vector2i(col, row)
			var rect := Rect2(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)

			if GridSystem.is_walkable(coord):
				draw_rect(rect, COLOR_FLOOR, true)
			else:
				draw_rect(rect, COLOR_WALL, true)

			# Coverage overlay
			if _covered_tiles.has(coord):
				draw_rect(rect, COLOR_COVERED, true)

	# Draw grid lines
	for row in range(h + 1):
		var y: float = row * TILE_SIZE
		draw_line(Vector2(0, y), Vector2(w * TILE_SIZE, y), COLOR_GRID_LINE, 1.0)
	for col in range(w + 1):
		var x: float = col * TILE_SIZE
		draw_line(Vector2(x, 0), Vector2(x, h * TILE_SIZE), COLOR_GRID_LINE, 1.0)
