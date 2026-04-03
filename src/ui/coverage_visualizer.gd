## CoverageVisualizer — visual-only tile highlight overlay.
## Implements: design/gdd/coverage-tracking.md (CoverageVisualizer spec)
## Task: S2-08
##
## Subscribes to CoverageTracking signals (tile_covered, tile_uncovered) via
## Level Coordinator wiring. Renders covered tiles as colored rects. Contains
## no game logic — purely display.
##
## Usage:
##   coverage_visualizer.initialize_level(grid_width, grid_height)
##   # Coordinator wires tile_covered / tile_uncovered / spawn_position_set
class_name CoverageVisualizer
extends Node2D


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

## Color drawn on covered tiles — grid-trail #FBD490.
const COLOR_COVERED: Color = Color(0.984, 0.831, 0.565, 0.6)


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

## Visual-state dictionary: Vector2i → bool. Driven entirely by signals.
var _tile_states: Dictionary = {}

## Tile size in pixels — matches GridSystem.
var _tile_size: int = 64

## Whether the visualizer has been initialized for the current level.
var _initialized: bool = false


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Resets visual state for a new level. Called by Level Coordinator before
## signals start firing.
func initialize_level(_grid_width: int, _grid_height: int) -> void:
	_tile_size = GridSystem.DEFAULT_TILE_SIZE_PX
	_tile_states.clear()
	_initialized = true
	queue_redraw()


## Returns whether the visualizer has been initialized.
func is_initialized() -> bool:
	return _initialized


## Returns the number of tiles currently shown as covered.
func get_covered_tile_count() -> int:
	var count: int = 0
	for val: bool in _tile_states.values():
		if val:
			count += 1
	return count


# —————————————————————————————————————————————
# Signal handlers (wired by Level Coordinator)
# —————————————————————————————————————————————

## Marks a tile as visually covered. Wired to CoverageTracking.tile_covered.
func on_tile_covered(coord: Vector2i) -> void:
	_tile_states[coord] = true
	queue_redraw()


## Marks a tile as visually uncovered. Wired to CoverageTracking.tile_uncovered.
func on_tile_uncovered(coord: Vector2i) -> void:
	_tile_states[coord] = false
	queue_redraw()


## Marks the spawn tile as covered immediately. Wired to
## SlidingMovement.spawn_position_set.
func on_spawn_position_set(pos: Vector2i) -> void:
	_tile_states[pos] = true
	queue_redraw()


# —————————————————————————————————————————————
# Drawing
# —————————————————————————————————————————————

func _draw() -> void:
	if not _initialized:
		return

	for coord: Vector2i in _tile_states:
		if _tile_states[coord]:
			var rect := Rect2(
				coord.x * _tile_size,
				coord.y * _tile_size,
				_tile_size,
				_tile_size,
			)
			draw_rect(rect, COLOR_COVERED, true)
