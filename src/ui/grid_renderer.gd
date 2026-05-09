## GridRenderer — visual grid drawing for the gameplay scene.
## Task: S2-05 (visual layer)
##
## Pure display node. Reads from GridSystem autoload to draw the grid.
## Coverage overlay is handled by CoverageVisualizer (S2-08).
## Owns no game state.
extends Node2D

const HomeTileArtScript = preload("res://src/ui/home_tile_art.gd")


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

signal entry_reveal_finished


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

var _tile_size: int = 72

## Pixel offset applied to center the grid on screen, below the HUD.
var _grid_offset: Vector2 = Vector2.ZERO
var _current_level_data: LevelData
var _render_layout: Dictionary = {}
var _entry_reveal_active: bool = false
var _entry_reveal_root: Node2D
var _entry_reveal_tween: Tween

const ENTRY_REVEAL_TOTAL_SEC: float = 0.9
const ENTRY_REVEAL_TILE_SCALE_SEC: float = 0.28


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
	
	# Scale layout gutters with the viewport so shorter web windows do not
	# starve the board of vertical space and shrink the cat/grid too aggressively.
	var hud_top_margin: float = clampf(viewport_h * 0.15, 96.0, 160.0)
	var bottom_margin: float = clampf(viewport_h * 0.06, 32.0, 64.0)
	var horizontal_padding: float = clampf(viewport_w * 0.04, 24.0, 48.0)
	
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
	if _entry_reveal_active:
		_finish_entry_reveal()
	else:
		_clear_entry_reveal(true)

	queue_redraw()


## Returns the computed grid offset for the parent coordinator to position itself.
func get_grid_offset() -> Vector2:
	return _grid_offset


## Returns the current tile size.
func get_tile_size() -> int:
	return _tile_size


## Returns the current render layout.
func get_render_layout() -> Dictionary:
	return _render_layout


func play_entry_reveal() -> void:
	var grid_w: int = GridSystem.get_width()
	var grid_h: int = GridSystem.get_height()
	if grid_w == 0 or grid_h == 0:
		entry_reveal_finished.emit()
		return

	var max_sum: int = grid_w + grid_h - 2
	var total_duration: float = ENTRY_REVEAL_TOTAL_SEC
	var scale_duration: float = minf(ENTRY_REVEAL_TILE_SCALE_SEC, total_duration)
	var delay_per_diag: float = 0.0
	if max_sum > 0:
		delay_per_diag = max(0.0, (total_duration - scale_duration) / float(max_sum))

	_clear_entry_reveal(true)
	_entry_reveal_active = true

	_entry_reveal_root = Node2D.new()
	_entry_reveal_root.name = "EntryReveal"
	add_child(_entry_reveal_root)

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

	_entry_reveal_tween = create_tween()
	_entry_reveal_tween.set_parallel(true)

	var reveal_count: int = 0
	for row: int in range(grid_h):
		for col: int in range(grid_w):
			var coord := Vector2i(col, row)
			var center: Vector2 = Vector2(
				(col + 0.5) * _tile_size,
				(row + 0.5) * _tile_size
			)
			var delay: float = float(coord.x + coord.y) * delay_per_diag
			if GridSystem.is_walkable(coord):
				reveal_count += _make_entry_reveal_sprite(
					floor_texture,
					center,
					Vector2(_tile_size, _tile_size),
					0,
					delay,
					scale_duration,
					_entry_reveal_tween
				)
			elif not use_simple_ui:
				reveal_count += _make_entry_reveal_sprite(
					visited_texture,
					center,
					Vector2(_tile_size, _tile_size),
					0,
					delay,
					scale_duration,
					_entry_reveal_tween
				)
			else:
				reveal_count += _make_entry_reveal_sprite(
					blocking_texture,
					center,
					Vector2(_tile_size, _tile_size),
					0,
					delay,
					scale_duration,
					_entry_reveal_tween
				)

	if not use_simple_ui:
		for wall_draw: Dictionary in _render_layout.get("wall_draws", []):
			var wall_coord: Vector2i = wall_draw.get("coord", Vector2i.ZERO) as Vector2i
			var wall_texture: Texture2D = wall_draw.get("texture", blocking_texture) as Texture2D
			var wall_center: Vector2 = Vector2(
				(wall_coord.x + 0.5) * _tile_size,
				(wall_coord.y + 0.5) * _tile_size
			)
			var wall_delay: float = float(wall_coord.x + wall_coord.y) * delay_per_diag
			reveal_count += _make_entry_reveal_sprite(
				wall_texture,
				wall_center,
				Vector2(_tile_size, _tile_size),
				10,
				wall_delay,
				scale_duration,
				_entry_reveal_tween
			)

		for obstacle_draw: Dictionary in _render_layout.get("obstacles", []):
			var origin: Vector2i = obstacle_draw.get("origin", Vector2i.ZERO) as Vector2i
			var size: Vector2i = obstacle_draw.get("size", Vector2i.ONE) as Vector2i
			for offset_y: int in range(size.y):
				for offset_x: int in range(size.x):
					var tile_center: Vector2 = Vector2(
						(origin.x + offset_x + 0.5) * _tile_size,
						(origin.y + offset_y + 0.5) * _tile_size
					)
					var tile_delay: float = float(origin.x + offset_x + origin.y + offset_y) * delay_per_diag
					reveal_count += _make_entry_reveal_sprite(
						visited_texture,
						tile_center,
						Vector2(_tile_size, _tile_size),
						20,
						tile_delay,
						scale_duration,
						_entry_reveal_tween
					)

			var obstacle_texture: Texture2D = obstacle_draw.get("texture", blocking_texture) as Texture2D
			var obstacle_center: Vector2 = Vector2(
				(origin.x + size.x * 0.5) * _tile_size,
				(origin.y + size.y * 0.5) * _tile_size
			)
			var obstacle_delay: float = float(origin.x + origin.y) * delay_per_diag
			var obstacle_size: Vector2 = Vector2(size.x * _tile_size, size.y * _tile_size)
			reveal_count += _make_entry_reveal_sprite(
				obstacle_texture,
				obstacle_center,
				obstacle_size,
				21,
				obstacle_delay,
				scale_duration,
				_entry_reveal_tween
			)

			var tabletop_texture: Texture2D = obstacle_draw.get("tabletop_texture", null) as Texture2D
			if tabletop_texture != null:
				var tabletop_size: Vector2 = Vector2.ONE * (_tile_size * 0.5)
				var asset_name: String = str(obstacle_draw.get("asset_name", "")).to_lower()
				var tabletop_origin: Vector2i = obstacle_draw.get("origin", Vector2i.ZERO) as Vector2i
				var is_shelf: bool = asset_name.find("shelf") >= 0
				var tabletop_seed: String = "%s|%d|%d|%d|%d" % [asset_name, tabletop_origin.x, tabletop_origin.y, size.x, size.y]
				var obstacle_rect := Rect2(
					origin.x * _tile_size,
					origin.y * _tile_size,
					size.x * _tile_size,
					size.y * _tile_size,
				)
				var max_offset_x: float = max(0.0, obstacle_rect.size.x - tabletop_size.x)
				var max_offset_y: float = max(0.0, obstacle_rect.size.y - tabletop_size.y)
				if is_shelf:
					max_offset_y *= 0.25
				var offset_x: float = max_offset_x * float(abs((tabletop_seed + "|x").hash()) % 1000) / 999.0
				var offset_y: float = max_offset_y * float(abs((tabletop_seed + "|y").hash()) % 1000) / 999.0
				var tabletop_rect := Rect2(
					obstacle_rect.position + Vector2(offset_x, offset_y),
					tabletop_size,
				)
				reveal_count += _make_entry_reveal_sprite(
					tabletop_texture,
					tabletop_rect.get_center(),
					tabletop_rect.size,
					22,
					obstacle_delay,
					scale_duration,
					_entry_reveal_tween
				)

	if reveal_count == 0:
		_finish_entry_reveal()
		return

	_entry_reveal_tween.finished.connect(_finish_entry_reveal, Object.CONNECT_ONE_SHOT)
	queue_redraw()


func skip_entry_reveal() -> void:
	if not _entry_reveal_active:
		return
	_finish_entry_reveal()


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

	if _entry_reveal_active and _entry_reveal_root != null:
		return

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


func _make_entry_reveal_sprite(
	texture: Texture2D,
	center: Vector2,
	size: Vector2,
	z_index: int,
	delay: float,
	duration: float,
	tween: Tween
) -> int:
	if texture == null or _entry_reveal_root == null:
		return 0
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = center
	sprite.z_index = z_index
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		tex_size = Vector2.ONE
	var target_scale: Vector2 = Vector2(size.x / tex_size.x, size.y / tex_size.y)
	sprite.scale = Vector2.ZERO
	_entry_reveal_root.add_child(sprite)
	tween.tween_property(sprite, "scale", target_scale, duration) \
		.set_trans(Tween.TRANS_SPRING).set_delay(delay)
	return 1


func _finish_entry_reveal() -> void:
	if not _entry_reveal_active:
		return
	_clear_entry_reveal(true)
	queue_redraw()
	entry_reveal_finished.emit()


func _clear_entry_reveal(reset_progress: bool) -> void:
	if _entry_reveal_tween != null and _entry_reveal_tween.is_valid():
		_entry_reveal_tween.kill()
	_entry_reveal_tween = null

	if _entry_reveal_root != null and is_instance_valid(_entry_reveal_root):
		_entry_reveal_root.queue_free()
	_entry_reveal_root = null

	if reset_progress:
		_entry_reveal_active = false
