## LevelProgression — authoritative source for level unlock state and progression.
## Implements: design/gdd/level-progression.md
## Task: S2-03
##
## Owns the ordered level catalogue, listens to StarRatingSystem.rating_computed,
## writes results to SaveManager, determines unlock and world-completion state,
## emits signals for Level Complete Screen and World Map.
##
## Level Progression is a node in the gameplay scene (not autoload). It requires
## a StarRatingSystem reference for signal subscription.
##
## Usage:
##   level_progression.initialize(catalogue, star_rating_ref)
##   level_progression.set_current_level(level_data)
##   level_progression.is_level_unlocked("w1_l2")
##   level_progression.get_next_level("w1_l1")
extends Node


# —————————————————————————————————————————————
# Signals
# —————————————————————————————————————————————

## Emitted after SaveManager write completes on rating_computed.
signal level_record_saved(level_id: String, stars: int, final_moves: int)

## Emitted when a completion event unlocks a level that was previously locked.
signal next_level_unlocked(level_data: LevelData)

## Emitted when the last level of a world is completed for the first time.
signal world_completed(world_id: int)


# —————————————————————————————————————————————
# Private state
# —————————————————————————————————————————————

## Sorted catalogue of all levels.
var _levels: Array[LevelData] = []

## Source catalogue reference (used for unlock-rule metadata).
var _catalogue: LevelCatalogue

## Maps level_id → index in _levels for O(1) lookup.
var _level_index_map: Dictionary = {}

## Currently active level (set by Level Coordinator).
var _current_level_data: LevelData

## Reference to StarRatingSystem for signal connection.
var _star_rating_ref: Node

## Whether initialize() has been called.
var _initialized: bool = false


# —————————————————————————————————————————————
# Public API
# —————————————————————————————————————————————

## Loads catalogue, builds index, connects to StarRatingSystem signal.
## Called by Level Coordinator when the gameplay scene loads.
func initialize(catalogue: LevelCatalogue, star_rating_ref: Node) -> void:
	if catalogue == null:
		push_error("LevelProgression: initialize() called with null catalogue.")
		return
	if star_rating_ref == null:
		push_error("LevelProgression: initialize() called with null star_rating_ref.")
		return

	# Disconnect previous signal if re-initializing
	if _star_rating_ref != null and _star_rating_ref.has_signal("rating_computed"):
		if _star_rating_ref.rating_computed.is_connected(_on_rating_computed):
			_star_rating_ref.rating_computed.disconnect(_on_rating_computed)

	_star_rating_ref = star_rating_ref
	_catalogue = catalogue

	# Sort catalogue by (world_id, level_index)
	_levels = catalogue.levels.duplicate()
	_levels.sort_custom(_compare_levels)

	# Build index map; detect duplicates (AC: LP-10)
	_level_index_map.clear()
	var i: int = 0
	while i < _levels.size():
		var ld: LevelData = _levels[i]
		if _level_index_map.has(ld.level_id):
			push_error(
				"LevelProgression: Duplicate level_id '%s' in catalogue. Skipping." % ld.level_id
			)
			_levels.remove_at(i)
			continue
		_level_index_map[ld.level_id] = i
		i += 1

	# Connect to rating_computed
	if star_rating_ref.has_signal("rating_computed"):
		star_rating_ref.rating_computed.connect(_on_rating_computed)

	_initialized = true


## Tells Level Progression which level is currently active.
## Stored for Level Coordinator and future systems that need to query current level.
func set_current_level(level_data: LevelData) -> void:
	_current_level_data = level_data


## Returns the currently active LevelData, or null if none set.
func get_current_level() -> LevelData:
	return _current_level_data


## Returns whether initialize() has been called.
func is_initialized() -> bool:
	return _initialized


## Returns true if the player may play this level. (AC: LP-1..LP-4)
func is_level_unlocked(level_id: String) -> bool:
	var data: LevelData = _get_level_data(level_id)
	if data == null:
		return false

	# Default-unlocked world entry levels (world 1 + configured special worlds).
	if _is_level_entry_unlocked_by_default(data):
		return true

	# Otherwise: previous level must be completed (AC: LP-2, LP-3)
	var prev: LevelData = _get_previous_level(data)
	if prev == null:
		return true
	return SaveManager.is_level_completed(prev.level_id)


## Delegates to SaveManager.is_level_completed().
func is_level_completed(level_id: String) -> bool:
	return SaveManager.is_level_completed(level_id)


## Delegates to SaveManager.get_best_stars().
func get_best_stars(level_id: String) -> int:
	return SaveManager.get_best_stars(level_id)


## Returns the next LevelData in sequence. Null if last level in game.
func get_next_level(level_id: String) -> LevelData:
	if not _level_index_map.has(level_id):
		return null
	var idx: int = _level_index_map[level_id]
	if idx + 1 >= _levels.size():
		return null
	return _levels[idx + 1]


## Returns all levels in a world, sorted by level_index. (AC: LP-9)
func get_levels_for_world(world_id: int) -> Array[LevelData]:
	var result: Array[LevelData] = []
	for ld: LevelData in _levels:
		if ld.world_id == world_id:
			result.append(ld)
	return result


## Returns the number of distinct worlds in the catalogue.
func get_world_count() -> int:
	var worlds: Dictionary = {}
	for ld: LevelData in _levels:
		worlds[ld.world_id] = true
	return worlds.size()


## Returns true if every level in the world is completed in SaveManager.
func is_world_completed(world_id: int) -> bool:
	var world_levels: Array[LevelData] = get_levels_for_world(world_id)
	if world_levels.is_empty():
		return false
	for ld: LevelData in world_levels:
		if not SaveManager.is_level_completed(ld.level_id):
			return false
	return true


## Returns the total number of levels in the catalogue.
func get_level_count() -> int:
	return _levels.size()


# —————————————————————————————————————————————
# Signal handlers
# —————————————————————————————————————————————

## Handles StarRatingSystem.rating_computed. Writes record to SaveManager,
## checks for unlock and world completion events, emits signals.
func _on_rating_computed(level_id: String, stars: int, final_moves: int) -> void:
	# Guard: ignore unknown level_ids to prevent phantom SaveManager writes
	var level_data: LevelData = _get_level_data(level_id)
	if level_data == null:
		push_error("LevelProgression: rating_computed for unknown level_id '%s'. Ignoring." % level_id)
		return

	# Sentinel handling: stars == -1 → treat as 0 for persistence (AC: LP-8)
	var effective_stars: int = maxi(stars, 0)

	# Check if next level was locked BEFORE we write (for unlock detection)
	var next: LevelData = get_next_level(level_id)
	var next_was_locked: bool = false
	if next != null:
		next_was_locked = not is_level_unlocked(next.level_id)

	# Check if world was incomplete BEFORE we write (for world_completed detection)
	var world_id: int = level_data.world_id
	var world_was_incomplete: bool = not is_world_completed(world_id)

	# Write to SaveManager (best-only semantics are in SaveManager)
	SaveManager.set_level_record(level_id, true, effective_stars, final_moves)

	# Check if next level is NOW unlocked (was locked, now unlocked) (AC: LP-6)
	if next != null and next_was_locked and is_level_unlocked(next.level_id):
		next_level_unlocked.emit(next)

	# Check if world is NOW completed (was incomplete, now complete) (AC: LP-7)
	if world_was_incomplete and is_world_completed(world_id):
		world_completed.emit(world_id)

	# Always emit level_record_saved (AC: LP-5)
	level_record_saved.emit(level_id, effective_stars, final_moves)


# —————————————————————————————————————————————
# Private helpers
# —————————————————————————————————————————————

## Returns the LevelData for a given level_id, or null if not found.
func _get_level_data(level_id: String) -> LevelData:
	if not _level_index_map.has(level_id):
		return null
	return _levels[_level_index_map[level_id]]


## Returns the previous level in sequence, or null if this is the first.
func _get_previous_level(data: LevelData) -> LevelData:
	if not _level_index_map.has(data.level_id):
		return null
	var idx: int = _level_index_map[data.level_id]
	if idx == 0:
		return null
	return _levels[idx - 1]


## True when this level is the entry level for a default-unlocked world.
func _is_level_entry_unlocked_by_default(data: LevelData) -> bool:
	if data.level_index != 1:
		return false
	if data.world_id == 1:
		return true
	return _is_world_always_unlocked(data.world_id)


## Returns whether a world should bypass normal cross-world unlock gating.
func _is_world_always_unlocked(world_id: int) -> bool:
	if _catalogue == null:
		return false
	return world_id in _catalogue.always_unlocked_world_ids


## Sort comparator: (world_id ASC, level_index ASC).
static func _compare_levels(a: LevelData, b: LevelData) -> bool:
	if a.world_id != b.world_id:
		return a.world_id < b.world_id
	return a.level_index < b.level_index
