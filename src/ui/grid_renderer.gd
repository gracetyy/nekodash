## GridRenderer — visual grid drawing for the gameplay scene.
## Task: S2-05 (visual layer)
##
## Pure display node. Reads from GridSystem autoload to draw the grid.
## Coverage overlay is handled by CoverageVisualizer (S2-08).
## Owns no game state.
extends Node2D

const HomeTileArtScript = preload("res://src/ui/home_tile_art.gd")


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

var _tile_size: int = 72

## Pixel offset applied to center the grid on screen, below the HUD.
var _grid_offset: Vector2 = Vector2.ZERO
var _current_level_data: LevelData
var _render_layout: Dictionary = {}


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Redraws the grid from GridSystem state and computes centering offset.
func render_grid(level_data: LevelData = null) -> void:
	if level_data != null:
		_current_level_data = level_data
	
	var grid_w: int = GridSystem.get_width()
	var grid_h: int = GridSystem.get_height()
	
	if grid_w == 0 or grid_h == 0:
		return

	var viewport_w: float = get_viewport_rect().size.x
	var viewport_h: float = get_viewport_rect().size.y
	
	# Spacing settings
	var hud_top_margin: float = 160.0
	var bottom_margin: float = 64.0
	var horizontal_padding: float = 48.0
	
	var available_w: float = viewport_w - horizontal_padding * 2.0
	var available_h: float = viewport_h - hud_top_margin - bottom_margin
	
	var max_tile_w: float = available_w / float(grid_w)
	var max_tile_h: float = available_h / float(grid_h)
	
	# Target tile size is the smaller of the two dimensions, clamped to reasonable range
	var target_tile_size: int = int(floor(minf(max_tile_w, max_tile_h)))
	# We want to keep it close to 72 if possible, but allow shrinking/growing
	target_tile_size = clampi(target_tile_size, 32, 128)
	
	_tile_size = target_tile_size
	GridSystem.set_tile_size(_tile_size)

	# Compute centering offset
	var grid_w_px: float = grid_w * _tile_size
	var grid_h_px: float = grid_h * _tile_size

	var x_offset: float = (viewport_w - grid_w_px) / 2.0
	var y_offset: float = hud_top_margin + (available_h - grid_h_px) / 2.0
	_grid_offset = Vector2(x_offset, y_offset)
	
	_render_layout = HomeTileArtScript.build_layout(
		_current_level_data,
		HomeTileArtScript.is_simple_ui_enabled()
	)

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

	var floor_texture: Texture2D = _render_layout.get(
		"floor_texture",
		HomeTileArtScript.SIMPLE_FLOOR_TEXTURE
	) as Texture2D
	var visited_texture: Texture2D = _render_layout.get(
		"visited_texture",
		HomeTileArtScript.SIMPLE_VISITED_TEXTURE
	) as Texture2D
	var blocking_texture: Texture2D = _render_layout.get(
		"blocking_texture",
		HomeTileArtScript.SIMPLE_BLOCKING_TEXTURE
	) as Texture2D
	var use_simple_ui: bool = _render_layout.get("simple_ui", false) as bool

	# Draw walkable floor first. Covered tiles are painted by CoverageVisualizer.
	for row: int in range(h):
		for col: int in range(w):
			var coord := Vector2i(col, row)
			var rect := Rect2(col * _tile_size, row * _tile_size, _tile_size, _tile_size)
			if GridSystem.is_walkable(coord):
				draw_texture_rect(floor_texture, rect, false)
			elif not use_simple_ui:
				draw_texture_rect(visited_texture, rect, false)
			elif use_simple_ui:
				draw_texture_rect(blocking_texture, rect, false)

	if use_simple_ui:
		return

	for wall_draw: Dictionary in _render_layout.get("wall_draws", []):
		var wall_coord: Vector2i = wall_draw.get("coord", Vector2i.ZERO) as Vector2i
		var wall_texture: Texture2D = wall_draw.get("texture", blocking_texture) as Texture2D
		var wall_rect := Rect2(
			wall_coord.x * _tile_size,
			wall_coord.y * _tile_size,
			_tile_size,
			_tile_size,
		)
		draw_texture_rect(wall_texture, wall_rect, false)

	for obstacle_draw: Dictionary in _render_layout.get("obstacles", []):
		var origin: Vector2i = obstacle_draw.get("origin", Vector2i.ZERO) as Vector2i
		var size: Vector2i = obstacle_draw.get("size", Vector2i.ONE) as Vector2i
		for offset_y: int in range(size.y):
			for offset_x: int in range(size.x):
				var floor_rect := Rect2(
					(origin.x + offset_x) * _tile_size,
					(origin.y + offset_y) * _tile_size,
					_tile_size,
					_tile_size,
				)
				draw_texture_rect(visited_texture, floor_rect, false)

		var obstacle_texture: Texture2D = obstacle_draw.get("texture", blocking_texture) as Texture2D
		var obstacle_rect := Rect2(
			origin.x * _tile_size,
			origin.y * _tile_size,
			size.x * _tile_size,
			size.y * _tile_size,
		)
		draw_texture_rect(obstacle_texture, obstacle_rect, false)

		var tabletop_texture: Texture2D = obstacle_draw.get("tabletop_texture", null) as Texture2D
		if tabletop_texture == null:
			continue

		var tabletop_size: Vector2 = Vector2.ONE * (_tile_size * 0.5)
		var asset_name: String = str(obstacle_draw.get("asset_name", "")).to_lower()
		var tabletop_origin: Vector2i = obstacle_draw.get("origin", Vector2i.ZERO) as Vector2i
		var is_shelf: bool = asset_name.find("shelf") >= 0
		var tabletop_seed: String = "%s|%d|%d|%d|%d" % [asset_name, tabletop_origin.x, tabletop_origin.y, size.x, size.y]
		var max_offset_x: float = max(0.0, obstacle_rect.size.x - tabletop_size.x)
		var max_offset_y: float = max(0.0, obstacle_rect.size.y - tabletop_size.y)
		if is_shelf:
			# Shelves only allow decor in the upper quarter; tables can use the full top surface.
			max_offset_y *= 0.25
		var offset_x: float = max_offset_x * float(abs((tabletop_seed + "|x").hash()) % 1000) / 999.0
		var offset_y: float = max_offset_y * float(abs((tabletop_seed + "|y").hash()) % 1000) / 999.0
		var tabletop_rect := Rect2(
			obstacle_rect.position + Vector2(offset_x, offset_y),
			tabletop_size,
		)
		draw_texture_rect(tabletop_texture, tabletop_rect, false)

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
