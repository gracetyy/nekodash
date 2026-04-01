## SaveManager — autoload singleton persisting all player progress.
## Implements: design/gdd/save-load-system.md
## Task: S1-03 (stub)
##
## Owns a single save file on disk (user://nekodash_save.json). Exposes
## read/write APIs consumed by Level Progression, Star Rating, Skin systems.
##
## Usage:
##   SaveManager.get_level_record("world1_level1")  # -> { completed, best_stars, best_moves }
##   SaveManager.set_level_record("world1_level1", true, 3, 8)
##   SaveManager.is_level_completed("world1_level1")  # -> bool
##   SaveManager.get_equipped_skin()                   # -> "cat_default"
##   SaveManager.unlock_skin("cat_cozy")
extends Node


# —————————————————————————————————————————————
# Constants
# —————————————————————————————————————————————

const SAVE_FILE_PATH: String = "user://nekodash_save.json"
const SAVE_VERSION: int = 1
const DEFAULT_SKIN_ID: String = "cat_default"


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted after set_level_record() writes a new best.
signal level_record_updated(level_id: String)

## Emitted after unlock_skin() successfully adds a new skin.
signal skin_unlocked(skin_id: String)

## Emitted after load_game() completes (success or default init).
signal save_loaded

## Emitted if the save file was corrupt; UI can show a "progress reset" notice.
signal save_corrupted


# —————————————————————————————————————————————
# State
# —————————————————————————————————————————————

var _data: Dictionary = {}
var _is_loaded: bool = false


# —————————————————————————————————————————————
# Lifecycle
# —————————————————————————————————————————————

func _ready() -> void:
	_init_default_data()
	_is_loaded = true
	push_warning("SaveManager: stub — disk I/O not yet implemented; using in-memory defaults.")
	save_loaded.emit()


# —————————————————————————————————————————————
# Public API — Persistence
# —————————————————————————————————————————————

## Loads save data from disk. Stub: initialises in-memory defaults only.
func load_game() -> void:
	_init_default_data()
	_is_loaded = true
	push_warning("SaveManager.load_game(): stub — disk read not implemented.")
	save_loaded.emit()


## Writes _data to disk immediately. Stub: no-op.
func save_game() -> void:
	push_warning("SaveManager.save_game(): stub — disk write not implemented.")


# —————————————————————————————————————————————
# Public API — Level Records
# —————————————————————————————————————————————

## Returns the record for the given level; returns default values if unseen.
func get_level_record(level_id: String) -> Dictionary:
	if not _is_loaded:
		push_warning("SaveManager.get_level_record(): called before load.")
		return _default_level_record()
	var levels: Dictionary = _data.get("levels", {})
	if levels.has(level_id):
		return levels[level_id].duplicate()
	return _default_level_record()


## Updates the record if stars > previous or moves < previous best. Emits
## level_record_updated on change.
func set_level_record(level_id: String, completed: bool, stars: int, moves: int) -> void:
	if not _is_loaded:
		push_warning("SaveManager.set_level_record(): called before load.")
		return
	var levels: Dictionary = _data.get("levels", {})
	var record: Dictionary = levels.get(level_id, _default_level_record())

	var changed: bool = false

	if completed and not record["completed"]:
		record["completed"] = true
		changed = true

	if stars > record["best_stars"]:
		record["best_stars"] = stars
		changed = true

	if moves > 0 and (record["best_moves"] == 0 or moves < record["best_moves"]):
		record["best_moves"] = moves
		changed = true

	if changed:
		levels[level_id] = record
		_data["levels"] = levels
		save_game()
		level_record_updated.emit(level_id)


## Convenience read; returns false for unseen levels.
func is_level_completed(level_id: String) -> bool:
	return get_level_record(level_id)["completed"]


## Convenience read; returns 0 for unseen levels.
func get_best_stars(level_id: String) -> int:
	return get_level_record(level_id)["best_stars"]


## Returns personal best move count; 0 if never completed.
func get_best_moves(level_id: String) -> int:
	return get_level_record(level_id)["best_moves"]


# —————————————————————————————————————————————
# Public API — Skins
# —————————————————————————————————————————————

## Returns the currently equipped skin ID.
func get_equipped_skin() -> String:
	return _data.get("equipped_skin_id", DEFAULT_SKIN_ID)


## Sets equipped skin if skin_id is in unlocked_skin_ids. Writes to disk.
func set_equipped_skin(skin_id: String) -> void:
	var unlocked: Array = _data.get("unlocked_skin_ids", [DEFAULT_SKIN_ID])
	if skin_id not in unlocked:
		push_warning("SaveManager.set_equipped_skin(): skin '%s' is not unlocked." % skin_id)
		return
	_data["equipped_skin_id"] = skin_id
	save_game()


## Returns copy of unlocked skin ID list.
func get_unlocked_skins() -> Array[String]:
	var unlocked: Array = _data.get("unlocked_skin_ids", [DEFAULT_SKIN_ID])
	var result: Array[String] = []
	for skin_id: String in unlocked:
		result.append(skin_id)
	return result


## Adds skin_id to unlocked_skin_ids if not already present. Writes to disk.
## Emits skin_unlocked.
func unlock_skin(skin_id: String) -> void:
	var unlocked: Array = _data.get("unlocked_skin_ids", [DEFAULT_SKIN_ID])
	if skin_id in unlocked:
		return
	unlocked.append(skin_id)
	_data["unlocked_skin_ids"] = unlocked
	save_game()
	skin_unlocked.emit(skin_id)


# —————————————————————————————————————————————
# Public API — Debug
# —————————————————————————————————————————————

## DEBUG ONLY — clears all data, reinitialises to default, writes to disk.
func reset_all_progress() -> void:
	if OS.has_feature("release"):
		push_warning("SaveManager.reset_all_progress(): disabled in release builds.")
		return
	_init_default_data()
	save_game()


# —————————————————————————————————————————————
# Private Helpers
# —————————————————————————————————————————————

func _init_default_data() -> void:
	_data = {
		"version": SAVE_VERSION,
		"levels": {},
		"equipped_skin_id": DEFAULT_SKIN_ID,
		"unlocked_skin_ids": [DEFAULT_SKIN_ID],
	}


func _default_level_record() -> Dictionary:
	return {
		"completed": false,
		"best_stars": 0,
		"best_moves": 0,
	}
