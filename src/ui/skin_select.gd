## SkinSelect — placeholder skin selection screen.
## Navigates back to Main Menu via deterministic SceneManager.go_to().
class_name SkinSelect
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const ICON_ARROW_LEFT: Texture2D = preload("res://assets/art/ui/icons/pill_interiors/icon_pill_arrow_left.png")

var _back_btn: BaseButton
var _title_label: Label
var _coming_soon_label: Label


func _ready() -> void:
	_back_btn = find_child("BackBtn", true, false) as BaseButton
	_title_label = find_child("TitleLabel", true, false) as Label
	_coming_soon_label = find_child("ComingSoonLabel", true, false) as Label

	if _back_btn != null and not _back_btn.pressed.is_connected(_on_back_btn_pressed):
		_back_btn.pressed.connect(_on_back_btn_pressed)
	_apply_visual_style()


func _apply_visual_style() -> void:
	if _title_label != null:
		ShellThemeUtil.apply_title(_title_label, 44)
	if _coming_soon_label != null:
		ShellThemeUtil.apply_body(_coming_soon_label, ShellThemeUtil.PLUM_SOFT, 24)
	if _back_btn != null:
		ShellThemeUtil.apply_pill_button(_back_btn, ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED)
		if _back_btn is Button:
			var back_button: Button = _back_btn as Button
			back_button.icon = ICON_ARROW_LEFT
			back_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			back_button.expand_icon = false


func _on_back_btn_pressed() -> void:
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)
