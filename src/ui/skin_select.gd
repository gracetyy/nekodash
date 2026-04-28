## SkinSelect — placeholder skin selection screen.
## Navigates back to Main Menu via deterministic SceneManager.go_to().
class_name SkinSelect
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

@export var _back_btn: BaseButton
@export var _title_label: Label
@export var _status_label: Label
@export var _equip_btn: BaseButton
@export var _skin_grid: GridContainer
var _skin_cards: Array[SkinCard] = []
var _selected_skin_id: String = "cat_default"


func _ready() -> void:
	if _back_btn == null:
		_back_btn = get_node_or_null("MarginContainer/VBox/Header/BackBtn")
	if _title_label == null:
		_title_label = get_node_or_null("MarginContainer/VBox/Header/TitleLabel")
	if _status_label == null:
		_status_label = get_node_or_null("MarginContainer/VBox/StatusLabel")
	if _equip_btn == null:
		_equip_btn = get_node_or_null("MarginContainer/VBox/EquipBtn")
	if _skin_grid == null:
		_skin_grid = get_node_or_null("MarginContainer/VBox/SkinGrid")
	assert(_back_btn != null, "_back_btn not assigned")
	assert(_title_label != null, "_title_label not assigned")
	assert(_status_label != null, "_status_label not assigned")
	assert(_equip_btn != null, "_equip_btn not assigned")
	assert(_skin_grid != null, "_skin_grid not assigned")

	if not _back_btn.pressed.is_connected(_on_back_btn_pressed):
		_back_btn.pressed.connect(_on_back_btn_pressed)
	if not _equip_btn.pressed.is_connected(_on_equip_btn_pressed):
		_equip_btn.pressed.connect(_on_equip_btn_pressed)
	
	if AppSettings != null:
		AppSettings.setting_changed.connect(_on_app_setting_changed)

	_apply_local_text_style()
	_populate_skins()
	_refresh_selection_state()


func _exit_tree() -> void:
	if AppSettings != null:
		var changed_callable := Callable(self, "_on_app_setting_changed")
		if AppSettings.setting_changed.is_connected(changed_callable):
			AppSettings.setting_changed.disconnect(changed_callable)


func _on_app_setting_changed(section: String, key: String, _value: Variant) -> void:
	if section == AppSettings.SECTION_SHELL and key == AppSettings.KEY_UNLOCK_ALL_SKINS:
		_populate_skins()
		_refresh_selection_state()


func _apply_local_text_style() -> void:
	if _title_label != null and _title_label.has_method("refresh_style"):
		_title_label.call("refresh_style")
	if _status_label != null:
		ShellThemeUtil.apply_body(_status_label, ShellThemeUtil.PLUM_SOFT, 18)


func _populate_skins() -> void:
	_skin_cards.clear()
	if _skin_grid == null:
		return

	# Clear existing children.
	for child in _skin_grid.get_children():
		child.queue_free()

	var all_skins := CosmeticDatabase.get_all_skins()
	var equipped_id := SaveManager.get_equipped_skin()
	var unlocked_ids := SaveManager.get_unlocked_skins()

	var card_scene: PackedScene = load("res://scenes/ui/components/cards/SkinCard.tscn")

	for skin_data in all_skins:
		var card: SkinCard = card_scene.instantiate()
		_skin_grid.add_child(card)
		_skin_cards.append(card)

		var state := SkinCard.CardState.LOCKED
		if skin_data.skin_id == equipped_id:
			state = SkinCard.CardState.EQUIPPED
		elif skin_data.skin_id in unlocked_ids:
			state = SkinCard.CardState.UNLOCKED

		card.configure(
			skin_data.skin_id,
			skin_data.display_name,
			"idle",
			state,
			skin_data.unlock_hint
		)

		if not card.pressed.is_connected(_on_skin_card_pressed):
			card.pressed.connect(_on_skin_card_pressed)

	_selected_skin_id = equipped_id


func _refresh_selection_state() -> void:
	var equipped_id := SaveManager.get_equipped_skin()
	var unlocked_ids := SaveManager.get_unlocked_skins()

	for card: SkinCard in _skin_cards:
		card.selected = card.skin_id == _selected_skin_id
		
		# Update state if it changed (e.g. after equipping)
		var state := SkinCard.CardState.LOCKED
		if card.skin_id == equipped_id:
			state = SkinCard.CardState.EQUIPPED
		elif card.skin_id in unlocked_ids:
			state = SkinCard.CardState.UNLOCKED
		
		if card.card_state != state:
			card.card_state = state
			if card.has_method("_apply_component_state"):
				card.call("_apply_component_state")

	if _status_label != null:
		var skin_data := CosmeticDatabase.get_skin(_selected_skin_id)
		_status_label.text = skin_data.display_name

	if _equip_btn != null:
		var is_unlocked := _selected_skin_id in unlocked_ids
		var is_already_equipped := _selected_skin_id == equipped_id
		_equip_btn.disabled = not is_unlocked or is_already_equipped


func _on_skin_card_pressed(skin_id: String) -> void:
	_selected_skin_id = skin_id
	_refresh_selection_state()


func _on_equip_btn_pressed() -> void:
	SaveManager.set_equipped_skin(_selected_skin_id)
	_refresh_selection_state()


func _on_back_btn_pressed() -> void:
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)
