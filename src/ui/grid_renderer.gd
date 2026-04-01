## GridRenderer — visual grid drawing for the gameplay scene.
## Task: S2-05 (visual layer)
##
## Pure display node. Reads from GridSystem autoload to draw the grid,
## subscribes to CoverageTracking.tile_covered to overlay covered tiles.
## Owns no game state.
extends Node2D


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const COLOR_FLOOR: Color = Color(0.15, 0.18, 0.35)
const COLOR_WALL: Color = Color(0.25, 0.25, 0.25)
const COLOR_COVERED: Color = Color(0.2, 0.7, 0.3, 0.6)
const COLOR_GRID_LINE: Color = Color(0.3, 0.3, 0.4, 0.4)


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _covered_tiles: Dictionary = {}
var _tile_size: int = 64

## Pixel offset applied to center the grid on screen, below the HUD.
var _grid_offset: Vector2 = Vector2.ZERO


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Clears coverage overlay and redraws grid from GridSystem.
## Computes an offset to center the grid horizontally and push it below the HUD.
func render_grid() -> void:
	_covered_tiles.clear()
	_tile_size = GridSystem.DEFAULT_TILE_SIZE_PX

	# Compute centering offset
	var grid_w_px: float = GridSystem.get_width() * _tile_size
	var grid_h_px: float = GridSystem.get_height() * _tile_size
	var viewport_w: float = get_viewport_rect().size.x
	var viewport_h: float = get_viewport_rect().size.y

	# Center horizontally, push below HUD (100px top margin for HUD)
	var hud_margin: float = 100.0
	var x_offset: float = (viewport_w - grid_w_px) / 2.0
	var y_offset: float = hud_margin + (viewport_h - hud_margin - grid_h_px) / 2.0
	_grid_offset = Vector2(x_offset, y_offset)

	queue_redraw()


## Returns the computed grid offset for the parent coordinator to position itself.
func get_grid_offset() -> Vector2:
	return _grid_offset


## Marks a single tile as covered and redraws.
func mark_covered(coord: Vector2i) -> void:
	_covered_tiles[coord] = true
	queue_redraw()


## Marks a single tile as uncovered and redraws (used by undo).
func mark_uncovered(coord: Vector2i) -> void:
	_covered_tiles.erase(coord)
	queue_redraw()


## Clears all coverage overlays without redrawing grid structure.
func clear_coverage() -> void:
	_covered_tiles.clear()
	queue_redraw()


# —————————————————————————————————————————————
# Drawing
# —————————————————————————————————————————————

func _draw() -> void:
	var w: int = GridSystem.get_width()
	var h: int = GridSystem.get_height()

	if w == 0 or h == 0:
		return

	# Draw tile fills (all coords relative to local origin — position handles offset)
	for row: int in range(h):
		for col: int in range(w):
			var coord := Vector2i(col, row)
			var rect := Rect2(col * _tile_size, row * _tile_size, _tile_size, _tile_size)

			if GridSystem.is_walkable(coord):
				draw_rect(rect, COLOR_FLOOR, true)
			else:
				draw_rect(rect, COLOR_WALL, true)

			# Coverage overlay
			if _covered_tiles.has(coord):
				draw_rect(rect, COLOR_COVERED, true)

	# Draw rounded border around the grid
	var grid_rect := Rect2(0, 0, w * _tile_size, h * _tile_size)
	draw_rect(grid_rect, COLOR_GRID_LINE, false, 2.0)

	# Draw grid lines
	for row: int in range(1, h):
		var y: float = row * _tile_size
		draw_line(Vector2(0, y), Vector2(w * _tile_size, y), COLOR_GRID_LINE, 1.0)
	for col: int in range(1, w):
		var x: float = col * _tile_size
		draw_line(Vector2(x, 0), Vector2(x, h * _tile_size), COLOR_GRID_LINE, 1.0)
