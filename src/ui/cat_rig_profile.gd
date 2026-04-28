## CatRigProfile — shared defaults for CatPartRig instances.
##
## Edit a single .tres profile to update baseline rig tuning globally.
class_name CatRigProfile
extends Resource


@export_category("Rig")
## Fallback skin when SaveManager skin lookup is unavailable.
@export var default_skin_id: String = "cat_default"
## Default face variant for rigs inheriting this profile.
@export_enum("idle", "blink", "excited", "relax", "smile", "curious", "happy", "peek", "surprised") var face_variant: String = "idle"

@export_category("Display")
## Final rendered size for each layered part canvas in pixels.
@export_range(16.0, 512.0, 1.0, "or_greater")
var display_size_px: float = 92.0
## Global offset applied to the assembled rig origin.
@export var display_offset: Vector2 = Vector2(0.0, -16.0)

@export_category("Pivots")
## Tail rotation anchor in source-canvas pixel coordinates.
@export var tail_pivot_source_px: Vector2 = Vector2(15.0, 35.0)
## Head rotation anchor in source-canvas pixel coordinates.
@export var head_pivot_source_px: Vector2 = Vector2(0.0, 8.0)

@export_category("Pose")
## Static head tilt used as the base pose while idle animation layers on top.
@export_range(-30.0, 30.0, 0.1)
var base_head_tilt_degrees: float = 0.0
## Static tail rotation used as the base pose while idle animation layers on top.
@export_range(-45.0, 45.0, 0.1)
var base_tail_rotation_degrees: float = 0.0

@export_category("Idle Motion")
## Enables idle tail sway motion (auto-disabled when reduce motion is active).
@export var idle_enabled: bool = true
## Seconds per full idle tail sway cycle.
@export_range(0.0, 10.0, 0.01, "or_greater")
var idle_tail_swing_period_sec: float = 1.45
## Maximum idle tail sway angle in degrees.
@export_range(0.0, 60.0, 0.1, "or_greater")
var idle_tail_swing_degrees: float = 10.0
## Seconds per full head breathing cycle.
@export_range(0.0, 10.0, 0.01, "or_greater")
var idle_head_breath_period_sec: float = 2.2
## Max head breathing travel in pixels (up/down around head pivot).
@export_range(0.0, 24.0, 0.1, "or_greater")
var idle_head_breath_amplitude_px: float = 2.0
