## Unit tests for LevelCompleteScreen UI node.
## Task: S2-06
## Covers: receive_scene_params, populate_results, star display, move count
##         display, new best badge, next button visibility, button handlers,
##         sentinel stars (-1), minimum_moves == 0 display, edge cases.
##
## Acceptance criteria cross-ref: design/gdd/level-complete-screen.md
extends GutTest

## Matches LevelCompleteScreen star color constants (design system tokens).
const STAR_EARNED_COLOR: Color = Color(0.961, 0.784, 0.259, 1.0)  # star-filled #F5C842
const STAR_UNEARNED_COLOR: Color = Color(0.784, 0.769, 0.816, 1.0)  # star-empty #C8C4D0

var _screen: Control # LevelCompleteScreen instance under test

# Mock UI nodes
var _level_name_label: Label
var _moves_label: Label
var _new_best_badge: Label
var _next_btn: Button
var _retry_btn: Button
var _world_map_btn: Button
var _star_1: Label
var _star_2: Label
var _star_3: Label
var _star_sentinel: Label

# Signal tracking
var _next_level_log: Array[LevelData] = []
var _retry_log: Array[LevelData] = []
var _world_map_count: int = 0


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	_screen = load("res://src/ui/level_complete_screen.gd").new()
	add_child_autofree(_screen)

	# Create mock UI nodes
	_level_name_label = Label.new()
	add_child_autofree(_level_name_label)

	_moves_label = Label.new()
	add_child_autofree(_moves_label)

	_new_best_badge = Label.new()
	_new_best_badge.text = "NEW BEST!"
	add_child_autofree(_new_best_badge)

	_next_btn = Button.new()
	add_child_autofree(_next_btn)

	_retry_btn = Button.new()
	add_child_autofree(_retry_btn)

	_world_map_btn = Button.new()
	add_child_autofree(_world_map_btn)

	_star_1 = Label.new()
	_star_1.text = "★"
	add_child_autofree(_star_1)

	_star_2 = Label.new()
	_star_2.text = "★"
	add_child_autofree(_star_2)

	_star_3 = Label.new()
	_star_3.text = "★"
	add_child_autofree(_star_3)

	_star_sentinel = Label.new()
	add_child_autofree(_star_sentinel)

	var stars: Array[Control] = [_star_1, _star_2, _star_3]
	_screen.set_ui_nodes(
		_level_name_label,
		_moves_label,
		_new_best_badge,
		_next_btn,
		_retry_btn,
		_world_map_btn,
		stars,
		_star_sentinel,
	)

	# Reset tracking
	_next_level_log.clear()
	_retry_log.clear()
	_world_map_count = 0

	_screen.next_level_requested.connect(_on_next_level)
	_screen.retry_requested.connect(_on_retry)
	_screen.world_map_requested.connect(_on_world_map)


# —————————————————————————————————————————————
# Signal receivers
# —————————————————————————————————————————————

func _on_next_level(ld: LevelData) -> void:
	_next_level_log.append(ld)


func _on_retry(ld: LevelData) -> void:
	_retry_log.append(ld)


func _on_world_map() -> void:
	_world_map_count += 1


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

func _make_level_data(
	level_id: String = "w1_l1",
	display_name: String = "Test Level",
	minimum_moves: int = 8,
) -> LevelData:
	var ld := LevelData.new()
	ld.level_id = level_id
	ld.display_name = display_name
	ld.minimum_moves = minimum_moves
	ld.grid_width = 3
	ld.grid_height = 3
	ld.star_3_moves = minimum_moves
	ld.star_2_moves = minimum_moves + 2 if minimum_moves > 0 else 0
	ld.star_1_moves = minimum_moves + 4 if minimum_moves > 0 else 0
	return ld


func _standard_params(overrides: Dictionary = {}) -> Dictionary:
	var ld: LevelData = overrides.get("level_data", _make_level_data())
	var base: Dictionary = {
		"level_data": ld,
		"stars": overrides.get("stars", 3),
		"final_moves": overrides.get("final_moves", 8),
		"prev_best_moves": overrides.get("prev_best_moves", 0),
		"was_previously_completed": overrides.get("was_previously_completed", false),
		"next_level_data": overrides.get("next_level_data", _make_level_data("w1_l2", "Next Level")),
	}
	return base


func _init_screen(overrides: Dictionary = {}) -> void:
	_screen.receive_scene_params(_standard_params(overrides))
	_screen.populate_results()


# —————————————————————————————————————————————
# Scene Params Tests
# —————————————————————————————————————————————

func test_receive_scene_params_sets_flag() -> void:
	_screen.receive_scene_params(_standard_params())
	assert_true(_screen.has_params())


func test_params_not_received_by_default() -> void:
	assert_false(_screen.has_params())


func test_receive_params_stores_stars() -> void:
	_screen.receive_scene_params(_standard_params({"stars": 2}))
	assert_eq(_screen.get_stars(), 2)


func test_receive_params_stores_final_moves() -> void:
	_screen.receive_scene_params(_standard_params({"final_moves": 12}))
	assert_eq(_screen.get_final_moves(), 12)


func test_receive_params_stores_level_data() -> void:
	var ld := _make_level_data("special", "Special")
	_screen.receive_scene_params(_standard_params({"level_data": ld}))
	assert_eq(_screen.get_level_data(), ld)


func test_receive_params_stores_next_level_data() -> void:
	var next := _make_level_data("w1_l3", "Level 3")
	_screen.receive_scene_params(_standard_params({"next_level_data": next}))
	assert_eq(_screen.get_next_level_data(), next)


func test_receive_params_null_next_level() -> void:
	_screen.receive_scene_params(_standard_params({"next_level_data": null}))
	assert_null(_screen.get_next_level_data())


func test_receive_params_defaults_for_missing_keys() -> void:
	_screen.receive_scene_params({"level_data": _make_level_data()})
	assert_eq(_screen.get_stars(), 0)
	assert_eq(_screen.get_final_moves(), 0)


# —————————————————————————————————————————————
# Populate Results Tests
# —————————————————————————————————————————————

func test_populate_sets_populated_flag() -> void:
	_init_screen()
	assert_true(_screen.is_populated())


func test_populate_not_populated_by_default() -> void:
	assert_false(_screen.is_populated())


func test_populate_sets_level_name() -> void:
	_init_screen({"level_data": _make_level_data("l1", "Sunny Fields")})
	assert_eq(_level_name_label.text, "Sunny Fields")


# —————————————————————————————————————————————
# Star Display Tests
# —————————————————————————————————————————————

func test_three_stars_all_bright() -> void:
	_init_screen({"stars": 3})
	assert_eq(_star_1.modulate, STAR_EARNED_COLOR)
	assert_eq(_star_2.modulate, STAR_EARNED_COLOR)
	assert_eq(_star_3.modulate, STAR_EARNED_COLOR)


func test_two_stars_two_bright_one_dim() -> void:
	_init_screen({"stars": 2})
	assert_eq(_star_1.modulate, STAR_EARNED_COLOR)
	assert_eq(_star_2.modulate, STAR_EARNED_COLOR)
	assert_eq(_star_3.modulate, STAR_UNEARNED_COLOR)


func test_one_star_one_bright_two_dim() -> void:
	_init_screen({"stars": 1})
	assert_eq(_star_1.modulate, STAR_EARNED_COLOR)
	assert_eq(_star_2.modulate, STAR_UNEARNED_COLOR)
	assert_eq(_star_3.modulate, STAR_UNEARNED_COLOR)


func test_zero_stars_all_dim() -> void:
	_init_screen({"stars": 0})
	assert_eq(_star_1.modulate, STAR_UNEARNED_COLOR)
	assert_eq(_star_2.modulate, STAR_UNEARNED_COLOR)
	assert_eq(_star_3.modulate, STAR_UNEARNED_COLOR)


func test_sentinel_stars_hides_star_nodes() -> void:
	_init_screen({"stars": - 1})
	assert_false(_star_1.visible)
	assert_false(_star_2.visible)
	assert_false(_star_3.visible)


func test_sentinel_stars_shows_question_mark() -> void:
	_init_screen({"stars": - 1})
	assert_true(_star_sentinel.visible)
	assert_eq(_star_sentinel.text, "?")


func test_normal_stars_hides_sentinel() -> void:
	# First show sentinel
	_init_screen({"stars": - 1})
	assert_true(_star_sentinel.visible)
	# Then normal stars
	_screen.receive_scene_params(_standard_params({"stars": 2}))
	_screen.populate_results()
	assert_false(_star_sentinel.visible)


# —————————————————————————————————————————————
# Move Count Display Tests
# —————————————————————————————————————————————

func test_moves_display_with_minimum() -> void:
	_init_screen({"final_moves": 10, "level_data": _make_level_data("l1", "L1", 8)})
	assert_eq(_moves_label.text, "10 / 8")


func test_moves_display_perfect_score() -> void:
	_init_screen({"final_moves": 8, "level_data": _make_level_data("l1", "L1", 8)})
	assert_eq(_moves_label.text, "8 / 8")


func test_moves_display_zero_minimum() -> void:
	_init_screen({"final_moves": 5, "level_data": _make_level_data("l1", "L1", 0)})
	assert_eq(_moves_label.text, "5")


func test_moves_display_large_values() -> void:
	_init_screen({"final_moves": 123, "level_data": _make_level_data("l1", "L1", 50)})
	assert_eq(_moves_label.text, "123 / 50")


# —————————————————————————————————————————————
# New Best Badge Tests
# —————————————————————————————————————————————

func test_new_best_first_completion() -> void:
	_init_screen({
		"was_previously_completed": false,
		"prev_best_moves": 0,
		"final_moves": 10,
	})
	assert_true(_new_best_badge.visible)
	assert_true(_screen.is_new_best())


func test_new_best_improved_score() -> void:
	_init_screen({
		"was_previously_completed": true,
		"prev_best_moves": 12,
		"final_moves": 10,
	})
	assert_true(_new_best_badge.visible)
	assert_true(_screen.is_new_best())


func test_no_new_best_same_score() -> void:
	_init_screen({
		"was_previously_completed": true,
		"prev_best_moves": 10,
		"final_moves": 10,
	})
	assert_false(_new_best_badge.visible)
	assert_false(_screen.is_new_best())


func test_no_new_best_worse_score() -> void:
	_init_screen({
		"was_previously_completed": true,
		"prev_best_moves": 8,
		"final_moves": 12,
	})
	assert_false(_new_best_badge.visible)
	assert_false(_screen.is_new_best())


func test_new_best_first_completion_with_prev_zero() -> void:
	# First completion always shows badge even if prev_best is 0
	_init_screen({
		"was_previously_completed": false,
		"prev_best_moves": 0,
		"final_moves": 15,
	})
	assert_true(_new_best_badge.visible)


# —————————————————————————————————————————————
# Next Level Button Tests
# —————————————————————————————————————————————

func test_next_button_visible_when_next_level_exists() -> void:
	_init_screen({"next_level_data": _make_level_data("w1_l2", "Next")})
	assert_true(_next_btn.visible)


func test_next_button_hidden_when_last_level() -> void:
	_init_screen({"next_level_data": null})
	assert_false(_next_btn.visible)


# —————————————————————————————————————————————
# Button Handler Tests
# —————————————————————————————————————————————

func test_next_btn_emits_signal() -> void:
	var next_ld := _make_level_data("w1_l2", "Next Level")
	_init_screen({"next_level_data": next_ld})
	_screen.on_next_btn_pressed()
	assert_eq(_next_level_log.size(), 1)
	assert_eq(_next_level_log[0], next_ld)


func test_next_btn_noop_when_no_next_level() -> void:
	_init_screen({"next_level_data": null})
	_screen.on_next_btn_pressed()
	assert_eq(_next_level_log.size(), 0)


func test_retry_btn_emits_signal() -> void:
	var ld := _make_level_data("w1_l1", "Current")
	_init_screen({"level_data": ld})
	_screen.on_retry_btn_pressed()
	assert_eq(_retry_log.size(), 1)
	assert_eq(_retry_log[0], ld)


func test_world_map_btn_emits_signal() -> void:
	_init_screen()
	_screen.on_world_map_btn_pressed()
	assert_eq(_world_map_count, 1)


func test_multiple_button_presses() -> void:
	_init_screen()
	_screen.on_world_map_btn_pressed()
	_screen.on_world_map_btn_pressed()
	_screen.on_world_map_btn_pressed()
	assert_eq(_world_map_count, 3)


func test_retry_noop_without_params() -> void:
	# No receive_scene_params, no populate
	_screen.on_retry_btn_pressed()
	assert_eq(_retry_log.size(), 0)


# —————————————————————————————————————————————
# Edge Cases
# —————————————————————————————————————————————

func test_populate_without_params_is_noop() -> void:
	_screen.populate_results()
	assert_false(_screen.is_populated())


func test_populate_with_null_level_data_is_noop() -> void:
	_screen.receive_scene_params({"level_data": null, "stars": 3})
	_screen.populate_results()
	assert_false(_screen.is_populated())


func test_receive_params_twice_overwrites() -> void:
	_screen.receive_scene_params(_standard_params({"stars": 1}))
	_screen.receive_scene_params(_standard_params({"stars": 3}))
	assert_eq(_screen.get_stars(), 3)


func test_all_stars_visible_after_normal_display() -> void:
	_init_screen({"stars": 2})
	assert_true(_star_1.visible)
	assert_true(_star_2.visible)
	assert_true(_star_3.visible)


func test_star_sentinel_hidden_by_default_after_normal_display() -> void:
	_init_screen({"stars": 2})
	assert_false(_star_sentinel.visible)
