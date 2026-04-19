## GridRenderer — visual grid drawing for the gameplay scene.
## Task: S2-05 (visual layer)
##
## Pure display node. Reads from GridSystem autoload to draw the grid.
## Coverage overlay is handled by CoverageVisualizer (S2-08).
## Owns no game state.
extends Node2D


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Grid floor tile — grid-floor #EEF9F1.
const FLOOR_TEXTURE: Texture2D = preload("res://assets/art/tiles/grids/grid_mint.png")
## Grid wall/obstacle tile — grid-wall #CEB6E4.
const WALL_TEXTURE: Texture2D = preload("res://assets/art/tiles/grids/grid_purple.png")


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _tile_size: int = 72

## Pixel offset applied to center the grid on screen, below the HUD.
var _grid_offset: Vector2 = Vector2.ZERO


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Redraws the grid from GridSystem state and computes centering offset.
func render_grid() -> void:
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
				draw_texture_rect(FLOOR_TEXTURE, rect, false)
			else:
				draw_texture_rect(WALL_TEXTURE, rect, false)
