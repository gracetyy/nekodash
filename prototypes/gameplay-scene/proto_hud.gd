# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can we display move count and coverage in a simple HUD?
# Date: 2026-04-01
extends Node2D

var _moves_text: String = "Moves: 0 / 0"
var _coverage_text: String = "Coverage: 0 / 0"
var _complete_text: String = ""
var _controls_text: String = "WASD/Arrows: Move | R: Restart | 1/2/3: Switch Level"


func update_moves(current: int, minimum: int) -> void:
	_moves_text = "Moves: %d / %d" % [current, minimum]
	queue_redraw()


func update_coverage(covered: int, total: int) -> void:
	var pct: float = (float(covered) / float(total) * 100.0) if total > 0 else 0.0
	_coverage_text = "Coverage: %d / %d (%.0f%%)" % [covered, total, pct]
	queue_redraw()


func show_complete_message(moves: int, minimum: int) -> void:
	if moves <= minimum:
		_complete_text = "PERFECT! Level Complete!"
	else:
		_complete_text = "Level Complete! (Optimal: %d moves)" % minimum
	queue_redraw()


func hide_complete_message() -> void:
	_complete_text = ""
	queue_redraw()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 18
	var y_offset: float = 10.0

	# Background bar
	draw_rect(Rect2(0, 0, 400, 90), Color(0, 0, 0, 0.6), true)

	# Move counter
	draw_string(font, Vector2(10, y_offset + 14), _moves_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

	# Coverage
	draw_string(font, Vector2(10, y_offset + 36), _coverage_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.CYAN)

	# Controls hint
	draw_string(font, Vector2(10, y_offset + 56), _controls_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))

	# Complete message
	if _complete_text != "":
		var complete_y: float = y_offset + 80
		draw_rect(Rect2(0, complete_y - 10, 400, 35), Color(0.1, 0.5, 0.1, 0.8), true)
		draw_string(font, Vector2(10, complete_y + 14), _complete_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.YELLOW)
