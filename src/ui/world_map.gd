## WorldMap — level-select screen showing all levels grouped by world.
## Implements: design/gdd/world-map.md
## Task: S3-04
##
## Loads the LevelCatalogue from the canonical path, reads save data from
## SaveManager, and renders a grid of level buttons per world. Players tap
## an unlocked level to start it. A back button returns to Main Menu.
##
## Usage:
##   SceneManager navigates here via go_to(Screen.WORLD_MAP).
##   Optional highlight_world_id param selects initial world tab.
class_name WorldMap
extends Control


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const CATALOGUE_PATH: String = "res://data/level_catalogue.tres"

## Gold color for earned stars (matches LevelCompleteScreen).
const STAR_EARNED_COLOR: Color = Color(1.0, 0.85, 0.2, 1.0)

## Grey color for unearned/empty stars.
const STAR_UNEARNED_COLOR: Color = Color(0.5, 0.5, 0.5, 1.0)

## Grey used for locked level buttons.
const LOCKED_COLOR: Color = Color(0.4, 0.4, 0.4, 1.0)


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when a level button is pressed.
signal level_selected(level_data: LevelData)

## Emitted when the back button is pressed.
signal back_requested


# —————————————————————————————————————————————
# Child node references
# —————————————————————————————————————————————

var _back_btn: BaseButton
var _world_tabs: TabBar
var _level_grid: GridContainer
var _no_levels_label: Label
var _title_label: Label


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _catalogue: LevelCatalogue
var _world_index: Dictionary = {} # int -> Array[LevelData]
var _sorted_world_ids: Array[int] = []
var _initial_world_id: int = -1


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_auto_discover_ui_nodes()
	_connect_navigation()

	_catalogue = load(CATALOGUE_PATH) as LevelCatalogue
	if _catalogue == null:
		push_error("WorldMap: LevelCatalogue not found at " + CATALOGUE_PATH)
		_show_empty_state()
		return

	if _catalogue.levels.is_empty():
		_show_empty_state()
		return

	_build_world_index()
	_create_world_tabs()

	# Determine initial world to display.
	var start_world: int = _sorted_world_ids[0]
	if _initial_world_id >= 0 and _initial_world_id in _sorted_world_ids:
		start_world = _initial_world_id
	elif _initial_world_id >= 0:
		# Requested world not in catalogue — fall back to first.
		start_world = _sorted_world_ids[0]

	var tab_index: int = _sorted_world_ids.find(start_world)
	if tab_index >= 0 and _world_tabs != null:
		_world_tabs.current_tab = tab_index

	_select_world(start_world)


# —————————————————————————————————————————————
# SceneManager contract
# —————————————————————————————————————————————

func receive_scene_params(params: Dictionary) -> void:
	_initial_world_id = params.get("highlight_world_id", -1) as int


# —————————————————————————————————————————————
# Public API (for tests)
# —————————————————————————————————————————————

## Returns the catalogue loaded by _ready().
func get_catalogue() -> LevelCatalogue:
	return _catalogue


## Returns the built world index dictionary.
func get_world_index() -> Dictionary:
	return _world_index


## Returns sorted world IDs.
func get_sorted_world_ids() -> Array[int]:
	return _sorted_world_ids


## Returns true if the given level is unlocked per the world map rules.
func is_level_unlocked(level_data: LevelData) -> bool:
	return _is_level_unlocked(level_data)


# —————————————————————————————————————————————
# World index
# —————————————————————————————————————————————

func _build_world_index() -> void:
	_world_index.clear()
	_sorted_world_ids.clear()

	for level: LevelData in _catalogue.levels:
		if not _world_index.has(level.world_id):
			_world_index[level.world_id] = [] as Array[LevelData]
		(_world_index[level.world_id] as Array[LevelData]).append(level)

	for world_id: int in _world_index:
		_sorted_world_ids.append(world_id)
		var arr: Array[LevelData] = _world_index[world_id]
		arr.sort_custom(func(a: LevelData, b: LevelData) -> bool: return a.level_index < b.level_index)

	_sorted_world_ids.sort()


# —————————————————————————————————————————————
# Unlock logic (duplicated from LevelProgression per GDD)
# —————————————————————————————————————————————

func _is_level_unlocked(level_data: LevelData) -> bool:
	if level_data.level_index == 1:
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
	return null


# —————————————————————————————————————————————
# UI builders
# —————————————————————————————————————————————

func _create_world_tabs() -> void:
	if _world_tabs == null:
		return
	_world_tabs.clear_tabs()
	for world_id: int in _sorted_world_ids:
		_world_tabs.add_tab("World %d" % world_id)


func _select_world(world_id: int) -> void:
	_clear_level_grid()

	var levels: Array = _world_index.get(world_id, [])
	for level: LevelData in levels:
		var btn: Button = _make_level_button(level)
		_level_grid.add_child(btn)


func _make_level_button(level: LevelData) -> Button:
	var btn: Button = Button.new()
	var unlocked: bool = _is_level_unlocked(level)

	if not unlocked:
		btn.text = "🔒"
		btn.disabled = true
		btn.modulate = LOCKED_COLOR
	else:
		var stars: int = SaveManager.get_best_stars(level.level_id)
		var completed: bool = SaveManager.is_level_completed(level.level_id)
		var star_text: String = _build_star_text(stars, completed)
		btn.text = "%d\n%s" % [level.level_index, star_text]
		btn.pressed.connect(_on_level_pressed.bind(level))

	btn.custom_minimum_size = Vector2(80, 80)
	return btn


func _build_star_text(stars: int, completed: bool) -> String:
	if not completed:
		return "☆☆☆"
	var filled: String = ""
	for i: int in range(3):
		if i < stars:
			filled += "★"
		else:
			filled += "☆"
	return filled


func _clear_level_grid() -> void:
	if _level_grid == null:
		return
	for child: Node in _level_grid.get_children():
		child.queue_free()


func _show_empty_state() -> void:
	if _no_levels_label != null:
		_no_levels_label.visible = true
	if _level_grid != null:
		_level_grid.visible = false
	if _world_tabs != null:
		_world_tabs.visible = false


# —————————————————————————————————————————————
# Button handlers
# —————————————————————————————————————————————

func _on_level_pressed(level_data: LevelData) -> void:
	level_selected.emit(level_data)


func _on_back_btn_pressed() -> void:
	back_requested.emit()


func _on_tab_changed(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= _sorted_world_ids.size():
		return
	_select_world(_sorted_world_ids[tab_index])


# —————————————————————————————————————————————
# Navigation
# —————————————————————————————————————————————

func _connect_navigation() -> void:
	if not level_selected.is_connected(_navigate_to_level):
		level_selected.connect(_navigate_to_level)
	if not back_requested.is_connected(_navigate_to_main_menu):
		back_requested.connect(_navigate_to_main_menu)


func _navigate_to_level(level_data: LevelData) -> void:
	SceneManager.go_to_level(level_data)


func _navigate_to_main_menu() -> void:
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)


# —————————————————————————————————————————————
# Auto-discover UI nodes from scene tree
# —————————————————————————————————————————————

func _auto_discover_ui_nodes() -> void:
	if _back_btn == null:
		_back_btn = get_node_or_null("MarginContainer/VBox/Header/BackBtn") as BaseButton
	if _back_btn != null:
		if not _back_btn.pressed.is_connected(_on_back_btn_pressed):
			_back_btn.pressed.connect(_on_back_btn_pressed)

	if _title_label == null:
		_title_label = get_node_or_null("MarginContainer/VBox/Header/TitleLabel") as Label

	if _world_tabs == null:
		_world_tabs = get_node_or_null("MarginContainer/VBox/WorldTabs") as TabBar
	if _world_tabs != null:
		if not _world_tabs.tab_changed.is_connected(_on_tab_changed):
			_world_tabs.tab_changed.connect(_on_tab_changed)

	if _level_grid == null:
		_level_grid = get_node_or_null("MarginContainer/VBox/ScrollContainer/LevelGrid") as GridContainer

	if _no_levels_label == null:
		_no_levels_label = get_node_or_null("MarginContainer/VBox/NoLevelsLabel") as Label
