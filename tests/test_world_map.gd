## Unit tests for WorldMap unlock logic, star display, and signals.
## Task: S3-09
## Covers: first-level-always-unlocked, sequential gate, star text, world index,
##         level_selected signal, back_requested signal.
extends GutTest

var _map: WorldMap


# —————————————————————————————————————————————
# Setup / Teardown
# —————————————————————————————————————————————

func before_each() -> void:
	# Reset the autoload SaveManager so unlock checks start fresh.
	SaveManager.reset_all_progress()

	# Create WorldMap without adding to tree (_ready won't fire — avoids
	# null UI node errors). autofree() handles cleanup.
	_map = WorldMap.new()
	autofree(_map)


# —————————————————————————————————————————————
# Helpers
# —————————————————————————————————————————————

func _make_level(p_id: String, p_world: int, p_index: int) -> LevelData:
	var ld: LevelData = LevelData.new()
	ld.level_id = p_id
	ld.world_id = p_world
	ld.level_index = p_index
	ld.display_name = "Test %s" % p_id
	ld.minimum_moves = p_index
	ld.star_3_moves = p_index
	ld.star_2_moves = p_index + 2
	ld.star_1_moves = p_index + 5
	return ld


func _setup_catalogue(
	levels: Array[LevelData],
	always_unlocked_world_ids: PackedInt32Array = PackedInt32Array(),
) -> void:
	var cat: LevelCatalogue = LevelCatalogue.new()
	cat.levels = levels
	cat.always_unlocked_world_ids = always_unlocked_world_ids
	_map._catalogue = cat
	_map._build_world_index()


# —————————————————————————————————————————————
# Unlock logic — first level always unlocked
# —————————————————————————————————————————————

func test_first_level_always_unlocked() -> void:
	var l1: LevelData = _make_level("w1_l1", 1, 1)
	_setup_catalogue([l1] as Array[LevelData])
	assert_true(_map.is_level_unlocked(l1), "Level index 1 should always be unlocked")


func test_world_two_entry_locked_until_world_one_final_completed() -> void:
	var w1_l1: LevelData = _make_level("w1_l1", 1, 1)
	var w1_l2: LevelData = _make_level("w1_l2", 1, 2)
	var w2_l1: LevelData = _make_level("w2_l1", 2, 1)
	var w2_l2: LevelData = _make_level("w2_l2", 2, 2)
	_setup_catalogue([w1_l1, w1_l2, w2_l1, w2_l2] as Array[LevelData])

	assert_false(_map.is_level_unlocked(w2_l1), "World 2 entry should be locked initially")

	SaveManager.set_level_record("w1_l1", true, 2, 5)
	assert_false(_map.is_level_unlocked(w2_l1), "World 2 entry stays locked until world 1 final")

	SaveManager.set_level_record("w1_l2", true, 2, 5)
	assert_true(_map.is_level_unlocked(w2_l1), "World 2 entry unlocks after world 1 final")


func test_special_world_entry_can_be_default_unlocked() -> void:
	var w1_l1: LevelData = _make_level("w1_l1", 1, 1)
	var w1_l2: LevelData = _make_level("w1_l2", 1, 2)
	var sp_l1: LevelData = _make_level("sp_l1", 99, 1)
	var sp_l2: LevelData = _make_level("sp_l2", 99, 2)
	_setup_catalogue(
		[w1_l1, w1_l2, sp_l1, sp_l2] as Array[LevelData],
		PackedInt32Array([99]),
	)

	assert_true(_map.is_level_unlocked(sp_l1), "Configured special world entry should be unlocked")
	assert_false(_map.is_level_unlocked(sp_l2), "Special world still gates sequentially within world")

	SaveManager.set_level_record("sp_l1", true, 2, 5)
	assert_true(_map.is_level_unlocked(sp_l2), "Special world second level unlocks after first")


# —————————————————————————————————————————————
# Unlock logic — sequential gating
# —————————————————————————————————————————————

func test_second_level_locked_until_first_completed() -> void:
	var l1: LevelData = _make_level("w1_l1", 1, 1)
	var l2: LevelData = _make_level("w1_l2", 1, 2)
	_setup_catalogue([l1, l2] as Array[LevelData])

	assert_false(_map.is_level_unlocked(l2), "l2 locked when l1 not completed")

	SaveManager.set_level_record("w1_l1", true, 2, 5)
	assert_true(_map.is_level_unlocked(l2), "l2 unlocked after l1 completed")


func test_third_level_requires_second_completed() -> void:
	var l1: LevelData = _make_level("w1_l1", 1, 1)
	var l2: LevelData = _make_level("w1_l2", 1, 2)
	var l3: LevelData = _make_level("w1_l3", 1, 3)
	_setup_catalogue([l1, l2, l3] as Array[LevelData])

	SaveManager.set_level_record("w1_l1", true, 3, 3)
	assert_false(_map.is_level_unlocked(l3), "l3 locked when l2 not completed")

	SaveManager.set_level_record("w1_l2", true, 1, 10)
	assert_true(_map.is_level_unlocked(l3), "l3 unlocked after l2 completed")


# —————————————————————————————————————————————
# Stars from SaveManager
# —————————————————————————————————————————————

func test_star_text_three_stars() -> void:
	var text: String = _map._build_star_text(3, true)
	assert_eq(text, "★★★")


func test_star_text_two_stars() -> void:
	var text: String = _map._build_star_text(2, true)
	assert_eq(text, "★★☆")


func test_star_text_one_star() -> void:
	var text: String = _map._build_star_text(1, true)
	assert_eq(text, "★☆☆")


func test_star_text_zero_stars() -> void:
	var text: String = _map._build_star_text(0, true)
	assert_eq(text, "☆☆☆")


func test_star_text_not_completed() -> void:
	var text: String = _map._build_star_text(0, false)
	assert_eq(text, "☆☆☆")


# —————————————————————————————————————————————
# World index building
# —————————————————————————————————————————————

func test_world_index_groups_by_world_id() -> void:
	var l1: LevelData = _make_level("w1_l1", 1, 1)
	var l2: LevelData = _make_level("w1_l2", 1, 2)
	var l3: LevelData = _make_level("w2_l1", 2, 1)
	_setup_catalogue([l1, l2, l3] as Array[LevelData])

	var idx: Dictionary = _map.get_world_index()
	assert_true(idx.has(1), "Should have world 1")
	assert_true(idx.has(2), "Should have world 2")
	assert_eq((idx[1] as Array).size(), 2, "World 1 should have 2 levels")
	assert_eq((idx[2] as Array).size(), 1, "World 2 should have 1 level")


func test_sorted_world_ids_ascending() -> void:
	var l1: LevelData = _make_level("w3_l1", 3, 1)
	var l2: LevelData = _make_level("w1_l1", 1, 1)
	_setup_catalogue([l1, l2] as Array[LevelData])

	var ids: Array[int] = _map.get_sorted_world_ids()
	assert_eq(ids[0], 1)
	assert_eq(ids[1], 3)


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

func test_level_selected_signal_emitted() -> void:
	var l1: LevelData = _make_level("w1_l1", 1, 1)
	_setup_catalogue([l1] as Array[LevelData])

	watch_signals(_map)
	_map._on_level_pressed(l1)
	assert_signal_emitted_with_parameters(_map, "level_selected", [l1])


func test_back_requested_signal_emitted() -> void:
	watch_signals(_map)
	_map._on_back_btn_pressed()
	assert_signal_emitted(_map, "back_requested")


func test_select_world_persists_last_world_id_to_app_settings() -> void:
	var l1: LevelData = _make_level("w1_l1", 1, 1)
	var l2: LevelData = _make_level("w2_l1", 2, 1)
	_setup_catalogue([l1, l2] as Array[LevelData])

	var list: VBoxContainer = VBoxContainer.new()
	add_child_autofree(list)
	_map._world_list = list

	AppSettings.set_last_world_id(1)
	_map._select_world(2)

	assert_eq(AppSettings.get_last_world_id(), 2)
