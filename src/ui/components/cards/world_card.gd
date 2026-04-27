class_name WorldCard
extends PanelContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

@export var world_id: int = 1
@export var world_title: String = "World 1"

@export var world_subtitle: String = "0 unlocked • 0 total"

@export var progress_text: String = "0 / 0"

@export var selected: bool = false

@export_range(1, 12, 1, "or_greater")
var grid_columns: int = 2

@export var _level_grid: GridContainer

var _is_component_ready: bool = false

@onready var _title_label: Label = $Margin/VBox/Header/TitleBox/TitleLabel
@onready var _subtitle_label: Label = $Margin/VBox/Header/TitleBox/SubtitleLabel
@onready var _progress_pill: Control = $Margin/VBox/Header/ProgressPill


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
			for grandchild in child.get_children():
				if grandchild is Control:
					grandchild.mouse_filter = Control.MOUSE_FILTER_PASS
					for ggrandchild in grandchild.get_children():
						if ggrandchild is Control:
							ggrandchild.mouse_filter = Control.MOUSE_FILTER_PASS

	if _level_grid == null:
		_level_grid = get_node_or_null("Margin/VBox/LevelGrid")
	assert(_level_grid != null, "_level_grid not assigned")
	_is_component_ready = true
	_apply_component_state()


func set_progress(text_value: String) -> void:
	progress_text = text_value
	if _is_component_ready:
		_apply_component_state()


func set_world_meta(title_value: String, subtitle_value: String) -> void:
	world_title = title_value
	world_subtitle = subtitle_value
	if _is_component_ready:
		_apply_component_state()


func set_selected(value: bool) -> void:
	selected = value
	if _is_component_ready:
		_apply_component_state()


func set_grid_columns(value: int) -> void:
	grid_columns = maxi(1, value)
	if _is_component_ready:
		_apply_component_state()


func clear_level_cards() -> void:
	var level_grid: GridContainer = get_level_grid()
	if level_grid == null:
		return
	for child: Node in level_grid.get_children():
		child.queue_free()


func add_level_card(card: Control) -> void:
	var level_grid: GridContainer = get_level_grid()
	if level_grid == null:
		return
	level_grid.add_child(card)


func get_level_grid() -> GridContainer:
	if _level_grid == null:
		_level_grid = get_node_or_null("Margin/VBox/LevelGrid")
	return _level_grid


func _apply_component_state() -> void:
	if not _is_component_ready:
		return
	var level_grid: GridContainer = get_level_grid()
	custom_minimum_size.y = 216.0
	add_theme_stylebox_override("panel", ShellThemeUtil.make_world_card_style(selected))
	ShellThemeUtil.apply_title(_title_label, 26)
	ShellThemeUtil.apply_body(_subtitle_label, ShellThemeUtil.PLUM_SOFT, 18)
	_title_label.text = world_title
	_subtitle_label.text = world_subtitle
	if _progress_pill != null and _progress_pill.has_method("set_value_text"):
		_progress_pill.call("set_value_text", progress_text)
	if level_grid != null:
		level_grid.columns = maxi(1, grid_columns)
