class_name ScreenBackdrop
extends Control

@export var scrim_color: Color = Color(1.0, 0.988235, 0.941176, 0.8)

@onready var _scrim: ColorRect = $Scrim


func _ready() -> void:
	_apply_component_state()


func _apply_component_state() -> void:
	_scrim.color = scrim_color
