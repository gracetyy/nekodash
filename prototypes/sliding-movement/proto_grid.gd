# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does slide-until-wall movement feel satisfying on mobile touch input?
# Date: 2026-03-31
#
# Minimal grid: 2D dictionary of Vector2i -> bool (true = walkable).
# Hardcoded 7x7 grid with interior walls for testing slide distances.

extends Node2D

const TILE_SIZE: int = 64
const GRID_WIDTH: int = 7
const GRID_HEIGHT: int = 7

# Grid data: true = walkable, false = wall
var _grid: Dictionary = {}

# Colors
const COLOR_WALKABLE := Color(0.92, 0.92, 0.88) # warm off-white
const COLOR_WALL := Color(0.25, 0.22, 0.28) # dark purple-grey
const COLOR_COVERED := Color(1.0, 0.85, 0.4, 0.6) # warm gold overlay
const COLOR_GRID_LINE := Color(0.8, 0.78, 0.74) # subtle grid line

var _covered_tiles: Dictionary = {}


func _ready() -> void:
	_build_grid()


func _build_grid() -> void:
	# Start with all walkable
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			_grid[Vector2i(x, y)] = true

	# Add border walls
	for x in range(GRID_WIDTH):
		_grid[Vector2i(x, 0)] = false
		_grid[Vector2i(x, GRID_HEIGHT - 1)] = false
	for y in range(GRID_HEIGHT):
		_grid[Vector2i(0, y)] = false
		_grid[Vector2i(GRID_WIDTH - 1, y)] = false

	# Interior walls — verified solvable in 13 moves
	# Solution: R D R U L R D U L D L D R
	_grid[Vector2i(3, 1)] = false # top-center wall
	_grid[Vector2i(1, 3)] = false # left-mid wall
	_grid[Vector2i(4, 5)] = false # bottom-right wall


func is_walkable(coord: Vector2i) -> bool:
	if not _grid.has(coord):
		return false
	return _grid[coord]


func get_all_walkable() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord: Vector2i in _grid:
		if _grid[coord]:
			result.append(coord)
	return result


func grid_to_pixel(coord: Vector2i) -> Vector2:
	return Vector2(coord) * TILE_SIZE + Vector2.ONE * (TILE_SIZE * 0.5)


func mark_covered(coord: Vector2i) -> void:
	_covered_tiles[coord] = true
	queue_redraw()


func mark_tiles_covered(tiles: Array[Vector2i]) -> void:
	for t: Vector2i in tiles:
		_covered_tiles[t] = true
	queue_redraw()


func reset_coverage() -> void:
	_covered_tiles.clear()
	queue_redraw()


func _draw() -> void:
	# Draw tiles
	for coord: Vector2i in _grid:
		var rect := Rect2(Vector2(coord) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
		if _grid[coord]:
			draw_rect(rect, COLOR_WALKABLE)
			# Grid lines
			draw_rect(rect, COLOR_GRID_LINE, false, 1.0)
		else:
			draw_rect(rect, COLOR_WALL)

	# Draw coverage overlay
	for coord: Vector2i in _covered_tiles:
		var rect := Rect2(Vector2(coord) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
		draw_rect(rect, COLOR_COVERED)
