class_name IconCircleButton
extends TextureButton

const ShellThemeUtil = preload("res://src/ui/shell_theme.gd")

enum Variant {
	BACK,
	CLOSE,
	PLAY,
	REPLAY,
	HOME,
	UNDO,
	PAUSE,
}

@export var variant: Variant = Variant.BACK

@export_range(40.0, 128.0, 1.0, "or_greater")
var button_size: float = 64.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_component_state()


func _apply_component_state() -> void:
	match variant:
		Variant.CLOSE:
			ShellThemeUtil.apply_circle_close_button(self , button_size)
		Variant.PLAY:
			ShellThemeUtil.apply_circle_play_button(self , button_size)
		Variant.REPLAY:
			ShellThemeUtil.apply_circle_replay_button(self , button_size)
		Variant.HOME:
			ShellThemeUtil.apply_circle_home_button(self , button_size)
		Variant.UNDO:
			ShellThemeUtil.apply_circle_undo_button(self , button_size)
		Variant.PAUSE:
			ShellThemeUtil.apply_circle_pause_button(self , button_size)
		_:
			ShellThemeUtil.apply_circle_back_button(self , button_size)
