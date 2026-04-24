## WorldMap — level-select screen showing all levels grouped by world.
## Implements: design/gdd/world-map.md
## Task: S3-04, shell donor parity pass
class_name WorldMap
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const WorldCardScene: PackedScene = preload("res://scenes/ui/components/cards/WorldCard.tscn")
const LevelCardScene: PackedScene = preload("res://scenes/ui/components/cards/LevelCard.tscn")

const CATALOGUE_PATH: String = "res://data/level_catalogue.tres"
const WORLD_TITLES: Dictionary = {
	1: "Pastel Plains",
	2: "Lilac Lanes",
	3: "Cream Caverns",
}

@export_category("World Card Layout")
## Minimum columns the level grid should attempt to use.
@export_range(1, 8, 1, "or_greater")
var grid_min_columns: int = 2

## Maximum columns the level grid is allowed to use.
@export_range(1, 12, 1, "or_greater")
var grid_max_columns: int = 6

## Minimum width per generated level card.
@export_range(80.0, 320.0, 1.0, "or_greater")
var level_card_min_width: float = 120.0

## Gap between generated level cards in the world grid.
@export_range(0.0, 40.0, 1.0, "or_greater")
var level_card_gap: float = 10.0

## Horizontal padding reserved around world card grids.
@export_range(0.0, 120.0, 1.0, "or_greater")
var world_card_inner_horizontal_padding: float = 40.0

@export_category("World Card Motion")
## Hover scale multiplier for unlocked level cards.
@export_range(1.0, 1.2, 0.01, "or_greater")
var level_card_hover_scale: float = 1.04

## Hover tween duration for level card scale transitions.
@export_range(0.01, 0.5, 0.01, "or_greater")
var level_card_hover_duration_sec: float = 0.1

## Max lock icon jiggle angle when pressing a locked level.
@export_range(0.0, 40.0, 0.1, "or_greater")
var lock_jiggle_rotation_degrees: float = 14.0

signal level_selected(level_data: LevelData)
signal back_requested

@export var _back_btn: BaseButton
@export var _header_card: PanelContainer
@export var _progress_chip: Control
@export var _world_list: VBoxContainer
@export var _scroll_container: ScrollContainer
@export var _no_levels_label: Label
@export var _title_label: Label
@export var _subtitle_label: Label
@export var _hint_label: Label

var _catalogue: LevelCatalogue
var _world_index: Dictionary = {} # int -> Array[LevelData]
var _sorted_world_ids: Array[int] = []
var _initial_world_id: int = -1
var _selected_world_id: int = -1
var _first_focus_button: BaseButton
var _last_grid_column_target: int = -1


func _ready() -> void:
	if _back_btn == null:
		_back_btn = get_node_or_null("MarginContainer/VBox/HeaderOuterMargin/HeaderCard/Margin/Header/BackBtn")
	if _header_card == null:
		_header_card = get_node_or_null("MarginContainer/VBox/HeaderOuterMargin/HeaderCard")
	if _progress_chip == null:
		_progress_chip = get_node_or_null("MarginContainer/VBox/HeaderOuterMargin/HeaderCard/Margin/Header/ProgressChip")
	if _world_list == null:
		_world_list = get_node_or_null("MarginContainer/VBox/ListOuterMargin/ScrollContainer/WorldList")
	if _scroll_container == null:
		_scroll_container = get_node_or_null("MarginContainer/VBox/ListOuterMargin/ScrollContainer")
	if _no_levels_label == null:
		_no_levels_label = get_node_or_null("MarginContainer/VBox/NoLevelsLabel")
	if _title_label == null:
		_title_label = get_node_or_null("MarginContainer/VBox/HeaderOuterMargin/HeaderCard/Margin/Header/TitleBox/TitleLabel")
	if _subtitle_label == null:
		_subtitle_label = get_node_or_null("MarginContainer/VBox/HeaderOuterMargin/HeaderCard/Margin/Header/TitleBox/SubtitleLabel")
	if _hint_label == null:
		_hint_label = get_node_or_null("MarginContainer/VBox/HintLabel")
	assert(_header_card != null, "_header_card not assigned")
	assert(_back_btn != null, "_back_btn not assigned")
	assert(_title_label != null, "_title_label not assigned")
	assert(_subtitle_label != null, "_subtitle_label not assigned")
	assert(_progress_chip != null, "_progress_chip not assigned")
	assert(_hint_label != null, "_hint_label not assigned")
	assert(_scroll_container != null, "_scroll_container not assigned")
	assert(_world_list != null, "_world_list not assigned")
	assert(_no_levels_label != null, "_no_levels_label not assigned")
	_connect_back_button_signal()
	_connect_navigation()
	_apply_visual_style()
	if not resized.is_connected(_on_world_map_resized):
		resized.connect(_on_world_map_resized)
	_last_grid_column_target = _target_world_grid_columns()

	_catalogue = load(CATALOGUE_PATH) as LevelCatalogue
	if _catalogue == null:
		push_error("WorldMap: LevelCatalogue not found at " + CATALOGUE_PATH)
		_show_empty_state()
		return

	if _catalogue.levels.is_empty():
		_show_empty_state()
		return

	_build_world_index()
	var start_world: int = _sorted_world_ids[0]
	if _initial_world_id >= 0 and _initial_world_id in _sorted_world_ids:
		start_world = _initial_world_id
	elif AppSettings.get_last_world_id() in _sorted_world_ids:
		start_world = AppSettings.get_last_world_id()

	_select_world(start_world)
	call_deferred("_apply_initial_focus")
	call_deferred("_refresh_world_layout_after_ready")


func receive_scene_params(params: Dictionary) -> void:
	_initial_world_id = params.get("highlight_world_id", -1) as int


func get_catalogue() -> LevelCatalogue:
	return _catalogue


func get_world_index() -> Dictionary:
	return _world_index


func get_sorted_world_ids() -> Array[int]:
	return _sorted_world_ids


func is_level_unlocked(level_data: LevelData) -> bool:
	return _is_level_unlocked(level_data)


func _build_world_index() -> void:
	_world_index.clear()
	_sorted_world_ids.clear()

	for level: LevelData in _catalogue.levels:
		if not _world_index.has(level.world_id):
			_world_index[level.world_id] = [] as Array[LevelData]
		(_world_index[level.world_id] as Array[LevelData]).append(level)

	for world_id: int in _world_index:
		_sorted_world_ids.append(world_id)
		var levels: Array[LevelData] = _world_index[world_id]
		levels.sort_custom(func(a: LevelData, b: LevelData) -> bool: return a.level_index < b.level_index)

	_sorted_world_ids.sort()


func _is_level_unlocked(level_data: LevelData) -> bool:
	if _is_level_entry_unlocked_by_default(level_data):
		return true
	var prev: LevelData = _get_prev_level(level_data)
	if prev == null:
		return true
	return SaveManager.is_level_completed(prev.level_id)


func _get_prev_level(level_data: LevelData) -> LevelData:
	var world_levels: Array = _world_index.get(level_data.world_id, [])
	for level: LevelData in world_levels:
		if level.level_index == level_data.level_index - 1:
			return level

	if level_data.level_index == 1:
		var prev_world_id: int = _get_prev_world_id(level_data.world_id)
		if prev_world_id >= 0:
			var prev_world_levels: Array[LevelData] = _world_index.get(prev_world_id, [])
			if not prev_world_levels.is_empty():
				return prev_world_levels[prev_world_levels.size() - 1]
	return null


func _get_prev_world_id(world_id: int) -> int:
	var idx: int = _sorted_world_ids.find(world_id)
	if idx <= 0:
		return -1
	return _sorted_world_ids[idx - 1]


func _is_level_entry_unlocked_by_default(level_data: LevelData) -> bool:
	if level_data.level_index != 1:
		return false
	if level_data.world_id == 1:
		return true
	return _is_world_always_unlocked(level_data.world_id)


func _is_world_always_unlocked(world_id: int) -> bool:
	if _catalogue == null:
		return false
	return world_id in _catalogue.always_unlocked_world_ids


func _select_world(world_id: int) -> void:
	_selected_world_id = world_id
	AppSettings.set_last_world_id(world_id)
	_rebuild_world_cards()
	_refresh_header_progress()


func _rebuild_world_cards() -> void:
	if _world_list == null:
		return

	_first_focus_button = null
	for child: Node in _world_list.get_children():
		child.queue_free()

	for world_id: int in _sorted_world_ids:
		var levels: Array[LevelData] = _world_index.get(world_id, [])
		_world_list.add_child(_make_world_card(world_id, levels))
	_animate_world_card_entries()


func _make_world_card(world_id: int, levels: Array[LevelData]) -> Control:
	var card_instance = WorldCardScene.instantiate()
	if not card_instance is PanelContainer:
		push_error("WorldMap: WorldCard scene did not instantiate as WorldCard.")
		return Control.new()
	var card: PanelContainer = card_instance as PanelContainer
	card.set("world_id", world_id)
	if card.has_method("set_world_meta"):
		card.call(
			"set_world_meta",
			"World %d — %s" % [world_id, _get_world_title(world_id)],
			"%d unlocked • %d total" % [_count_unlocked_levels(levels), levels.size()]
		)
	if card.has_method("set_progress"):
		card.call("set_progress", _get_world_progress_text(levels))
	if card.has_method("set_selected"):
		card.call("set_selected", world_id == _selected_world_id)
	if card.has_method("set_grid_columns"):
		card.call("set_grid_columns", _world_grid_columns(levels.size()))

	var grid: GridContainer = null
	if card.has_method("get_level_grid"):
		grid = card.call("get_level_grid") as GridContainer
	if grid != null:
		grid.add_theme_constant_override("h_separation", int(level_card_gap))
		grid.add_theme_constant_override("v_separation", int(level_card_gap))

	for level: LevelData in levels:
		if card.has_method("add_level_card"):
			card.call("add_level_card", _make_level_card(level))

	return card


func _world_grid_columns(level_count: int) -> int:
	if level_count <= 0:
		return 1
	var available_width: float = _estimate_world_card_grid_width()
	var columns: int = mini(level_count, _target_world_grid_columns())
	while columns > 1:
		var required_width: float = (float(columns) * level_card_min_width) + (float(columns - 1) * level_card_gap)
		if required_width <= available_width + 0.5:
			break
		columns -= 1
	var two_columns_fit: bool = available_width >= ((2.0 * level_card_min_width) + level_card_gap - 0.5)
	if level_count >= 2 and two_columns_fit:
		return maxi(2, columns)
	return maxi(1, columns)


func _target_world_grid_columns() -> int:
	var grid_width: float = _estimate_world_card_grid_width()
	var min_columns: int = maxi(1, mini(grid_min_columns, grid_max_columns))
	var max_columns: int = maxi(1, maxi(grid_min_columns, grid_max_columns))
	if grid_width <= 0.0:
		return min_columns
	var slot_width: float = level_card_min_width + level_card_gap
	var estimated_columns: int = int(floor((grid_width + level_card_gap) / slot_width))
	return clampi(estimated_columns, min_columns, max_columns)


func _estimate_world_card_grid_width() -> float:
	var width: float = 0.0
	if _scroll_container != null:
		width = _scroll_container.size.x
		if width <= 0.0:
			var scroll_parent: Control = _scroll_container.get_parent_control()
			if scroll_parent != null:
				width = scroll_parent.size.x
	if _world_list != null:
		if width <= 0.0:
			width = _world_list.size.x
		if width <= 0.0:
			var parent_control: Control = _world_list.get_parent_control()
			if parent_control != null:
				width = parent_control.size.x
	if width <= 0.0:
		width = size.x
		if width <= 0.0 and is_inside_tree():
			width = get_viewport_rect().size.x
	if _scroll_container != null:
		var v_scroll: VScrollBar = _scroll_container.get_v_scroll_bar()
		if v_scroll != null and v_scroll.visible:
			width -= v_scroll.size.x
	return maxf(0.0, width - world_card_inner_horizontal_padding)


func _on_world_map_resized() -> void:
	var target_columns: int = _target_world_grid_columns()
	if target_columns == _last_grid_column_target:
		return
	_last_grid_column_target = target_columns
	if _world_index.is_empty():
		return
	_rebuild_world_cards()
	call_deferred("_apply_initial_focus")


func _refresh_world_layout_after_ready() -> void:
	if _world_index.is_empty():
		return
	await get_tree().process_frame
	_last_grid_column_target = _target_world_grid_columns()
	_rebuild_world_cards()
	call_deferred("_apply_initial_focus")


func _make_level_card(level: LevelData) -> Control:
	var unlocked: bool = _is_level_unlocked(level)
	var completed: bool = SaveManager.is_level_completed(level.level_id)
	var stars: int = SaveManager.get_best_stars(level.level_id)
	var level_card_instance = LevelCardScene.instantiate()
	if not level_card_instance is PanelContainer:
		push_error("WorldMap: LevelCard scene did not instantiate as LevelCard.")
		return Control.new()
	var card: PanelContainer = level_card_instance as PanelContainer

	var card_state: String = "unlocked"
	if not unlocked:
		card_state = "locked"
	elif completed and stars >= 3:
		card_state = "complete"

	card.set("min_width", level_card_min_width)
	card.set("hover_scale", level_card_hover_scale)
	card.set("hover_duration_sec", level_card_hover_duration_sec)
	if card.has_method("configure"):
		card.call("configure", level.level_id, level.level_index, card_state, stars if completed else 0)

	var overlay_button: BaseButton = card.find_child("OverlayButton", true, false) as BaseButton
	if unlocked:
		if card.has_signal("pressed"):
			card.connect("pressed", Callable(self , "_on_level_card_selected").bind(level))
		if _first_focus_button == null and level.world_id == _selected_world_id and overlay_button != null:
			_first_focus_button = overlay_button
	else:
		var lock_icon: TextureRect = card.find_child("LockIcon", true, false) as TextureRect
		if card.has_signal("locked_pressed"):
			card.connect("locked_pressed", Callable(self , "_on_locked_level_card_pressed").bind(card, lock_icon))

	return card


func _count_unlocked_levels(levels: Array[LevelData]) -> int:
	var total: int = 0
	for level: LevelData in levels:
		if _is_level_unlocked(level):
			total += 1
	return total


func _get_world_progress_text(levels: Array[LevelData]) -> String:
	var earned_stars: int = 0
	for level: LevelData in levels:
		earned_stars += SaveManager.get_best_stars(level.level_id)
	return "%d / %d" % [earned_stars, levels.size() * 3]


func _get_world_title(world_id: int) -> String:
	return str(WORLD_TITLES.get(world_id, "World %d" % world_id))


func _refresh_header_progress() -> void:
	if _title_label != null:
		_title_label.text = "World Selection"
	if _progress_chip == null:
		return
	var total_stars: int = 0
	var total_possible: int = 0
	for world_id: int in _sorted_world_ids:
		var levels: Array[LevelData] = _world_index.get(world_id, [])
		total_possible += levels.size() * 3
		for level: LevelData in levels:
			total_stars += SaveManager.get_best_stars(level.level_id)
	if _progress_chip.has_method("set_value_text"):
		_progress_chip.call("set_value_text", "%d / %d" % [total_stars, total_possible])


func _refresh_hint_text() -> void:
	if _hint_label == null:
		return
	_hint_label.text = ""


func _show_empty_state() -> void:
	if _no_levels_label != null:
		_no_levels_label.visible = true
	if _world_list != null:
		_world_list.visible = false


func _on_level_pressed(level_data: LevelData) -> void:
	AppSettings.set_last_world_id(level_data.world_id)
	level_selected.emit(level_data)


func _on_level_card_selected(_level_id: String, level_data: LevelData) -> void:
	_on_level_pressed(level_data)


func _on_locked_level_pressed(card: PanelContainer, lock_icon: TextureRect) -> void:
	_play_locked_level_feedback(card, lock_icon)


func _on_locked_level_card_pressed(_level_id: String, card: PanelContainer, lock_icon: TextureRect) -> void:
	_on_locked_level_pressed(card, lock_icon)


func _on_back_btn_pressed() -> void:
	back_requested.emit()


func _connect_navigation() -> void:
	if not level_selected.is_connected(_navigate_to_level):
		level_selected.connect(_navigate_to_level)
	if not back_requested.is_connected(_navigate_to_main_menu):
		back_requested.connect(_navigate_to_main_menu)


func _navigate_to_level(level_data: LevelData) -> void:
	SceneManager.go_to_level(level_data)


func _navigate_to_main_menu() -> void:
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)


func _apply_initial_focus() -> void:
	if _first_focus_button != null:
		_first_focus_button.grab_focus()
	elif _back_btn != null:
		_back_btn.grab_focus()


func _connect_back_button_signal() -> void:
	if _back_btn != null and not _back_btn.pressed.is_connected(_on_back_btn_pressed):
		_back_btn.pressed.connect(_on_back_btn_pressed)


func _apply_visual_style() -> void:
	if _header_card != null:
		_header_card.add_theme_stylebox_override("panel", ShellThemeUtil.make_ribbon_style("white"))
	ShellThemeUtil.apply_title(_title_label, 38)
	if _subtitle_label != null:
		_subtitle_label.visible = false
	if _hint_label != null:
		_hint_label.visible = false
	if _progress_chip != null:
		_progress_chip.visible = false


func _play_locked_level_feedback(card: PanelContainer, lock_icon: TextureRect) -> void:
	if card == null:
		return
	if _is_reduce_motion_enabled():
		if lock_icon != null:
			lock_icon.modulate = Color(1.0, 0.92, 0.92, 1.0)
			var tint_tween: Tween = lock_icon.create_tween()
			tint_tween.tween_property(lock_icon, "modulate", Color.WHITE, 0.12)
		return

	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ONE
	if lock_icon != null:
		lock_icon.pivot_offset = lock_icon.size * 0.5
		lock_icon.scale = Vector2.ONE
		lock_icon.rotation_degrees = 0.0

	var card_tween: Tween = card.create_tween()
	card_tween.tween_property(card, "scale", Vector2(0.96, 0.96), 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card_tween.tween_property(card, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if lock_icon != null:
		var lock_tween: Tween = lock_icon.create_tween()
		lock_tween.tween_property(lock_icon, "rotation_degrees", -lock_jiggle_rotation_degrees, 0.06)
		lock_tween.tween_property(lock_icon, "rotation_degrees", lock_jiggle_rotation_degrees * 0.7, 0.08)
		lock_tween.tween_property(lock_icon, "rotation_degrees", 0.0, 0.08)
		lock_tween.parallel().tween_property(lock_icon, "scale", Vector2(1.12, 1.12), 0.08)
		lock_tween.tween_property(lock_icon, "scale", Vector2.ONE, 0.14)


func _animate_world_card_entries() -> void:
	if _world_list == null:
		return
	if _is_reduce_motion_enabled():
		for node: Node in _world_list.get_children():
			if node is Control:
				(node as Control).modulate = Color(1.0, 1.0, 1.0, 1.0)
				(node as Control).scale = Vector2.ONE
		return

	var card_index: int = 0
	for node: Node in _world_list.get_children():
		if not node is Control:
			continue
		var card: Control = node as Control
		card.pivot_offset = card.size * Vector2(0.5, 0.0)
		card.modulate = Color(1.0, 1.0, 1.0, 0.0)
		card.scale = Vector2(0.97, 0.97)
		var tween: Tween = card.create_tween()
		var delay_sec: float = float(card_index) * 0.04
		tween.tween_property(card, "modulate:a", 1.0, 0.2).set_delay(delay_sec) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.24).set_delay(delay_sec) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_index += 1


func _is_reduce_motion_enabled() -> bool:
	return AppSettings != null and AppSettings.get_reduce_motion()
