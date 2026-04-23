## SkinSelect — placeholder skin selection screen.
## Navigates back to Main Menu via deterministic SceneManager.go_to().
class_name SkinSelect
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")
const PLACEHOLDER_PREVIEW_TEXTURE: Texture2D = preload("res://assets/art/cats/cat_default_idle.png")

@export var _back_btn: BaseButton
@export var _title_label: Label
@export var _status_label: Label
@export var _equip_btn: BaseButton
@export var _skin_grid: GridContainer
var _skin_cards: Array[SkinCard] = []
var _selected_skin_id: String = "cat_default"


func _ready() -> void:
	assert(_back_btn != null, "_back_btn not assigned")
	assert(_title_label != null, "_title_label not assigned")
	assert(_status_label != null, "_status_label not assigned")
	assert(_equip_btn != null, "_equip_btn not assigned")
	assert(_skin_grid != null, "_skin_grid not assigned")

	if not _back_btn.pressed.is_connected(_on_back_btn_pressed):
		_back_btn.pressed.connect(_on_back_btn_pressed)
	if not _equip_btn.pressed.is_connected(_on_equip_btn_pressed):
		_equip_btn.pressed.connect(_on_equip_btn_pressed)
	_apply_local_text_style()
	_configure_placeholder_cards()
	_refresh_selection_state()


func _apply_local_text_style() -> void:
	if _title_label != null:
		ShellThemeUtil.apply_title(_title_label, 44)
	if _status_label != null:
		ShellThemeUtil.apply_body(_status_label, ShellThemeUtil.PLUM_SOFT, 18)


func _configure_placeholder_cards() -> void:
	_skin_cards.clear()
	if _skin_grid == null:
		return

	for child: Node in _skin_grid.get_children():
		if not child is SkinCard:
			continue
		var card: SkinCard = child as SkinCard
		_skin_cards.append(card)
		if not card.pressed.is_connected(_on_skin_card_pressed):
			card.pressed.connect(_on_skin_card_pressed)

	if _skin_cards.size() >= 1:
		_skin_cards[0].configure("cat_default", "Default Cat", PLACEHOLDER_PREVIEW_TEXTURE, SkinCard.CardState.EQUIPPED)
	if _skin_cards.size() >= 2:
		_skin_cards[1].configure("cat_cozy", "Cozy Cat", PLACEHOLDER_PREVIEW_TEXTURE, SkinCard.CardState.UNLOCKED)
	if _skin_cards.size() >= 3:
		_skin_cards[2].configure("cat_stargazer", "Stargazer", PLACEHOLDER_PREVIEW_TEXTURE, SkinCard.CardState.LOCKED, "Complete World 1")

	_selected_skin_id = SaveManager.get_equipped_skin() if SaveManager != null else "cat_default"
	if _selected_skin_id.is_empty():
		_selected_skin_id = "cat_default"


func _refresh_selection_state() -> void:
	for card: SkinCard in _skin_cards:
		card.selected = card.skin_id == _selected_skin_id
	if _status_label != null:
		_status_label.text = "Componentized placeholder skin cards. Runtime cosmetic-data wiring stays deferred."
	if _equip_btn != null:
		_equip_btn.disabled = true


func _on_skin_card_pressed(skin_id: String) -> void:
	_selected_skin_id = skin_id
	_refresh_selection_state()


func _on_equip_btn_pressed() -> void:
	if _status_label != null:
		_status_label.text = "Equip wiring is intentionally deferred until CosmeticDatabase exists."


func _on_back_btn_pressed() -> void:
	SceneManager.go_to(SceneManager.Screen.MAIN_MENU)
