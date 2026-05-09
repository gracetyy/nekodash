class_name SkinCard
extends PanelContainer

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal pressed(skin_id: String)
signal locked_pressed(skin_id: String)

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

@export var selected: bool = false:
	set(val):
		selected = val
		if is_inside_tree():
			_apply_component_state()

@onready var _preview: Control = $VBox/Preview
@onready var _preview_cat: CatRig = $VBox/Preview/CatRig
@onready var _name_label: Label = $VBox/NameLabel
@onready var _hint_label: Label = $VBox/UnlockHintLabel
@onready var _equipped_badge: BadgeEquipped = $VBox/EquippedBadge
@onready var _lock_overlay: Control = $LockOverlay
@onready var _lock_icon: TextureRect = $LockOverlay/LockIcon
@onready var _selection_highlight: Control = $SelectionHighlight
@onready var _overlay_button: Button = $OverlayButton


func _ready() -> void:
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	_overlay_button.add_theme_stylebox_override("normal", empty_style)
	_overlay_button.add_theme_stylebox_override("hover", empty_style)
	_overlay_button.add_theme_stylebox_override("pressed", empty_style)
	_overlay_button.add_theme_stylebox_override("focus", empty_style)
	if OS.has_feature("web"):
		# Web exports can delay click release; fire on press for snappier UI.
		_overlay_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
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
		_preview_cat.display_size_px = 100.0
		_preview_cat.refresh_rig()
	_name_label.text = skin_name
	ShellThemeUtil.apply_body(_name_label, ShellThemeUtil.PLUM, 20)
	_hint_label.text = unlock_hint
	ShellThemeUtil.apply_body(_hint_label, ShellThemeUtil.PLUM_SOFT, 14)
	_hint_label.visible = card_state == CardState.LOCKED and unlock_hint.strip_edges() != ""
	_equipped_badge.visible = card_state == CardState.EQUIPPED
	_lock_overlay.visible = card_state == CardState.LOCKED
	_lock_icon.texture = ShellThemeUtil.WORLD_MAP_LOCK_TEXTURE
	_selection_highlight.visible = selected and card_state != CardState.LOCKED
	_preview.modulate = Color(1.0, 1.0, 1.0, 1.0) if card_state != CardState.LOCKED else Color(0.8, 0.8, 0.8, 1.0)


func _make_card_style() -> StyleBoxFlat:
	var fill: Color = ShellThemeUtil.CREAM
	var border: Color = ShellThemeUtil.PLUM_SOFT
	var border_width: int = 2
	
	if card_state == CardState.LOCKED:
		fill = ShellThemeUtil.DISABLED_FILL
		border = ShellThemeUtil.PLUM_SOFT
	
	if selected and card_state != CardState.LOCKED:
		border = Color("#a083bd")
		border_width = 6
	elif card_state == CardState.EQUIPPED:
		fill = ShellThemeUtil.CREAM
		border = ShellThemeUtil.GOLD
		border_width = 4
		
	var style: StyleBoxFlat = ShellThemeUtil.make_rounded_style(fill, border, 20, border_width)
	style.content_margin_left = 16.0
	style.content_margin_top = 16.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 16.0
	return style


func _on_overlay_pressed() -> void:
	if card_state == CardState.LOCKED:
		_play_locked_feedback()
		locked_pressed.emit(skin_id)
		return
	pressed.emit(skin_id)


func _play_locked_feedback() -> void:
	if SfxManager != null:
		SfxManager.play_locked()
	
	if AppSettings != null and AppSettings.get_reduce_motion():
		if _lock_icon != null:
			_lock_icon.modulate = Color(1.0, 0.92, 0.92, 1.0)
			var tint_tween: Tween = _lock_icon.create_tween()
			tint_tween.tween_property(_lock_icon, "modulate", Color.WHITE, 0.12)
		return

	pivot_offset = size * 0.5
	scale = Vector2.ONE
	if _lock_icon != null:
		_lock_icon.pivot_offset = _lock_icon.size * 0.5
		_lock_icon.scale = Vector2.ONE
		_lock_icon.rotation_degrees = 0.0

	var card_tween: Tween = create_tween()
	card_tween.tween_property(self , "scale", Vector2(0.96, 0.96), 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card_tween.tween_property(self , "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _lock_icon != null:
		var lock_jiggle: float = 14.0
		var lock_tween: Tween = _lock_icon.create_tween()
		lock_tween.tween_property(_lock_icon, "rotation_degrees", -lock_jiggle, 0.06)
		lock_tween.tween_property(_lock_icon, "rotation_degrees", lock_jiggle * 0.7, 0.08)
		lock_tween.tween_property(_lock_icon, "rotation_degrees", 0.0, 0.08)
		lock_tween.parallel().tween_property(_lock_icon, "scale", Vector2(1.12, 1.12), 0.08)
		lock_tween.tween_property(_lock_icon, "scale", Vector2.ONE, 0.14)
