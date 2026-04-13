## MainMenu — title screen with navigation to World Map and Skins.
## Task: S3-04 (bug fix — back button target), S4-14 (Skins + CatSprite wiring)
##
## Simple title screen that lets the player start the game by navigating
## to the World Map. Acts as the landing screen and the back-button target
## from WorldMap. Shows CatSprite using the equipped skin placeholder.
class_name MainMenu
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted when the play button is pressed.
signal play_requested


# —————————————————————————————————————————————
# Child node references
# —————————————————————————————————————————————

var _play_btn: BaseButton
var _options_btn: BaseButton
var _credits_btn: BaseButton
var _skins_btn: BaseButton
var _hero_card: PanelContainer
var _hint_label: Label


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_auto_discover_ui_nodes()
	_connect_signals()
	_apply_visual_style()
	_refresh_hint_text()
	if _play_btn != null:
		_play_btn.grab_focus()


# —————————————————————————————————————————————
# Private methods
# —————————————————————————————————————————————

func _auto_discover_ui_nodes() -> void:
	_play_btn = _find_child_safe("PlayBtn", "BaseButton") as BaseButton
	_options_btn = _find_child_safe("OptionsBtn", "BaseButton") as BaseButton
	_credits_btn = _find_child_safe("CreditsBtn", "BaseButton") as BaseButton
	_skins_btn = _find_child_safe("SkinsBtn", "BaseButton") as BaseButton
	_hero_card = _find_child_safe("HeroCard", "PanelContainer") as PanelContainer
	_hint_label = _find_child_safe("HintLabel", "Label") as Label


func _find_child_safe(child_name: String, expected_type: String) -> Node:
	var node: Node = find_child(child_name, true, false)
	if node == null:
		push_warning("MainMenu: expected child '%s' (%s) not found." % [child_name, expected_type])
	return node


func _connect_signals() -> void:
	if _play_btn != null:
		_play_btn.pressed.connect(_on_play_btn_pressed)
	if _options_btn != null:
		_options_btn.pressed.connect(_on_options_btn_pressed)
	if _credits_btn != null:
		_credits_btn.pressed.connect(_on_credits_btn_pressed)
	if _skins_btn != null:
		_skins_btn.pressed.connect(_on_skins_btn_pressed)


func _on_play_btn_pressed() -> void:
	play_requested.emit()
	_navigate_to_world_map()


func _on_options_btn_pressed() -> void:
	SceneManager.show_overlay(SceneManager.Overlay.OPTIONS, {
		"title": "Options",
	})


func _on_credits_btn_pressed() -> void:
	SceneManager.go_to(SceneManager.Screen.CREDITS)


func _on_skins_btn_pressed() -> void:
	SceneManager.go_to(SceneManager.Screen.SKIN_SELECT)


func _navigate_to_world_map() -> void:
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP, {
		"highlight_world_id": AppSettings.get_last_world_id(),
	})


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_panel(_hero_card, ShellThemeUtil.CREAM)
	ShellThemeUtil.apply_pill_button(_play_btn, ShellThemeUtil.GOLD, ShellThemeUtil.GOLD_PRESSED)
	ShellThemeUtil.apply_pill_button(_skins_btn, ShellThemeUtil.MINT, ShellThemeUtil.MINT_PRESSED)
	ShellThemeUtil.apply_pill_button(_options_btn, ShellThemeUtil.LILAC, ShellThemeUtil.LILAC_PRESSED)
	ShellThemeUtil.apply_pill_button(_credits_btn, ShellThemeUtil.BLUSH, ShellThemeUtil.LILAC_PRESSED)


func _refresh_hint_text() -> void:
	if _hint_label == null:
		return
	match AppSettings.get_effective_input_hint_mode():
		AppSettings.INPUT_HINT_TOUCH:
			_hint_label.text = "Tap a button to pick up where your cat left off."
		_:
			_hint_label.text = "Use arrows, tab, or a controller to move focus."
