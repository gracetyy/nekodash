# Undo / Restart

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Pillar 3 — Complete Your Own Way / Pillar 1 — Every Move Is a Choice

## Overview

The Undo / Restart system owns a history stack of move snapshots and applies them
to reverse or fully reset game state. It is the coordinator that writes to all
other per-level stateful systems (Sliding Movement, Coverage Tracking, Move Counter)
in a controlled sequence. It has no state of its own beyond the history stack and
a reference to the active `LevelData`.

**Undo** pops the top snapshot off the stack and applies it — restoring cat position,
coverage map, and move count to their state immediately before that move. One undo
= one move reversed. The history stack has an unlimited depth at MVP (levels are
short; memory cost is negligible).

**Restart** discards the entire history stack and re-initializes the level from
its initial state — equivalent to loading the level fresh, but without a scene
reload. Cat snaps to spawn, coverage resets, move count resets to zero.

Neither Undo nor Restart incurs a move count penalty. There is no cost to
experimenting.

## Player Fantasy

"Wait — I saw a better path two moves ago. Let me just undo that."

The undo button is the puzzle's safety net. It transforms "I made a mistake, I have
to restart everything" into "I made a mistake, I can fix it." That shift from full
reset to surgical correction is the difference between a punishing game and a
welcoming one. A player who knows they can undo freely will take bolder experimental
swipes. Exploration and experimentation are core to great puzzle play.

Restart is the "clear the board" option — same intent as starting over, but instant.
No loading screen, no animation, just: snap back to the beginning and think again.

Both serve **Pillar 3 — Complete Your Own Way**: the player controls the pace and
direction of their own puzzle-solving without fear of permanent mistakes.
Both serve **Pillar 1 — Every Move Is a Choice**: undo removes the memory burden of
"I can never take that back", making every choice deliberate rather than anxious.

## Detailed Design

### The Move Snapshot

Every move is recorded as a `MoveSnapshot`:

```gdscript
class MoveSnapshot:
    var cat_pos_before: Vector2i       # cat position before the slide
    var coverage_before: Dictionary    # deep copy from get_coverage_snapshot()
    var move_count_before: int         # current_moves before the slide
```

A snapshot captures the complete pre-move state of all three stateful components.
It is taken **before** the Level Coordinator applies the rest of the move pipeline —
at the moment the coordinator receives the completed slide and before coverage or move
count state is mutated.

### Core Rules

1. **Snapshot on coordinator dispatch**: Undo/Restart records a `MoveSnapshot` when the
   Level Coordinator calls `record_snapshot(...)` as the first step of
   `process_move(from_pos, to_pos, direction, tiles_covered)`. The snapshot captures the
   state **before** the slide that just completed: `cat_pos_before = from_pos`,
   `coverage_before = get_coverage_snapshot()`, `move_count_before = MoveCounter.current_moves`.

   > **Pipeline note**: the snapshot is no longer dependent on subscriber ordering.
   > The coordinator calls the move systems explicitly, so the pre-mutation state is
   > captured before Move Counter or Coverage Tracking can mutate their values.

2. **Undo**: `undo() -> void` is the single public method for undoing one move.
   - If `_history` is empty, logs a warning and returns (no-op).
   - Pops the top `MoveSnapshot` from `_history`.
   - Applies in this exact order:
     1. `SlidingMovement.set_grid_position_instant(snapshot.cat_pos_before)` — kills any tween, snaps cat.
     2. `CoverageTracking.restore_coverage_snapshot(snapshot.coverage_before)` — restores tile coverage state.
     3. `MoveCounter.set_move_count(snapshot.move_count_before)` — rewinds move count.
   - Emits `undo_applied(moves_remaining_in_history: int)`.

3. **Restart**: `restart() -> void` reinitializes the level without a scene reload.
   - Clears `_history` completely.
   - Applies in this exact order:
     1. `SlidingMovement.set_grid_position_instant(_spawn_pos)` — kills any tween, snaps to spawn.
     2. `CoverageTracking.reset_coverage()` — clears all coverage.
     3. `MoveCounter.reset_move_count()` — resets counter to 0.
     4. `SlidingMovement.initialize_level(_spawn_pos)` — re-emits `spawn_position_set` so Coverage Tracking pre-covers the starting tile.
   - Emits `level_restarted`.

   > **Order matters**: `set_grid_position_instant()` before `initialize_level()`
   > because `initialize_level()` re-emits`spawn_position_set` which Coverage
   > Tracking handles. `reset_coverage()` before `initialize_level()` so the
   > starting tile is freshly pre-covered, not added to stale state.

4. **Level initialization**: At level load, `initialize(level_data: LevelData, spawn_pos: Vector2i)` stores `_spawn_pos` and `_level_data`, clears `_history`.

5. **No undo through level completion**: Once `level_completed` fires (Coverage
   Tracking), the history stack is frozen — `undo()` becomes a no-op. The player
   is on the level-complete overlay at this point anyway; the HUD undo control should
   be disabled or hidden. This prevents rewinding past completion into a broken Coverage state.

6. **History depth**: Unlimited at MVP. A 20-move level produces 20 snapshots, each
   holding a `Dictionary` copy of coverage (~20–50 tiles) plus two ints. Total
   memory per snapshot ≈ a few hundred bytes. 20 moves × 500 bytes = ~10 KB.
   Negligible.

7. **Undo available on first move**: After one completed move, the stack has one
   entry and `undo()` is valid. Before the first slide, the stack is empty and
   `undo()` is a no-op (no moves to undo). The HUD undo button should be disabled
   when `_history.is_empty()`.

8. **`can_undo() -> bool`**: Returns `not _history.is_empty()`. Used by HUD to
   enable/disable the undo button without exposing the stack itself.

9. **`undo_count() -> int`**: Returns `_history.size()`. Useful for HUD or
   debug display showing how many undos are available.

### Coordinator-Owned Move Pipeline

The Level Coordinator now owns move processing directly. It is the only consumer of
move completion, and it invokes the three stateful systems in a fixed order:

1. `record_snapshot(...)`
2. `MoveCounter.increment(...)`
3. `CoverageTracking.apply_tiles_covered(...)`

Undo/Restart still has a compatibility `on_slide_completed(...)` adapter for legacy wiring,
but the documented contract is the coordinator-owned pipeline above.

### States and Transitions

| State             | Entry Condition                                   | Exit Condition                                       | Behavior                                                                                                  |
| ----------------- | ------------------------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Uninitialized** | Scene loaded; `initialize()` not yet called       | `initialize()` called                                | `undo()` and `restart()` are no-ops with warnings                                                         |
| **Active**        | `initialize()` called; level in progress          | `level_completed` fires; `initialize()` called again | Normal operation; records history; undo and restart work                                                  |
| **Frozen**        | `level_completed` received from Coverage Tracking | `initialize()` called (next level / retry)           | `_history` cleared; `undo()` is no-op; `restart()` still allowed (same as calling `initialize()` + reset) |

### Interactions with Other Systems

| System                | Direction                        | Interface                                                                                                                                            |
| --------------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sliding Movement**  | Bidirectional                    | Subscribes to `slide_completed` (snapshot); calls `set_grid_position_instant(coord)` (undo position); calls `initialize_level(spawn_pos)` (restart). |
| **Coverage Tracking** | Bidirectional                    | Calls `get_coverage_snapshot()` at snapshot time; calls `restore_coverage_snapshot(snapshot)` on undo; calls `reset_coverage()` on restart.          |
| **Move Counter**      | Undo/Restart → Move Counter      | Calls `set_move_count(n)` on undo; calls `reset_move_count()` on restart.                                                                            |
| **Coverage Tracking** | Coverage Tracking → Undo/Restart | Subscribes to `level_completed`; on receipt, freezes the history stack.                                                                              |
| **HUD**               | Undo/Restart → HUD               | Emits `undo_applied` and `level_restarted`; HUD subscribes to update undo button enabled state. HUD reads `can_undo()`.                              |
| **Level Coordinator** | Level Coordinator → Undo/Restart | Calls `initialize()` at level load; calls `record_snapshot()` as the first step in `process_move(...)`.                                              |

## Signals

| Signal                                | Payload              | Description                                                                   |
| ------------------------------------- | -------------------- | ----------------------------------------------------------------------------- |
| `undo_applied(moves_in_history: int)` | remaining undo depth | Fired after a successful undo. HUD updates button enabled state.              |
| `level_restarted`                     | —                    | Fired after restart completes. HUD and other systems can reset their display. |

## Formulas

### Snapshot Memory Estimate

$$
\text{snapshot\_bytes} \approx (\text{covered\_tiles} \times 20) + 16
$$

Where:

- `covered_tiles` = tiles in the coverage snapshot dictionary (grows per move, max = total walkable tiles)
- `20` bytes ≈ per `Vector2i` key + `bool` value in a GDScript Dictionary
- `16` bytes for two `int` fields

For a 15-tile level at move 10, snapshot ≈ (10 × 20) + 16 = 216 bytes. Total for 20 snapshots ≈ ~4 KB. Negligible.

### Undo Stack Depth

Unlimited at MVP. Post-jam cap if memory profiling shows concern:

$$
\text{max\_history} = \text{level\_move\_count} \times 3
$$

_Not implemented at MVP — noted only for post-jam reference._

## Edge Cases

| Scenario                                                                              | Expected Behavior                                                                                                                                                                                               | Rationale                                                                       |
| ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `undo()` called with empty history                                                    | No-op; warning logged. HUD button should be disabled at this point.                                                                                                                                             | Guard for unexpected calls; HUD `can_undo()` check prevents this normally       |
| `undo()` called during `SLIDING` state (tween in flight)                              | `set_grid_position_instant()` kills the tween; undo completes normally. The in-flight move dispatch is cancelled by the coordinator.                                                                            | Tween kill is Sliding Movement's responsibility; undo coordinates safely        |
| `restart()` called during `SLIDING` state                                             | Same as undo mid-slide: `set_grid_position_instant()` kills tween; history cleared; state reset proceeds.                                                                                                       | Restart always works regardless of animation state                              |
| `level_completed` fires, then player taps undo button                                 | `undo()` is a no-op (Frozen state); HUD control should already be disabled or hidden after `level_completed`.                                                                                                   | Prevents broken state: coverage at 100% should not be partially unwound         |
| Coordinator calls `increment()` or `apply_tiles_covered()` before `record_snapshot()` | Snapshot captures post-mutation coverage state; undo would restore incorrect coverage.                                                                                                                          | **This is a critical bug.** The coordinator-owned pipeline must preserve order. |
| `restart()` called immediately after `initialize()` (zero moves)                      | History empty; `set_grid_position_instant` snaps to spawn (no-op since already there); `reset_coverage()` a no-op; `initialize_level()` re-emits `spawn_position_set`. Valid operation.                         | Idempotent restart from zero-move state                                         |
| Very large level with many unique tiles in history snapshots                          | Snapshots grow; at MVP no cap. If memory is a concern post-jam, implement LRU or fixed-depth stack.                                                                                                             | Flagged for post-jam monitoring, not an MVP action                              |
| Two rapid undo button taps before first undo completes                                | Second call hits `_history` in partially-modified state? No — undo operations are synchronous (no tweens, all instant writes). Second call sees reduced stack and applies it cleanly, or hits empty and no-ops. | GDScript signal handlers are synchronous; no async concern                      |

## Dependencies

| System                | Direction                | Nature                                                                                        | Hard/Soft                                                                      |
| --------------------- | ------------------------ | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Sliding Movement**  | Bidirectional            | Subscribes to `slide_completed`; calls `set_grid_position_instant()` and `initialize_level()` | **Hard** — cannot record or apply history without this interface               |
| **Coverage Tracking** | Bidirectional            | Reads snapshot API and calls restore; calls `reset_coverage()`                                | **Hard** — undo without coverage rollback leaves the board in wrong state      |
| **Move Counter**      | Undo/Restart → Write     | Calls `set_move_count()` and `reset_move_count()`                                             | **Hard** — undo without move count rollback misleads the HUD                   |
| **Level Coordinator** | Level Coordinator → Undo | Calls `initialize()`; controls the coordinator-owned move pipeline                            | **Hard** — Undo/Restart is useless without initialization and correct ordering |

## Tuning Knobs

No runtime tuning knobs at MVP. History is unlimited.

| Future knob              | Description                                                                      |
| ------------------------ | -------------------------------------------------------------------------------- |
| `max_history_depth: int` | Cap on undo stack depth; `0` = unlimited. Post-jam option if memory is a concern |

## Visual/Audio Requirements

| Event              | Owner               | Description                                                                                                                                                                 | Priority   |
| ------------------ | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| Undo button tap    | HUD                 | Button press animation; enabled/disabled state driven by `can_undo()`                                                                                                       | MVP-Polish |
| Undo visual        | Coverage Visualizer | On `undo_applied`, previously-covered tiles revert to uncovered appearance; driven by `restore_coverage_snapshot()` re-triggering Coverage Tracking's `tile_covered` signal | MVP-Polish |
| Restart button tap | HUD                 | Button press animation; always enabled                                                                                                                                      | MVP-Polish |
| Undo SFX           | SFX Manager         | Subscribes to `undo_applied`; plays a soft "reverse" click                                                                                                                  | MVP-Polish |
| Restart SFX        | SFX Manager         | Subscribes to `level_restarted`; plays a short reset chime                                                                                                                  | MVP-Polish |

> **Coverage Visualizer note**: After `restore_coverage_snapshot()`, Coverage Tracking
> should emit signals for all tiles that changed state (newly uncovered) so the
> visualizer can update. The current Coverage Tracking GDD emits `coverage_updated`
> after `restore_coverage_snapshot()`. The Coverage Visualizer must handle both
> tile-covered and tile-uncovered visual states. This is flagged as a dependency
> on the Coverage Tracking implementation details — confirm in implementation.

## UI Requirements

Undo/Restart exposes two pieces of information to the HUD:

- `can_undo() -> bool` — drives undo button enabled/disabled state
- `undo_count() -> int` — optional; can display remaining undo depth

The HUD owns all button layout and visual feedback. Undo/Restart emits signals
that the HUD subscribes to; it does not call HUD methods directly.

**Undo button**: always visible in the gameplay HUD; disabled (greyed out) when
`can_undo()` returns `false`.

**Restart button**: always visible and always enabled in the gameplay HUD.

## Acceptance Criteria

| #     | Criterion                                                                                                                                                                  |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| UR-1  | After one completed move, `_history.size() == 1` and `can_undo() == true`.                                                                                                 |
| UR-2  | After `undo()`, cat position equals `from_pos` of the last slide; coverage is as it was before that slide; move count is decremented by 1.                                 |
| UR-3  | After `undo()`, `_history.size()` decreases by 1; `undo_applied` is emitted with the new history size.                                                                     |
| UR-4  | `undo()` with empty history is a no-op with a warning log; no state changes occur.                                                                                         |
| UR-5  | After `restart()`, cat is at spawn position; coverage map matches post–`spawn_position_set` state (only starting tile covered); `current_moves == 0`; `_history` is empty. |
| UR-6  | `restart()` during a `SLIDING` animation kills the tween and completes the restart correctly.                                                                              |
| UR-7  | After `level_completed`, `undo()` is a no-op. `restart()` still functions.                                                                                                 |
| UR-8  | The snapshot taken by Undo/Restart captures coverage state **before** Coverage Tracking processes the same completed move.                                                 |
| UR-9  | `level_restarted` signal is emitted exactly once per `restart()` call.                                                                                                     |
| UR-10 | Three sequential undos after three moves return the board to its initial state, equivalent to `restart()` from that position.                                              |

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Priority | Owner                                           | Resolution                                             |
| ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------------------------------------- | ------------------------------------------------------ |
| OQ-1 | Coverage Tracking's `restore_coverage_snapshot()` currently only emits `coverage_updated(covered, total)` per the Coverage Tracking GDD. Should it also emit per-tile `tile_uncovered` signals for tiles that became uncovered during the restore? The Coverage Visualizer needs per-tile feedback to correctly revert visuals. Provisional: add `tile_uncovered(coord: Vector2i)` signal to Coverage Tracking for the undo path. Flag this as an amendment to the Coverage Tracking GDD. | High     | Resolve before implementing Coverage Visualizer | Provisional: add `tile_uncovered` to Coverage Tracking |
| OQ-2 | Should there be a visible "undo count" indicator in the HUD (e.g., "↩ 3")? Provisional: no at MVP — `can_undo()` is enough for the button state; the count adds visual noise.                                                                                                                                                                                                                                                                                                             | Low      | Resolve during HUD GDD                          | Provisional: no count display                          |
| OQ-3 | Should the Level Coordinator own the explicit move pipeline or continue to rely on direct move-completion subscribers? Resolution: the Level Coordinator owns the explicit pipeline (`record_snapshot` → `increment` → `apply_tiles_covered`), so the ordering dependency is removed.                                                                                                                                                                                                     | Low      | Resolved                                        | Explicit coordinator-owned pipeline                    |
