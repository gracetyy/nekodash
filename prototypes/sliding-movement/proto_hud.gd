# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does slide-until-wall movement feel satisfying on mobile touch input?
# Date: 2026-03-31
#
# HUD overlay: shows move count, coverage, and tuning knob values.
# Press R to restart. Press 1/2/3 to change slide speed presets.

extends Node2D

var _cat: Node2D
var _grid: Node2D

var _move_count: int = 0
var _speed_label: String = "Default (15 t/s)"


func _ready() -> void:
	_cat = get_parent().get_node("ProtoCat")
	_grid = get_parent().get_node("ProtoGrid")
	_cat.slide_completed.connect(_on_slide_completed)
	_cat.slide_blocked.connect(_on_slide_blocked)


func _on_slide_completed(_from: Vector2i, _to: Vector2i, _dir: Vector2i, _tiles: Array[Vector2i]) -> void:
	_move_count += 1
	queue_redraw()


func _on_slide_blocked(_pos: Vector2i, _dir: Vector2i) -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Background bar
	var bar_rect := Rect2(0, 0, 450, 30)
	draw_rect(bar_rect, Color(0, 0, 0, 0.5))

	# Coverage count
	var all_w: Array[Vector2i] = _grid.get_all_walkable()
	var covered: int = 0
	for t: Vector2i in all_w:
		if _grid._covered_tiles.has(t):
			covered += 1

	var text: String = "Moves: %d | Coverage: %d/%d | Speed: %s | R=Restart" % [_move_count, covered, all_w.size(), _speed_label]
	draw_string(ThemeDB.fallback_font, Vector2(8, 20), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
