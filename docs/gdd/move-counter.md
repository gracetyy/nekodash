# Move Counter

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Pillar 2 — Always Know How Close to Perfect You Are

## Overview

The Move Counter tracks the number of moves the player has made in the current level attempt and compares that count against the `minimum_moves` value baked into `LevelData`. It owns a single integer — `current_moves: int` — that increments once per completed move when the Level Coordinator calls `increment(...)`. At level load it reads `minimum_moves`, `star_3_moves`, `star_2_moves`, and `star_1_moves` from `LevelData` and caches them for the session. It exposes `current_moves` and `minimum_moves` to the HUD for live display, fires `move_count_changed` after each increment, and exposes `get_final_move_count() -> int` for the Level Complete Screen and Star Rating System to query when `level_completed` fires. It does not compute star ratings — that belongs to Star Rating System. It does not control game flow. It is a thin, stateless counter that answers one question: "how many moves has the player made?"

## Player Fantasy

The number at the top of the screen. "Target: 8 moves" in small calm text. "Moves: 3" building below it with each swipe. The gap closing. The quiet tension of "can I still do it in 8?" on move 6. The small triumph when the board goes gold on move 8 — or the immediate urge to restart when it was move 11.

This is **Pillar 2 — Always Know How Close to Perfect You Are** in its most literal form. The move count and target are visible from the first move to the last. The player is never in doubt about where they stand. That information does not judge — it informs. A player who finishes in 11 when the target was 8 sees "11 / 8" and immediately understands what "better" means without needing to be told.

## Detailed Design

### Core Rules

1. **Initialization**: At level load, Move Counter reads `level_data.minimum_moves`, `level_data.star_3_moves`, `level_data.star_2_moves`, and `level_data.star_1_moves` from the `LevelData` resource. It caches these as read-only values for the session. It sets `current_moves = 0`.

2. **Counting**: The Level Coordinator calls `increment()` once per completed move. Each call increments `current_moves` by 1 and emits `move_count_changed(current_moves: int, minimum_moves: int)`.

3. **One completed move = one increment**: Blocked slides (`slide_blocked`) never emit a completed move and therefore never increment `current_moves`. There is no other increment path.

4. **No decrement during play**: `current_moves` never decreases during a live level attempt. Undo rewinds the count via `set_move_count(n: int)` — called by the Undo system with the pre-move snapshot value.

5. **Undo support**: Move Counter exposes `set_move_count(n: int) -> void`. The Undo system calls this to rewind `current_moves` to the pre-move value. Move Counter emits `move_count_changed` after the set. This is the only external write path to `current_moves`.

6. **Level complete read-out**: Move Counter exposes `get_final_move_count() -> int`, which returns `current_moves` at the moment the level completes. Star Rating System and Level Complete Screen call this at `level_completed` time. No special capture is needed — `current_moves` does not change after `level_completed` unless a restart occurs.

7. **Minimum moves display**: If `minimum_moves == 0` (level unsolved by BFS, under authoring), Move Counter omits the target display — it emits `move_count_changed` with `minimum_moves = 0`, and the HUD renders without a target. This is a graceful degradation for unreleased or in-development levels.

8. **Restart**: On level restart, the Undo/Restart system calls `reset_move_count()`. Move Counter sets `current_moves = 0` and emits `move_count_changed(0, minimum_moves)`.

9. **Read-only public interface**: External systems read `current_moves` and `minimum_moves` as properties. The only write paths are internal (`increment()`), and `set_move_count()` / `reset_move_count()` for Undo/Restart.

### States and Transitions

Move Counter has no explicit state machine — it is a stateless counter. Its "states" are simply aspects of the enclosing level session:

| Phase        | Entry Condition                          | Behavior                                                             |
| ------------ | ---------------------------------------- | -------------------------------------------------------------------- |
| **Reset**    | `reset_move_count()` called; level loads | `current_moves = 0`; `move_count_changed(0, minimum_moves)` emitted  |
| **Counting** | `increment()` called                     | `current_moves += 1`; `move_count_changed` emitted                   |
| **Rewound**  | `set_move_count(n)` called               | `current_moves = n`; `move_count_changed(n, minimum_moves)` emitted  |
| **Frozen**   | `level_completed` fired (from Coverage)  | Count stops incrementing until restart (no more slides are accepted) |

### Interactions with Other Systems

| System                    | Direction                        | Interface                                                                                                                 |
| ------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Level Coordinator**     | Level Coordinator → Move Counter | Calls `increment()` once per completed move.                                                                              |
| **Level Data Format**     | Level Data Format → Move Counter | Reads `minimum_moves`, `star_3_moves`, `star_2_moves`, `star_1_moves` at level load; cached for the session.              |
| **Undo/Restart**          | Undo/Restart → Move Counter      | Calls `set_move_count(n)` to rewind; calls `reset_move_count()` on full restart.                                          |
| **HUD**                   | Move Counter → HUD               | HUD subscribes to `move_count_changed(current, minimum)` to update the live display.                                      |
| **Star Rating System**    | Move Counter → Star Rating       | Star Rating reads `get_final_move_count()` (and optionally `minimum_moves`, `star_n_moves`) at `level_completed` time.    |
| **Level Complete Screen** | Move Counter → Level Complete    | Level Complete Screen reads `get_final_move_count()` to display the player's final score.                                 |
| **Coverage Tracking**     | Coverage Tracking → (indirect)   | Coverage Tracking emits `level_completed`; Move Counter uses this as the implicit "freeze" point — count stops advancing. |

## Formulas

### Move Increment

```
current_moves += 1    # On each coordinator-dispatched move
```

No formula more complex than this. One valid slide = one move.

### Undo Rewind

```
current_moves = snapshot_move_count    # Set by Undo system
```

| Variable              | Type  | Description                                                                                      |
| --------------------- | ----- | ------------------------------------------------------------------------------------------------ |
| `snapshot_move_count` | `int` | Move count at the moment before the undone move; supplied by Undo/Restart from its history stack |

### Star Rating Threshold Comparison (reference, owned by Star Rating System)

Move Counter exposes the raw values; Star Rating System performs the comparison:

```
if final_moves <= star_3_moves:  rating = 3
elif final_moves <= star_2_moves: rating = 2
elif final_moves <= star_1_moves: rating = 1
else:                             rating = 0
```

| Variable       | Type  | Source                   | Description                       |
| -------------- | ----- | ------------------------ | --------------------------------- |
| `final_moves`  | `int` | `get_final_move_count()` | Player's move count at completion |
| `star_3_moves` | `int` | `LevelData`              | Perfect play threshold            |
| `star_2_moves` | `int` | `LevelData`              | Good play threshold               |
| `star_1_moves` | `int` | `LevelData`              | Casual completion threshold       |

_This formula is documented here for reference and cross-system clarity. It is implemented in Star Rating System, not Move Counter._

### Moves Over Minimum (HUD display)

```
moves_over_minimum = current_moves - minimum_moves
```

Positive = over target; 0 = exactly on target; negative = under (impossible — move count never exceeds a run, but displayed as 0 if minimum_moves is 0). Used optionally by HUD to show "+N" delta.

| Variable        | Type  | Notes                                          |
| --------------- | ----- | ---------------------------------------------- |
| `current_moves` | `int` | Always ≥ 0                                     |
| `minimum_moves` | `int` | 0 if unsolved — HUD omits delta display when 0 |

## Edge Cases

| Scenario                                                           | Expected Behavior                                                                                                                                                                                                  | Rationale                                                                                                                                                               |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `minimum_moves == 0` (level not yet solved by BFS)                 | Move Counter still tracks `current_moves`; HUD receives `minimum_moves = 0` and omits the target display                                                                                                           | Allows playtesting unfinished levels without crashing or misleading data                                                                                                |
| `set_move_count(0)` called (undo to start)                         | `current_moves = 0`; `move_count_changed(0, minimum_moves)` emitted; valid                                                                                                                                         | Undoing all moves back to level start is a valid user action                                                                                                            |
| `set_move_count(n)` called with `n > current_moves`                | Log a warning; clamp to `current_moves`; do not allow count to increase via undo API                                                                                                                               | Undo only decrements; a larger value indicates a Undo/Restart logic error                                                                                               |
| `increment()` called after `level_completed`                       | Should not occur — Coverage Tracking completes after the slide that triggered completion; Sliding Movement blocks new input immediately after. If it does arrive, increment is ignored (state is frozen).          | Race condition guard; Coverage Tracking's `level_completed` is synchronous                                                                                              |
| Player achieves `current_moves > star_1_moves`                     | No special behavior from Move Counter — count continues incrementing; Star Rating will assign 0 stars at completion                                                                                                | Move Counter is neutral; it does not penalize or cap                                                                                                                    |
| Player reaches exact `minimum_moves` on completion                 | `current_moves == minimum_moves`; `move_count_changed` emitted normally; Star Rating System will assign 3 stars                                                                                                    | Normal happy-path scenario; no special handling needed in Move Counter                                                                                                  |
| `reset_move_count()` called during an active slide (mid-animation) | `current_moves = 0`; `move_count_changed` emitted immediately; the in-flight move dispatch that finishes after the tween ends will re-increment to 1 unless the restart also killed the tween via Sliding Movement | Restart path: Undo/Restart kills the tween via `set_grid_position_instant()` before calling reset; execution order must be: kill tween → reset coverage → reset counter |

## Dependencies

| System                    | Direction                        | Nature                                                                                                                  | Hard/Soft                                                                                        |
| ------------------------- | -------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Level Coordinator**     | Level Coordinator → Move Counter | Calls `increment()`; this is the only increment trigger                                                                 | **Hard** — no moves can be counted without this call                                             |
| **Level Data Format**     | Level Data Format → Move Counter | Reads `minimum_moves` + star thresholds at level load; cached for the session                                           | **Hard** — without `minimum_moves`, the HUD cannot display a target (degrades to no-target mode) |
| **Undo/Restart**          | Undo/Restart → Move Counter      | Calls `set_move_count()` and `reset_move_count()` to control the count during undo and restart operations               | **Hard** — undo would show wrong move count without this write path                              |
| **HUD**                   | Move Counter → HUD               | Subscribes to `move_count_changed(current, minimum)`; reads `current_moves`, `minimum_moves` as properties              | **Soft** — game logic is unaffected; only display breaks without HUD                             |
| **Star Rating System**    | Move Counter → Star Rating       | Reads `get_final_move_count()` at completion; star thresholds could also be read from here or directly from `LevelData` | **Soft** — Star Rating can read `LevelData` directly; Move Counter is a convenience accessor     |
| **Level Complete Screen** | Move Counter → Level Complete    | Reads `get_final_move_count()` to display the player's score on the completion screen                                   | **Soft** — UI only; game logic unaffected                                                        |

## Tuning Knobs

Move Counter has no runtime tuning knobs — it is a deterministic counter. The thresholds it displays (`star_3_moves`, etc.) are owned by `LevelData` and authored per-level by the level designer.

The only design-time parameter the Move Counter influences is the **HUD display format** for `current_moves` vs. `minimum_moves`:

| Display Option                | Example                  | Notes                                              |
| ----------------------------- | ------------------------ | -------------------------------------------------- |
| Fraction (`current / target`) | `6 / 8`                  | Immediately legible gap; recommended default       |
| Separate labels               | `Moves: 6` + `Target: 8` | Two distinct UI elements; more flexible for layout |
| Delta only (`+N`)             | `+2`                     | Compact; only shows gap; loses absolute context    |
| Current only (no target)      | `6`                      | When `minimum_moves == 0`; graceful fallback       |

_Display format is owned by the HUD GDD. Move Counter exposes the numbers regardless of display choice._

## Visual/Audio Requirements

Move Counter itself produces no visuals or audio. All feedback is owned by downstream systems:

| Event                                              | Owner                 | Description                                                                  | Priority     |
| -------------------------------------------------- | --------------------- | ---------------------------------------------------------------------------- | ------------ |
| `move_count_changed` (normal increment)            | HUD                   | HUD updates the move number display; optionally a brief number-pop animation | Required     |
| Reaching `minimum_moves` exactly at level complete | HUD + SFX Manager     | Optional "perfect!" visual flair in HUD; SFX for exact-minimum landing       | Stretch goal |
| `move_count_changed` after undo (count decrements) | HUD                   | HUD updates the display; no special animation needed                         | Required     |
| Move count displayed on Level Complete Screen      | Level Complete Screen | Final move count shown alongside star rating                                 | Required     |

## UI Requirements

Move Counter exposes two values for HUD display:

- `current_moves: int` — updated live after every coordinator-dispatched move
- `minimum_moves: int` — set at level load; constant for the session (0 if unsolved)

The HUD is responsible for all layout decisions (position, font, animation) — Move Counter only provides the data. The exact format ("6 / 8", "+2 over target", etc.) is a HUD GDD decision.

One special case: when `minimum_moves == 0`, the HUD must suppress the target display (show only `current_moves`). Move Counter passes `minimum_moves = 0` in `move_count_changed`; HUD decides how to render.

## Acceptance Criteria

| #    | Criterion                                                                                                                        |
| ---- | -------------------------------------------------------------------------------------------------------------------------------- |
| MC-1 | After level load with `minimum_moves = 8`, `current_moves == 0` and `minimum_moves == 8`; `move_count_changed(0, 8)` is emitted. |
| MC-2 | Each completed move increments `current_moves` by exactly 1 and emits `move_count_changed(n, minimum_moves)`.                    |
| MC-3 | `slide_blocked` does NOT increment `current_moves`.                                                                              |
| MC-4 | After `set_move_count(3)`, `current_moves == 3`; `move_count_changed(3, minimum_moves)` is emitted.                              |
| MC-5 | After `reset_move_count()`, `current_moves == 0`; `move_count_changed(0, minimum_moves)` is emitted.                             |
| MC-6 | `get_final_move_count()` returns `current_moves` at level complete time.                                                         |
| MC-7 | With `minimum_moves == 0`, `move_count_changed` is still emitted normally with `minimum_moves = 0`; no crash or error.           |
| MC-8 | `set_move_count(n)` with `n > current_moves` logs a warning and does not increase `current_moves`.                               |
| MC-9 | `move_count_changed` signal fires exactly once per completed move, not zero times or more than once.                             |

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                     | Priority | Owner                                 | Resolution               |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------- | ------------------------ |
| OQ-1 | Should Move Counter also cache and expose `star_3_moves`, `star_2_moves`, `star_1_moves` as properties (so Star Rating System reads from Move Counter rather than directly from `LevelData`)? Provisional: Star Rating System reads directly from `LevelData` — simpler, fewer dependencies. | Low      | Resolve during Star Rating System GDD | Provisional: direct read |
| OQ-2 | Should there be a `move_count_at_limit` signal when `current_moves > star_1_moves` (all stars lost)? Could drive a subtle HUD glow or prompt. Provisional: no — keeps Move Counter neutral and avoids HUD complexity at MVP.                                                                 | Low      | Resolve during HUD GDD                | Provisional: no signal   |
