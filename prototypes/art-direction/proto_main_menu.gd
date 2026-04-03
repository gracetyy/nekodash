# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the kawaii art direction feel cohesive across UI screens?
# Date: 2026-04-03
extends Control

var _cat_bob_time: float = 0.0

func _process(delta: float) -> void:
	_cat_bob_time += delta
	var cat: Control = get_node_or_null("VBox/CatArea/CatSprite")
	if cat:
		cat.position.y = sin(_cat_bob_time * 2.0) * 4.0
