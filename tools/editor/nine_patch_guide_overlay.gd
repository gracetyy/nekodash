@tool
extends Control
## Draws live 9-slice guides for NinePatchRect nodes while editing the theme board.


@export var source_root_path: NodePath = NodePath("..")
@export var border_color: Color = Color(1.0, 0.42, 0.26, 0.9)
@export var guide_color: Color = Color(0.26, 0.76, 0.98, 0.95)
@export var center_fill_color: Color = Color(0.26, 0.76, 0.98, 0.16)
@export_range(1.0, 4.0, 0.5) var line_width: float = 1.5
@export var show_center_fill: bool = true


var _canvas_rect_cache: Rect2 = Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(Engine.is_editor_hint())
	queue_redraw()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var source_root: Node = get_node_or_null(source_root_path)
	if source_root == null:
		return

	var targets: Array[NinePatchRect] = []
	_collect_targets(source_root, targets)
	_canvas_rect_cache = get_global_rect()

	for patch: NinePatchRect in targets:
		if not is_instance_valid(patch):
			continue
		if not patch.visible:
			continue
		_draw_patch_guides(patch)


func _collect_targets(node: Node, out_targets: Array[NinePatchRect]) -> void:
	for child: Node in node.get_children():
		if child == self:
			continue

		var patch: NinePatchRect = child as NinePatchRect
		if patch != null:
			out_targets.append(patch)

		_collect_targets(child, out_targets)


func _draw_patch_guides(patch: NinePatchRect) -> void:
	var patch_rect_global: Rect2 = patch.get_global_rect()
	var local_position: Vector2 = patch_rect_global.position - _canvas_rect_cache.position
	var patch_rect_local: Rect2 = Rect2(local_position, patch_rect_global.size)
	if patch_rect_local.size.x <= 0.0 or patch_rect_local.size.y <= 0.0:
		return

	draw_rect(patch_rect_local, border_color, false, line_width)

	var source_size: Vector2 = patch_rect_local.size
	if patch.texture != null:
		source_size = patch.texture.get_size()

	var safe_source_width: float = maxf(source_size.x, 1.0)
	var safe_source_height: float = maxf(source_size.y, 1.0)

	var left_ratio: float = float(patch.patch_margin_left) / safe_source_width
	var right_ratio: float = float(patch.patch_margin_right) / safe_source_width
	var top_ratio: float = float(patch.patch_margin_top) / safe_source_height
	var bottom_ratio: float = float(patch.patch_margin_bottom) / safe_source_height

	var left_x: float = patch_rect_local.position.x + (patch_rect_local.size.x * left_ratio)
	var right_x: float = patch_rect_local.end.x - (patch_rect_local.size.x * right_ratio)
	var top_y: float = patch_rect_local.position.y + (patch_rect_local.size.y * top_ratio)
	var bottom_y: float = patch_rect_local.end.y - (patch_rect_local.size.y * bottom_ratio)

	left_x = clampf(left_x, patch_rect_local.position.x, patch_rect_local.end.x)
	right_x = clampf(right_x, patch_rect_local.position.x, patch_rect_local.end.x)
	top_y = clampf(top_y, patch_rect_local.position.y, patch_rect_local.end.y)
	bottom_y = clampf(bottom_y, patch_rect_local.position.y, patch_rect_local.end.y)

	draw_line(
		Vector2(left_x, patch_rect_local.position.y),
		Vector2(left_x, patch_rect_local.end.y),
		guide_color,
		line_width
	)
	draw_line(
		Vector2(right_x, patch_rect_local.position.y),
		Vector2(right_x, patch_rect_local.end.y),
		guide_color,
		line_width
	)
	draw_line(
		Vector2(patch_rect_local.position.x, top_y),
		Vector2(patch_rect_local.end.x, top_y),
		guide_color,
		line_width
	)
	draw_line(
		Vector2(patch_rect_local.position.x, bottom_y),
		Vector2(patch_rect_local.end.x, bottom_y),
		guide_color,
		line_width
	)

	if not show_center_fill:
		return

	var center_position: Vector2 = Vector2(minf(left_x, right_x), minf(top_y, bottom_y))
	var center_size: Vector2 = Vector2(absf(right_x - left_x), absf(bottom_y - top_y))
	if center_size.x <= 0.0 or center_size.y <= 0.0:
		return

	var center_rect: Rect2 = Rect2(center_position, center_size)
	draw_rect(center_rect, center_fill_color, true)
