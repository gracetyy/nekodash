class_name ConfirmNavigationModal
extends Control

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

signal confirmed
signal canceled

@export var _backdrop: ColorRect
@export var _ribbon: RibbonHeader
@export var _panel: PanelContainer
@export var _body_label: Label
@export var _confirm_btn: Button
@export var _cancel_btn: Button


func _ready() -> void:
	if _backdrop == null:
		_backdrop = get_node_or_null("Backdrop")
	if _ribbon == null:
		_ribbon = get_node_or_null("Ribbon") as RibbonHeader
	if _panel == null:
		_panel = get_node_or_null("Panel") as PanelContainer
	if _body_label == null:
		_body_label = get_node_or_null("Panel/Margin/VBox/BodyLabel") as Label
	if _confirm_btn == null:
		_confirm_btn = get_node_or_null("Panel/Margin/VBox/ButtonRow/ConfirmBtn") as Button
	if _cancel_btn == null:
		_cancel_btn = get_node_or_null("Panel/Margin/VBox/ButtonRow/CancelBtn") as Button

	assert(_backdrop != null, "_backdrop not assigned")
	assert(_ribbon != null, "_ribbon not assigned")
	assert(_panel != null, "_panel not assigned")
	assert(_body_label != null, "_body_label not assigned")
	assert(_confirm_btn != null, "_confirm_btn not assigned")
	assert(_cancel_btn != null, "_cancel_btn not assigned")

	if not _confirm_btn.pressed.is_connected(_on_confirm_btn_pressed):
		_confirm_btn.pressed.connect(_on_confirm_btn_pressed)
	if not _cancel_btn.pressed.is_connected(_on_cancel_btn_pressed):
		_cancel_btn.pressed.connect(_on_cancel_btn_pressed)
	if not resized.is_connected(_on_modal_resized):
		resized.connect(_on_modal_resized)

	_apply_visual_style()
	_on_modal_resized()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel_btn_pressed()


func show_modal(
	title_text: String,
	body_text: String,
	confirm_text: String = "Go to Level Select",
	cancel_text: String = "Stay"
) -> void:
	if _ribbon != null:
		_ribbon.set_title(title_text)
	if _body_label != null:
		_body_label.text = body_text
	if _confirm_btn != null:
		_confirm_btn.text = confirm_text
	if _cancel_btn != null:
		_cancel_btn.text = cancel_text

	visible = true
	_on_modal_resized()
	_play_intro_animation()
	_cancel_btn.grab_focus()


func hide_modal() -> void:
	visible = false
	if _panel != null:
		_panel.scale = Vector2.ONE
		_panel.modulate = Color.WHITE


func _on_confirm_btn_pressed() -> void:
	hide_modal()
	confirmed.emit()


func _on_cancel_btn_pressed() -> void:
	hide_modal()
	canceled.emit()


func _on_modal_resized() -> void:
	_layout_to_viewport()


func _layout_to_viewport() -> void:
	if _panel == null or _ribbon == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_width: float = clampf(viewport_size.x - 36.0, 300.0, 440.0)
	var panel_height: float = clampf(viewport_size.y - 140.0, 220.0, 320.0)

	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = - panel_width * 0.5
	_panel.offset_top = - panel_height * 0.5 + 34.0
	_panel.offset_right = panel_width * 0.5
	_panel.offset_bottom = panel_height * 0.5 + 34.0

	var ribbon_width: float = panel_width + 64.0
	var ribbon_top: float = _panel.offset_top - 72.0
	_ribbon.anchor_left = 0.5
	_ribbon.anchor_top = 0.5
	_ribbon.anchor_right = 0.5
	_ribbon.anchor_bottom = 0.5
	_ribbon.offset_left = - ribbon_width * 0.5
	_ribbon.offset_top = ribbon_top
	_ribbon.offset_right = ribbon_width * 0.5
	_ribbon.offset_bottom = ribbon_top + 90.0


func _apply_visual_style() -> void:
	ShellThemeUtil.apply_modal_backdrop(_backdrop)
	if _body_label != null:
		ShellThemeUtil.apply_body(_body_label, ShellThemeUtil.PLUM, 22)
		_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _play_intro_animation() -> void:
	if _panel == null:
		return
	if AppSettings != null and AppSettings.get_reduce_motion():
		_panel.scale = Vector2.ONE
		_panel.modulate = Color.WHITE
		return
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.96, 0.96)
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
