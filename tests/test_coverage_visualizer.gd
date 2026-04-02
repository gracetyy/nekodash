## Tests for CoverageVisualizer — visual-only coverage overlay.
## Implements: design/gdd/coverage-tracking.md (CoverageVisualizer spec)
## Task: S2-08
extends GutTest


# —————————————————————————————————————————————
# Instance
# —————————————————————————————————————————————

var _vis: CoverageVisualizer


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_vis = CoverageVisualizer.new()
	add_child_autofree(_vis)


# —————————————————————————————————————————————
# initialize_level
# —————————————————————————————————————————————

func test_initialize_level_sets_initialized() -> void:
	assert_false(_vis.is_initialized(), "Should not be initialized before call")
	_vis.initialize_level(5, 5)
	assert_true(_vis.is_initialized(), "Should be initialized after call")


func test_initialize_level_resets_covered_count() -> void:
	_vis.initialize_level(3, 3)
	_vis.on_tile_covered(Vector2i(0, 0))
	_vis.on_tile_covered(Vector2i(1, 0))
	assert_eq(_vis.get_covered_tile_count(), 2)

	_vis.initialize_level(3, 3)
	assert_eq(_vis.get_covered_tile_count(), 0, "Reinitialize should clear tiles")


# —————————————————————————————————————————————
# on_tile_covered
# —————————————————————————————————————————————

func test_tile_covered_increments_count() -> void:
	_vis.initialize_level(4, 4)
	_vis.on_tile_covered(Vector2i(1, 1))
	assert_eq(_vis.get_covered_tile_count(), 1)

	_vis.on_tile_covered(Vector2i(2, 1))
	assert_eq(_vis.get_covered_tile_count(), 2)


func test_tile_covered_idempotent() -> void:
	_vis.initialize_level(4, 4)
	_vis.on_tile_covered(Vector2i(1, 1))
	_vis.on_tile_covered(Vector2i(1, 1))
	assert_eq(_vis.get_covered_tile_count(), 1, "Covering same tile twice should count once")


# —————————————————————————————————————————————
# on_tile_uncovered
# —————————————————————————————————————————————

func test_tile_uncovered_decrements_count() -> void:
	_vis.initialize_level(4, 4)
	_vis.on_tile_covered(Vector2i(1, 1))
	_vis.on_tile_covered(Vector2i(2, 1))
	assert_eq(_vis.get_covered_tile_count(), 2)

	_vis.on_tile_uncovered(Vector2i(1, 1))
	assert_eq(_vis.get_covered_tile_count(), 1)


func test_tile_uncovered_on_absent_tile_is_safe() -> void:
	_vis.initialize_level(4, 4)
	_vis.on_tile_uncovered(Vector2i(9, 9))
	assert_eq(_vis.get_covered_tile_count(), 0, "Uncovering absent tile should not crash")


# —————————————————————————————————————————————
# on_spawn_position_set
# —————————————————————————————————————————————

func test_spawn_position_marks_tile_covered() -> void:
	_vis.initialize_level(4, 4)
	_vis.on_spawn_position_set(Vector2i(1, 1))
	assert_eq(_vis.get_covered_tile_count(), 1, "Spawn tile should be covered")


func test_spawn_then_cover_is_still_one_tile() -> void:
	_vis.initialize_level(4, 4)
	_vis.on_spawn_position_set(Vector2i(1, 1))
	_vis.on_tile_covered(Vector2i(1, 1))
	assert_eq(_vis.get_covered_tile_count(), 1, "Spawn + cover same tile = 1")


# —————————————————————————————————————————————
# Full undo scenario
# —————————————————————————————————————————————

func test_cover_then_uncover_all_returns_to_zero() -> void:
	_vis.initialize_level(3, 3)
	_vis.on_spawn_position_set(Vector2i(0, 0))
	_vis.on_tile_covered(Vector2i(1, 0))
	_vis.on_tile_covered(Vector2i(2, 0))
	assert_eq(_vis.get_covered_tile_count(), 3)

	_vis.on_tile_uncovered(Vector2i(2, 0))
	_vis.on_tile_uncovered(Vector2i(1, 0))
	assert_eq(_vis.get_covered_tile_count(), 1, "Only spawn tile remains")


# —————————————————————————————————————————————
# Restart scenario (via tile_uncovered signals from reset_coverage)
# CoverageTracking.reset_coverage() emits tile_uncovered for each covered
# tile, which CoverageVisualizer handles via the existing on_tile_uncovered.
# spawn_position_set then re-colors the spawn tile.
# —————————————————————————————————————————————

func test_tile_uncovered_clears_all_covered_tiles() -> void:
	_vis.initialize_level(4, 4)
	_vis.on_spawn_position_set(Vector2i(0, 0))
	_vis.on_tile_covered(Vector2i(1, 0))
	_vis.on_tile_covered(Vector2i(2, 0))
	assert_eq(_vis.get_covered_tile_count(), 3)

	_vis.on_tile_uncovered(Vector2i(0, 0))
	_vis.on_tile_uncovered(Vector2i(1, 0))
	_vis.on_tile_uncovered(Vector2i(2, 0))
	assert_eq(_vis.get_covered_tile_count(), 0, "All tiles cleared via tile_uncovered")


func test_restart_flow_spawn_only_after_uncover_all() -> void:
	# Simulates: tile_uncovered × N (from reset_coverage) → spawn_position_set
	_vis.initialize_level(4, 4)
	_vis.on_spawn_position_set(Vector2i(0, 0))
	_vis.on_tile_covered(Vector2i(1, 0))
	_vis.on_tile_covered(Vector2i(2, 0))

	# reset_coverage emits tile_uncovered for each covered tile
	_vis.on_tile_uncovered(Vector2i(0, 0))
	_vis.on_tile_uncovered(Vector2i(1, 0))
	_vis.on_tile_uncovered(Vector2i(2, 0))
	# spawn_position_set re-fires for the spawn tile
	_vis.on_spawn_position_set(Vector2i(0, 0))
	assert_eq(_vis.get_covered_tile_count(), 1, "Only spawn tile colored after restart")
