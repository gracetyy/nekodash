# HUD

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-04-02
> **System #**: 18 of 22
> **Category**: UI
> **Priority**: MVP-Polish

---

## Overview

The HUD is the in-level overlay that gives the player the information they need while
playing: current move count vs. minimum, live tile coverage, and interactive buttons for
undo and restart. It is a pure display and input-forwarding layer — it reads from gameplay
systems via signals and properties, forwards button presses to Undo/Restart, and owns no
game state of its own.

The HUD lives as a child of the gameplay scene root (the same scene as Level Coordinator).
It is not an autoload. It receives references to Move Counter, Undo/Restart, Coverage
Tracking, and the current LevelData via `initialize()` at level load.

---

## Player Fantasy

Clear information, no clutter. The player glances at the HUD and knows: how many moves
they've made, how many tiles are left, and whether undo is available. They shouldn't need to
think about those numbers — they should just be there, unobtrusive and correct. The HUD is
the difference between a puzzle that feels legible and one that feels mysterious in the wrong
way. A broken move counter, a stuck coverage display, or a greyed-out undo button that won't
respond — these are the failure modes. When the HUD is working, the player never notices it;
they just play.

---

## Responsibilities

| Responsibility                                       | Owned By                         |
| ---------------------------------------------------- | -------------------------------- |
| Display current move count and minimum moves target  | HUD ✅                           |
| Display live tile coverage (count or percentage)     | HUD ✅                           |
| Display and enable/disable Undo button               | HUD ✅                           |
| Display Restart button                               | HUD ✅                           |
| Forward Undo button press to Undo/Restart            | HUD ✅                           |
| Forward Restart button press to Undo/Restart         | HUD ✅                           |
| Hide/lock interactive elements after level_completed | HUD ✅                           |
| Counting moves, tracking coverage                    | Move Counter / Coverage Tracking |
| Executing undo and restart logic                     | Undo / Restart                   |
| Scene transitions                                    | Scene Manager                    |

---

## Design Rules

1. **Signal-driven updates**: HUD never polls. It subscribes to:
   - `MoveCounter.move_count_changed(current_moves: int, minimum_moves: int)` — updates
     move display
   - `CoverageTracking.coverage_updated(covered: int, total: int)` — updates tile
     coverage display
   - `UndoRestart.undo_applied(moves_in_history: int)` — refreshes undo button state
   - `UndoRestart.level_restarted` — resets all displays to initial state (calls
     `_refresh_all_displays()`)
   - `CoverageTracking.level_completed` — locks interactive elements

2. **Undo button enabled state**: The Undo button is enabled only when
   `UndoRestart.can_undo()` returns true. It is checked:
   - On `move_count_changed` (primary: UndoRestart snapshot is guaranteed to exist by
     the time this fires, so the button reflects live state after every slide)
   - On `undo_applied` (belt-and-suspenders: stack may now be empty)
   - On `level_restarted` (stack is empty after restart)
   - On `initialize()` (stack is empty at level load)

3. **`minimum_moves == 0` graceful display**: When `minimum_moves == 0` (in-development
   level), the move target is hidden — the move display shows only the current count
   with no "/ N" denominator. The HUD checks this condition from the initial
   `initialize()` call and suppresses the target label.

4. **Lock on level complete**: When `level_completed` fires, the Undo and Restart buttons
   are both hidden (or visually dimmed and input-blocked). The player is now looking at a
   completed puzzle — the Level Complete Screen will appear shortly. Restart is still
   logically available on the Undo/Restart system but the HUD does not expose it post-
   completion. The existing Undo/Restart GDD states: "restart still works, undo is a
   no-op after `level_completed`" — the HUD enforces this by simply hiding both buttons.

5. **Coverage display**: Hidden from player-facing HUD by default (decided post-playtest:
   tile colours already communicate progress visually). The `CoverageLabel` node remains
   in the scene but is set to `visible = false`. Coverage signals still flow to the HUD
   for debug-mode use. If reinstated, the display format is tile count: `"X / Y"`
   (e.g. `"12 / 20"`); no code changes are needed, only a visibility toggle.

6. **No animation at MVP**: Labels update instantly on signal. Counter bump animations
   (scale pop, color flash) are a polish task for post-jam. The HUD layout must leave
   enough space for these effects without requiring structural changes.

7. **Restart confirmation**: No confirmation dialog at MVP. Tapping Restart immediately
   calls `UndoRestart.restart()`. A confirmation step may be added post-jam if playtesting
   shows accidental presses.

8. **HUD does not navigate**: The HUD has no "back to world map" or "quit" button at MVP.
   Once in a level, the player's exit path is to complete it or use the device back button
   (which SceneManager may intercept — out of HUD scope).

---

## Display Elements

| Element            | Signal Source                                                           | Content                                         | Notes                                               |
| ------------------ | ----------------------------------------------------------------------- | ----------------------------------------------- | --------------------------------------------------- |
| **Moves prefix**   | Static (set at init)                                                    | `"Moves: "` (trailing space)                    | Plain Label prepended to Move label                 |
| **Move label**     | `move_count_changed`                                                    | `"{current} / {min}"` or `"{current}"` if min=0 | Right-aligned; large; prominent                     |
| **Coverage label** | `coverage_updated`                                                      | `"{covered} / {total}"`                         | Hidden by default (`visible = false`); debug only   |
| **Undo button**    | `move_count_changed`, `undo_applied`, `level_restarted`, `initialize()` | Icon + optional label "Undo"                    | Disabled (greyed) when `can_undo() == false`        |
| **Restart button** | `level_completed` (hide)                                                | Icon + optional label "Restart"                 | Always enabled while playing; hidden after complete |

---

## Initialization

`initialize(level_data: LevelData, move_counter: MoveCounter, undo_restart: UndoRestart,
            coverage_tracking: CoverageTracking) -> void`

Called by Level Coordinator after all gameplay nodes are ready:

1. Set `_move_minimum = level_data.minimum_moves`; cache for display logic
2. Connect to `move_counter.move_count_changed`
3. Connect to `coverage_tracking.coverage_updated` and `coverage_tracking.level_completed`
4. Connect to `undo_restart.undo_applied` and `undo_restart.level_restarted`
5. Store `_undo_restart_ref = undo_restart`
6. Call `_refresh_all_displays()` with initial state (0 moves, initial coverage from
   `coverage_tracking.covered_count` / `coverage_tracking.total_walkable`)
7. Update undo button: `_undo_btn.disabled = not undo_restart.can_undo()`

---

## Signal Handlers

### `_on_move_count_changed(current: int, minimum: int)`

```
if minimum == 0:
    _move_label.text = str(current)
else:
    _move_label.text = "%d / %d" % [current, minimum]
_undo_btn.disabled = not _undo_restart_ref.can_undo()  # refresh after every slide
```

> **Why here?** The Level Coordinator now dispatches the move pipeline in a fixed
> order, so Undo/Restart snapshots are already recorded by the time `move_count_changed`
> fires. Reading `can_undo()` here gives a live, correct result every time.

### `_on_coverage_updated(covered: int, total: int)`

```
_coverage_label.text = "%d / %d" % [covered, total]
```

### `_on_undo_applied(_moves_remaining: int)`

```
_undo_btn.disabled = not _undo_restart_ref.can_undo()
```

### `_on_level_restarted()`

```
_refresh_all_displays()
_undo_btn.disabled = true  # history is empty after restart
_undo_btn.visible = true
_restart_btn.visible = true
```

### `_on_level_completed()`

```
_undo_btn.visible = false
_restart_btn.visible = false
```

### Button Presses

```
func _on_undo_btn_pressed() -> void:
    _undo_restart_ref.undo()

func _on_restart_btn_pressed() -> void:
    _undo_restart_ref.restart()
```

---

## Layout Notes

The HUD is a `CanvasLayer` (or a `Control` node anchored over the gameplay viewport).
Suggested layout zones:

```
┌───────────────────────────────────┐
│  [Undo]  [Restart]  [Exit]        │  ← Top bar (button row)
│                                   │
│         [ puzzle grid ]           │  ← Centre (HUD-free zone)
│                                   │
│              Moves: 4/8           │  ← Bottom bar (stats row)
└───────────────────────────────────┘
```

Exact pixel sizes and fonts are owned by the Art Director's style guide. HUD GDD defines
layout intent and element groupings only.

### Color Tokens (from `docs/design/design-system.md`)

| Element             | Token           | Hex       |
| ------------------- | --------------- | --------- |
| Pill background     | `hud-pill-bg`   | `#735D6B` |
| Move counter text   | `hud-pill-text` | `#F8EBC2` |
| Moves prefix text   | `hud-pill-text` | `#F8EBC2` |
| Undo / Restart btns | `btn-secondary` | `#A5D5BD` |
| Exit button         | `btn-tertiary`  | `#C0AFE2` |
| Button labels       | `text-on-btn`   | `#FFFFFF` |

---

## Accessibility Notes

- Undo button disabled state must be visually distinct (not just colour — use opacity or
  icon change for colour-blind accessibility).
- Minimum font size for move label and coverage label: 18sp equivalent, scalable.
- Restart and Undo buttons must meet minimum 44×44pt tap target size on mobile.

---

## Edge Cases

| Edge Case                                      | Behaviour                                                                                                |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `minimum_moves == 0`                           | Move display shows `"{current}"` only; no denominator                                                    |
| `level_completed` fires                        | Both interactive buttons hidden immediately                                                              |
| Heavy undo usage leaves history empty mid-play | Undo button disabled; no crash                                                                           |
| `initialize()` called twice (level reload)     | Second call reconnects signals; `disconnect()` on previous connections first to avoid duplicate handlers |
| Coverage total is 1 (single-tile puzzle)       | Display shows `"1 / 1"` on init; level completes immediately on `spawn_position_set`                     |

---

## Acceptance Criteria

| ID    | Criterion                                                                             |
| ----- | ------------------------------------------------------------------------------------- |
| HU-1  | Move label shows `"0 / N"` at level load (N = `minimum_moves`)                        |
| HU-2  | Move label updates to `"1 / N"` after the first slide                                 |
| HU-3  | When `minimum_moves == 0`, move label shows `"0"` at load and `"1"` after first slide |
| HU-4  | Coverage label shows `"1 / T"` at load (starting tile pre-covered)                    |
| HU-5  | Coverage label increments correctly after each slide                                  |
| HU-6  | Undo button is disabled (greyed) at level load                                        |
| HU-7  | Undo button enables after the first slide                                             |
| HU-8  | Undo button disables again after undoing back to zero moves                           |
| HU-9  | Tapping Undo calls `UndoRestart.undo()`                                               |
| HU-10 | Tapping Restart calls `UndoRestart.restart()` and all HUD displays reset              |
| HU-11 | Both buttons are hidden after `level_completed` fires                                 |

---

## Tuning Knobs

None at MVP — all display is driven by incoming signals and `LevelData`. Post-jam option: `MOVE_FLASH_DURATION: float = 0.3` for the move counter flash animation when a new best is beaten.

---

## Dependencies

| Depends On        | Interface Used                                                                                                                        |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Move Counter      | `move_count_changed(current, minimum)` signal                                                                                         |
| Coverage Tracking | `coverage_updated(covered, total)` signal; `level_completed` signal; `covered_count`, `total_walkable` properties (read once at init) |
| Undo / Restart    | `undo_applied(moves_in_history)` signal; `level_restarted` signal; `can_undo() -> bool`; `undo() -> void`; `restart() -> void`        |
| Level Data Format | `minimum_moves: int` (read once at init)                                                                                              |

---

## Resolutions to Open Questions from Upstream GDDs

| Source                 | OQ                                                    | Resolution                                                                              |
| ---------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Coverage Tracking OQ-2 | Should `coverage_updated` fire per-tile or per-slide? | **Per-slide** — HUD updates once per slide, not per tile. No per-tile animation at MVP. |

---

## Open Questions

| ID   | Question                                                                                            | Priority | Resolution                                                                                                        |
| ---- | --------------------------------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should best stars (from SaveManager) be shown in the HUD during play (e.g. three small star icons)? | Low      | Provisional: no — keep HUD minimal. Stars are shown on Level Complete Screen only.                                |
| OQ-2 | Should the coverage label show `"X / Y tiles"` or just `"X / Y"`?                                   | Low      | Provisional: `"X / Y"` — icon-based context will make it clear without the word "tiles". Art Director to confirm. |
