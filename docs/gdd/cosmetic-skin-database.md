# Cosmetic / Skin Database

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 6 of 22
> **Category**: Progression
> **Priority**: MVP-Skins

---

## Overview

The Cosmetic / Skin Database is a static data catalog that defines every cat skin in the
game: its ID, display name, preview art, and gameplay art. It is an autoload singleton
(`CosmeticDatabase`) that loads a `SkinDatabase` resource from disk at startup and exposes
a simple lookup API.

The database has **no knowledge of unlock state** — it only knows what skins exist and what
their assets are. Whether a skin is unlocked for a specific player is tracked by
`SaveManager`. Unlock _conditions_ (which milestones trigger which skin) are defined in the
Skin Unlock / Milestone Tracker.

---

## Player Fantasy

A catalog of cats the player has never seen. When a player opens the Skin Select Screen
for the first time and scrolls past the default cat to find several locked silhouettes,
they're looking at a promise: _there are more cats, and you can earn them_. The Cosmetic
Database is what makes that promise real and trustworthy — every skin shown exists as a
properly defined resource with real art, a real ID, and a real unlock condition. Its player
fantasy is the quiet confidence that the cat shown on any screen is correct: the right
sprite, the right name, the right state. It never shows a broken placeholder or undefined
skin.

---

## Responsibilities

| Responsibility                            | Owned By                        |
| ----------------------------------------- | ------------------------------- |
| Define all skin IDs and their asset paths | Cosmetic Database ✅            |
| Provide texture lookup by skin ID         | Cosmetic Database ✅            |
| Track which skins are unlocked            | Save / Load System              |
| Define unlock conditions                  | Skin Unlock / Milestone Tracker |
| Present skins to player                   | Skin Select Screen              |

---

## Data Structure

### `SkinData` Resource

```gdscript
class_name SkinData
extends Resource

@export var skin_id: String = ""
@export var display_name: String = ""
@export var preview_texture: Texture2D      # Used in Main Menu and Skin Select Screen
@export var gameplay_texture: Texture2D     # Used by the sliding cat node in gameplay
@export var is_default_unlocked: bool = false  # True only for the starter skin
```

At MVP, `preview_texture` and `gameplay_texture` may reference the same asset.

### `SkinDatabase` Resource

```gdscript
class_name SkinDatabase
extends Resource

@export var skins: Array[SkinData] = []
```

Stored at: `res://data/skin_database.tres`

---

## `CosmeticDatabase` Autoload

`CosmeticDatabase` is registered in `project.godot` as an autoload. It loads
`SkinDatabase` at `_ready()` and builds a lookup index.

```gdscript
# res://src/systems/cosmetic_database.gd
extends Node

const DATABASE_PATH := "res://data/skin_database.tres"
const DEFAULT_SKIN_ID := "cat_default"

var _db: SkinDatabase
var _index: Dictionary = {}  # String skin_id → SkinData

func _ready() -> void:
    _db = load(DATABASE_PATH) as SkinDatabase
    assert(_db != null, "SkinDatabase not found at " + DATABASE_PATH)
    for skin in _db.skins:
        _index[skin.skin_id] = skin

func get_skin(skin_id: String) -> SkinData:
    if _index.has(skin_id):
        return _index[skin_id]
    push_warning("CosmeticDatabase: unknown skin_id '%s', returning default." % skin_id)
    return _index.get(DEFAULT_SKIN_ID)

func get_preview_texture(skin_id: String) -> Texture2D:
    return get_skin(skin_id).preview_texture

func get_gameplay_texture(skin_id: String) -> Texture2D:
    return get_skin(skin_id).gameplay_texture

func get_all_skins() -> Array[SkinData]:
    return _db.skins

func get_default_skin_id() -> String:
    return DEFAULT_SKIN_ID
```

---

## Skin Catalog (MVP)

| `skin_id`       | `display_name` | `is_default_unlocked` | Unlock Path                    |
| --------------- | -------------- | --------------------- | ------------------------------ |
| `"cat_default"` | "Default Cat"  | `true`                | Always has it                  |
| `"cat_cozy"`    | "Cozy Cat"     | `false`               | Milestone: 3-star any 5 levels |
| `"cat_sakura"`  | "Sakura Cat"   | `false`               | Milestone: Complete World 1    |

> Exact unlock conditions and milestone thresholds are defined in the
> Skin Unlock / Milestone Tracker GDD. This table lists them here for catalog completeness
> only.

---

## Asset Paths Convention

All skin textures live under `res://assets/art/cats/`:

```
res://assets/art/cats/
    cat_default_preview.png
    cat_default_gameplay.png
    cat_cozy_preview.png
    cat_cozy_gameplay.png
    cat_sakura_preview.png
    cat_sakura_gameplay.png
```

At MVP, `*_preview.png` and `*_gameplay.png` may be the same file.

---

## Access Pattern

Other systems access skins through the `CosmeticDatabase` autoload:

```gdscript
# Main Menu — show equipped cat
var texture := CosmeticDatabase.get_preview_texture(SaveManager.get_equipped_skin())
_cat_sprite.texture = texture

# Gameplay — set cat sprite when level loads
var texture := CosmeticDatabase.get_gameplay_texture(SaveManager.get_equipped_skin())
_cat_sprite_node.texture = texture

# Skin Select Screen — list all skins
for skin in CosmeticDatabase.get_all_skins():
    # check SaveManager.is_skin_unlocked(skin.skin_id) then build UI
```

---

## Design Rules

1. **CosmeticDatabase is read-only**: No system may modify skin definitions at runtime.
   All data comes from the `.tres` resource on disk.

2. **One source of truth for skin IDs**: `skin_id` strings used in `SaveManager`
   (`equipped_skin_id`, `unlocked_skin_ids`) must match strings in `SkinDatabase` exactly.
   CosmeticDatabase is the authority on what IDs are valid.

3. **Always-valid default**: If a requested skin ID is not found (e.g. save from an old
   build references a removed skin), fall back to `"cat_default"` with a warning. Never
   crash.

4. **Default skin always unlocked**: Exactly one skin has `is_default_unlocked = true`.
   `SaveManager` seeds `unlocked_skin_ids` with this skin's ID on first launch.
   `CosmeticDatabase` should `assert` that exactly one default skin exists at load.

5. **No unlock logic here**: `CosmeticDatabase` does not know if a skin is unlocked for
   the current player. `SaveManager.is_skin_unlocked(skin_id)` handles that.

6. **Autoload load order**: `CosmeticDatabase` must be ordered after `SaveManager` in
   the autoload list so that systems starting up can safely call both.

---

## Edge Cases

| Edge Case                                          | Behaviour                                                                   |
| -------------------------------------------------- | --------------------------------------------------------------------------- |
| `skin_id` not in database                          | Returns `cat_default` skin with a push_warning                              |
| Database file missing or corrupt                   | `assert` fires in debug; log error in release and show no cat preview       |
| Multiple skins marked `is_default_unlocked = true` | `assert` in debug; use first one found                                      |
| No skins in database                               | `get_all_skins()` returns empty array; Skin Select Screen shows empty state |

---

## Acceptance Criteria

| ID   | Criterion                                                                                         |
| ---- | ------------------------------------------------------------------------------------------------- |
| CD-1 | `CosmeticDatabase.get_skin("cat_default")` returns the default skin data                          |
| CD-2 | `CosmeticDatabase.get_preview_texture("cat_cozy")` returns a valid Texture2D                      |
| CD-3 | `CosmeticDatabase.get_skin("unknown_id")` returns the default skin (not null)                     |
| CD-4 | `CosmeticDatabase.get_all_skins()` returns all skins defined in the database                      |
| CD-5 | Exactly one skin has `is_default_unlocked = true`                                                 |
| CD-6 | `SaveManager.get_equipped_skin()` on fresh save returns a skin ID that exists in CosmeticDatabase |

---

## Tuning Knobs

None at MVP. The database is a static `SkinDatabase` resource loaded once at startup. All skin data is authored at design time — no runtime-adjustable parameters.

---

## Dependencies

| Depends On                             | Interface Used                                                                                       |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Save / Load System                     | `get_equipped_skin()` — called by systems that use CosmeticDatabase indirectly; `is_skin_unlocked()` |
| (none — no upstream code dependencies) | CosmeticDatabase loads from a `.tres` resource; no code dependencies at runtime                      |

---

## Open Questions

| ID   | Question                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Priority        | Resolution                                                                                                                                                            |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should skins have a `rarity` or `category` field for grouping in the Skin Select Screen?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Low             | Provisional: No at MVP. At 3 skins, no grouping needed. Add `rarity: String` field post-jam.                                                                          |
| OQ-2 | Should `SkinData` include the unlock condition text for display in the Skin Select Screen ("Locked: 3-star 5 levels")?                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Medium          | Provisional: Yes — add `unlock_hint: String` field to `SkinData`. Skin Select Screen shows it below locked skins. Populate in the .tres authoring; no logic required. |
| OQ-3 | **Post-jam: skins with gameplay abilities.** Some skins should have passive effects that alter gameplay (e.g. "Ghost Cat" slides through one obstacle per level; "Lucky Cat" gets one free undo that doesn't count toward the undo penalty; "Speedster Cat" treats one extra move as free for star calculation). This requires: **(a)** `SkinData` gains a `@export var ability: SkinAbility` field (new Resource subclass). **(b)** A new **Skin Ability System** GDD defines the ability types and how they integrate with Sliding Movement, Undo/Restart, and Star Rating System. **(c)** At level load, the active skin's ability is queried from `CosmeticDatabase` and injected into the affected systems. **Critical design constraint**: abilities must not make levels unsolvable or invalidate BFS minimum-move data. Abilities that reduce effective move count are out-of-scope without re-running the BFS solver per-skin. Design a standalone Skin Ability System GDD before any implementation work. | High (Post-jam) | Design Skin Ability System GDD first. CosmeticDatabase only needs the `ability` field added to `SkinData` — no other changes to this system.                          |
