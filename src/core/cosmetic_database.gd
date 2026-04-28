## CosmeticDatabase — autoload singleton managing skin data and assets.
## Implements: docs/gdd/cosmetic-skin-database.md
extends Node

const DATABASE_PATH := "res://data/skin_database.tres"
const DEFAULT_SKIN_ID := "cat_default"

var _db: SkinDatabase
var _index: Dictionary = {}  # String skin_id → SkinData


func _ready() -> void:
	_load_database()


func _load_database() -> void:
	if not ResourceLoader.exists(DATABASE_PATH):
		push_error("CosmeticDatabase: SkinDatabase not found at %s" % DATABASE_PATH)
		return

	_db = load(DATABASE_PATH) as SkinDatabase
	if _db == null:
		push_error("CosmeticDatabase: Failed to load SkinDatabase at %s" % DATABASE_PATH)
		return

	_index.clear()
	for skin in _db.skins:
		if skin == null: continue
		_index[skin.skin_id] = skin

	_verify_database()


func _verify_database() -> void:
	if not _index.has(DEFAULT_SKIN_ID):
		push_error("CosmeticDatabase: Required default skin '%s' missing from database." % DEFAULT_SKIN_ID)
	
	var default_count: int = 0
	for skin in _db.skins:
		if skin.is_default_unlocked:
			default_count += 1
	
	if default_count == 0:
		push_warning("CosmeticDatabase: No skins marked as is_default_unlocked.")
	elif default_count > 1:
		push_warning("CosmeticDatabase: Multiple skins marked as is_default_unlocked.")


## Returns the SkinData resource for the given ID.
func get_skin(skin_id: String) -> SkinData:
	if _index.has(skin_id):
		return _index[skin_id]
	
	if _index.has(DEFAULT_SKIN_ID):
		if not skin_id.is_empty():
			push_warning("CosmeticDatabase: Unknown skin_id '%s', falling back to default." % skin_id)
		return _index[DEFAULT_SKIN_ID]
	
	# Emergency fallback if database is completely broken.
	var fallback := SkinData.new()
	fallback.skin_id = DEFAULT_SKIN_ID
	fallback.display_name = "Default Cat"
	return fallback


## Returns all skins in the database.
func get_all_skins() -> Array[SkinData]:
	if _db == null: return []
	return _db.skins


## Returns the preview texture (Main Menu / Skin Select).
func get_preview_texture(skin_id: String) -> Texture2D:
	var skin := get_skin(skin_id)
	return skin.preview_texture if skin else null


## Returns the gameplay texture (SlidingMovement).
func get_gameplay_texture(skin_id: String) -> Texture2D:
	var skin := get_skin(skin_id)
	return skin.gameplay_texture if skin else null


## Returns the default skin ID.
func get_default_skin_id() -> String:
	return DEFAULT_SKIN_ID
