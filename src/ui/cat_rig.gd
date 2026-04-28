@tool
## CatRig — reusable UI wrapper for the shared cat part rig.
##
## Hosts CatPartRig inside a Control so it can be dropped into UI layouts
## without each screen re-implementing the rig wiring.
class_name CatRig
extends Control


# —————————————————————————————————————————————
# Exports
# —————————————————————————————————————————————

@export_category("Global Profile")
@export var use_global_profile: bool = true
@export_file("*.tres") var global_profile_path: String = "res://data/cat_rig_defaults.tres"
@export var local_profile_override: CatRigProfile
@export var override_display_locally: bool = true
@export var override_pivots_locally: bool = false
@export var override_idle_locally: bool = true
@export var override_face_locally: bool = true
@export var override_pose_locally: bool = true

@export_category("Rig")
@export var skin_id_override: String = ""
@export_enum("idle", "blink", "excited", "relax", "smile") var face_variant: String = "idle"

@export_category("Pose")
@export_enum("custom", "idle", "curious", "happy", "peek", "smile") var pose_variant: String = "idle"
@export_range(-30.0, 30.0, 0.1) var base_head_tilt_degrees: float = 0.0
@export_range(-45.0, 45.0, 0.1) var base_tail_rotation_degrees: float = 0.0

@export_category("Display")
@export_range(16.0, 512.0, 1.0, "or_greater") var display_size_px: float = 92.0
@export var display_offset: Vector2 = Vector2(0.0, -16.0)

@export_category("Pivots")
@export var tail_pivot_source_px: Vector2 = Vector2(15.0, 35.0)
@export var head_pivot_source_px: Vector2 = Vector2(0.0, 8.0)

@export_category("Idle Motion")
@export var idle_enabled: bool = true
@export_range(0.0, 10.0, 0.01, "or_greater") var idle_tail_swing_period_sec: float = 1.45
@export_range(0.0, 60.0, 0.1, "or_greater") var idle_tail_swing_degrees: float = 10.0
@export_range(0.0, 10.0, 0.01, "or_greater") var idle_head_breath_period_sec: float = 2.2
@export_range(0.0, 24.0, 0.1, "or_greater") var idle_head_breath_amplitude_px: float = 2.0

@export_category("Editor")
@export var auto_refresh_in_editor: bool = true


# —————————————————————————————————————————————
# Node refs
# —————————————————————————————————————————————

var _rig: CatPartRig
var _editor_preview_signature: String = ""


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_cache_rig()
	_apply_pose_variant_defaults()
	_apply_to_rig()
	_sync_rig_layout()
	_editor_preview_signature = _build_editor_preview_signature()
	set_process(true)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not auto_refresh_in_editor:
		return
	var signature: String = _build_editor_preview_signature()
	if signature == _editor_preview_signature:
		return
	_editor_preview_signature = signature
	_apply_pose_variant_defaults()
	_apply_to_rig()
	_sync_rig_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_rig_layout()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

func refresh_rig() -> void:
	_cache_rig()
	_apply_pose_variant_defaults()
	_apply_to_rig()
	_sync_rig_layout()


func refresh_skin() -> void:
	if _rig == null:
		_cache_rig()
	if _rig == null:
		return
	_rig.refresh_skin()


# —————————————————————————————————————————————
# Internal helpers
# —————————————————————————————————————————————

func _cache_rig() -> void:
	_rig = get_node_or_null("Rig") as CatPartRig


func _apply_pose_variant_defaults() -> void:
	match pose_variant:
		"idle":
			face_variant = "idle"
			base_head_tilt_degrees = 0.0
			base_tail_rotation_degrees = 0.0
		"curious":
			face_variant = "idle"
			base_head_tilt_degrees = 10.0
			base_tail_rotation_degrees = 8.0
		"happy":
			face_variant = "smile"
			base_head_tilt_degrees = 0.0
			base_tail_rotation_degrees = 0.0
		"peek":
			face_variant = "idle"
			base_head_tilt_degrees = -10.0
			base_tail_rotation_degrees = 12.0
		"smile":
			face_variant = "smile"
			base_head_tilt_degrees = 0.0
			base_tail_rotation_degrees = 0.0
		_:
			pass


func _apply_to_rig() -> void:
	if _rig == null:
		return

	_rig.set("use_global_profile", use_global_profile)
	_rig.set("global_profile_path", global_profile_path)
	_rig.set("local_profile_override", local_profile_override)
	_rig.set("override_display_locally", override_display_locally)
	_rig.set("override_pivots_locally", override_pivots_locally)
	_rig.set("override_idle_locally", override_idle_locally)
	_rig.set("override_face_locally", override_face_locally)
	_rig.set("override_pose_locally", override_pose_locally)
	_rig.set("skin_id_override", skin_id_override)
	_rig.set("face_variant", face_variant)
	_rig.set("base_head_tilt_degrees", base_head_tilt_degrees)
	_rig.set("base_tail_rotation_degrees", base_tail_rotation_degrees)
	_rig.set("display_size_px", display_size_px)
	_rig.set("display_offset", display_offset)
	_rig.set("tail_pivot_source_px", tail_pivot_source_px)
	_rig.set("head_pivot_source_px", head_pivot_source_px)
	_rig.set("idle_enabled", idle_enabled)
	_rig.set("idle_tail_swing_period_sec", idle_tail_swing_period_sec)
	_rig.set("idle_tail_swing_degrees", idle_tail_swing_degrees)
	_rig.set("idle_head_breath_period_sec", idle_head_breath_period_sec)
	_rig.set("idle_head_breath_amplitude_px", idle_head_breath_amplitude_px)
	if _rig.has_method("refresh_rig"):
		_rig.call("refresh_rig")


func _sync_rig_layout() -> void:
	if _rig == null:
		_cache_rig()
	if _rig == null:
		return
	_rig.position = size * 0.5


func _build_editor_preview_signature() -> String:
	return "|".join([
		str(use_global_profile),
		global_profile_path,
		str(local_profile_override),
		str(override_display_locally),
		str(override_pivots_locally),
		str(override_idle_locally),
		str(override_face_locally),
		str(override_pose_locally),
		skin_id_override,
		face_variant,
		pose_variant,
		str(base_head_tilt_degrees),
		str(base_tail_rotation_degrees),
		str(display_size_px),
		str(display_offset),
		str(tail_pivot_source_px),
		str(head_pivot_source_px),
		str(idle_enabled),
		str(idle_tail_swing_period_sec),
		str(idle_tail_swing_degrees),
		str(idle_head_breath_period_sec),
		str(idle_head_breath_amplitude_px),
	])