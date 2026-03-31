# Milestone 1: Core Loop Playable

**Target Date**: 2026-04-07
**Status**: In Progress (Sprint 1)

## Description

A real level can be played end-to-end on device: cat slides over a `.tres`-loaded
grid, coverage is tracked, and the move counter increments and displays. The game
loop from "open level" → "slide around" → "100% coverage" functions correctly.
No UI polish, no audio, no skins required.

## Exit Criteria

- [ ] GridSystem autoload operational — `is_walkable()`, `grid_to_pixel()` APIs live
- [ ] InputSystem autoload operational — `slide_requested(direction)` signal fires reliably on swipe and keyboard
- [ ] SaveManager and SceneManager autoload stubs exist and are callable
- [ ] At least 3 levels authored as `.tres` LevelData resources with `minimum_moves` set
- [ ] SlidingMovement production node slides cat correctly on a LevelData-loaded grid
- [x] Mobile sliding feel validated — easing locked as **TRANS_QUAD**; speed locked as **desktop 15 t/s / mobile 25 t/s** (platform-adaptive)
- [ ] CoverageTracking system tracks visited tiles and fires `coverage_completed` signal
- [ ] MoveCounter increments on slides and resets on `level_restarted` signal

## Systems Delivered by This Milestone

| System                       | Status             |
| ---------------------------- | ------------------ |
| GridSystem                   | Planned (Sprint 1) |
| InputSystem                  | Planned (Sprint 1) |
| SaveManager (stub)           | Planned (Sprint 1) |
| SceneManager (stub)          | Planned (Sprint 1) |
| LevelDataFormat              | Planned (Sprint 1) |
| SlidingMovement (production) | Planned (Sprint 1) |
| CoverageTracking             | Planned (Sprint 1) |
| MoveCounter                  | Planned (Sprint 1) |

## Not In Scope

- HUD, audio, skins, undo/restart, star rating, UI screens
- BFS Solver (nice-to-have for Sprint 1; required for M2 level authoring)
- Obstacle variants beyond static walls

## Suggested Next Steps

### Immediately (Sprint 1, this week)

| What to do                                                                     | Why                                               |
| ------------------------------------------------------------------------------ | ------------------------------------------------- |
| `Implement S1-01: GridSystem autoload`                                         | First dependency — everything else blocks on this |
| `Implement S1-02: InputSystem autoload`                                        | Can be done in parallel with GridSystem           |
| After those two: `Implement S1-03: SaveManager and SceneManager stubs`         | Fast (stubs only), unblocks scene loading         |
| `Implement S1-04: LevelDataFormat and author 3 tutorial levels as .tres files` | Needs GridSystem done first                       |
| `Implement S1-05: SlidingMovement production node`                             | Needs all of the above                            |

### After Sprint 1 Must-Haves are done

| What to do                                               | Why                                           |
| -------------------------------------------------------- | --------------------------------------------- |
| `/sprint-plan status`                                    | Get a live Sprint 1 status report             |
| `Implement S1-07 CoverageTracking and S1-08 MoveCounter` | Should Have — completes the core loop         |
| `Implement S1-09: BFS Minimum Solver offline tool`       | Nice to Have — unblocks authoring more levels |

### Sprint 2 onwards

| What to do                          | Why                                                                |
| ----------------------------------- | ------------------------------------------------------------------ |
| `/sprint-plan new`                  | Generate Sprint 2 plan (Undo/Restart, HUD, LevelCompleteScreen)    |
| `Implement the Undo/Restart system` | Next gameplay system after core loop is working                    |
| `Implement the HUD`                 | Needs MoveCounter + Undo/Restart                                   |
| `/gate-check M1`                    | Formal check that M1 exit criteria are all met before moving to M2 |
