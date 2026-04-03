# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can GridSystem + SlidingMovement + CoverageTracking + MoveCounter
#           wire together into a playable end-to-end level?
# Date: 2026-04-01
extends Node2D

@onready var grid_renderer: Node2D = $GridRenderer
@onready var sliding_movement: Node2D = $SlidingMovement
@onready var coverage_tracking: Node = $CoverageTracking
@onready var move_counter: Node = $MoveCounter
@onready var hud: Node2D = $HUD

# Hardcoded level path for prototype
var _level_path: String = "res://data/levels/world1/w1_l2.tres"


func _ready() -> void:
	var level_data: LevelData = load(_level_path) as LevelData
	if level_data == null:
		push_error("GameplayScene: Failed to load level: " + _level_path)
		return

	# 1. Load grid into autoload
	GridSystem.load_grid(level_data)

	# 2. Initialize state systems (before triggering events)
	coverage_tracking.initialize_level()
	move_counter.initialize_level(level_data)

	# 3. Wire signals BEFORE sliding_movement init so spawn_position_set is received
	# Order matters: MoveCounter BEFORE CoverageTracking so the count is correct
	# when level_completed fires (see design/gdd/level-coordinator.md)
	move_counter.bind_sliding_movement(sliding_movement)
	coverage_tracking.bind_sliding_movement(sliding_movement)

	# 4. Now initialize sliding — emits spawn_position_set, caught by coverage_tracking
	sliding_movement.initialize_level(level_data.cat_start)

	# 4. Listen for completion
	coverage_tracking.level_completed.connect(_on_level_completed)

	# 5. Listen for coverage updates to repaint grid overlay + update HUD
	coverage_tracking.tile_covered.connect(_on_tile_covered)
	coverage_tracking.coverage_updated.connect(_on_coverage_updated)

	# 6. Listen for move count changes to update HUD
	move_counter.move_count_changed.connect(_on_move_count_changed)

	# 7. Initial grid render (grid_renderer stays at (0,0) to match grid_to_pixel coords)
	grid_renderer.render_grid()
	grid_renderer.mark_covered(level_data.cat_start)

	# 8. Position HUD below grid area
	var grid_pixel_height: float = level_data.grid_height * 64.0
	hud.position = Vector2(0, grid_pixel_height + 20)

	# 9. HUD initial state
	hud.update_moves(0, level_data.minimum_moves)
	hud.update_coverage(coverage_tracking.get_covered_count(), coverage_tracking.get_total_walkable())

	print("[GameplayScene] Level '%s' loaded — %d walkable tiles, %d minimum moves" % [
		level_data.display_name,
		coverage_tracking.get_total_walkable(),
		level_data.minimum_moves
	])


func _on_tile_covered(coord: Vector2i) -> void:
	grid_renderer.mark_covered(coord)


func _on_coverage_updated(covered: int, total: int) -> void:
	hud.update_coverage(covered, total)


func _on_move_count_changed(current_moves: int, minimum_moves: int) -> void:
	hud.update_moves(current_moves, minimum_moves)


func _on_level_completed() -> void:
	print("[GameplayScene] LEVEL COMPLETE! Moves: %d / Minimum: %d" % [
		move_counter.get_current_moves(),
		move_counter.get_minimum_moves()
	])
	hud.show_complete_message(
		move_counter.get_current_moves(),
		move_counter.get_minimum_moves()
	)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_R:
			_restart_level()
		KEY_1:
			_level_path = "res://data/levels/world1/w1_l1.tres"
			_restart_level()
		KEY_2:
			_level_path = "res://data/levels/world1/w1_l2.tres"
			_restart_level()
		KEY_3:
			_level_path = "res://data/levels/world1/w1_l3.tres"
			_restart_level()


func _restart_level() -> void:
	coverage_tracking.unbind_sliding_movement(sliding_movement)
	move_counter.unbind_sliding_movement(sliding_movement)

	var level_data: LevelData = load(_level_path) as LevelData
	if level_data == null:
		push_error("GameplayScene: Failed to load level: " + _level_path)
		return
	GridSystem.load_grid(level_data)
	coverage_tracking.initialize_level()
	move_counter.initialize_level(level_data)
	# Order matters: MoveCounter BEFORE CoverageTracking (see _ready)
	move_counter.bind_sliding_movement(sliding_movement)
	coverage_tracking.bind_sliding_movement(sliding_movement)
	sliding_movement.initialize_level(level_data.cat_start)

	grid_renderer.render_grid()
	grid_renderer.mark_covered(level_data.cat_start)
	hud.position = Vector2(0, level_data.grid_height * 64.0 + 20)
	hud.update_moves(0, level_data.minimum_moves)
	hud.update_coverage(coverage_tracking.get_covered_count(), coverage_tracking.get_total_walkable())
	hud.hide_complete_message()

	print("[GameplayScene] Restarted level: " + level_data.display_name)
