## WorldMap — level-select screen showing all levels grouped by world.
## Implements: design/gdd/world-map.md
## Task: S3-04, shell donor parity pass
class_name WorldMap
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

const CATALOGUE_PATH: String = "res://data/level_catalogue.tres"
const CAT_TEXTURE: Texture2D = preload("res://design/draft/sprite-cat.png")
const WORLD_TITLES: Dictionary = {
	1: "Pastel Plains",
	2: "Lilac Lanes",
	3: "Cream Caverns",
}

signal level_selected(level_data: LevelData)
signal back_requested

var _back_btn: BaseButton
var _header_card: PanelContainer
var _progress_chip: PanelContainer
var _world_list: VBoxContainer
var _no_levels_label: Label
var _title_label: Label
var _hint_label: Label
var _progress_label: Label

var _catalogue: LevelCatalogue
var _world_index: Dictionary = {} # int -> Array[LevelData]
var _sorted_world_ids: Array[int] = []
var _initial_world_id: int = -1
var _selected_world_id: int = -1
var _first_focus_button: BaseButton


func _ready() -> void:
	_auto_discover_ui_nodes()
	_connect_navigation()
	_apply_visual_style()
	_refresh_hint_text()

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


func _make_world_card(world_id: int, levels: Array[LevelData]) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 210.0)
	var fill_color: Color = ShellThemeUtil.CREAM if world_id != _selected_world_id else Color(1.0, 0.949, 0.839, 1.0)
	var style: StyleBoxFlat = ShellThemeUtil.make_rounded_style(fill_color)
	if world_id == _selected_world_id:
		style.border_color = ShellThemeUtil.GOLD_PRESSED
	card.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var title_label: Label = Label.new()
	title_label.text = "World %d — %s" % [world_id, _get_world_title(world_id)]
	ShellThemeUtil.apply_title(title_label, 26)
	title_box.add_child(title_label)

	var subtitle_label: Label = Label.new()
	subtitle_label.text = "%d levels unlocked • %d total" % [_count_unlocked_levels(levels), levels.size()]
	ShellThemeUtil.apply_body(subtitle_label, ShellThemeUtil.PLUM_SOFT, 16)
	title_box.add_child(subtitle_label)

	var progress_badge: Label = Label.new()
	progress_badge.text = _get_world_progress_text(levels)
	progress_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_badge.custom_minimum_size = Vector2(124.0, 44.0)
	progress_badge.add_theme_stylebox_override("normal", ShellThemeUtil.make_rounded_style(ShellThemeUtil.GOLD, ShellThemeUtil.PLUM, 20, 4))
	progress_badge.add_theme_color_override("font_color", ShellThemeUtil.PLUM)
	header.add_child(progress_badge)

	var body: HBoxContainer = HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	vbox.add_child(body)

	var mascot_panel: PanelContainer = PanelContainer.new()
	mascot_panel.custom_minimum_size = Vector2(92.0, 92.0)
	mascot_panel.add_theme_stylebox_override("panel", ShellThemeUtil.make_rounded_style(Color(1.0, 0.973, 0.925, 1.0), ShellThemeUtil.PLUM_SOFT, 20, 4))
	mascot_panel.visible = world_id == _selected_world_id or world_id == AppSettings.get_last_world_id()
	body.add_child(mascot_panel)

	var mascot_rect: TextureRect = TextureRect.new()
	mascot_rect.texture = CAT_TEXTURE
	mascot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	mascot_rect.offset_left = 8.0
	mascot_rect.offset_top = 8.0
	mascot_rect.offset_right = -8.0
	mascot_rect.offset_bottom = -8.0
	mascot_panel.add_child(mascot_rect)

	var grid: GridContainer = GridContainer.new()
	grid.columns = mini(levels.size(), 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)

	for level: LevelData in levels:
		grid.add_child(_make_level_card(level))

	return card


func _make_level_card(level: LevelData) -> Control:
	var unlocked: bool = _is_level_unlocked(level)
	var completed: bool = SaveManager.is_level_completed(level.level_id)
	var stars: int = SaveManager.get_best_stars(level.level_id)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(92.0, 100.0)

	var fill: Color = ShellThemeUtil.CREAM
	if not unlocked:
		fill = ShellThemeUtil.DISABLED_FILL
	elif completed and stars >= 3:
		fill = ShellThemeUtil.GOLD

	var style: StyleBoxFlat = ShellThemeUtil.make_rounded_style(fill, ShellThemeUtil.PLUM if unlocked else ShellThemeUtil.PLUM_SOFT, 22, 4)
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8.0
	vbox.offset_top = 8.0
	vbox.offset_right = -8.0
	vbox.offset_bottom = -8.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var number_label: Label = Label.new()
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.add_theme_font_size_override("font_size", 30)
	number_label.add_theme_color_override("font_color", ShellThemeUtil.PLUM)
	vbox.add_child(number_label)

	var stars_label: Label = Label.new()
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_color_override("font_color", ShellThemeUtil.PLUM)
	stars_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(stars_label)

	if unlocked:
		number_label.text = str(level.level_index)
		stars_label.text = _build_star_text(stars, completed)
	else:
		number_label.text = "LOCK"
		number_label.add_theme_font_size_override("font_size", 18)
		stars_label.text = "🔒"

	var button: Button = Button.new()
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	card.add_child(button)

	if unlocked:
		button.pressed.connect(_on_level_pressed.bind(level))
		if _first_focus_button == null and level.world_id == _selected_world_id:
			_first_focus_button = button
	else:
		button.disabled = true

	return card


func _build_star_text(stars: int, completed: bool) -> String:
	if not completed:
		return "☆☆☆"
	var text: String = ""
	for i: int in range(3):
		text += "★" if i < stars else "☆"
	return text


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
	return "★ %d / %d" % [earned_stars, levels.size() * 3]


func _get_world_title(world_id: int) -> String:
	return str(WORLD_TITLES.get(world_id, "World %d" % world_id))


func _refresh_header_progress() -> void:
	if _title_label != null:
		_title_label.text = "World Selection"
	if _progress_label == null:
		return
	var total_stars: int = 0
	var total_possible: int = 0
	for world_id: int in _sorted_world_ids:
		var levels: Array[LevelData] = _world_index.get(world_id, [])
		total_possible += levels.size() * 3
		for level: LevelData in levels:
			total_stars += SaveManager.get_best_stars(level.level_id)
	_progress_label.text = "★ %d / %d" % [total_stars, total_possible]


func _refresh_hint_text() -> void:
	if _hint_label == null:
		return
	match AppSettings.get_effective_input_hint_mode():
		AppSettings.INPUT_HINT_TOUCH:
			_hint_label.text = "Tap a level card to start sliding."
		_:
			_hint_label.text = "Choose a level card, then press Enter to start."


func _show_empty_state() -> void:
	if _no_levels_label != null:
		_no_levels_label.visible = true
	if _world_list != null:
		_world_list.visible = false


func _on_level_pressed(level_data: LevelData) -> void:
	AppSettings.set_last_world_id(level_data.world_id)
	level_selected.emit(level_data)


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


func _auto_discover_ui_nodes() -> void:
	_header_card = get_node_or_null("MarginContainer/VBox/HeaderCard") as PanelContainer
	_back_btn = get_node_or_null("MarginContainer/VBox/HeaderCard/Margin/Header/BackBtn") as BaseButton
	if _back_btn != null and not _back_btn.pressed.is_connected(_on_back_btn_pressed):
		_back_btn.pressed.connect(_on_back_btn_pressed)

	_title_label = get_node_or_null("MarginContainer/VBox/HeaderCard/Margin/Header/TitleBox/TitleLabel") as Label
	_progress_chip = get_node_or_null("MarginContainer/VBox/HeaderCard/Margin/Header/ProgressChip") as PanelContainer
	_progress_label = get_node_or_null("MarginContainer/VBox/HeaderCard/Margin/Header/ProgressChip/ProgressBadge") as Label
	_hint_label = get_node_or_null("MarginContainer/VBox/HintLabel") as Label
	_world_list = get_node_or_null("MarginContainer/VBox/ScrollContainer/WorldList") as VBoxContainer
	_no_levels_label = get_node_or_null("MarginContainer/VBox/NoLevelsLabel") as Label


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_panel(_header_card, ShellThemeUtil.CREAM)
	ShellThemeUtil.apply_pill_button(_back_btn, ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED, ShellThemeUtil.PLUM, 52.0)
	ShellThemeUtil.apply_panel(_progress_chip, ShellThemeUtil.GOLD)
	if _progress_label != null:
		_progress_label.add_theme_color_override("font_color", ShellThemeUtil.PLUM)
