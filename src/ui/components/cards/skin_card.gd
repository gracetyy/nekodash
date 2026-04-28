class_name SkinCard
extends PanelContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal pressed(skin_id: String)

enum CardState {
	UNLOCKED,
	LOCKED,
	EQUIPPED,
}

@export var skin_id: String = ""
@export var skin_name: String = "Default Cat"

@export var unlock_hint: String = ""

@export var preview_pose_variant: String = "idle"

@export var card_state: CardState = CardState.UNLOCKED

@export var selected: bool = false

@onready var _preview: Control = $CardMargin/VBox/Preview
@onready var _preview_cat: CatRig = $CardMargin/VBox/Preview/CatRig
@onready var _name_label: Label = $CardMargin/VBox/NameLabel
@onready var _hint_label: Label = $CardMargin/VBox/UnlockHintLabel
@onready var _equipped_badge: BadgeEquipped = $CardMargin/VBox/EquippedBadge
@onready var _lock_overlay: Control = $CardMargin/LockOverlay
@onready var _lock_icon: TextureRect = $CardMargin/LockOverlay/LockIcon
@onready var _overlay_button: Button = $OverlayButton


func _ready() -> void:
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	_overlay_button.add_theme_stylebox_override("normal", empty_style)
	_overlay_button.add_theme_stylebox_override("hover", empty_style)
	_overlay_button.add_theme_stylebox_override("pressed", empty_style)
	_overlay_button.add_theme_stylebox_override("focus", empty_style)
	if not _overlay_button.pressed.is_connected(_on_overlay_pressed):
		_overlay_button.pressed.connect(_on_overlay_pressed)
	_apply_component_state()


func configure(new_skin_id: String, display_name: String, pose_variant: String, state: CardState, hint_text: String = "") -> void:
	skin_id = new_skin_id
	skin_name = display_name
	preview_pose_variant = pose_variant
	card_state = state
	unlock_hint = hint_text
	_apply_component_state()


func _apply_component_state() -> void:
	add_theme_stylebox_override("panel", _make_card_style())
	if _preview_cat != null:
		_preview_cat.skin_id_override = skin_id
		_preview_cat.pose_variant = preview_pose_variant
		_preview_cat.display_size_px = 72.0
		_preview_cat.refresh_rig()
	_name_label.text = skin_name
	ShellThemeUtil.apply_body(_name_label, ShellThemeUtil.PLUM, 20)
	_hint_label.text = unlock_hint
	ShellThemeUtil.apply_body(_hint_label, ShellThemeUtil.PLUM_SOFT, 14)
	_hint_label.visible = card_state == CardState.LOCKED and unlock_hint.strip_edges() != ""
	_equipped_badge.visible = card_state == CardState.EQUIPPED
	_lock_overlay.visible = card_state == CardState.LOCKED
	_lock_icon.texture = ShellThemeUtil.WORLD_MAP_LOCK_TEXTURE
	_preview.modulate = Color(1.0, 1.0, 1.0, 1.0) if card_state != CardState.LOCKED else Color(0.8, 0.8, 0.8, 1.0)


func _make_card_style() -> StyleBoxFlat:
	var fill: Color = ShellThemeUtil.CREAM
	var border: Color = ShellThemeUtil.PLUM_SOFT
	var border_width: int = 2
	if card_state == CardState.LOCKED:
		fill = ShellThemeUtil.DISABLED_FILL
		border = ShellThemeUtil.PLUM_SOFT
	elif card_state == CardState.EQUIPPED:
		fill = ShellThemeUtil.CREAM
		border = ShellThemeUtil.GOLD
		border_width = 4
	elif selected:
		fill = ShellThemeUtil.CREAM_SOFT
		border = ShellThemeUtil.LILAC
		border_width = 4
	var style: StyleBoxFlat = ShellThemeUtil.make_rounded_style(fill, border, 20, border_width)
	style.content_margin_left = 12.0
	style.content_margin_top = 12.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 12.0
	return style


func _on_overlay_pressed() -> void:
	pressed.emit(skin_id)
