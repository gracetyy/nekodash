## PauseMenu — gameplay pause overlay with resume, restart, options, and exit.
class_name PauseMenu
extends CanvasLayer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal resume_requested
signal restart_requested
signal options_requested
signal main_menu_requested

var _resume_btn: BaseButton
var _restart_btn: BaseButton
var _options_btn: BaseButton
var _main_menu_btn: BaseButton
var _panel: PanelContainer
var _backdrop: ColorRect


func _ready() -> void:
	_auto_discover_ui_nodes()
	_connect_signals()
	_connect_navigation()
	_apply_visual_style()
	if _resume_btn != null:
		_resume_btn.grab_focus()


func on_resume_btn_pressed() -> void:
	resume_requested.emit()


func on_restart_btn_pressed() -> void:
	restart_requested.emit()


func on_options_btn_pressed() -> void:
	options_requested.emit()


func on_main_menu_btn_pressed() -> void:
	main_menu_requested.emit()


func _connect_signals() -> void:
	if _resume_btn != null and not _resume_btn.pressed.is_connected(on_resume_btn_pressed):
		_resume_btn.pressed.connect(on_resume_btn_pressed)
	if _restart_btn != null and not _restart_btn.pressed.is_connected(on_restart_btn_pressed):
		_restart_btn.pressed.connect(on_restart_btn_pressed)
	if _options_btn != null and not _options_btn.pressed.is_connected(on_options_btn_pressed):
		_options_btn.pressed.connect(on_options_btn_pressed)
	if _main_menu_btn != null and not _main_menu_btn.pressed.is_connected(on_main_menu_btn_pressed):
		_main_menu_btn.pressed.connect(on_main_menu_btn_pressed)


func _connect_navigation() -> void:
	if not resume_requested.is_connected(_handle_resume_requested):
		resume_requested.connect(_handle_resume_requested)
	if not restart_requested.is_connected(_handle_restart_requested):
		restart_requested.connect(_handle_restart_requested)
	if not options_requested.is_connected(_handle_options_requested):
		options_requested.connect(_handle_options_requested)
	if not main_menu_requested.is_connected(_handle_main_menu_requested):
		main_menu_requested.connect(_handle_main_menu_requested)


func _handle_resume_requested() -> void:
	SceneManager.hide_overlay()


func _handle_restart_requested() -> void:
	SceneManager.hide_overlay()
	var scene: Node = get_tree().current_scene
	if scene != null and scene.has_method("restart_level"):
		scene.restart_level()


func _handle_options_requested() -> void:
	SceneManager.show_overlay(SceneManager.Overlay.OPTIONS, {
		"pause_tree": true,
		"return_overlay": int(SceneManager.Overlay.PAUSE),
		"title": "Paused Options",
	})


func _handle_main_menu_requested() -> void:
	SceneManager.hide_overlay()
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)


func _auto_discover_ui_nodes() -> void:
	_backdrop = get_node_or_null("Backdrop") as ColorRect
	_panel = get_node_or_null("Backdrop/Panel") as PanelContainer
	_resume_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/ResumeBtn") as BaseButton
	_restart_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/RestartBtn") as BaseButton
	_options_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/OptionsBtn") as BaseButton
	_main_menu_btn = get_node_or_null("Backdrop/Panel/Margin/VBox/MainMenuBtn") as BaseButton


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_modal_backdrop(_backdrop)
	ShellThemeUtil.apply_panel(_panel, ShellThemeUtil.CREAM)
	ShellThemeUtil.apply_pill_button(_resume_btn, ShellThemeUtil.GOLD, ShellThemeUtil.GOLD_PRESSED)
	ShellThemeUtil.apply_pill_button(_restart_btn, ShellThemeUtil.MINT, ShellThemeUtil.MINT_PRESSED)
	ShellThemeUtil.apply_pill_button(_options_btn, ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED)
	ShellThemeUtil.apply_pill_button(_main_menu_btn, ShellThemeUtil.BLUSH, ShellThemeUtil.LILAC_PRESSED)
