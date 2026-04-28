class_name SkinData
extends Resource

## Unique ID used in SaveManager and code lookup.
@export var skin_id: String = ""
## User-facing name.
@export var display_name: String = ""
## Used in Main Menu and Skin Select Screen.
@export var preview_texture: Texture2D
## Used by the sliding cat node in gameplay (if using simple sprite).
@export var gameplay_texture: Texture2D
## Hint text for locked skins.
@export var unlock_hint: String = ""
## If true, this skin is unlocked by default on new saves.
@export var is_default_unlocked: bool = false
