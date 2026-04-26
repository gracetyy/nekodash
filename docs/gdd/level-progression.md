# Level Progression

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 16 of 23
> **Category**: Progression
> **Priority**: MVP-Polish

---

## Overview

The Level Progression system is the authoritative source for which levels exist, what order
they appear in, which are unlocked, and what happens after a level is completed. It owns the
ordered level catalogue, listens to `StarRatingSystem.rating_computed`, writes the result to
`SaveManager`, determines whether a next level or a new world now becomes accessible, and
emits signals so the Level Complete overlay and World Map can refresh their state.

Level Progression does not display anything and does not change scenes — it publishes facts.
The Level Complete overlay/screen flow and World Map read from it.

---

## Player Fantasy

The reassuring feeling that the next puzzle is waiting. When a player finishes a level and
taps "Next Level," the Level Progression system is what makes that tap do something
meaningful. It knows what level comes next, whether the player has earned it, and whether
this completion just unlocked a new world. Level Progression is entirely invisible — it has
no display, no animation, no sound. Its player fantasy is felt only through its downstream
effects: the World Map showing one more unlocked button, the Level Complete Screen knowing
what to show. It is only noticeable when it breaks.

---

## Responsibilities

| Responsibility                                                              | Owned By             |
| --------------------------------------------------------------------------- | -------------------- |
| Maintain ordered catalogue of all `LevelData` resources                     | Level Progression ✅ |
| Determine whether a level is locked / unlocked / completed                  | Level Progression ✅ |
| Write completion record to SaveManager after level ends                     | Level Progression ✅ |
| Determine next level after current                                          | Level Progression ✅ |
| Determine if a full world is now complete                                   | Level Progression ✅ |
| Emit `level_record_saved`, `world_completed`, `next_level_unlocked` signals | Level Progression ✅ |
| Star computation                                                            | Star Rating System   |
| Persistence (read/write JSON)                                               | Save / Load System   |
| Scene transitions                                                           | Scene Manager        |
| Display unlock state                                                        | World Map            |

---

## Design Rules

1. **Completion-only unlock gate**: The next level unlocks when the current level is
   completed (any star count, including 0 stars). Stars are feedback — they never gate
   progression. This is absolute; no star requirements for any level unlock.

2. **World-sequential linear unlock**: Level Progression unlocks the immediately next
   level by `(world_id, level_index)` order. Within a world, levels unlock one at a time.
   The first level of the next world unlocks as soon as the last level of the current world
   is completed. World N+1 level 1 never unlocks before world N's last level is done.

3. **First level always unlocked**: `world_id == 1, level_index == 1` is always accessible.
   Level Progression treats it as unlocked regardless of save state.

4. **Level Progression subscribes to `rating_computed`**: When
   `StarRatingSystem.rating_computed` fires, Level Progression:
   a. Calls `SaveManager.set_level_record(level_id, completed=true, stars, moves)`
   b. Evaluates whether the next level is newly unlocked (ChecksNextLevelUnlock)
   c. Evaluates whether the current world is newly completed (ChecksWorldComplete)
   d. Emits the appropriate signals

5. **`stars == -1` sentinel handling**: When `rating_computed` fires with `stars == -1`
   (in-development unsolved level), Level Progression still writes `completed = true` to
   SaveManager but passes `stars = 0` and `moves = final_moves`. It does not emit
   `star_record_improved`. This ensures developers can test completion flow with unreleased
   levels without corrupting star records.

6. **Best-only semantics are in SaveManager**: Level Progression passes the current
   attempt's result to `SaveManager.set_level_record()` unconditionally. SaveManager
   applies best-only logic. Level Progression does not duplicate that check.

7. **Catalogue is static at runtime**: All `LevelData` resources are loaded once at
   `_ready()` via `preload()` paths defined in a `LevelCatalogue` resource, sorted by
   `(world_id, level_index)`. The catalogue does not change at runtime. No DLC or
   remote-content loading at MVP.

8. **Level Progression is a node in the gameplay scene, not an autoload**: It requires
   access to `StarRatingSystem` (another gameplay scene node). It is instantiated by the
   gameplay scene root (Level Coordinator) not as a global singleton. It has no cross-scene
   lifecycle — the World Map and Level Complete Screen query its state through SaveManager
   (which _is_ an autoload) and via signals emitted before the gameplay scene is torn down.

---

## Catalogue Loading

### LevelCatalogue Resource

A `LevelCatalogue` resource (`class_name LevelCatalogue extends Resource`) contains:

```
@export var levels: Array[LevelData]
```

Authored by the level designer: all `.tres` LevelData files are added to this array in
`(world_id, level_index)` order. Level Progression sorts at runtime as a validation step.

### Initialization

`initialize(catalogue: LevelCatalogue, star_rating_ref: StarRatingSystem) -> void`

Called by Level Coordinator when the gameplay scene loads:

1. Stores `_levels: Array[LevelData]` — sorted by `(world_id ASC, level_index ASC)`
2. Builds `_level_index_map: Dictionary[String, int]` — maps `level_id → index in _levels`
3. Connects to `star_rating_ref.rating_computed`
4. Caches `_current_level_data` reference (set by Level Coordinator at level load, via
   `set_current_level(level_data)`)

---

## Core Flow

### On `rating_computed(level_id, stars, final_moves)`

```
var effective_stars: int = max(stars, 0)  # -1 sentinel → treat as 0
SaveManager.set_level_record(level_id, true, effective_stars, final_moves)

# Check if next level newly unlocked
var next: LevelData = get_next_level(level_id)
if next != null:
    var was_unlocked: bool = is_level_unlocked(next.level_id)
    if not was_unlocked:
        next_level_unlocked.emit(next)

# Check if world newly completed
var world: int = _level_map[level_id].world_id
if _is_world_newly_completed(world):
    world_completed.emit(world)

level_record_saved.emit(level_id, effective_stars, final_moves)
```

---

## Unlock Logic

`is_level_unlocked(level_id: String) -> bool`

```
var data: LevelData = _get_level_data(level_id)
if data == null: return false

# First level of the whole game is always unlocked
if data.world_id == 1 and data.level_index == 1:
    return true

# Otherwise: previous level must be completed
var prev: LevelData = _get_previous_level(data)
if prev == null: return true  # first in world, previous world's last must be done
return SaveManager.is_level_completed(prev.level_id)
```

`_get_previous_level(data: LevelData) -> LevelData`:

- If `data.level_index > 1`: return level at `(data.world_id, data.level_index - 1)`
- If `data.level_index == 1` and `data.world_id > 1`: return last level of world
  `data.world_id - 1`
- If `data.world_id == 1` and `data.level_index == 1`: return null (already handled above)

---

## Public Interface

### Methods

| Method                 | Signature                                                                | Description                                                                           |
| ---------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| `initialize`           | `(catalogue: LevelCatalogue, star_rating_ref: StarRatingSystem) -> void` | Load catalogue, build index, connect signal                                           |
| `set_current_level`    | `(level_data: LevelData) -> void`                                        | Tells Level Progression which level is currently active (called by Level Coordinator) |
| `is_level_unlocked`    | `(level_id: String) -> bool`                                             | True if the player may play this level                                                |
| `is_level_completed`   | `(level_id: String) -> bool`                                             | Delegates to `SaveManager.is_level_completed()`                                       |
| `get_best_stars`       | `(level_id: String) -> int`                                              | Delegates to `SaveManager.get_best_stars()`                                           |
| `get_next_level`       | `(level_id: String) -> LevelData`                                        | Returns next LevelData in sequence; null if last level                                |
| `get_levels_for_world` | `(world_id: int) -> Array[LevelData]`                                    | All levels in a world, sorted by level_index                                          |
| `get_world_count`      | `() -> int`                                                              | Number of distinct worlds in the catalogue                                            |
| `is_world_completed`   | `(world_id: int) -> bool`                                                | True if every level in the world is completed in SaveManager                          |

### Signals

| Signal                | Arguments                                        | When Fired                                                         |
| --------------------- | ------------------------------------------------ | ------------------------------------------------------------------ |
| `level_record_saved`  | `level_id: String, stars: int, final_moves: int` | After SaveManager write completes on `rating_computed`             |
| `next_level_unlocked` | `level_data: LevelData`                          | When a completion event unlocks a level that was previously locked |
| `world_completed`     | `world_id: int`                                  | When the last level of a world is completed for the first time     |

### `is_world_newly_completed` (private)

Fires `world_completed` only when the transition was incomplete → complete this session.
Reads `SaveManager.is_level_completed()` for all levels in the world _after_ the write,
then checks whether the world was already complete before this play by querying whether
the previous level (just before the last one) was complete beforehand. Because SaveManager
has already been updated, the simplest approach is:

> World is newly complete if `is_world_completed(world_id)` is now true AND
> the level just completed is the last in the world (`get_next_level() == null` within
> the world, OR world_id of next is different).

This avoids storing prior state; it checks post-write.

---

## Level Catalogue Design Assumptions (MVP)

| Parameter        | Value               | Source                                  |
| ---------------- | ------------------- | --------------------------------------- |
| World count      | 3                   | Level Data Format GDD / game-concept.md |
| Levels per world | 5–7                 | game-concept.md MVP scope (15–20 total) |
| Total levels     | 15–20               | Level Data Format GDD                   |
| Level ordering   | Linear within world | Design Rule 2                           |

Level Progression does not hard-code these numbers — it reads them from the catalogue.
The table documents the expected authoring intent.

---

## Edge Cases

| Edge Case                                         | Behaviour                                                                                                            |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Last level in the entire game completed           | `get_next_level()` returns null; no `next_level_unlocked` emitted; `world_completed` fires if applicable             |
| `stars == -1` (unsolved in-dev level)             | Sets `completed = true`, `best_stars = 0`; no `star_record_improved` signal; marks unlock normally                   |
| Player replays a completed level with worse stars | SaveManager best-only logic absorbs it; no regression; `level_record_saved` still fires                              |
| Catalogue has duplicate `level_id`                | Level Progression logs an error push_error() and skips duplicates; first entry wins (matches Level Data Format AC-7) |
| Catalogue is empty                                | `get_world_count()` returns 0; `is_level_unlocked()` always returns false; non-fatal                                 |

---

## Acceptance Criteria

| ID    | Criterion                                                                                           |
| ----- | --------------------------------------------------------------------------------------------------- |
| LP-1  | World 1, level 1 is unlocked with no save data                                                      |
| LP-2  | World 1, level 2 is locked until world 1 level 1 is completed                                       |
| LP-3  | World 2, level 1 is locked until world 1's final level is completed                                 |
| LP-4  | Completing a level with 0 stars still unlocks the next level                                        |
| LP-5  | `level_record_saved` fires after every `rating_computed`, including replays                         |
| LP-6  | `next_level_unlocked` fires at most once per level per playthrough (only on first unlock)           |
| LP-7  | `world_completed` fires exactly once when the last level of a world is completed for the first time |
| LP-8  | `stars == -1` results in `completed = true, best_stars = 0` in SaveManager                          |
| LP-9  | `get_levels_for_world(world_id)` returns levels in ascending `level_index` order                    |
| LP-10 | Duplicate `level_id` in catalogue logs `push_error()` and second entry is ignored                   |

---

## Tuning Knobs

None at MVP. All progression rules are data-driven (catalogue order, single-unlock rule). No runtime-configurable constants.

---

## Dependencies

| Depends On         | Interface Used                                                              |
| ------------------ | --------------------------------------------------------------------------- |
| Star Rating System | `rating_computed(level_id, stars, final_moves)` signal                      |
| Level Data Format  | `level_id`, `world_id`, `level_index`, `display_name` fields on `LevelData` |
| Save / Load System | `set_level_record()`, `is_level_completed()`, `get_best_stars()`            |

---

## Downstream Consumers

| Consumer                            | What it reads                                                                                             | When                                                                    |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| **Level Coordinator**               | Subscribes to `level_record_saved`; calls `get_next_level()` to build Level Complete Screen params        | After `level_record_saved` fires; immediately triggers scene transition |
| **World Map / Level Select**        | Calls `is_level_unlocked()`, `get_best_stars()`, `get_levels_for_world()` on scene load                   | On World Map load / `level_record_saved`                                |
| **Skin Unlock / Milestone Tracker** | Subscribes to `level_record_saved`; queries cumulative stars via `SaveManager.get_best_stars()` per level | On `level_record_saved`                                                 |

> **Unlock logic duplication**: World Map reimplements `is_level_unlocked()` with
> the same rule as Level Progression (previous level completed = next unlocked).
> This is intentional — World Map loads when the gameplay scene is not alive, so
> it cannot call into Level Progression directly. **If the unlock rule ever changes,
> it must be updated in both `level-progression.md` and `world-map.md`.**

| `world_completed` has no documented subscriber | At MVP no system reacts to `world_completed`. It is defined for future use (e.g., a "World Complete!" banner on the Level Complete Screen). Level Coordinator may optionally pass `world_completed` state as a boolean in the scene params dict if the banner is implemented. If unused at ship, consider suppressing or removing the signal to avoid confusion. |

---

## Open Questions

| ID   | Question                                                                                                                                   | Priority | Resolution                                                                                                                                  |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Does Level Coordinator hold the `LevelCatalogue` reference, or does Level Progression load it from a known `res://` path? Either is clean. | Low      | Provisional: Level Coordinator loads the catalogue and injects it via `initialize()`. This keeps asset references out of Level Progression. |
| OQ-2 | Should `world_completed` also be emitted for worlds that were already complete when the game is loaded (i.e., replayed levels)?            | Low      | No — `world_completed` is a _first-time_ event signal. World Map reads completion state directly from `is_world_completed()` on load.       |
