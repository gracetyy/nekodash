@tool
## GlobalCatEditor — visual workspace for editing shared CatRigProfile defaults.
##
## Drag the handle nodes in the 2D viewport to update display offset and pivot
## values in the shared profile resource.
extends Node2D

const CAT_RIG_PATH: NodePath = NodePath("GlobalCatRig")
const DISPLAY_OFFSET_HANDLE_PATH: NodePath = NodePath("DisplayOffsetHandle")
const TAIL_PIVOT_HANDLE_PATH: NodePath = NodePath("TailPivotHandle")
const HEAD_PIVOT_HANDLE_PATH: NodePath = NodePath("HeadPivotHandle")
const BREATHING_HANDLE_PATH: NodePath = NodePath("HeadPivotHandle/BreathingHandle")
const TAIL_PIVOT_GUIDE_PATH: NodePath = NodePath("TailPivotGuide")
const HEAD_PIVOT_GUIDE_PATH: NodePath = NodePath("HeadPivotGuide")
const BREATHING_GUIDE_PATH: NodePath = NodePath("BreathingGuide")


@export_file("*.tres") var profile_path: String = "res://data/cat_rig_defaults.tres"
## Re-syncs handles when profile values change outside this scene.
@export var auto_sync_from_external_profile_changes: bool = true
## Toggle to pull handle positions from current profile values.
@export var sync_handles_from_profile_now: bool = false:
	set(value):
		_sync_handles_from_profile_now_flag = value
		if not value:
			return
		_sync_handles_from_profile_now_flag = false
		_sync_handles_from_profile()
	get:
		return _sync_handles_from_profile_now_flag
## Toggle to save profile changes to disk immediately.
@export var save_profile_now: bool = false:
	set(value):
		_save_profile_now_flag = value
		if not value:
			return
		_save_profile_now_flag = false
		_save_profile()
	get:
		return _save_profile_now_flag
## Shows helper lines from display origin to each pivot handle.
@export var show_pivot_guides: bool = true

@export_category("Head Preview")
## Enables side-to-side head tilt preview in the editor.
@export var preview_head_swing: bool = true
## Maximum head tilt during preview, in degrees.
@export_range(0.0, 30.0, 0.1, "or_greater")
var preview_head_swing_degrees: float = 6.0
## Seconds per full head-swing cycle.
@export_range(0.1, 10.0, 0.01, "or_greater")
var preview_head_swing_period_sec: float = 1.6


var _cat_rig: Node = null
var _display_offset_handle: Node2D = null
var _tail_pivot_handle: Node2D = null
var _head_pivot_handle: Node2D = null
var _breathing_handle: Node2D = null
var _tail_pivot_guide: Line2D = null
var _head_pivot_guide: Line2D = null
var _breathing_guide: Line2D = null

var _profile: CatRigProfile = null
var _sync_handles_from_profile_now_flag: bool = false
var _save_profile_now_flag: bool = false
var _cached_display_handle_position: Vector2 = Vector2.ZERO
var _cached_tail_handle_position: Vector2 = Vector2.ZERO
var _cached_head_handle_position: Vector2 = Vector2.ZERO
var _cached_breathing_handle_position: Vector2 = Vector2.ZERO
var _cached_profile_signature: String = ""
var _head_preview_time_sec: float = 0.0


func _ready() -> void:
	_resolve_nodes()
	_load_profile()
	_apply_profile_to_cat_rig()
	_sync_handles_from_profile()
	set_process(true)
	_apply_head_swing_preview(0.0)


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if not _has_valid_setup():
		return

	if auto_sync_from_external_profile_changes:
		_sync_from_profile_if_changed()

	_sync_profile_from_handles_if_changed()
	_refresh_guide_lines()
	_apply_head_swing_preview(delta)


func _resolve_nodes() -> void:
	_cat_rig = get_node_or_null(CAT_RIG_PATH)
	_display_offset_handle = get_node_or_null(DISPLAY_OFFSET_HANDLE_PATH) as Node2D
	_tail_pivot_handle = get_node_or_null(TAIL_PIVOT_HANDLE_PATH) as Node2D
	_head_pivot_handle = get_node_or_null(HEAD_PIVOT_HANDLE_PATH) as Node2D
	_breathing_handle = get_node_or_null(BREATHING_HANDLE_PATH) as Node2D
	_tail_pivot_guide = get_node_or_null(TAIL_PIVOT_GUIDE_PATH) as Line2D
	_head_pivot_guide = get_node_or_null(HEAD_PIVOT_GUIDE_PATH) as Line2D
	_breathing_guide = get_node_or_null(BREATHING_GUIDE_PATH) as Line2D


func _load_profile() -> void:
	_profile = null
	if profile_path.is_empty():
		push_warning("GlobalCatEditor: profile_path is empty.")
		return
	if not ResourceLoader.exists(profile_path):
		push_warning("GlobalCatEditor: profile path does not exist: %s" % profile_path)
		return

	var loaded_resource: Resource = load(profile_path)
	_profile = loaded_resource as CatRigProfile
	if _profile == null:
		push_warning("GlobalCatEditor: profile is not a CatRigProfile: %s" % profile_path)
		return

	_cached_profile_signature = _build_profile_signature()


func _apply_profile_to_cat_rig() -> void:
	if _cat_rig == null or _profile == null:
		return

	_cat_rig.set("local_profile_override", _profile)
	_cat_rig.set("use_global_profile", true)
	_cat_rig.set("override_display_locally", false)
	_cat_rig.set("override_pivots_locally", false)
	_cat_rig.set("override_idle_locally", false)
	_cat_rig.set("override_face_locally", false)
	_cat_rig.set("auto_refresh_in_editor", true)
	if _cat_rig.has_method("refresh_rig"):
		_cat_rig.call("refresh_rig")


func _sync_handles_from_profile() -> void:
	if _profile == null:
		return
	if _display_offset_handle == null or _tail_pivot_handle == null or _head_pivot_handle == null or _breathing_handle == null:
		return

	_display_offset_handle.position = _profile.display_offset
	_tail_pivot_handle.position = _profile.display_offset + _profile.tail_pivot_source_px
	_head_pivot_handle.position = _profile.display_offset + _profile.head_pivot_source_px
	_breathing_handle.position = Vector2(0.0, -_profile.idle_head_breath_amplitude_px)
	_cache_handle_positions()
	_refresh_guide_lines()


func _sync_profile_from_handles_if_changed() -> void:
	if _profile == null:
		return

	var display_position: Vector2 = _display_offset_handle.position
	var tail_position: Vector2 = _tail_pivot_handle.position
	var head_position: Vector2 = _head_pivot_handle.position
	var breathing_position_local: Vector2 = _breathing_handle.position
	var breathing_distance_px: float = absf(breathing_position_local.y)
	breathing_position_local = Vector2(0.0, -breathing_distance_px)
	if _breathing_handle.position != breathing_position_local:
		_breathing_handle.position = breathing_position_local

	if display_position == _cached_display_handle_position \
	and tail_position == _cached_tail_handle_position \
	and head_position == _cached_head_handle_position \
	and breathing_position_local == _cached_breathing_handle_position:
		return

	_profile.display_offset = display_position
	_profile.tail_pivot_source_px = tail_position - display_position
	_profile.head_pivot_source_px = head_position - display_position
	_profile.idle_head_breath_amplitude_px = breathing_distance_px

	_cache_handle_positions()
	_cached_profile_signature = _build_profile_signature()
	_apply_profile_to_cat_rig()


func _sync_from_profile_if_changed() -> void:
	if _profile == null:
		return
	var signature: String = _build_profile_signature()
	if signature == _cached_profile_signature:
		return

	_cached_profile_signature = signature
	_sync_handles_from_profile()
	_apply_profile_to_cat_rig()


func _cache_handle_positions() -> void:
	_cached_display_handle_position = _display_offset_handle.position
	_cached_tail_handle_position = _tail_pivot_handle.position
	_cached_head_handle_position = _head_pivot_handle.position
	_cached_breathing_handle_position = _breathing_handle.position


func _refresh_guide_lines() -> void:
	if _tail_pivot_guide != null:
		_tail_pivot_guide.visible = show_pivot_guides
		_tail_pivot_guide.points = PackedVector2Array([
			_display_offset_handle.position,
			_tail_pivot_handle.position,
		])
	if _head_pivot_guide != null:
		_head_pivot_guide.visible = show_pivot_guides
		_head_pivot_guide.points = PackedVector2Array([
			_display_offset_handle.position,
			_head_pivot_handle.position,
		])
	if _breathing_guide != null:
		_breathing_guide.visible = show_pivot_guides
		_breathing_guide.points = PackedVector2Array([
			_head_pivot_handle.position,
			_head_pivot_handle.position + _breathing_handle.position,
		])


func _save_profile() -> void:
	if _profile == null:
		return
	var save_error: Error = ResourceSaver.save(_profile, profile_path)
	if save_error != OK:
		push_warning("GlobalCatEditor: failed to save profile (%s): %s" % [profile_path, error_string(save_error)])


func _build_profile_signature() -> String:
	if _profile == null:
		return "null"

	var parts: PackedStringArray = [
		_profile.default_skin_id,
		_profile.face_variant,
		str(_profile.display_size_px),
		str(_profile.display_offset),
		str(_profile.tail_pivot_source_px),
		str(_profile.head_pivot_source_px),
		str(_profile.idle_enabled),
		str(_profile.idle_tail_swing_period_sec),
		str(_profile.idle_tail_swing_degrees),
		str(_profile.idle_head_breath_period_sec),
		str(_profile.idle_head_breath_amplitude_px),
	]
	return "|".join(parts)


func _has_valid_setup() -> bool:
	return _profile != null \
		and _display_offset_handle != null \
		and _tail_pivot_handle != null \
		and _head_pivot_handle != null \
		and _breathing_handle != null


func _apply_head_swing_preview(delta: float) -> void:
	if _cat_rig == null:
		return

	var tilt_callable: Callable = Callable(_cat_rig, "set_head_tilt_immediate")
	if not tilt_callable.is_valid():
		return

	if not preview_head_swing or preview_head_swing_degrees <= 0.0 or preview_head_swing_period_sec <= 0.0:
		_head_preview_time_sec = 0.0
		tilt_callable.call(0.0)
		return

	_head_preview_time_sec += delta
	var cycle: float = (_head_preview_time_sec / preview_head_swing_period_sec) * TAU
	var tilt_degrees: float = sin(cycle) * preview_head_swing_degrees
	tilt_callable.call(tilt_degrees)
