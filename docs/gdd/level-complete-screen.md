# Level Complete Screen

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 19 of 22
> **Category**: UI
> **Priority**: MVP-Polish

---

## Overview

The Level Complete Screen is the post-level results view. It shows the player their star
rating, final move count, and any new personal best, then offers three navigation choices:
play the next level, retry the same level, or return to the World Map.

It is a separate Godot scene (`res://scenes/ui/level_complete.tscn`) loaded by Scene
Manager after the gameplay scene hands over the confirmed result data. The screen receives
its context via `receive_scene_params()`, populates results in `_ready()`, and delegates
all navigation to `SceneManager`.

---

## Player Fantasy

The pause after the last tile lights up. The cat has reached full coverage, the music sting
hits, and then: this screen. Stars appear. The move count is confirmed. A "NEW BEST" badge
appears if the player just beat themselves. For a moment, the puzzle is finished and the
result is real. This screen is the punctuation mark at the end of the puzzle sentence —
without it, the completion would feel incomplete, like a joke without a punchline. Done well,
it closes the loop cleanly and makes the player want to open another one.

---

## Responsibilities

| Responsibility                             | Owned By                                   |
| ------------------------------------------ | ------------------------------------------ |
| Display stars earned this attempt          | Level Complete Screen ✅                   |
| Display final move count                   | Level Complete Screen ✅                   |
| Display personal best indicator (new best) | Level Complete Screen ✅                   |
| Display level name                         | Level Complete Screen ✅                   |
| Provide Next Level button                  | Level Complete Screen ✅                   |
| Provide Retry button                       | Level Complete Screen ✅                   |
| Provide World Map button                   | Level Complete Screen ✅                   |
| Computing star rating                      | Star Rating System                         |
| Persisting record                          | Save / Load System (via Level Progression) |
| Navigating to next screen                  | Scene Manager                              |

---

## Scene Transition Contract

### How the screen is reached

The gameplay scene root's Level Coordinator collects the final result data after the level
ends, then calls:

```gdscript
# In Level Coordinator, on _on_level_record_saved(level_id, stars, final_moves):
var next_level := _level_progression.get_next_level(level_id)
SceneManager.go_to(Screen.LEVEL_COMPLETE, {
    "level_data":               _current_level_data,
    "stars":                    stars,           # int, -1 to 3
    "final_moves":              final_moves,     # int
    "prev_best_moves":          _prev_best_moves, # snapshotted at level load time
    "was_previously_completed": _was_previously_completed, # snapshotted at level load
    "next_level_data":          next_level       # LevelData or null if last level
})
```

`_prev_best_moves` and `_was_previously_completed` are snapshotted by the Level
Coordinator at **level load time** (before any moves) by reading from `SaveManager` —
the only safe moment to capture previous-session bests before the current session's
write overwrites them.

> **Why pass plain data instead of a node reference?** `LevelProgression` is a node
> inside the gameplay scene that SceneManager is about to unload. Passing a node
> reference as a scene param is unsafe — the node may be freed before the incoming scene
> has a chance to use it. All required data is collected while the gameplay scene is
> still alive, then passed as value types.

### `receive_scene_params(params: Dictionary) -> void`

```gdscript
_current_level_data        = params.get("level_data")
_stars                     = params.get("stars", 0)         # int -1..3
_final_moves               = params.get("final_moves", 0)   # int
_prev_best_moves           = params.get("prev_best_moves", 0)
_was_previously_completed  = params.get("was_previously_completed", false)
_next_level_data           = params.get("next_level_data")  # LevelData or null
```

All display data is available immediately on `receive_scene_params`. The screen
does **not** wait for any further signals — it populates results in `_ready()`.

---

## Display Elements

| Element               | Source                                                    | Content                                     | Notes                                                        |
| --------------------- | --------------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------------ |
| **Level name**        | `_current_level_data.display_name`                        | Level title                                 | Set immediately in `_ready()`                                |
| **Star display**      | `_stars` param (int, -1 to 3)                             | 0–3 filled star icons                       | Stars animate in one-by-one at MVP-Polish; instant at MVP    |
| **Cat illustration**  | `_stars` + perfect check (`final_moves <= minimum_moves`) | Curious / Smile / Excited expression sprite | Smile is used for perfect clears; excited is fallback 3-star |
| **Move count**        | `_final_moves` param                                      | `"{final} / {min}"` or `"{final}"` if min=0 | Same format rules as HUD                                     |
| **New best badge**    | `_prev_best_moves` + `_was_previously_completed` params   | "NEW BEST!" label                           | Shown if first completion or final_moves < prev_best_moves   |
| **Next Level button** | `_next_level_data` param                                  | Enabled if `_next_level_data != null`       | Hidden if null (last level)                                  |
| **Retry button**      | Always visible                                            | Re-launches same level                      | Calls `SceneManager.go_to_level(_current_level_data)`        |
| **World Map button**  | Always visible                                            | Returns to World Map                        | Calls `SceneManager.go_to(Screen.WORLD_MAP)`                 |

---

## Design Rules

1. **Display results immediately from params**: All result data arrives in
   `receive_scene_params()`. `_ready()` immediately calls `populate_results()` and
   `_update_next_button()`. No signal connection to Level Progression is needed or
   present — the data is already confirmed by the time the screen loads.

2. **`stars == -1` sentinel**: If `level_record_saved` fires with `stars == -1`
   (in-development level), suppress the star display entirely — show dashes or an empty
   star row with a "?" indicator. The move count is still shown.

3. **New best detection**: `_prev_best_moves` and `_was_previously_completed` arrive as
   params (snapshotted by Level Coordinator at level load, before the save write).
   In `_populate_results()`, if `_was_previously_completed == false` (first completion)
   or `final_moves < _prev_best_moves`, show the "NEW BEST" badge. No SaveManager
   read from this screen.

4. **Next Level button availability**: `_next_level_data` was pre-computed by the
   Level Coordinator before the transition. If it is `null` (last level in game), hide
   the button. If it is a valid `LevelData`, show the button. The Level Coordinator
   already applied the unlock check via `LevelProgression.get_next_level()` (which
   only returns next level if it is unlocked).

5. **First-time world completion**: If `LevelProgression.world_completed` fired (Level
   Complete Screen may subscribe to it), show a brief "World Complete!" banner before the
   standard results layout. This is optional at MVP — skip the banner and go straight to
   results if the implementation time cost is high. Document as a stretch item.

6. **No star animation at MVP**: Stars appear instantly. The layout must accommodate a
   sequential pop-in animation (post-jam polish) without structural change.

7. **Level Complete Screen owns no game state**: It reads from params and signals. It
   never calls StarRatingSystem, MoveCounter, or CoverageTracking directly. Its only
   write action is triggering navigation via SceneManager.

8. **`minimum_moves == 0` handling**: When `_current_level_data.minimum_moves == 0`,
   the move display shows only the final count (no denominator), matching HUD behavior.

9. **Perfect-clear cat expression**: Use `cat_default_smile` when
   `final_moves <= minimum_moves` and `minimum_moves > 0`. Use `cat_default_excited`
   for other 3-star non-perfect outcomes and `cat_default_curious` for lower outcomes.

---

## Initialization Flow

```gdscript
func receive_scene_params(params: Dictionary) -> void:
    _current_level_data       = params.get("level_data")
    _stars                    = params.get("stars", 0)
    _final_moves              = params.get("final_moves", 0)
    _prev_best_moves          = params.get("prev_best_moves", 0)
    _was_previously_completed = params.get("was_previously_completed", false)
    _next_level_data          = params.get("next_level_data")

func _ready() -> void:
    _level_name_label.text = _current_level_data.display_name
    _populate_results(_stars, _final_moves)
    _update_next_button()

func _populate_results(stars: int, final_moves: int) -> void:
    _show_stars(stars)  # -1 → suppress; 0-3 → fill icons
    if _current_level_data.minimum_moves == 0:
        _moves_label.text = str(final_moves)
    else:
        _moves_label.text = "%d / %d" % [final_moves, _current_level_data.minimum_moves]
    # New best badge
    var is_first := not _was_previously_completed
    var is_better := _prev_best_moves > 0 and final_moves < _prev_best_moves
    _new_best_badge.visible = is_first or is_better

func _update_next_button() -> void:
    # _next_level_data pre-computed by Level Coordinator; null = last level
    if _next_level_data == null:
        _next_btn.visible = false
    else:
        _next_btn.visible = true
```

---

## Button Handlers

```gdscript
func _on_next_btn_pressed() -> void:
    SceneManager.go_to_level(_next_level_data)

func _on_retry_btn_pressed() -> void:
    SceneManager.go_to_level(_current_level_data)

func _on_world_map_btn_pressed() -> void:
    SceneManager.go_to(Screen.WORLD_MAP)
```

---

## Layout Notes

```
┌─────────────────────────────┐
│       [Level Name]          │  ← Top
│                             │
│       ★  ★  ★              │  ← Star row (3 icons, filled/empty)
│                             │
│    Moves: 8 / 8  [NEW BEST] │  ← Score row
│                             │
│  [Next Level]  [Retry]  [Map] │  ← Button row
└─────────────────────────────┘
```

Button row order: Next Level (primary, if available) → Retry → World Map.
When Next Level is hidden, Retry becomes the leftmost/primary button.

---

## Edge Cases

| Edge Case                                                 | Behaviour                                                                               |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `stars == -1` (in-dev level)                              | Star row shows dashes; move count shown normally                                        |
| Last level in game (`get_next_level()` returns null)      | Next Level button hidden; Retry and World Map only                                      |
| First time completing a level                             | `_prev_best_moves == 0` → "NEW BEST" badge shown                                        |
| Replay with worse move count                              | No new best badge; previous best preserved in SaveManager                               |
| `next_level_data` is null but player is not on last level | Should not occur if Level Coordinator computes correctly; Next Level hidden as fallback |

---

## Acceptance Criteria

| ID    | Criterion                                                                                 |
| ----- | ----------------------------------------------------------------------------------------- |
| LC-1  | Level name is displayed immediately when the screen loads                                 |
| LC-2  | Star display and move count appear immediately when the screen loads (from params)        |
| LC-3  | 3 stars → 3 filled star icons; 0 stars → 0 filled                                         |
| LC-4  | `stars == -1` → star icons suppressed or shown as "?"                                     |
| LC-5  | Move display shows `"{final} / {min}"` when `minimum_moves > 0`                           |
| LC-6  | Move display shows `"{final}"` only when `minimum_moves == 0`                             |
| LC-7  | "NEW BEST" badge shown on first completion of a level                                     |
| LC-8  | "NEW BEST" badge shown when `final_moves < previous best_moves`                           |
| LC-9  | Next Level button visible and functional after first-time completion of a non-final level |
| LC-10 | Next Level button hidden when on the last level                                           |
| LC-11 | Retry button navigates back to the same level                                             |
| LC-12 | World Map button navigates to World Map                                                   |

---

## Tuning Knobs

None at MVP. All display is data-driven from params received at scene load. No configurable animation durations or display thresholds.

---

## Dependencies

| Depends On         | Interface Used                                                                                                               |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| Level Coordinator  | Provides all result data as params: `stars`, `final_moves`, `prev_best_moves`, `was_previously_completed`, `next_level_data` |
| Level Data Format  | `display_name`, `minimum_moves`, `level_id` (from `_current_level_data` param)                                               |
| Save / Load System | No reads from this screen. SaveManager was read by Level Coordinator before transition.                                      |
| Scene Manager      | `go_to()`, `go_to_level()` for all navigation                                                                                |

---

## Open Questions

| ID   | Question                                                                                | Priority | Resolution                                                                                                                                                      |
| ---- | --------------------------------------------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should "World Complete!" banner be shown MVP or post-jam?                               | Low      | Provisional: post-jam stretch. Subscribe to `world_completed` in code but only show a simple text label, no animation. If too costly, remove entirely from MVP. |
| OQ-2 | Should best stars (from SaveManager) be shown next to current stars (e.g. "Best: ★★★")? | Low      | Provisional: no — keep results focused on current attempt. Historical best is visible on World Map level buttons.                                               |
