# Skin Unlock / Milestone Tracker

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 17 of 22
> **Category**: Progression
> **Priority**: MVP-Skins

---

## Overview

The Skin Unlock / Milestone Tracker is an autoload singleton (`MilestoneTracker`) that
monitors player progress and unlocks cosmetic skins when cumulative milestones are reached.
It subscribes to `SaveManager.level_record_updated` and re-evaluates all milestone
conditions after every level save. When a condition is met, it calls
`SaveManager.unlock_skin()` — SaveManager then emits `skin_unlocked` which any UI layer
can observe.

The Milestone Tracker knows nothing about UI. It never shows notifications. It only
evaluates conditions and triggers unlocks.

---

## Player Fantasy

The quiet surprise. The player didn't know they were working toward anything specific. Then
suddenly, after completing a level, a new screen appears: a cat they've never seen is
now unlocked. They didn't grind for it. They just played, and the game was watching. That
feeling — unexpected reward for consistent play — is the Milestone Tracker's entire purpose.
It makes cosmetic unlocks feel discovered rather than purchased. The tracker is silent until
it fires, and when it fires, the impact belongs entirely to the player.

---

## Responsibilities

| Responsibility                                            | Owned By                                           |
| --------------------------------------------------------- | -------------------------------------------------- |
| Define milestone conditions (what progress → which skin)  | Milestone Tracker ✅                               |
| Evaluate milestone conditions after each level completion | Milestone Tracker ✅                               |
| Call `SaveManager.unlock_skin()` when a milestone is hit  | Milestone Tracker ✅                               |
| Storing which skins are unlocked                          | Save / Load System                                 |
| Emitting `skin_unlocked` signal                           | Save / Load System                                 |
| Showing unlock notification to player                     | Post-jam / UI layer subscribing to `skin_unlocked` |
| Skin data and asset paths                                 | Cosmetic / Skin Database                           |

---

## Integration Point

```
SaveManager.level_record_updated(level_id)
    └→ MilestoneTracker._on_level_record_updated(level_id)
           └→ evaluate all milestones
                   └→ SaveManager.unlock_skin(skin_id) [if condition met]
                           └→ SaveManager.skin_unlocked(skin_id) [SaveManager emits]
```

The Milestone Tracker does **not** subscribe to `LevelProgression.level_record_saved`
because Level Progression is a gameplay-scene node that is not alive when MilestoneTracker
needs to outlast it. `SaveManager.level_record_updated` is the authoritative
post-write event from an autoload.

---

## Autoload

`MilestoneTracker` is registered in `project.godot` as an autoload. Autoload order:
`SaveManager` → `CosmeticDatabase` → `MilestoneTracker`.

```gdscript
# res://src/systems/milestone_tracker.gd
extends Node

const CATALOGUE_PATH := "res://data/level_catalogue.tres"

var _catalogue: LevelCatalogue

func _ready() -> void:
    _catalogue = load(CATALOGUE_PATH) as LevelCatalogue
    assert(_catalogue != null, "MilestoneTracker: LevelCatalogue not found")
    SaveManager.level_record_updated.connect(_on_level_record_updated)
    # Run once at startup to catch any milestones that should have been
    # awarded from a prior session (e.g. first launch after update).
    _evaluate_all_milestones()

func _on_level_record_updated(_level_id: String) -> void:
    _evaluate_all_milestones()
```

---

## Milestone Definitions (MVP)

Milestones are defined as an Array of typed Dictionaries. At MVP, milestone definitions
live in code. If the milestone list grows, extract to a Resource later.

```gdscript
const _MILESTONES: Array[Dictionary] = [
    {
        "skin_id":   "cat_cozy",
        "type":      "total_3stars",
        "threshold": 5,
    },
    {
        "skin_id":  "cat_sakura",
        "type":     "world_complete",
        "world_id": 1,
    },
]
```

---

## Condition Evaluation

```gdscript
func _evaluate_all_milestones() -> void:
    for milestone in _MILESTONES:
        var skin_id: String = milestone["skin_id"]
        # Skip if already unlocked (SaveManager.unlock_skin is idempotent,
        # but skipping avoids unnecessary catalogue iteration every save).
        if SaveManager.get_unlocked_skins().has(skin_id):
            continue
        if _is_condition_met(milestone):
            SaveManager.unlock_skin(skin_id)

func _is_condition_met(milestone: Dictionary) -> bool:
    match milestone["type"]:
        "total_3stars":
            return _count_3star_levels() >= milestone["threshold"]
        "world_complete":
            return _is_world_complete(milestone["world_id"])
        _:
            push_error("MilestoneTracker: unknown milestone type: " + milestone["type"])
            return false
```

### `total_3stars` Condition

Counts how many distinct levels have a best star rating ≥ 3:

```gdscript
func _count_3star_levels() -> int:
    var count := 0
    for level in _catalogue.levels:
        if SaveManager.get_best_stars(level.level_id) >= 3:
            count += 1
    return count
```

### `world_complete` Condition

Returns true if every level in the given world is completed:

```gdscript
func _is_world_complete(world_id: int) -> bool:
    for level in _catalogue.levels:
        if level.world_id == world_id:
            if not SaveManager.is_level_completed(level.level_id):
                return false
    return true
```

> **Empty world guard**: If no levels in the catalogue match `world_id`, returns `true`
> (vacuously true). This would immediately award the skin — guard against this in
> authoring by ensuring the catalogue always has levels for rewarded worlds.

---

## Startup Catch-Up Evaluation

`_evaluate_all_milestones()` is called at `_ready()`. This handles:

1. **Game update scenario**: A new skin with milestone conditions is shipped; the player
   already met the conditions in a prior version. On first launch after update, the
   milestone fires and the skin is awarded immediately without requiring another level play.

2. **Save corruption/restore**: If save data is partially restored, re-evaluation ensures
   unlock state is consistent with progress data.

---

## SaveManager Amendment

> **Required addition to Save / Load System**:
> `is_skin_unlocked(skin_id: String) -> bool` — convenience method (same pattern as
> `is_level_completed`). Returns `get_unlocked_skins().has(skin_id)`. Needed by
> Skin Select Screen for clean per-skin lock checks.

---

## Design Rules

1. **Fire-and-forget design**: MilestoneTracker calls `SaveManager.unlock_skin()` and
   trusts SaveManager's `skin_unlocked` signal to notify any UI. No UI code in this
   system.

2. **Idempotent unlock call**: `SaveManager.unlock_skin()` is a no-op if the skin is
   already unlocked. MilestoneTracker's own early-exit check (`has(skin_id)`) is a
   performance optimisation, not a correctness requirement.

3. **Milestone definitions must reference valid skin IDs**: Each `skin_id` in
   `_MILESTONES` must exist in `CosmeticDatabase`. This is a content authoring constraint,
   not enforced at runtime. Validate in the CosmeticDatabase `assert` on load.

4. **LevelCatalogue path matches World Map**: Same `res://data/level_catalogue.tres`
   canonical path used everywhere. Single source of truth.

5. **Star count uses best-only semantics**: Only the best-ever star count for each level
   contributes to milestones. Replaying a 3-starred level multiple times counts as 1.

---

## Edge Cases

| Edge Case                                                          | Behaviour                                                                                                               |
| ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| Player already has skin unlocked from prior session                | Milestone check skips evaluation early; no duplicate `unlock_skin` call                                                 |
| World has no levels in catalogue                                   | `_is_world_complete()` returns `true` (vacuous) — **content authoring must ensure all milestone world IDs have levels** |
| LevelCatalogue missing at startup                                  | `assert` fires in debug; no milestones evaluated; no crash in release (null-checked)                                    |
| `level_record_updated` fires rapidly (two quick level completions) | Each call re-evaluates all milestones; idempotent calls mean this is safe                                               |
| New milestone definition added after player already qualifies      | Startup catch-up evaluation awards skin on next launch                                                                  |

---

## Acceptance Criteria

| ID   | Criterion                                                                                               |
| ---- | ------------------------------------------------------------------------------------------------------- |
| MT-1 | After saving a level with 3 stars for the 5th time, `SaveManager.skin_unlocked` fires with `"cat_cozy"` |
| MT-2 | Completing all levels in World 1 triggers `SaveManager.skin_unlocked` with `"cat_sakura"`               |
| MT-3 | Calling the above scenarios again (already unlocked) does not emit `skin_unlocked` again                |
| MT-4 | On startup with conditions already met (new session), `_ready()` awards any pending milestones          |
| MT-5 | MilestoneTracker loads LevelCatalogue successfully from the canonical path                              |

---

## Tuning Knobs

Milestone thresholds are defined in the `_MILESTONES` constant array inside `MilestoneTracker`. Designers add, change, or remove milestone conditions by modifying that array — no logic code changes required.

---

## Dependencies

| Depends On               | Interface Used                                                                                                     |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Save / Load System       | `level_record_updated` signal; `unlock_skin()`; `get_best_stars()`; `is_level_completed()`; `get_unlocked_skins()` |
| Cosmetic / Skin Database | `skin_id` strings must match database entries (authoring contract, not runtime API)                                |
| Level Data Format        | `LevelData.world_id: int`, `LevelData.level_id: String`, `LevelData.level_index: int`                              |
| LevelCatalogue resource  | Loaded from `res://data/level_catalogue.tres`                                                                      |

---

## Open Questions

| ID   | Question                                                                                                                 | Priority | Resolution                                                                                                                                          |
| ---- | ------------------------------------------------------------------------------------------------------------------------ | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should milestone definitions be moved to a Resource (for content-team authoring of new milestones without code changes)? | Low      | Post-jam. At MVP with 2 milestones, inline code is sufficient.                                                                                      |
| OQ-2 | Should a `milestone_reached(skin_id: String)` signal be added to MilestoneTracker for UI toast display?                  | Medium   | Provisional: No — `SaveManager.skin_unlocked(skin_id)` already exists for this purpose. UI subscribes to SaveManager. Avoid duplicating the signal. |
