# Sliding Movement

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Pillar 1 — Every Move Is a Choice; Pillar 2 — Joyful at Every Moment

## Overview

The Sliding Movement system is the core verb of NekoDash. When the player swipes (or presses a key), the cat launches in the given cardinal direction and glides across the grid, tile by tile, until the next tile in that direction is a wall or grid boundary — then it stops. There are no partial stops on open tiles, no momentum adjustments, no analog movement. One swipe = one discrete slide from current position to the first obstacle. The system owns the cat's logical position (`cat_pos: Vector2i`), all slide resolution math, and the animation tween that brings the cat's visual position in sync with its logical position. It is the primary producer of game events: every valid slide emits signals consumed by Coverage Tracking (which tiles were covered), Move Counter (how many moves were spent), and Undo/Restart (snapshot before each move). It also owns the `is_accepting_input` flag that gates Input System output during animation. Without this system, there is no game.

## Player Fantasy

A slide should feel like a release. The player spots the route, swipes — and the cat launches. The cat doesn't shuffle or creep; it _goes_. It covers the ground with speed and purpose, then lands with a small, satisfying squish that says: "here." Then it's still, patient, waiting. The whole interaction is under 300ms for a short slide and under 700ms for a long one. Neither the waiting nor the moving should feel like friction.

This serves **Pillar 1 — Every Move Is a Choice**: the physics-free, grid-perfect slide makes every outcome legible and predictable. The player can see exactly where the cat will land before they swipe. There is no unexpected drift, no overshooting, no "why did it stop there?" **Pillar 2 — Joyful at Every Moment** is served by the animation: the slide easing, the landing squish, and the blocked "bump" animation all communicate personality and warmth, even when the move doesn't achieve what the player wanted. The cat isn't broken when it bumps a wall; it's expressive.

## Detailed Design

### Core Rules

1. **Input reception**: The Sliding Movement system connects to the `direction_input(direction: Vector2i)` signal emitted by the Input System. It is the sole consumer of this signal.

2. **Slide resolution** (algorithm):

   ```
   func resolve_slide(start: Vector2i, direction: Vector2i) -> Vector2i:
       pos = start
       while grid.is_walkable(pos + direction):
           pos += direction
       return pos
   ```

   The loop continues until the _next_ tile in `direction` is BLOCKING or out-of-bounds. Out-of-bounds always returns BLOCKING per Grid System convention — no explicit bounds guard needed. A `MAX_SLIDE_DISTANCE` constant (value: 20) is checked each iteration and triggers an error log if exceeded; this guards against malformed level data, not normal gameplay.

3. **Blocked slide** (landing == start): If `resolve_slide()` returns the same position the cat is already at, the slide is rejected:
   - Emit `slide_blocked(cat_pos, direction)`
   - Play the bump animation (brief nudge toward the wall, then return)
   - Do **not** change `cat_pos`, do **not** change `is_accepting_input`, do **not** increment move count.
   - The system remains in `IDLE` state throughout.

4. **Valid slide** (landing ≠ start):
   - Compute `tiles_covered` — all `Vector2i` positions from `cat_pos + direction` to `landing` inclusive, walked one step at a time in `direction`
   - Set `is_accepting_input = false`
   - Transition to `SLIDING` state
   - Emit `slide_started(cat_pos, landing, direction)`
   - Update `cat_pos = landing`
   - Start tween animation from old pixel position to new pixel position
   - When tween completes: emit `slide_completed(old_pos, landing, direction, tiles_covered)`, reset `is_accepting_input = true`, transition to `IDLE` state

5. **Move counting ownership**: Sliding Movement does **not** own the move count integer. It emits `slide_completed` and Move Counter increments its own counter. One `slide_completed` emission = one move. Blocked slides never emit `slide_completed`.

6. **State machine**: Three states — `IDLE`, `SLIDING`, `LOCKED`. In `IDLE`, valid direction input triggers a slide. In `SLIDING`, all input is ignored (Input System also blocks it). In `LOCKED`, all input is ignored. Only Scene Manager can enter/exit `LOCKED` state.

7. **`is_accepting_input` ownership**: This bool is declared on the Sliding Movement node. Input System reads it as a gate. Sliding Movement is the only system that writes it. It is `true` in `IDLE`, `false` in `SLIDING`, determined by Scene Manager in `LOCKED` (reset to `true` when transitioning back to `IDLE`).

8. **Level initialization**: When a level loads, the calling system (Level Manager or equivalent coordinator) calls `initialize_level(spawn_pos: Vector2i)`. This snaps `cat_pos` to `spawn_pos`, sets pixel position instantly, transitions to `IDLE`, and emits `spawn_position_set(spawn_pos)` — a signal Coverage Tracking uses to mark the starting tile as pre-covered (matching the BFS Solver's initial state convention).

9. **Undo/Restart interface**: For Undo/Restart to rewind the cat's position, it calls `set_grid_position_instant(coord: Vector2i)`. This kills any in-flight tween, snaps `cat_pos` to `coord`, sets pixel position instantly, resets `is_accepting_input = true`, and transitions to `IDLE`. No signals are emitted (Undo/Restart owns the state rollback coordination).

10. **No direct dependency on Coverage Tracking or Move Counter**: Sliding Movement knows nothing about these systems. They observe it via signals.

### States and Transitions

| State       | Entry Condition                                                       | Exit Condition                                                | Behavior                                                                                         |
| ----------- | --------------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **IDLE**    | Level initialized; tween complete; `set_grid_position_instant()` call | Valid direction input received; Scene Manager sends LOCKED    | Accepts direction input; blocked input emits `slide_blocked`; valid input starts slide           |
| **SLIDING** | Valid direction input (landing ≠ current pos)                         | Tween animation completes; `set_grid_position_instant()` call | Input ignored; tween running; `is_accepting_input = false`; `slide_completed` on tween finish    |
| **LOCKED**  | Scene Manager sends non-PLAYING state signal                          | Scene Manager sends PLAYING state signal                      | All input ignored; `is_accepting_input` set per Scene Manager; used during menus, level complete |

```
IDLE ──[valid input]──► SLIDING ──[tween complete]──► IDLE
IDLE ──[blocked input]──► IDLE  (no state change; emits slide_blocked)
IDLE ──[Scene Manager: LOCKED]──► LOCKED
LOCKED ──[Scene Manager: PLAYING]──► IDLE
SLIDING ──[set_grid_position_instant()]──► IDLE  (restart mid-slide)
```

### Interactions with Other Systems

| System                | Direction                            | Interface                                                                                                                                                                                           |
| --------------------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Input System**      | Input System → Sliding Movement      | Subscribes to `direction_input(direction: Vector2i)` signal. Sliding Movement sets `is_accepting_input: bool` which Input System reads to gate emission.                                            |
| **Grid System**       | Sliding Movement → Grid System       | Calls `grid.is_walkable(coord: Vector2i) -> bool` during slide resolution. Also reads `GridSystem.DEFAULT_TILE_SIZE_PX` to compute pixel positions.                                                 |
| **Level Data Format** | Level Data Format → Sliding Movement | At level load, `LevelData.cat_start` is passed to `initialize_level(spawn_pos)`. Sliding Movement does not hold a reference to `LevelData` after initialization.                                    |
| **Scene Manager**     | Scene Manager → Sliding Movement     | Sends state change notifications (PLAYING → non-PLAYING); Sliding Movement enters/exits `LOCKED` state accordingly.                                                                                 |
| **Coverage Tracking** | Sliding Movement → Coverage Tracking | Coverage Tracking subscribes to `spawn_position_set(pos)` (pre-covers starting tile) and `slide_completed(from, to, dir, tiles_covered)` (marks all traversed tiles covered).                       |
| **Move Counter**      | Sliding Movement → Move Counter      | Move Counter subscribes to `slide_completed` and increments its counter once per emission.                                                                                                          |
| **Undo/Restart**      | Bidirectional                        | Undo/Restart subscribes to `slide_completed` to record move history. Undo/Restart calls `set_grid_position_instant(coord)` to rewind cat position; also calls `initialize_level()` on full restart. |

## Formulas

### Slide Resolution

```
func resolve_slide(start: Vector2i, direction: Vector2i) -> Vector2i:
    pos = start
    iterations = 0
    while grid.is_walkable(pos + direction) and iterations < MAX_SLIDE_DISTANCE:
        pos += direction
        iterations += 1
    if iterations >= MAX_SLIDE_DISTANCE:
        push_error("Slide exceeded MAX_SLIDE_DISTANCE — possible malformed level")
    return pos
```

| Variable             | Type       | Range / Value                        | Description                                                       |
| -------------------- | ---------- | ------------------------------------ | ----------------------------------------------------------------- |
| `start`              | `Vector2i` | Any valid grid coord                 | Cat's current position before the slide                           |
| `direction`          | `Vector2i` | `(0,-1)`, `(0,1)`, `(-1,0)`, `(1,0)` | Cardinal direction from `direction_input` signal                  |
| `pos`                | `Vector2i` | From `start` to landing              | Current candidate landing position; advances each iteration       |
| `MAX_SLIDE_DISTANCE` | `int`      | 20 (const)                           | Safety guard for malformed grids; higher than any realistic level |
| return value         | `Vector2i` | Grid coord                           | Landing tile; equals `start` if immediately blocked               |

### Tiles Covered Computation

```
func compute_tiles_covered(start: Vector2i, landing: Vector2i, direction: Vector2i) -> Array[Vector2i]:
    tiles = []
    step = start + direction
    while step != landing + direction:    # inclusive of landing
        tiles.append(step)
        step += direction
    return tiles
```

This matches the BFS Solver's coverage mask update exactly — all tiles from `(start + direction)` to `landing` inclusive. The starting tile (`start`) is excluded; it was covered on the previous move (or at level initialization).

| Variable    | Type              | Description                                          |
| ----------- | ----------------- | ---------------------------------------------------- |
| `start`     | `Vector2i`        | Cat position before slide (old `cat_pos`)            |
| `landing`   | `Vector2i`        | Cat position after slide (return of `resolve_slide`) |
| `direction` | `Vector2i`        | Slide direction                                      |
| return      | `Array[Vector2i]` | All tiles the cat passed over, including landing     |

### Pixel Position from Grid Coordinate

```
func grid_to_pixel(coord: Vector2i) -> Vector2:
    return Vector2(coord) * TILE_SIZE + Vector2.ONE * (TILE_SIZE * 0.5)
```

| Variable    | Type       | Value / Source                         | Description                            |
| ----------- | ---------- | -------------------------------------- | -------------------------------------- |
| `coord`     | `Vector2i` | Any grid coordinate                    | Logical grid position to convert       |
| `TILE_SIZE` | `float`    | `GridSystem.DEFAULT_TILE_SIZE_PX` = 64 | Tile size in pixels                    |
| return      | `Vector2`  | Pixel position                         | Center of the tile in local node space |

_Note: This formula assumes the CatController node is a child of (or at the same origin as) the TileMapLayer grid node. If the cat node is at a different scene level, add `grid_node.global_position` offset._

### Slide Animation Duration

```
func compute_slide_duration(tile_count: int) -> float:
    return max(MIN_SLIDE_DURATION_SEC, tile_count / SLIDE_VELOCITY_TILES_PER_SEC)
```

| Variable                       | Type    | Default / Source                                          | Description                                           |
| ------------------------------ | ------- | --------------------------------------------------------- | ----------------------------------------------------- |
| `tile_count`                   | `int`   | `max(abs(landing.x - start.x), abs(landing.y - start.y))` | Number of tiles traversed in one axis                 |
| `SLIDE_VELOCITY_TILES_PER_SEC` | `float` | 15.0 (tuning knob)                                        | Visual speed of the slide in tiles per second         |
| `MIN_SLIDE_DURATION_SEC`       | `float` | 0.10 (tuning knob)                                        | Minimum animation time regardless of tile count       |
| return                         | `float` | Duration in seconds                                       | e.g.: 1-tile → 0.10s, 5-tile → 0.33s, 10-tile → 0.67s |

_This constant-velocity formula ensures consistent perceived speed regardless of slide distance. A 10-tile slide looks and feels proportionally longer than a 2-tile slide._

## Edge Cases

| Scenario                                                                            | Expected Behavior                                                                                                                          | Rationale                                                                                                                          |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| Cat attempts slide into wall immediately adjacent (`landing == start`)              | `slide_blocked` emitted; bump animation plays; no state change; no move count                                                              | Distinct from valid slide; player should see clear feedback that no move occurred                                                  |
| Cat at grid edge, slides toward that edge                                           | `is_walkable(out-of-bounds)` returns false; cat stays at edge; treated as `landing == start` → emit `slide_blocked`                        | Out-of-bounds = BLOCKING per Grid System; edge is indistinguishable from a wall tile                                               |
| Input arrives while in `SLIDING` state                                              | Ignored silently (Input System already gates this via `is_accepting_input`; state machine double-checks)                                   | Double guard: Input System + state machine prevents ghost moves                                                                    |
| Restart called mid-slide (`set_grid_position_instant()` during SLIDING)             | `_slide_tween.kill()` terminates animation; no `slide_completed` emitted; cat snaps to requested position                                  | In-flight tween must be killed before `finished` signal fires; otherwise stale state transition occurs                             |
| Level load called while in `SLIDING` state                                          | Same as restart mid-slide; `initialize_level()` kills tween, resets to `IDLE`                                                              | Consistent initialization path regardless of prior state                                                                           |
| Two `direction_input` signals in same frame (theoretical)                           | Second signal arrives while state = `SLIDING`; `is_accepting_input = false`; silently discarded                                            | Cannot happen in normal operation; `SLIDING` is set synchronously before tween starts                                              |
| `tiles_covered` computed but `grid.is_walkable()` returns false for a step mid-path | Should never occur — slide stops at first non-walkable tile; only walkable tiles exist between `start` and `landing`                       | If this fires, the grid has inconsistent state; log an error                                                                       |
| Level only has 1 walkable tile                                                      | Cat initialized at that tile; all 4 directions are `slide_blocked`; level is technically complete at start                                 | Degenerate level; `minimum_moves = 0` (BFS solver handles this); Level Design guidelines forbid shipping it                        |
| `spawn_position_set` emitted but Coverage Tracking not yet connected                | Coverage Tracking subscribes in `_ready()`; if `initialize_level()` is called before Coverage Tracking's `_ready()` runs, signal is missed | Node initialization order: ensure Level Manager calls `initialize_level()` after all child nodes are ready; or use `call_deferred` |
| Blocked animation interrupted by valid input while bump tween plays                 | Bump animation killed; valid slide tween starts; state = `SLIDING`                                                                         | Bump animation does not set `is_accepting_input = false` — it's cosmetic only; input can interrupt it                              |

## Dependencies

| System                | Direction                            | Nature                                                                                                                                     | Hard/Soft                                                                                                     |
| --------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| **Grid System**       | Sliding Movement → Grid              | Calls `is_walkable(coord)` in slide resolution loop; reads `DEFAULT_TILE_SIZE_PX` for pixel position calculation                           | **Hard** — cannot resolve slide without grid data                                                             |
| **Input System**      | Input System → Sliding Movement      | Consumes `direction_input` signal; owns `is_accepting_input` flag that Input System reads                                                  | **Hard** — no movement without input; no input gating without this flag                                       |
| **Level Data Format** | Level Data Format → Sliding Movement | Reads `cat_start: Vector2i` from `LevelData` at level initialization; no ongoing dependency                                                | **Hard** — needs a valid spawn position at load                                                               |
| **Scene Manager**     | Scene Manager → Sliding Movement     | Receives state change signals to enter/exit `LOCKED`; without this, input fires during menus and level-complete screens                    | **Hard** — needed for correct state gating                                                                    |
| **Coverage Tracking** | Sliding Movement → Coverage Tracking | Downstream subscriber of `slide_completed(tiles_covered)` and `spawn_position_set`; Sliding Movement has no reference to Coverage Tracking | **Soft** — Sliding Movement emits signals regardless; Coverage Tracking subscribing is optional at this layer |
| **Move Counter**      | Sliding Movement → Move Counter      | Downstream subscriber of `slide_completed`; Sliding Movement has no reference to Move Counter                                              | **Soft** — same pattern as Coverage Tracking                                                                  |
| **Undo/Restart**      | Bidirectional                        | Downstream subscriber of `slide_completed`; calls `set_grid_position_instant()` to rewind position                                         | **Soft** (downstream) / **Hard** (position rewind API must exist for Undo to function)                        |

## Tuning Knobs

| Parameter                      | Current Value | Safe Range           | `@export` | Effect of Increase                                                            | Effect of Decrease                                                             |
| ------------------------------ | ------------- | -------------------- | --------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `SLIDE_VELOCITY_TILES_PER_SEC` | 15.0          | 8.0 – 25.0           | Yes       | Faster slides; can feel snappy or frantic; reduce for accessibility           | Slower slides; more deliberate feel; can feel sluggish for fast puzzle-solvers |
| `MIN_SLIDE_DURATION_SEC`       | 0.10          | 0.05 – 0.20          | Yes       | Short slides linger longer; good for accessibility/legibility                 | Very short 1-tile slides can look like a pop rather than a movement            |
| `BLOCKED_BUMP_OFFSET_PX`       | 6.0           | 2.0 – 16.0           | Yes       | More dramatic bump toward wall; reads more clearly as "hit something"         | Subtle; may not read as a blocked attempt on small mobile screens              |
| `BLOCKED_BUMP_DURATION_SEC`    | 0.12          | 0.06 – 0.25          | Yes       | Longer bump animation; stalls input rhythm (input is NOT blocked during bump) | Faster feedback; less expressive                                               |
| `CAT_LAND_SQUISH_SCALE`        | (1.2, 0.85)   | (1.05–1.3, 0.7–0.95) | Yes       | More exaggerated landing squish; cartoony; polarizing                         | Subtle; may not register as a landing on small screens                         |
| `CAT_LAND_SQUISH_DURATION_SEC` | 0.08          | 0.04 – 0.15          | Yes       | Squish lingers; more cartoony                                                 | Fast snap back; snappier feel                                                  |
| `MAX_SLIDE_DISTANCE`           | 20            | 16 – 20              | No        | Higher guard; covers hypothetical grids > 15×15 if `MAX_GRID_SIZE` increases  | Should not go below `MAX_GRID_SIZE`; could truncate valid slides               |

_All `@export` parameters are exposed on the CatController node for editor tuning without code changes. `MAX_SLIDE_DISTANCE` is a const, not exported — it is a correctness guard, not a design parameter._

## Visual/Audio Requirements

| Event                           | Visual Feedback                                                                                                                                  | Audio Feedback                                    | Haptic (Mobile)     | Priority     |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- | ------------------- | ------------ |
| Slide start (valid move)        | Cat launches in direction with motion blur or stretch on the sprite (stretch: `(0.85, 1.15)` vertical → horizontal travel, inverted for up/down) | Brief high-pitched slide/whoosh SFX (rising tone) | Light tap vibration | Required     |
| Slide in motion (during tween)  | Smooth position tween from start to landing; optional motion trail (stretch goal)                                                                | None during motion                                | None                | Required     |
| Slide landing                   | Cat reaches landing tile; squish animation `(1.2, 0.85)` → `(1.0, 1.0)` over 0.08s then 0.12s                                                    | Soft "thud" or "pat" SFX (landing tone)           | Very light tap      | Required     |
| Blocked slide (slide into wall) | Cat nudges `BLOCKED_BUMP_OFFSET_PX` toward wall then springs back over `BLOCKED_BUMP_DURATION_SEC`; keeps position on current tile               | Soft "bonk" or "bumf" SFX (distinct from landing) | Short pulse         | Required     |
| Level start (spawn)             | Cat appears at `cat_start` with a small pop-in scale animation `(0)` → `(1.1, 1.1)` → `(1.0, 1.0)`                                               | Level start chime (owned by Level/Scene Manager)  | None                | Required     |
| Motion trail VFX                | Faint arc of paw-prints or color-tinted ghost of the cat fading along the slide path                                                             | None                                              | None                | Stretch goal |

_Visual stretch animation (horizontal travel → lean forward): apply directional squish based on `direction`. Left/right travel: `scale = Vector2(0.85, 1.15)` at slide start, then ease to `(1.0, 1.0)` at 20% through the tween using Tween.parallel(). Up/down travel: `scale = Vector2(1.15, 0.85)`. These can be added as a parallel tween track without restructuring the core animation._

_All SFX calls go through the SFX Manager autoload. Sliding Movement calls `SFX.play("slide_start")`, `SFX.play("slide_land")`, `SFX.play("slide_blocked")`. SFX Manager owns the audio bus assignment and volume._

## UI Requirements

The Sliding Movement system has no persistent UI of its own. The cat sprite is the primary UI artifact — it communicates state through animation.

- **Cat sprite**: Owned by this system; positioned and animated by the Tween chain. Art direction (sprite sheet, expressions, idle animation) is owned by the Art Director.
- **No on-screen velocity indicator, no ghost path preview**: These are post-MVP polish features. At MVP, the player sees only the cat's current position and the path it will take (inferrable from grid state alone — no UI preview needed per Pillar 1's legibility goal).
- **Input hint overlay** (first-launch only): Owned by the UI/Onboarding system. Input System handles dismissal on first valid `direction_input`. Sliding Movement is unaware of this overlay.

## Acceptance Criteria

| #     | Criterion                                                                                                                                                                                |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SM-1  | A valid swipe in any direction causes the cat to slide to the first BLOCKING tile in that direction, stopping at the last WALKABLE tile before it.                                       |
| SM-2  | `slide_completed` carries the correct `from_pos`, `to_pos`, `direction`, and `tiles_covered` for a known test level (hand-verified path).                                                |
| SM-3  | `tiles_covered` in `slide_completed` includes every tile from `(from_pos + direction)` to `to_pos` inclusive, and no others.                                                             |
| SM-4  | A swipe into an adjacent wall emits `slide_blocked` and does NOT emit `slide_started` or `slide_completed`; `cat_pos` is unchanged; move count is unchanged (verified via Move Counter). |
| SM-5  | `is_accepting_input` is `false` for the entire duration of the slide animation (from tween start to tween `finished`), then `true` immediately after.                                    |
| SM-6  | A swipe arriving while in `SLIDING` state is silently discarded; no ghost move occurs after the in-flight slide completes.                                                               |
| SM-7  | Calling `set_grid_position_instant(coord)` during a slide: kills animation, snaps cat visually to correct pixel position, resets `is_accepting_input = true`, state = `IDLE`.            |
| SM-8  | After `initialize_level(spawn_pos)`, `spawn_position_set(spawn_pos)` is emitted; `cat_pos == spawn_pos`; pixel position equals the tile center at `spawn_pos`.                           |
| SM-9  | Cat slide animation duration matches `max(MIN_SLIDE_DURATION_SEC, tile_count / SLIDE_VELOCITY_TILES_PER_SEC)` within a 10ms tolerance.                                                   |
| SM-10 | Cat is visually centered on the landing tile upon tween completion (pixel position = `grid_to_pixel(landing)`, within 1px tolerance).                                                    |
| SM-11 | Slide performance: `resolve_slide()` completes in ≤ 0.5ms on target mobile hardware (profiler measurement).                                                                              |
| SM-12 | Out-of-bounds slide: cat positioned at grid edge, swipes further toward that edge → treated as blocked (no movement, no move count, emits `slide_blocked`).                              |

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                                         | Priority | Owner                                       | Resolution                        |
| ---- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------- | --------------------------------- |
| OQ-1 | **RESOLVED** (from Input System OQ-1): Should a cancelled mid-swipe (finger reverses before release) use final delta or peak delta for direction? **Decision**: Final delta. Input System's validity check handles this — if the final gesture delta is below `MIN_SWIPE_DISTANCE_PX`, no signal is emitted.     | —        | —                                           | Final delta. Closed.              |
| OQ-2 | **RESOLVED** (from Input System OQ-3): Should holding a key while in `Blocked` state queue one move to fire on unblock? **Decision**: No. Silent discard. Keeps Sliding Movement stateless between slides; avoids ghost-move UX. Undo history is simpler without speculative buffering.                          | —        | —                                           | No queuing. Closed.               |
| OQ-3 | Should there be a single-input buffer for mobile (swipe during last ~100ms of animation plays after tween completes)? The gameplay programmer flagged this as a potential mobile UX improvement. Currently: silent discard. Revisit after first mobile playtesting session.                                      | Medium   | Gameplay Programmer + UX Designer           | Open — revisit at mobile playtest |
| OQ-4 | Should the blocked "bump" animation suppress input during its duration? Currently: bump is cosmetic; `is_accepting_input` stays `true`. If the bump is long enough (~0.12s) and a rapid swipe arrives, the cat can start sliding before the bump visual finishes. Likely fine; verify in playtest.               | Low      | Gameplay Programmer                         | Open — verify in playtest         |
| OQ-5 | Should `set_grid_position_instant()` optionally emit a `position_rewound(coord)` signal for Undo/Restart to use, or should Undo/Restart handle all state rollback coordination externally? Depends on Undo/Restart GDD design. **Provisional**: External coordination (no signal); revisit during Undo GDD.      | Medium   | Resolve during Undo/Restart GDD             | Provisional                       |
| OQ-6 | Cat node hierarchy: is `CatController` a child of the `TileMapLayer` grid node (favoring `grid_to_pixel` working without offset) or a sibling at scene level? Impacts `global_position` vs. `position` in the pixel formula. **Provisional**: Child of grid container; confirm during scene architecture sprint. | Medium   | Lead Programmer + Scene Architecture review | Provisional                       |
