## LevelCompleteOverlay — modal wrapper that shows level complete UI above gameplay.
class_name LevelCompleteOverlay
extends CanvasLayer

var _pending_params: Dictionary = {}
@export var _content: Control
@export var _next_btn: BaseButton
@export var _retry_btn: BaseButton


func receive_scene_params(params: Dictionary) -> void:
	_pending_params = params.duplicate(true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	assert(_content != null, "_content not assigned")
	assert(_next_btn != null, "_next_btn not assigned")
	assert(_retry_btn != null, "_retry_btn not assigned")
	_content.process_mode = Node.PROCESS_MODE_ALWAYS

	if not _content.next_level_requested.is_connected(_on_next_level_requested):
		_content.next_level_requested.connect(_on_next_level_requested)
	if not _content.retry_requested.is_connected(_on_retry_requested):
		_content.retry_requested.connect(_on_retry_requested)
	if not _content.world_map_requested.is_connected(_on_world_map_requested):
		_content.world_map_requested.connect(_on_world_map_requested)

	if not _pending_params.is_empty():
		call_deferred("_apply_pending_params")

	if _next_btn.visible:
		_next_btn.grab_focus()
	else:
		_retry_btn.grab_focus()


func _apply_pending_params() -> void:
	if _content == null or _pending_params.is_empty():
		return
	await get_tree().process_frame
	var params: Dictionary = _pending_params.duplicate(true)
	params["internal_navigation"] = false
	_content.receive_scene_params(params)
	_content.populate_results()


func _on_next_level_requested(level_data: LevelData) -> void:
	SceneManager.hide_overlay()
	SceneManager.go_to_level(level_data)


func _on_retry_requested(level_data: LevelData) -> void:
	SceneManager.hide_overlay()
	SceneManager.go_to_level(level_data)


func _on_world_map_requested() -> void:
	SceneManager.hide_overlay()
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP)
