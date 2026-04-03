# PROTOTYPE - NOT FOR PRODUCTION
# Question: Do the new draft UI assets create a cohesive kawaii visual identity
#           when assembled into actual game screens?
# Date: 2026-04-03
extends Control

# Screen management
var current_screen: int = 0
var screens: Array[Control] = []

func _ready() -> void:
	# Collect all screen children
	for child in get_children():
		if child is Control and child.name != "ScreenLabel" and child.name != "ScreenLabelBg":
			screens.append(child)
			child.visible = false
	if screens.size() > 0:
		screens[0].visible = true
	_update_label()
	_connect_buttons()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_next_screen()
	elif event.is_action_pressed("ui_left"):
		_prev_screen()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _next_screen() -> void:
	if screens.size() == 0:
		return
	screens[current_screen].visible = false
	current_screen = (current_screen + 1) % screens.size()
	screens[current_screen].visible = true
	_update_label()

func _prev_screen() -> void:
	if screens.size() == 0:
		return
	screens[current_screen].visible = false
	current_screen = (current_screen - 1 + screens.size()) % screens.size()
	screens[current_screen].visible = true
	_update_label()

func _update_label() -> void:
	var label: Label = get_node_or_null("ScreenLabelBg/ScreenLabel") as Label
	if not label:
		return
	var names: Array[String] = ["Main Menu", "Gameplay HUD", "Level Complete", "World Map"]
	var name_str: String = names[current_screen] if current_screen < names.size() else "Screen %d" % current_screen
	label.text = "[%d/%d] %s  (← → to navigate, ESC to quit)" % [current_screen + 1, screens.size(), name_str]


func _show_screen(index: int) -> void:
	if index < 0 or index >= screens.size():
		return
	screens[current_screen].visible = false
	current_screen = index
	screens[current_screen].visible = true
	_update_label()


func _connect_buttons() -> void:
	# Main Menu buttons
	var play_btn: BaseButton = get_node_or_null("MainMenu/VBox/ButtonArea/PlayBtnBg")
	if play_btn:
		play_btn.pressed.connect(_show_screen.bind(1)) # Go to Gameplay HUD
	var skins_btn: BaseButton = get_node_or_null("MainMenu/VBox/ButtonArea/SkinsBtnBg")
	if skins_btn:
		skins_btn.pressed.connect(_show_screen.bind(3)) # Go to World Map (skins placeholder)

	# Gameplay HUD buttons
	var exit_btn: BaseButton = get_node_or_null("GameplayHUD/HUDBottom/ExitBtnBg")
	if exit_btn:
		exit_btn.pressed.connect(_show_screen.bind(0)) # Back to Main Menu
	var undo_btn: BaseButton = get_node_or_null("GameplayHUD/HUDBottom/UndoBtnBg")
	if undo_btn:
		undo_btn.pressed.connect(func() -> void: print("[Proto] Undo pressed"))
	var restart_btn: BaseButton = get_node_or_null("GameplayHUD/HUDBottom/RestartBtnBg")
	if restart_btn:
		restart_btn.pressed.connect(func() -> void: print("[Proto] Restart pressed"))

	# Level Complete buttons
	var next_btn: BaseButton = get_node_or_null("LevelComplete/VBox/ButtonsVBox/NextBtnBg")
	if next_btn:
		next_btn.pressed.connect(func() -> void: print("[Proto] Next Level pressed"))
	var retry_btn: BaseButton = get_node_or_null("LevelComplete/VBox/ButtonsVBox/RetryBtnBg")
	if retry_btn:
		retry_btn.pressed.connect(_show_screen.bind(1)) # Back to Gameplay
	var map_btn: BaseButton = get_node_or_null("LevelComplete/VBox/ButtonsVBox/MapBtnBg")
	if map_btn:
		map_btn.pressed.connect(_show_screen.bind(3)) # Go to World Map

	# World Map buttons
	var back_btn: BaseButton = get_node_or_null("WorldMap/VBox/BackBtnBg")
	if back_btn:
		back_btn.pressed.connect(_show_screen.bind(0)) # Back to Main Menu
