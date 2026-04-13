## CreditsScreen — shell route listing project credits and returning to Main Menu.
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

var _back_btn: BaseButton
var _card: PanelContainer


func _ready() -> void:
	_back_btn = find_child("BackBtn", true, false) as BaseButton
	_card = find_child("CreditsCard", true, false) as PanelContainer
	ShellThemeUtil.apply_panel(_card, ShellThemeUtil.CREAM)
	ShellThemeUtil.apply_pill_button(_back_btn, ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED)
	if _back_btn != null and not _back_btn.pressed.is_connected(_on_back_btn_pressed):
		_back_btn.pressed.connect(_on_back_btn_pressed)
	if _back_btn != null:
		_back_btn.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_to_main_menu()


func _on_back_btn_pressed() -> void:
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)
