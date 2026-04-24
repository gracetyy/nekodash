## LoadingScreen — simple shell loading state owned by SceneManager.
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

var _target_screen_name: String = "Loading"
var _progress: float = 0.0

@export var _title_label: Label
@export var _progress_bar: ProgressBar
@export var _panel: PanelContainer


func _ready() -> void:
	if _panel == null:
		_panel = get_node_or_null("CenterContainer/LoadingCard")
	if _title_label == null:
		_title_label = get_node_or_null("CenterContainer/LoadingCard/CardMargin/VBox/TitleLabel")
	if _progress_bar == null:
		_progress_bar = get_node_or_null("CenterContainer/LoadingCard/CardMargin/VBox/ProgressBar")
	assert(_panel != null, "_panel not assigned")
	assert(_title_label != null, "_title_label not assigned")
	assert(_progress_bar != null, "_progress_bar not assigned")
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
