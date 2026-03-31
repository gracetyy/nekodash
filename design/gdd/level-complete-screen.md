# Level Complete Screen

> **Status**: Draft
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 19 of 22
> **Category**: UI
> **Priority**: MVP-Polish

---

## Overview

The Level Complete Screen is the post-level results view. It shows the player their star
rating, final move count (vs. minimum), and any new personal best, then offers three
navigation choices: play the next level, retry the same level, or return to the World Map.

It is a separate Godot scene (`res://scenes/ui/level_complete.tscn`) loaded by Scene
Manager after `level_completed` fires in the gameplay scene. It receives its context via
`receive_scene_params()`, subscribes to `LevelProgression.level_record_saved` to read
confirmed star and move data after SaveManager has written it, and delegates all navigation
to `SceneManager`.

---

## Responsibilities

| Responsibility                             | Owned By                                   |
| ------------------------------------------ | ------------------------------------------ |
| Display stars earned this attempt          | Level Complete Screen ✅                   |
| Display final move count and minimum moves | Level Complete Screen ✅                   |
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

The gameplay scene root's Level Coordinator subscribes to `CoverageTracking.level_completed`
and calls:

```gdscript
SceneManager.go_to(Screen.LEVEL_COMPLETE, {
    "level_data": _current_level_data,
    "level_progression": _level_progression_ref,
    "final_moves": _move_counter.get_final_move_count()
})
```

These three params are the minimum contract. The Level Complete Screen reads them from
`receive_scene_params()`.

### `receive_scene_params(params: Dictionary) -> void`

```
_current_level_data = params.get("level_data")         # LevelData
_level_progression = params.get("level_progression")  # LevelProgression node ref
_final_moves = params.get("final_moves", 0)            # int
```

After receiving params, the screen does **not** immediately show star results — it waits
for `LevelProgression.level_record_saved` to fire (confirming SaveManager has written the
record) before populating the star display. This ensures the displayed result is the
authoritative confirmed value, not a guess.

> **Why wait for `level_record_saved`?** `StarRatingSystem.rating_computed` and
> `LevelProgression.level_record_saved` fire close together but in separate signal
> emissions. Waiting for `level_record_saved` guarantees the data shown matches exactly
> what was saved. It also provides a natural beat before the results animate in.

---

## Display Elements

| Element               | Source                                                                                   | Content                                          | Notes                                                                 |
| --------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------ | --------------------------------------------------------------------- |
| **Level name**        | `_current_level_data.display_name`                                                       | Level title                                      | Set immediately on `receive_scene_params`                             |
| **Star display**      | `level_record_saved` signal `stars` arg                                                  | 0–3 filled star icons                            | Stars animate in one-by-one at MVP-Polish; instant at MVP             |
| **Move count**        | `level_record_saved` signal `final_moves` arg                                            | `"{final} / {min}"` or `"{final}"` if min=0      | Same format rules as HUD                                              |
| **New best badge**    | Compare `final_moves` to `SaveManager.get_level_record(level_id).best_moves` (pre-write) | "NEW BEST!" label                                | Only shown if final_moves < previous best moves (or first completion) |
| **Next Level button** | `_level_progression.get_next_level(level_id)`                                            | Enabled if next level exists and is now unlocked | Hidden if `get_next_level()` returns null (last level)                |
| **Retry button**      | Always visible                                                                           | Re-launches same level                           | Calls `SceneManager.go_to_level(_current_level_data)`                 |
| **World Map button**  | Always visible                                                                           | Returns to World Map                             | Calls `SceneManager.go_to(Screen.WORLD_MAP)`                          |

---

## Design Rules

1. **Wait for `level_record_saved` before displaying results**: Connect to
   `_level_progression.level_record_saved` in `_ready()`. The handler populates star
   display and move count. The level name is shown immediately (no wait needed).

2. **`stars == -1` sentinel**: If `level_record_saved` fires with `stars == -1`
   (in-development level), suppress the star display entirely — show dashes or an empty
   star row with a "?" indicator. The move count is still shown.

3. **New best detection**: Before `level_record_saved` fires, the Level Complete Screen
   reads `SaveManager.get_level_record(_current_level_data.level_id)` in
   `receive_scene_params()` to snapshot the _previous_ best moves. After
   `level_record_saved` fires, if `final_moves < _prev_best_moves` (or
   `_prev_best_moves == 0` for first completion), show the "NEW BEST" badge.

4. **Next Level button availability**: After `level_record_saved` fires, call
   `_level_progression.get_next_level(level_id)`. If it returns a `LevelData` and
   `_level_progression.is_level_unlocked(next.level_id)` is true, enable the button.
   Otherwise hide it.

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

---

## Initialization Flow

```
_ready():
    Connect _level_progression.level_record_saved → _on_level_record_saved
    Connect _level_progression.world_completed → _on_world_completed (optional MVP-stretch)
    _level_name_label.text = _current_level_data.display_name
    _snapshot_prev_best()  # read SaveManager before write lands

_snapshot_prev_best():
    var record = SaveManager.get_level_record(_current_level_data.level_id)
    _prev_best_moves = record.get("best_moves", 0)
    _was_previously_completed = record.get("completed", false)

_on_level_record_saved(level_id, stars, final_moves):
    if level_id != _current_level_data.level_id:
        return  # guard against stale signals from prior levels
    _populate_results(stars, final_moves)
    _update_next_button()

_populate_results(stars, final_moves):
    _show_stars(stars)  # -1 → suppress; 0-3 → fill icons
    if _current_level_data.minimum_moves == 0:
        _moves_label.text = str(final_moves)
    else:
        _moves_label.text = "%d / %d" % [final_moves, _current_level_data.minimum_moves]
    # New best badge
    var is_first = not _was_previously_completed
    var is_better = _prev_best_moves > 0 and final_moves < _prev_best_moves
    _new_best_badge.visible = is_first or is_better

_update_next_button():
    var next = _level_progression.get_next_level(_current_level_data.level_id)
    if next == null or not _level_progression.is_level_unlocked(next.level_id):
        _next_btn.visible = false
    else:
        _next_btn.visible = true
        _next_level_data = next
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

| Edge Case                                             | Behaviour                                                                       |
| ----------------------------------------------------- | ------------------------------------------------------------------------------- |
| `stars == -1` (in-dev level)                          | Star row shows dashes; move count shown normally                                |
| Last level in game (`get_next_level()` returns null)  | Next Level button hidden; Retry and World Map only                              |
| First time completing a level                         | `_prev_best_moves == 0` → "NEW BEST" badge shown                                |
| Replay with worse move count                          | No new best badge; previous best preserved in SaveManager                       |
| `level_record_saved` fires for a different level_id   | Handler returns early; no display corruption                                    |
| Player taps buttons before `level_record_saved` fires | Retry and World Map always work; Next Level button is hidden until results land |

---

## Acceptance Criteria

| ID    | Criterion                                                                                 |
| ----- | ----------------------------------------------------------------------------------------- |
| LC-1  | Level name is displayed immediately when the screen loads                                 |
| LC-2  | Star display and move count appear after `level_record_saved` fires                       |
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

## Dependencies

| Depends On         | Interface Used                                                                                       |
| ------------------ | ---------------------------------------------------------------------------------------------------- |
| Star Rating System | `stars` value arrives via `level_record_saved` (indirect; Star Rating → Level Progression → signal)  |
| Level Progression  | `level_record_saved(level_id, stars, final_moves)` signal; `get_next_level()`; `is_level_unlocked()` |
| Move Counter       | `final_moves` passed via `receive_scene_params` params                                               |
| Level Data Format  | `display_name`, `minimum_moves`, `level_id`                                                          |
| Save / Load System | `get_level_record()` — read _before_ `level_record_saved` fires to snapshot previous best            |
| Scene Manager      | `go_to()`, `go_to_level()` for all navigation                                                        |

---

## Open Questions

| ID   | Question                                                                                | Priority | Resolution                                                                                                                                                      |
| ---- | --------------------------------------------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should "World Complete!" banner be shown MVP or post-jam?                               | Low      | Provisional: post-jam stretch. Subscribe to `world_completed` in code but only show a simple text label, no animation. If too costly, remove entirely from MVP. |
| OQ-2 | Should best stars (from SaveManager) be shown next to current stars (e.g. "Best: ★★★")? | Low      | Provisional: no — keep results focused on current attempt. Historical best is visible on World Map level buttons.                                               |
