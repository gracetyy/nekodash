# World Map / Level Select

> **Status**: Draft
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 20 of 22
> **Category**: UI
> **Priority**: MVP-Polish

---

## Overview

The World Map is the central level-select screen. It loads the `LevelCatalogue` resource
from disk, reads save data from `SaveManager`, and renders a grid of level buttons grouped
by world. Players tap an unlocked level button to start it. A back button returns to the
Main Menu.

**Architectural note**: `LevelProgression` is a node inside the gameplay scene and is not
alive when the World Map is shown. The World Map does **not** call LevelProgression
methods. It derives lock state using the same rule LevelProgression uses — the first level
of each world is always unlocked; any subsequent level is unlocked if the previous level's
record is completed in SaveManager.

---

## Responsibilities

| Responsibility                             | Owned By                               |
| ------------------------------------------ | -------------------------------------- |
| Display all worlds and their level buttons | World Map ✅                           |
| Show lock/unlock state per level           | World Map ✅ (reads SaveManager)       |
| Show best star count per level             | World Map ✅ (reads SaveManager)       |
| Navigate to a level when tapped            | World Map ✅ (via SceneManager)        |
| Navigate back to Main Menu                 | World Map ✅ (via SceneManager)        |
| Persisting level records                   | Save / Load System                     |
| Level metadata (name, world, index)        | Level Data Format (via LevelCatalogue) |
| Scene transitions                          | Scene Manager                          |

---

## LevelCatalogue Loading

The World Map loads `LevelCatalogue` at a canonical path:

```gdscript
const CATALOGUE_PATH := "res://data/level_catalogue.tres"

func _ready() -> void:
    _catalogue = load(CATALOGUE_PATH) as LevelCatalogue
    assert(_catalogue != null, "LevelCatalogue not found at " + CATALOGUE_PATH)
    _build_world_index()
    _populate_ui()
```

> **Canonical path contract**: `res://data/level_catalogue.tres` is the single source of
> truth for the level list. Both World Map and Level Coordinator must load from this path.
> This is the resolution of Level Progression OQ-1.

---

## Unlock Logic

World Map applies the same unlock rule as LevelProgression inline:

```gdscript
func _is_level_unlocked(level_data: LevelData) -> bool:
    if level_data.level_index == 1:
        return true
    var prev := _get_prev_level(level_data)
    if prev == null:
        return true
    return SaveManager.is_level_completed(prev.level_id)

func _get_prev_level(level_data: LevelData) -> LevelData:
    var world_levels := _world_index.get(level_data.world_id, []) as Array[LevelData]
    for level in world_levels:
        if level.level_index == level_data.level_index - 1:
            return level
    return null
```

This logic is duplicated from Level Progression intentionally — the World Map is a separate
scene with no live Level Progression node to query. If the unlock rule changes, both places
must be updated. Document this as a known deliberate duplication.

---

## World Index

`_build_world_index()` groups all levels by `world_id`:

```gdscript
var _world_index: Dictionary = {}  # int -> Array[LevelData], sorted by level_index

func _build_world_index() -> void:
    for level in _catalogue.levels:
        if not _world_index.has(level.world_id):
            _world_index[level.world_id] = []
        _world_index[level.world_id].append(level)
    for world_id in _world_index:
        var arr: Array[LevelData] = _world_index[world_id]
        arr.sort_custom(func(a, b): return a.level_index < b.level_index)
```

World IDs are rendered in ascending numeric order.

---

## Layout

```
┌───────────────────────────────────────────────┐
│  [← Back]             NekoDash                │  ← Header
├───────────────────────────────────────────────┤
│  World 1  │  World 2  │  World 3  │  …        │  ← World tabs
├───────────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐      │
│  │  1   │  │  2   │  │  3   │  │  🔒  │      │  ← Level button grid
│  │ ★★★  │  │ ★★☆  │  │ ★☆☆  │  │      │      │
│  └──────┘  └──────┘  └──────┘  └──────┘      │
│  ┌──────┐  ┌──────┐  …                        │
│  │  5   │  │  6   │                           │
│  │ ☆☆☆  │  │ 🔒   │                           │
│  └──────┘  └──────┘                           │
└───────────────────────────────────────────────┘
```

- **World tabs**: one tab per `world_id` in ascending order
- **Level grid**: 4 columns (portrait mobile); buttons show level number and star count
- **Lock icon**: shown in place of stars for locked levels; button is non-interactive
- **Back button**: top-left; calls `SceneManager.go_back()` (or `go_to(Screen.MAIN_MENU)`)

---

## Level Button Display

Each level button shows:

| State                    | Content                                             |
| ------------------------ | --------------------------------------------------- |
| **Locked**               | Lock icon; no stars; disabled; tapping does nothing |
| **Unlocked, not played** | Level number; empty stars (3 × ☆); enabled          |
| **Completed**            | Level number; filled stars (0–3 × ★); enabled       |

Level "number" displayed as `level_data.level_index` (a tidy integer e.g. "1", "2").

---

## Navigation

| Action                    | Call                                   |
| ------------------------- | -------------------------------------- |
| Tap unlocked level button | `SceneManager.go_to_level(level_data)` |
| Tap locked level button   | No-op (button disabled)                |
| Tap Back button           | `SceneManager.go_to(Screen.MAIN_MENU)` |

---

## Scene Transition Contract

### `receive_scene_params(params: Dictionary) -> void`

World Map accepts an optional `highlight_world_id: int` param. If provided, the
corresponding world tab is selected on load instead of defaulting to World 1.

```gdscript
func receive_scene_params(params: Dictionary) -> void:
    _initial_world_id = params.get("highlight_world_id", 1)
```

Callers that pass this param:

- Level Complete Screen's "World Map" button (optional; may not pass it at MVP)

If not passed, default to World 1 (world with lowest `world_id`).

---

## Initialization Flow

```
_ready():
    _catalogue = load(CATALOGUE_PATH)
    _build_world_index()
    _create_world_tabs()
    _select_world(_initial_world_id)

_select_world(world_id: int):
    _clear_level_grid()
    var levels = _world_index.get(world_id, [])
    for level in levels:
        var btn = _make_level_button(level)
        _level_grid.add_child(btn)

_make_level_button(level: LevelData) -> Control:
    var unlocked := _is_level_unlocked(level)
    var stars := SaveManager.get_best_stars(level.level_id)
    # set label, star icons, enabled state, pressed signal
    return btn
```

---

## Design Rules

1. **All data is read-only on load**: World Map never writes to SaveManager or any other
   system. It is a pure display + navigation layer.

2. **No live refresh at MVP**: The World Map is rebuilt from scratch each time the scene
   loads. SaveManager always reflects the current save state, so data is fresh on every
   visit. Subscribing to `SaveManager.level_record_updated` is a post-jam polish item.

3. **Locked button accessibility**: Locked buttons must be visually distinct (greyed out +
   lock icon) and non-interactive (`disabled = true`). Do not hide them — players should
   see what's coming.

4. **World tabs are always shown**: Even if a world has all levels locked (impossible under
   the unlock rules, but defensive), the tab exists with locked buttons.

5. **Empty catalogue guard**: If `_catalogue.levels` is empty, show a "No levels found"
   label and the back button only. Do not crash.

6. **Single scroll area**: Within a world's level grid, use a `ScrollContainer` if the
   number of levels exceeds the visible area. No horizontal pagination — all levels in one
   scrollable column/grid.

7. **Level display name vs index**: At MVP use `level_data.level_index` (integer) as the
   button label. `display_name` is available for rich labels (post-jam).

---

## Edge Cases

| Edge Case                                                   | Behaviour                                                                |
| ----------------------------------------------------------- | ------------------------------------------------------------------------ |
| Player has never played (all locked except World 1 Level 1) | World 1 Level 1 shows unlocked, 0 stars; all others locked               |
| All levels in a world are completed                         | All buttons show star counts; Last level enabled; tab still shows        |
| `highlight_world_id` points to a world not in catalogue     | Fall back to first world (lowest world_id)                               |
| Only one world in catalogue                                 | Single tab; no tab-switching UI needed                                   |
| Level `best_stars == 0` but `is_level_completed == true`    | Show 0 filled stars (valid: completed with 0 stars via -1 sentinel path) |

---

## Acceptance Criteria

| ID   | Criterion                                                                                     |
| ---- | --------------------------------------------------------------------------------------------- |
| WM-1 | Screen loads and displays all worlds from LevelCatalogue                                      |
| WM-2 | World 1 Level 1 is always shown as unlocked on first launch (fresh save)                      |
| WM-3 | A completed level shows its best star count (0–3 stars)                                       |
| WM-4 | An unplayed unlocked level shows 3 empty stars                                                |
| WM-5 | A locked level shows a lock icon and cannot be tapped                                         |
| WM-6 | Tapping an unlocked level launches that level via SceneManager                                |
| WM-7 | Back button returns to Main Menu                                                              |
| WM-8 | Selecting a world tab shows only that world's levels                                          |
| WM-9 | When `receive_scene_params` provides `highlight_world_id`, that world tab is selected on load |

---

## Dependencies

| Depends On              | Interface Used                                                                        |
| ----------------------- | ------------------------------------------------------------------------------------- |
| Level Data Format       | `LevelData`: `level_id`, `world_id`, `level_index`, `display_name`                    |
| Save / Load System      | `SaveManager.is_level_completed()`, `SaveManager.get_best_stars()`                    |
| Scene Manager           | `go_to_level(level_data)`, `go_to(Screen.MAIN_MENU)`                                  |
| LevelCatalogue resource | `@export var levels: Array[LevelData]`; loaded from `res://data/level_catalogue.tres` |

---

## Intentional Design Decisions

| Decision                                                 | Rationale                                                                                                                                                                                                                            |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| World Map duplicates unlock logic from Level Progression | LevelProgression is not an autoload; it doesn't exist when World Map is shown. The rule (first level always unlocked; others need prev completed) is simple and stable enough to duplicate safely. If the rule changes, update both. |
| No live subscribe to `level_record_updated`              | World Map is always freshly instantiated on visit; `_ready()` reads latest save. Live refresh adds complexity for negligible benefit.                                                                                                |
| `res://data/level_catalogue.tres` as canonical path      | Single known location avoids injection complexity on a pure-read screen.                                                                                                                                                             |

---

## Open Questions

| ID   | Question                                                                                                 | Priority | Resolution                                                                                                                            |
| ---- | -------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should the World Map remember the last-visited world across sessions (save `last_world_id` to settings)? | Low      | Provisional: No — default to World 1 always. Too small a detail for jam scope.                                                        |
| OQ-2 | Should completed levels show total star count for the world (e.g. "12/15 ★")?                            | Low      | Provisional: Yes, as a world-level summary header — one line per world tab showing cumulative stars. Easy to add, visually rewarding. |
