# Star Rating System

> **Status**: Approved
> **Created**: 2026-03-30
> **Last Updated**: 2026-03-30
> **System #**: 15 of 22
> **Category**: Progression
> **Priority**: MVP-Polish

---

## Overview

The Star Rating System calculates and broadcasts the player's star score at the end of each
level. It owns one pure computation: compare the player's final move count against three
threshold values baked into `LevelData` and return a 0–3 star integer. It fires one signal
carrying the result. It does not animate, does not persist, and does not alter game flow.

This system enforces the game's key promise — _always know how close to perfect you are_ —
by making performance legible: three stars means optimal play, zero stars means the level was
finished but inefficiently. In all cases, level completion is what matters for progression;
stars are informational feedback.

---

## Player Fantasy

The number at the end. When the Level Complete Screen appears and the stars pop in — one,
two, three — the player knows exactly where they stand. Three stars means they found the
optimal path. One star means they completed it but left moves on the table. Zero stars means
they ground through it by brute force. None of these are wrong, but all of them are
meaningful. The Star Rating System is what creates the difference between "I finished" and
"I know where I stand." It is the honest mirror the game holds up at the end of every level.

---

## Responsibilities

| Responsibility                                        | Owned By                                   |
| ----------------------------------------------------- | ------------------------------------------ |
| Compute star rating from final move count             | Star Rating System ✅                      |
| Cache star thresholds at level load                   | Star Rating System ✅                      |
| Emit `rating_computed` signal                         | Star Rating System ✅                      |
| Track current-session move count                      | Move Counter                               |
| Define `star_1_moves`, `star_2_moves`, `star_3_moves` | Level Data Format                          |
| Persist best star record                              | Save / Load System (via Level Progression) |
| Display stars to the player                           | Level Complete Screen                      |
| Gate level unlocks on star count                      | Level Progression                          |

---

## Design Rules

1. **One trigger**: Star Rating System connects to `CoverageTracking.level_completed`. It
   computes the rating exactly once per level attempt, immediately on that signal, then
   becomes inert until the next `initialize_level()` call.

2. **One source of truth for moves**: `MoveCounter.get_final_move_count()` is the only
   read path for the player's final move count. Star Rating System holds no move counter
   of its own.

3. **LevelData owns the thresholds**: Star Rating System reads `star_1_moves`,
   `star_2_moves`, and `star_3_moves` from the `LevelData` resource at `initialize_level()`
   time and caches them. It does not re-read from Move Counter's cache. Move Counter and
   Star Rating independently cache from the same LevelData source.

4. **Formula is locked**:

   ```
   if final_moves <= star_3_moves → 3 stars
   elif final_moves <= star_2_moves → 2 stars
   elif final_moves <= star_1_moves → 1 star
   else → 0 stars
   ```

   `star_3_moves == minimum_moves` always (enforced by BFS Minimum Solver at authoring time).
   A 3-star rating means the player solved the level in the minimum possible moves.

5. **0 stars is valid**: A player who completes the level in more moves than `star_1_moves`
   earns 0 stars. This is a legitimate outcome — the level is still marked completed for
   progression purposes. Stars measure quality of play, not whether the player may proceed.

6. **Star Rating does not write to SaveManager**: It fires `rating_computed` and is done.
   Level Progression subscribes to that signal and calls `SaveManager.set_level_record()`.
   Star Rating System has no SaveManager dependency.

7. **Graceful zero-threshold handling**: If `minimum_moves == 0` (level not yet solved by
   BFS; in-development content), all three thresholds will be 0 or meaningless. When all
   thresholds are 0, Star Rating System skips computation and emits `rating_computed` with
   `stars = -1` (sentinel) so downstream systems can suppress star display rather than
   show incorrect results. Level Progression must treat `stars == -1` as "no rating — do
   not update record".

8. **No per-level memory**: Star Rating System holds only the current level's thresholds
   and the computed result for the current attempt. It does not maintain a history of
   ratings and does not read from SaveManager.

---

## Initialization

`initialize_level(level_data: LevelData, move_counter_ref: MoveCounter) -> void`

Called by the Level Coordinator when a level loads. Star Rating System:

1. Caches `_star_3_moves`, `_star_2_moves`, `_star_1_moves`, `_level_id`, and
   `_minimum_moves` from `level_data`.
2. Stores a reference to `move_counter_ref` for end-of-level read.
3. Resets `_current_rating = -1` (no rating yet this attempt).
4. Connects to `CoverageTracking.level_completed` (or reconnects, clearing any prior
   connection).

---

## Core Computation

`_on_level_completed() -> void` — private handler

```
var final_moves: int = _move_counter.get_final_move_count()

# Graceful degradation for unsolved/in-development levels
if _minimum_moves == 0:
    _current_rating = -1
    rating_computed.emit(_level_id, -1, final_moves)
    return

if final_moves <= _star_3_moves:
    _current_rating = 3
elif final_moves <= _star_2_moves:
    _current_rating = 2
elif final_moves <= _star_1_moves:
    _current_rating = 1
else:
    _current_rating = 0

rating_computed.emit(_level_id, _current_rating, final_moves)
```

---

## Public Interface

### Methods

| Method               | Signature                                                        | Description                                                                            |
| -------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `initialize_level`   | `(level_data: LevelData, move_counter_ref: MoveCounter) -> void` | Load thresholds, store move counter ref, reset state                                   |
| `get_current_rating` | `() -> int`                                                      | Returns rating from this attempt: 0–3, or -1 if unsolved threshold or not yet computed |

### Signals

| Signal            | Arguments                                        | When Fired                                                                               |
| ----------------- | ------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `rating_computed` | `level_id: String, stars: int, final_moves: int` | Immediately after `level_completed` triggers computation. Fired at most once per attempt |

### Read-Only Properties

| Property       | Type  | Source                        |
| -------------- | ----- | ----------------------------- |
| `star_3_moves` | `int` | Cached from LevelData at init |
| `star_2_moves` | `int` | Cached from LevelData at init |
| `star_1_moves` | `int` | Cached from LevelData at init |

---

## Downstream Consumers

| Consumer                            | What it reads                                                                       | When                                           |
| ----------------------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------- |
| **Level Progression**               | Subscribes to `rating_computed`; calls `SaveManager.set_level_record()`             | On `rating_computed`                           |
| **Level Complete Screen**           | Subscribes to `rating_computed`; reads `stars` and `final_moves` to animate display | On `rating_computed`                           |
| **Skin Unlock / Milestone Tracker** | Reads cumulative star counts from SaveManager (not directly from Star Rating)       | After Level Progression has written the record |

Level Complete Screen and Level Progression both subscribe independently to `rating_computed`.
The order in which they receive it does not matter — Level Complete Screen reads display
data, Level Progression writes to SaveManager. There is no sequencing dependency between
them on this signal.

---

## Edge Cases

| Edge Case                                                                   | Behaviour                                                                                                                                          |
| --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `minimum_moves == 0` (in-development level)                                 | Emits `rating_computed` with `stars = -1`; Level Progression must ignore this; Level Complete Screen must suppress star display                    |
| `star_3_moves == star_2_moves`                                              | Not a design error — player must hit exact minimum for 3 stars; otherwise falls through to 2-star check normally                                   |
| Player uses undo heavily, ends on minimum moves                             | (**MVP**) 3 stars — undo is a permitted tool; the formula is purely final-state. (**Post-jam: see OQ-2** — undo count will impose a star penalty.) |
| Player restarts and completes; `rating_computed` already fired this attempt | On restart, Level Coordinator calls `initialize_level()` again, which resets `_current_rating = -1` and reconnects the `level_completed` signal    |

---

## Acceptance Criteria

| ID   | Criterion                                                                                                                   |
| ---- | --------------------------------------------------------------------------------------------------------------------------- |
| SR-1 | `rating_computed` fires exactly once per level attempt, on `level_completed`                                                |
| SR-2 | A player finishing in `star_3_moves` moves receives 3 stars                                                                 |
| SR-3 | A player finishing in `star_3_moves + 1` through `star_2_moves` moves receives 2 stars                                      |
| SR-4 | A player finishing in `star_2_moves + 1` through `star_1_moves` moves receives 1 star                                       |
| SR-5 | A player finishing in more than `star_1_moves` moves receives 0 stars                                                       |
| SR-6 | When `minimum_moves == 0`, `rating_computed` fires with `stars = -1` and Level Progression does not update SaveManager      |
| SR-7 | After restart, the next `level_completed` re-fires `rating_computed` with fresh data                                        |
| SR-8 | Star Rating System never calls `SaveManager` directly                                                                       |
| SR-9 | `get_current_rating()` returns the result of the most recent computation, or -1 if no computation has occurred this attempt |

---

## Tuning Knobs

None at MVP. Star thresholds (`star_3_moves`, `star_2_moves`, `star_1_moves`) are per-level data authored in `LevelData`. The rating formula is locked. Post-jam option: `STAR_1_FLOOR: int` to guarantee at least 1 star when `final_moves < star_1_moves * N`.

---

## Dependencies

| Depends On        | Interface Used                                                              |
| ----------------- | --------------------------------------------------------------------------- |
| Move Counter      | `get_final_move_count() -> int`                                             |
| Level Data Format | `star_1_moves`, `star_2_moves`, `star_3_moves`, `minimum_moves`, `level_id` |
| Coverage Tracking | `level_completed` signal (trigger)                                          |

---

## Open Questions

| ID   | Question                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Priority        | Resolution                                                                                                                                                                 |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should Level Coordinator inject the MoveCounter reference into Star Rating at init, or should Star Rating get it from autoload / node path? Injected reference is cleanest for testability.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Low             | Provisional: Level Coordinator injects at `initialize_level()` call. Revisit during Level Coordinator implementation.                                                      |
| OQ-2 | **Post-jam**: Undo count should penalise stars — a player who undoes many times and then hits the minimum move count should not receive 3 stars as easily as one who played cleanly. Design options: **(a) effective-move penalty** — each undo increments an internal counter; effective_moves = final_moves + (undo_count × PENALTY_PER_UNDO); thresholds evaluated against effective_moves. **(b) star cap** — any undo usage caps the maximum achievable stars at 2 (never 3). **(c) threshold tightening** — LevelData gains extra `star_3_moves_no_undo` and `star_3_moves_with_undo` fields, set by BFS tooling. Requires `UndoRestart.undo_count()` to feed into Star Rating at computation time. The current formula and API (`rating_computed` signature, `initialize_level` signature) are MVP-locked; this change will require a breaking formula update. | High (Post-jam) | Design before first post-jam release. Recommended option: **(a)** with a small penalty (e.g. PENALTY_PER_UNDO = 0 at MVP; set to 1 post-jam). Avoids new LevelData fields. |
