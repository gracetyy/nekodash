## LevelCompleteOverlay — modal wrapper that shows level complete UI above gameplay.
class_name LevelCompleteOverlay
extends CanvasLayer

var _pending_params: Dictionary = {}
var _content: LevelCompleteScreen


func receive_scene_params(params: Dictionary) -> void:
	_pending_params = params.duplicate(true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_content = get_node_or_null("Content") as LevelCompleteScreen
	if _content == null:
		push_error("LevelCompleteOverlay: missing Content LevelCompleteScreen instance.")
		return
	_content.process_mode = Node.PROCESS_MODE_ALWAYS

	if not _content.next_level_requested.is_connected(_on_next_level_requested):
		_content.next_level_requested.connect(_on_next_level_requested)
	if not _content.retry_requested.is_connected(_on_retry_requested):
		_content.retry_requested.connect(_on_retry_requested)
	if not _content.world_map_requested.is_connected(_on_world_map_requested):
		_content.world_map_requested.connect(_on_world_map_requested)

	if not _pending_params.is_empty():
		_pending_params["internal_navigation"] = false
		_content.receive_scene_params(_pending_params)
		_content.populate_results()

	var next_btn: BaseButton = _content.find_child("NextLevelBtn", true, false) as BaseButton
	var retry_btn: BaseButton = _content.find_child("RetryBtn", true, false) as BaseButton
	if next_btn != null and next_btn.visible:
		next_btn.grab_focus()
	elif retry_btn != null:
		retry_btn.grab_focus()


func _on_next_level_requested(level_data: LevelData) -> void:
	SceneManager.hide_overlay()
	SceneManager.go_to_level(level_data)


func _on_retry_requested(level_data: LevelData) -> void:
	SceneManager.hide_overlay()
	SceneManager.go_to_level(level_data)


func _on_world_map_requested() -> void:
	SceneManager.hide_overlay()
	SceneManager.go_to(SceneManager.Screen.WORLD_MAP)
