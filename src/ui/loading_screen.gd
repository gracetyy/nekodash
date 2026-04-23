## LoadingScreen — simple shell loading state owned by SceneManager.
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

var _target_screen_name: String = "Loading"
var _progress: float = 0.0

var _title_label: Label
var _progress_bar: ProgressBar
var _panel: PanelContainer


func _ready() -> void:
	_panel = find_child("LoadingCard", true, false) as PanelContainer
	_title_label = find_child("TitleLabel", true, false) as Label
	_progress_bar = find_child("ProgressBar", true, false) as ProgressBar
	ShellThemeUtil.apply_progress_bar(_progress_bar)
	_refresh()


func receive_scene_params(params: Dictionary) -> void:
	_target_screen_name = str(params.get("target_screen_name", "Loading"))
	_progress = params.get("progress", 0.0) as float


func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	_refresh()


func _refresh() -> void:
	if _title_label != null:
		_title_label.text = "Loading %s" % _target_screen_name
	if _progress_bar != null:
		_progress_bar.value = _progress * 100.0
