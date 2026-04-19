@tool
## CatPartRig — shared layered cat assembly for gameplay and UI contexts.
##
## Builds a cat from part sprites that share the same source canvas origin.
## Exposes pivots and sizing as exported values so artists can tune in editor.
class_name CatPartRig
extends Node2D

const CatRigProfile = preload("res://src/ui/cat_rig_profile.gd")


# —————————————————————————————————————————————
# Exports
# —————————————————————————————————————————————

@export_category("Global Profile")
## Uses a shared profile as the default source for rig tuning values.
@export var use_global_profile: bool = true
## Profile path used when no local override profile is assigned.
@export_file("*.tres") var global_profile_path: String = "res://data/cat_rig_defaults.tres"
## Optional local profile override for this specific rig instance.
@export var local_profile_override: CatRigProfile
## If true, use local display values instead of profile display values.
@export var override_display_locally: bool = false
## If true, use local pivot values instead of profile pivot values.
@export var override_pivots_locally: bool = false
## If true, use local idle values instead of profile idle values.
@export var override_idle_locally: bool = false
## If true, use local face variant instead of profile face variant.
@export var override_face_locally: bool = false

@export_category("Rig")
## Optional skin id override. Leave empty to follow SaveManager equipped skin.
@export var skin_id_override: String = ""
## Face overlay variant used on top of the head part.
@export_enum("idle", "blink", "excited", "relax", "smile") var face_variant: String = "idle"

@export_category("Display")
## Final rendered size for each layered part canvas in pixels.
@export_range(16.0, 512.0, 1.0, "or_greater")
var display_size_px: float = 92.0
## Global offset applied to the assembled rig origin.
@export var display_offset: Vector2 = Vector2(0.0, -16.0)

@export_category("Pivots")
## Tail rotation anchor in source-canvas pixel coordinates.
@export var tail_pivot_source_px: Vector2 = Vector2(36.0, 94.0)
## Head rotation anchor in source-canvas pixel coordinates.
@export var head_pivot_source_px: Vector2 = Vector2(0.0, 34.0)

@export_category("Idle Motion")
## Enables idle tail sway motion (auto-disabled when reduce motion is active).
@export var idle_enabled: bool = true
## Seconds per full idle tail sway cycle.
@export_range(0.0, 10.0, 0.01, "or_greater")
var idle_tail_swing_period_sec: float = 1.45
## Maximum idle tail sway angle in degrees.
@export_range(0.0, 60.0, 0.1, "or_greater")
var idle_tail_swing_degrees: float = 10.0

@export_category("Editor")
## Auto-refreshes rig preview when exported values change in the inspector.
@export var auto_refresh_in_editor: bool = true


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const PARTS_DIR: String = "res://assets/art/cats/parts"
const DEFAULT_SKIN_ID: String = "cat_default"
const DEFAULT_FACE_VARIANT: String = "idle"
const SOURCE_CANVAS_FALLBACK_PX: float = 320.0


# —————————————————————————————————————————————
# Node refs
# —————————————————————————————————————————————

var _tail_pivot: Node2D
var _tail_sprite: Sprite2D
var _body_sprite: Sprite2D
var _legs_sprite: Sprite2D
var _head_pivot: Node2D
var _head_sprite: Sprite2D
var _face_sprite: Sprite2D


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _part_sprites: Array[Sprite2D] = []
var _source_canvas_size_px: float = SOURCE_CANVAS_FALLBACK_PX
var _idle_time_sec: float = 0.0
var _head_tilt_tween: Tween
var _editor_preview_signature: String = ""


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_ensure_rig_nodes()
	refresh_rig()
	_editor_preview_signature = _build_editor_preview_signature()
	set_process(true)


func _process(delta: float) -> void:
	if not is_inside_tree():
		return

	if Engine.is_editor_hint():
		if auto_refresh_in_editor:
			# Keep editor preview responsive while tweaking exported values.
			_refresh_editor_preview_if_needed()
		else:
			_apply_layout()

	if not _effective_idle_enabled():
		_reset_tail_pose()
		return

	if _is_reduce_motion_enabled():
		if _idle_time_sec != 0.0:
			_idle_time_sec = 0.0
		_reset_tail_pose()
		return

	_idle_time_sec += delta
	_apply_idle_tail_pose(_idle_time_sec)


func _exit_tree() -> void:
	if _head_tilt_tween and _head_tilt_tween.is_valid():
		_head_tilt_tween.kill()


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

func refresh_rig() -> void:
	_ensure_rig_nodes()
	_apply_layout()
	_assign_part_textures(_resolve_skin_id())


func refresh_skin() -> void:
	_assign_part_textures(_resolve_skin_id())


func set_head_tilt_immediate(target_degrees: float) -> void:
	if _head_pivot == null or not is_instance_valid(_head_pivot):
		return
	_head_pivot.rotation_degrees = target_degrees


func tween_head_tilt(target_degrees: float, duration_sec: float) -> void:
	if _head_pivot == null or not is_instance_valid(_head_pivot):
		return

	if _head_tilt_tween and _head_tilt_tween.is_valid():
		_head_tilt_tween.kill()

	if _is_reduce_motion_enabled() or duration_sec <= 0.0:
		set_head_tilt_immediate(0.0 if _is_reduce_motion_enabled() else target_degrees)
		return

	_head_tilt_tween = create_tween()
	_head_tilt_tween.tween_property(_head_pivot, "rotation_degrees", target_degrees, duration_sec) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


# —————————————————————————————————————————————
# Node setup
# —————————————————————————————————————————————

func _ensure_rig_nodes() -> void:
	_tail_pivot = get_node_or_null("TailPivot") as Node2D
	if _tail_pivot == null:
		_tail_pivot = Node2D.new()
		_tail_pivot.name = "TailPivot"
		add_child(_tail_pivot)
	_tail_pivot.z_index = 0

	_tail_sprite = _tail_pivot.get_node_or_null("Tail") as Sprite2D
	if _tail_sprite == null:
		_tail_sprite = Sprite2D.new()
		_tail_sprite.name = "Tail"
		_tail_pivot.add_child(_tail_sprite)
	_tail_sprite.centered = true
	_tail_sprite.z_index = 0

	_body_sprite = get_node_or_null("Body") as Sprite2D
	if _body_sprite == null:
		_body_sprite = Sprite2D.new()
		_body_sprite.name = "Body"
		add_child(_body_sprite)
	_body_sprite.centered = true
	_body_sprite.z_index = 1

	_legs_sprite = get_node_or_null("Legs") as Sprite2D
	if _legs_sprite == null:
		_legs_sprite = Sprite2D.new()
		_legs_sprite.name = "Legs"
		add_child(_legs_sprite)
	_legs_sprite.centered = true
	_legs_sprite.z_index = 2

	_head_pivot = get_node_or_null("HeadPivot") as Node2D
	if _head_pivot == null:
		_head_pivot = Node2D.new()
		_head_pivot.name = "HeadPivot"
		add_child(_head_pivot)
	_head_pivot.z_index = 3

	_head_sprite = _head_pivot.get_node_or_null("Head") as Sprite2D
	if _head_sprite == null:
		_head_sprite = Sprite2D.new()
		_head_sprite.name = "Head"
		_head_pivot.add_child(_head_sprite)
	_head_sprite.centered = true
	_head_sprite.z_index = 0

	_face_sprite = _head_pivot.get_node_or_null("Face") as Sprite2D
	if _face_sprite == null:
		_face_sprite = Sprite2D.new()
		_face_sprite.name = "Face"
		_head_pivot.add_child(_face_sprite)
	_face_sprite.centered = true
	_face_sprite.z_index = 1

	_part_sprites = [_tail_sprite, _body_sprite, _legs_sprite, _head_sprite, _face_sprite]


func _refresh_editor_preview_if_needed() -> void:
	if not is_inside_tree():
		return
	var signature: String = _build_editor_preview_signature()
	if signature == _editor_preview_signature:
		return
	_editor_preview_signature = signature
	refresh_rig()


func _build_editor_preview_signature() -> String:
	var profile: CatRigProfile = _effective_profile()
	var parts: PackedStringArray = [
		str(use_global_profile),
		global_profile_path,
		str(local_profile_override),
		_build_profile_signature(profile),
		str(override_display_locally),
		str(override_pivots_locally),
		str(override_idle_locally),
		str(override_face_locally),
		skin_id_override,
		_effective_face_variant(),
		str(_effective_display_size_px()),
		str(_effective_display_offset()),
		str(_effective_tail_pivot_source_px()),
		str(_effective_head_pivot_source_px()),
		str(_effective_idle_enabled()),
		str(_effective_idle_tail_swing_period_sec()),
		str(_effective_idle_tail_swing_degrees()),
	]
	return "|".join(parts)


func _build_profile_signature(profile: CatRigProfile) -> String:
	if profile == null:
		return "null"

	var parts: PackedStringArray = [
		profile.default_skin_id,
		profile.face_variant,
		str(profile.display_size_px),
		str(profile.display_offset),
		str(profile.tail_pivot_source_px),
		str(profile.head_pivot_source_px),
		str(profile.idle_enabled),
		str(profile.idle_tail_swing_period_sec),
		str(profile.idle_tail_swing_degrees),
	]
	return "|".join(parts)


func _apply_layout() -> void:
	if not is_inside_tree():
		return
	position = _effective_display_offset()

	if _tail_pivot != null and is_instance_valid(_tail_pivot):
		_tail_pivot.position = _effective_tail_pivot_source_px()
	if _tail_sprite != null and is_instance_valid(_tail_sprite):
		_tail_sprite.position = - _effective_tail_pivot_source_px()

	if _head_pivot != null and is_instance_valid(_head_pivot):
		_head_pivot.position = _effective_head_pivot_source_px()
	if _head_sprite != null and is_instance_valid(_head_sprite):
		_head_sprite.position = - _effective_head_pivot_source_px()
	if _face_sprite != null and is_instance_valid(_face_sprite):
		_face_sprite.position = - _effective_head_pivot_source_px()

	_apply_part_scale()


func _apply_part_scale() -> void:
	if _source_canvas_size_px <= 0.0:
		return

	var part_scale: float = _effective_display_size_px() / _source_canvas_size_px
	var part_scale_vec: Vector2 = Vector2.ONE * part_scale
	for sprite: Sprite2D in _part_sprites:
		if sprite == null or not is_instance_valid(sprite):
			continue
		sprite.scale = part_scale_vec


# —————————————————————————————————————————————
# Texture resolution
# —————————————————————————————————————————————

func _assign_part_textures(skin_id: String) -> void:
	_tail_sprite.texture = _resolve_part_texture(skin_id, "tail")
	_body_sprite.texture = _resolve_part_texture(skin_id, "body")
	_legs_sprite.texture = _resolve_part_texture(skin_id, "legs")
	_head_sprite.texture = _resolve_part_texture(skin_id, "head")
	_face_sprite.texture = _resolve_face_texture()

	_source_canvas_size_px = _resolve_source_canvas_size_px()
	_apply_part_scale()


func _resolve_part_texture(skin_id: String, part_name: String) -> Texture2D:
	var requested_path: String = _part_path(skin_id, part_name)
	var requested_texture: Texture2D = _load_texture_if_exists(requested_path)
	if requested_texture != null:
		return requested_texture

	if skin_id != DEFAULT_SKIN_ID:
		var fallback_path: String = _part_path(DEFAULT_SKIN_ID, part_name)
		var fallback_texture: Texture2D = _load_texture_if_exists(fallback_path)
		if fallback_texture != null:
			return fallback_texture

	return null


func _resolve_face_texture() -> Texture2D:
	var requested_face_path: String = _face_path(_effective_face_variant())
	var face_texture: Texture2D = _load_texture_if_exists(requested_face_path)
	if face_texture != null:
		return face_texture

	var fallback_face_path: String = _face_path(DEFAULT_FACE_VARIANT)
	return _load_texture_if_exists(fallback_face_path)


func _part_path(skin_id: String, part_name: String) -> String:
	return "%s/%s_%s.png" % [PARTS_DIR, skin_id, part_name]


func _face_path(face_name: String) -> String:
	return "%s/cat_face_%s.png" % [PARTS_DIR, face_name]


func _load_texture_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _resolve_source_canvas_size_px() -> float:
	for sprite: Sprite2D in _part_sprites:
		if sprite == null or sprite.texture == null:
			continue
		var texture_size: Vector2i = sprite.texture.get_size()
		if texture_size.x > 0:
			return float(texture_size.x)
	return SOURCE_CANVAS_FALLBACK_PX


# —————————————————————————————————————————————
# Animation helpers
# —————————————————————————————————————————————

func _apply_idle_tail_pose(elapsed_sec: float) -> void:
	if _tail_pivot == null or not is_instance_valid(_tail_pivot):
		return

	if _effective_idle_tail_swing_period_sec() <= 0.0:
		_tail_pivot.rotation_degrees = 0.0
		return

	var cycle: float = (elapsed_sec / _effective_idle_tail_swing_period_sec()) * TAU
	_tail_pivot.rotation_degrees = sin(cycle) * _effective_idle_tail_swing_degrees()


func _reset_tail_pose() -> void:
	if _tail_pivot != null and is_instance_valid(_tail_pivot):
		_tail_pivot.rotation_degrees = 0.0


# —————————————————————————————————————————————
# Misc
# —————————————————————————————————————————————

func _resolve_skin_id() -> String:
	if not skin_id_override.is_empty():
		return skin_id_override

	var fallback_skin_id: String = _effective_default_skin_id()

	if SaveManager == null:
		return fallback_skin_id

	if SaveManager.has_method("get_equipped_skin"):
		var equipped_skin_value: Variant = SaveManager.call("get_equipped_skin")
		if equipped_skin_value is String and not (equipped_skin_value as String).is_empty():
			return equipped_skin_value as String

	if SaveManager.has_method("get_equipped_skin_id"):
		var equipped_skin_id_value: Variant = SaveManager.call("get_equipped_skin_id")
		if equipped_skin_id_value is String and not (equipped_skin_id_value as String).is_empty():
			return equipped_skin_id_value as String

	return fallback_skin_id


func _effective_profile() -> CatRigProfile:
	if local_profile_override != null:
		return local_profile_override
	if not use_global_profile:
		return null
	if global_profile_path.is_empty() or not ResourceLoader.exists(global_profile_path):
		return null
	return load(global_profile_path) as CatRigProfile


func _effective_display_size_px() -> float:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not override_display_locally:
		return profile.display_size_px
	return display_size_px


func _effective_display_offset() -> Vector2:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not override_display_locally:
		return profile.display_offset
	return display_offset


func _effective_tail_pivot_source_px() -> Vector2:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not override_pivots_locally:
		return profile.tail_pivot_source_px
	return tail_pivot_source_px


func _effective_head_pivot_source_px() -> Vector2:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not override_pivots_locally:
		return profile.head_pivot_source_px
	return head_pivot_source_px


func _effective_idle_enabled() -> bool:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not override_idle_locally:
		return profile.idle_enabled
	return idle_enabled


func _effective_idle_tail_swing_period_sec() -> float:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not override_idle_locally:
		return profile.idle_tail_swing_period_sec
	return idle_tail_swing_period_sec


func _effective_idle_tail_swing_degrees() -> float:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not override_idle_locally:
		return profile.idle_tail_swing_degrees
	return idle_tail_swing_degrees


func _effective_face_variant() -> String:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not override_face_locally and not profile.face_variant.is_empty():
		return profile.face_variant
	if face_variant.is_empty():
		return DEFAULT_FACE_VARIANT
	return face_variant


func _effective_default_skin_id() -> String:
	var profile: CatRigProfile = _effective_profile()
	if profile != null and not profile.default_skin_id.is_empty():
		return profile.default_skin_id
	return DEFAULT_SKIN_ID


func _is_reduce_motion_enabled() -> bool:
	if Engine.is_editor_hint():
		return false
	return AppSettings != null and AppSettings.get_reduce_motion()
