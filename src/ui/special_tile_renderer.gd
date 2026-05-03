## SpecialTileRenderer — visual drawing for special tiles (KILL, STOP_TILE, ONE_WAY).
## Task: Fix visual disappearance when covered by trail.
##
## Separated from GridRenderer to ensure it renders ABOVE CoverageVisualizer.
extends Node2D


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _tile_size: int = 72
var _current_level_data: LevelData
var _render_layout: Dictionary = {}


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

func render_special_tiles(level_data: LevelData, tile_size: int, layout: Dictionary) -> void:
	_current_level_data = level_data
	_tile_size = tile_size
	_render_layout = layout
	queue_redraw()


# —————————————————————————————————————————————
# Drawing
# —————————————————————————————————————————————

func _draw() -> void:
	if _render_layout.is_empty():
		return

	# Draw special tiles (KILL, STOP_TILE, ONE_WAY)
	for special: Dictionary in _render_layout.get("special_draws", []):
		var coord: Vector2i = special.get("coord", Vector2i.ZERO) as Vector2i
		var type: int = special.get("type", 0) as int
		var rect := Rect2(coord.x * _tile_size, coord.y * _tile_size, _tile_size, _tile_size)
		var special_texture: Texture2D = special.get("texture", null) as Texture2D
		
		if special_texture != null:
			draw_texture_rect(special_texture, rect, false)
			continue
		
		match type:
			GridSystem.SpecialTileType.KILL:
				# Red translucent overlay with a warning pattern
				draw_rect(rect, Color(1.0, 0.0, 0.0, 0.3), true)
				# Draw an X
				var padding: float = _tile_size * 0.2
				draw_line(rect.position + Vector2(padding, padding), rect.end - Vector2(padding, padding), Color.WHITE, 2.0)
				draw_line(rect.position + Vector2(rect.size.x - padding, padding), rect.position + Vector2(padding, rect.size.y - padding), Color.WHITE, 2.0)
				
			GridSystem.SpecialTileType.STOP_TILE:
				# Green circle in the middle
				var center: Vector2 = rect.get_center()
				var radius: float = _tile_size * 0.3
				draw_circle(center, radius, Color(0.0, 1.0, 0.0, 0.5))
				draw_arc(center, radius, 0, TAU, 32, Color.WHITE, 2.0)
				
			GridSystem.SpecialTileType.ONE_WAY_UP, \
			GridSystem.SpecialTileType.ONE_WAY_DOWN, \
			GridSystem.SpecialTileType.ONE_WAY_LEFT, \
			GridSystem.SpecialTileType.ONE_WAY_RIGHT:
				# Directional arrow
				var center: Vector2 = rect.get_center()
				var arrow_size: float = _tile_size * 0.4
				var direction: Vector2 = Vector2.ZERO
				match type:
					GridSystem.SpecialTileType.ONE_WAY_UP: direction = Vector2.UP
					GridSystem.SpecialTileType.ONE_WAY_DOWN: direction = Vector2.DOWN
					GridSystem.SpecialTileType.ONE_WAY_LEFT: direction = Vector2.LEFT
					GridSystem.SpecialTileType.ONE_WAY_RIGHT: direction = Vector2.RIGHT
				
				var tip: Vector2 = center + direction * arrow_size * 0.5
				var base: Vector2 = center - direction * arrow_size * 0.5
				draw_line(base, tip, Color.WHITE, 3.0)
				# Draw arrow head
				var perp := Vector2(-direction.y, direction.x) * arrow_size * 0.2
				draw_line(tip, tip - direction * arrow_size * 0.3 + perp, Color.WHITE, 3.0)
				draw_line(tip, tip - direction * arrow_size * 0.3 - perp, Color.WHITE, 3.0)
