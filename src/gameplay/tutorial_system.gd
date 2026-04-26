class_name TutorialSystem
extends CanvasLayer

const TutorialBubbleScene = preload("res://scenes/ui/components/tutorial/TutorialBubble.tscn")
const PillButtonScene = preload("res://scenes/ui/components/buttons/PillButton.tscn")
const PILL_HOVER_WIRED_META: String = "_shell_pill_hover_wired"

const ARROW_DOWN = preload("res://assets/art/ui/icons/arrows/white_down.png")
const ARROW_UP = preload("res://assets/art/ui/icons/arrows/white_up.png")
const ARROW_PURPLE_RIGHT = preload("res://assets/art/ui/icons/arrows/purple_right.png")

var _level_id: String = ""
var _step: int = 0
var _active_bubbles: Array[Control] = []
var _active_arrows: Array[TextureRect] = []
var _skip_btn: BaseButton = null

var _coordinator: Node = null
var _grid_renderer: Node = null
var _sliding_movement: Node = null

var _tutorial_active: bool = false


func _ready() -> void:
	layer = 30 # Above HUD
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)


func initialize(coordinator: Node, level_data: LevelData) -> void:
	if AppSettings.get_tutorial_skipped():
		_cleanup()
		return
		
	_level_id = level_data.level_id
	if _level_id not in ["w1_l1", "w1_l2", "w1_l3"]:
		_cleanup()
		return
		
	_coordinator = coordinator
	_grid_renderer = coordinator.get_node_or_null("GridRenderer")
	_sliding_movement = coordinator.get_node_or_null("SlidingMovement")
	
	if _grid_renderer == null or _sliding_movement == null:
		_cleanup()
		return
		
	_tutorial_active = true
	_step = 0
	
	_sliding_movement.slide_completed.connect(_on_slide_completed)
	
	_create_skip_button()
	_play_current_step()


func _cleanup() -> void:
	_tutorial_active = false
	_clear_current_ui()
	if _skip_btn != null:
		_skip_btn.queue_free()
	if _sliding_movement != null:
		_sliding_movement.forced_direction = Vector2i.ZERO
		if _sliding_movement.slide_completed.is_connected(_on_slide_completed):
			_sliding_movement.slide_completed.disconnect(_on_slide_completed)


func _create_skip_button() -> void:
	_skip_btn = PillButtonScene.instantiate() as BaseButton
	# Disable shared pill hover scaling so tutorial skip button keeps its compact size.
	_skip_btn.set_meta(PILL_HOVER_WIRED_META, true)
	_skip_btn.text = "Skip Tutorial"
	_skip_btn.scale = Vector2(0.55, 0.55)
	add_child(_skip_btn)
	_skip_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_position_skip_button()
	_position_skip_button.call_deferred()
	
	_skip_btn.pressed.connect(_on_skip_pressed)


func _position_skip_button() -> void:
	if _skip_btn == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	_skip_btn.reset_size()
	var button_size: Vector2 = _skip_btn.get_combined_minimum_size() * _skip_btn.scale
	var pos_x: float = maxf(0.0, viewport_size.x - button_size.x - 16.0)
	var pos_y: float = maxf(0.0, viewport_size.y - button_size.y - 16.0)
	_skip_btn.position = Vector2(pos_x, pos_y)


func _on_viewport_size_changed() -> void:
	_position_skip_button()


func _on_skip_pressed() -> void:
	AppSettings.set_tutorial_skipped(true)
	_cleanup()


func _play_current_step() -> void:
	_clear_current_ui()
	if not _tutorial_active:
		return
		
	match _level_id:
		"w1_l1":
			_play_w1_l1_step()
		"w1_l2":
			_play_w1_l2_step()
		"w1_l3":
			_play_w1_l3_step()


func _clear_current_ui() -> void:
	for b in _active_bubbles:
		if b != null:
			b.queue_free()
	_active_bubbles.clear()
	for a in _active_arrows:
		if a != null:
			a.queue_free()
	_active_arrows.clear()


func _show_bubble(grid_pos: Vector2i, text: String, point_down: bool = true) -> void:
	_show_bubble_with_options(grid_pos, text, point_down, true, Vector2.ZERO)


func _show_bubble_no_arrow(
	grid_pos: Vector2i,
	text: String,
	point_down: bool = true,
	bubble_offset: Vector2 = Vector2.ZERO
) -> void:
	_show_bubble_with_options(grid_pos, text, point_down, false, bubble_offset)


func _show_bubble_with_options(
	grid_pos: Vector2i,
	text: String,
	point_down: bool,
	show_arrow: bool,
	bubble_offset: Vector2
) -> void:
	var bubble = TutorialBubbleScene.instantiate() as Control
	bubble.custom_minimum_size.x = 220
	bubble.size.x = 220
	if bubble.has_method("apply_text"):
		bubble.apply_text(text)
	else:
		var label = bubble.get_node_or_null("Label")
		if label:
			label.text = text
	add_child(bubble)
	_active_bubbles.append(bubble)
	
	# Position them
	var px: Vector2 = GridSystem.grid_to_pixel(grid_pos) + _grid_renderer.get_grid_offset()
	
	# Force layout update
	bubble.reset_size()
	var b_size = bubble.get_combined_minimum_size()

	var bubble_anchor_pos: Vector2

	if point_down:
		bubble_anchor_pos = px + Vector2(-b_size.x / 2.0, -36.0 - 40.0 - 2.0 - b_size.y + 5.0)
	else:
		bubble_anchor_pos = px + Vector2(-b_size.x / 2.0, 36.0 + 2.0 + 40.0 - 5.0)

	if show_arrow:
		var arrow = TextureRect.new()
		arrow.texture = ARROW_DOWN if point_down else ARROW_UP
		arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		arrow.custom_minimum_size = Vector2(40, 40)
		add_child(arrow)
		_active_arrows.append(arrow)

		if point_down:
			# Arrow points down to top of tile
			arrow.position = px + Vector2(-20, -36 - 40 - 2)
		else:
			# Arrow points up to bottom of tile
			arrow.position = px + Vector2(-20, 36 + 2)

		bubble.position = bubble_anchor_pos + bubble_offset

		# Animation
		var tween: Tween = create_tween().set_loops()
		var move_dist = 6.0
		var base_y = arrow.position.y
		if point_down:
			tween.tween_property(arrow, "position:y", base_y + move_dist, 0.6).set_trans(Tween.TRANS_SINE)
			tween.tween_property(arrow, "position:y", base_y, 0.6).set_trans(Tween.TRANS_SINE)
		else:
			tween.tween_property(arrow, "position:y", base_y - move_dist, 0.6).set_trans(Tween.TRANS_SINE)
			tween.tween_property(arrow, "position:y", base_y, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		bubble.position = bubble_anchor_pos + bubble_offset
		
	# Keep bubble on-screen
	var screen_width = 540.0
	bubble.position.x = clampf(bubble.position.x, 10.0, screen_width - b_size.x - 10.0)


func _show_directional_arrow(grid_pos: Vector2i, texture: Texture2D) -> void:
	var arrow = TextureRect.new()
	arrow.texture = texture
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.custom_minimum_size = Vector2(48, 48)
	add_child(arrow)
	_active_arrows.append(arrow)
	
	var px: Vector2 = GridSystem.grid_to_pixel(grid_pos) + _grid_renderer.get_grid_offset()
	arrow.position = px - Vector2(24, 24) # Center on tile
	arrow.scale = Vector2.ONE


func _play_w1_l1_step() -> void:
	var cat_pos: Vector2i = _sliding_movement.get_cat_pos()
	var mode: String = AppSettings.get_effective_input_hint_mode()
	var move_verb: String = "Swipe Right" if mode == AppSettings.INPUT_HINT_TOUCH else "Press D"
	
	match _step:
		0:
			_sliding_movement.forced_direction = Vector2i.RIGHT
			_show_directional_arrow(Vector2i(2, 1), ARROW_PURPLE_RIGHT)
			_show_bubble_no_arrow(Vector2i(2, 1), move_verb + " to move the cat!", true, Vector2(34, 0))
		1:
			_sliding_movement.forced_direction = Vector2i.ZERO
			var prev_cat_pos = Vector2i(3, 1) # Position after first slide
			_show_bubble_no_arrow(prev_cat_pos, "Cat slides continuously until it hits an obstacle or wall.", true)
			_show_bubble(Vector2i(1, 1), "This is a visited tile.", false)
		2:
			_show_bubble(Vector2i(1, 3), "Objective: cover all unvisited tiles!", true)
		3:
			_cleanup() # End of tutorial for l1

func _play_w1_l2_step() -> void:
	match _step:
		0:
			var cat_pos: Vector2i = _sliding_movement.get_cat_pos()
			_show_bubble_no_arrow(cat_pos, "Levels can be completed in multiple ways. Objective is to use the smallest number of moves possible!", true)
		1:
			_cleanup()

func _play_w1_l3_step() -> void:
	match _step:
		0:
			var cat_pos: Vector2i = _sliding_movement.get_cat_pos()
			_show_bubble_no_arrow(cat_pos, "Completing levels with fewer moves earns you more stars!", true)
		1:
			_cleanup()


func _on_slide_completed(from_pos: Vector2i, to_pos: Vector2i, direction: Vector2i, tiles_covered: Array[Vector2i]) -> void:
	if _tutorial_active:
		_sliding_movement.forced_direction = Vector2i.ZERO
		_step += 1
		_play_current_step()


func _find_first_unvisited(exclude_pos: Vector2i) -> Vector2i:
	for y in range(GridSystem.get_height()):
		for x in range(GridSystem.get_width()):
			var pos := Vector2i(x, y)
			if pos != exclude_pos and GridSystem.is_walkable(pos):
				# Ideally check coverage_tracking, but for step 0 it's fine
				return pos
	return Vector2i.ZERO
