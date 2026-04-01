# Milestone 1: Core Loop Playable

**Target Date**: 2026-04-07
**Status**: ✅ Complete (delivered 2026-04-01, Day 1 of Sprint 1)

## Description

A real level can be played end-to-end on device: cat slides over a `.tres`-loaded
grid, coverage is tracked, and the move counter increments and displays. The game
loop from "open level" → "slide around" → "100% coverage" functions correctly.
No UI polish, no audio, no skins required.

## Exit Criteria

- [x] GridSystem autoload operational — `is_walkable()`, `grid_to_pixel()` APIs live
- [x] InputSystem autoload operational — `slide_requested(direction)` signal fires reliably on swipe and keyboard
- [x] SaveManager and SceneManager autoload stubs exist and are callable
- [x] At least 3 levels authored as `.tres` LevelData resources with `minimum_moves` set
- [x] SlidingMovement production node slides cat correctly on a LevelData-loaded grid
- [x] Mobile sliding feel validated — easing locked as **TRANS_QUAD**; speed locked as **desktop 15 t/s / mobile 25 t/s** (platform-adaptive)
- [x] CoverageTracking system tracks visited tiles and fires `coverage_completed` signal
- [x] MoveCounter increments on slides and resets on `level_restarted` signal

## Systems Delivered by This Milestone

| System                       | Status                                                        |
| ---------------------------- | ------------------------------------------------------------- |
| GridSystem                   | ✅ Done (Sprint 1) — 27 tests                                 |
| InputSystem                  | ✅ Done (Sprint 1) — 22 tests                                 |
| SaveManager (stub)           | ✅ Done (Sprint 1) — 24 tests                                 |
| SceneManager (stub)          | ✅ Done (Sprint 1) — 14 tests                                 |
| LevelDataFormat              | ✅ Done (Sprint 1) — 33 tests, 3 tutorial levels              |
| SlidingMovement (production) | ✅ Done (Sprint 1) — 40 tests, code-reviewed                  |
| CoverageTracking             | ✅ Done (Sprint 1) — 37 tests, code-reviewed                  |
| MoveCounter                  | ✅ Done (Sprint 1) — 27 tests, code-reviewed                  |
| BFS Minimum Solver           | ✅ Done (Sprint 1) — 19 tests, code-reviewed (NTH, delivered) |

## Not In Scope

- HUD, audio, skins, undo/restart, star rating, UI screens
- BFS Solver (nice-to-have for Sprint 1; required for M2 level authoring)
- Obstacle variants beyond static walls

## Suggested Next Steps

### Immediately (Sprint 1, this week) — remaining

| What to do                                                          | Why                               |
| ------------------------------------------------------------------- | --------------------------------- |
| ~~`Implement S1-01: GridSystem autoload`~~                          | ✅ Done                           |
| ~~`Implement S1-02: InputSystem autoload`~~                         | ✅ Done                           |
| ~~`Implement S1-03: SaveManager and SceneManager stubs`~~           | ✅ Done                           |
| ~~`Implement S1-04: LevelDataFormat and author 3 tutorial levels`~~ | ✅ Done                           |
| ~~`Implement S1-05: SlidingMovement production node`~~              | ✅ Done                           |
| ~~`Implement S1-07 CoverageTracking`~~                              | ✅ Done — 37 tests, code-reviewed |
| ~~`Implement S1-08 MoveCounter`~~                                   | ✅ Done — 27 tests, code-reviewed |

### After Sprint 1 Must-Haves are done

| What to do                                                   | Why                                               |
| ------------------------------------------------------------ | ------------------------------------------------- |
| ~~`/sprint-plan status`~~                                    | ✅ Done                                           |
| ~~`Implement S1-07 CoverageTracking and S1-08 MoveCounter`~~ | ✅ Done — core loop complete                      |
| `Implement S1-09: BFS Minimum Solver offline tool`           | ~~Nice to Have — unblocks authoring more levels~~ |

> ✅ **S1-09 delivered** — `tools/level_solver.gd`, 19 tests, code-reviewed.

### Sprint 2 onwards

| What to do                          | Why                                                                |
| ----------------------------------- | ------------------------------------------------------------------ |
| `/sprint-plan new`                  | Generate Sprint 2 plan (Undo/Restart, HUD, LevelCompleteScreen)    |
| `Implement the Undo/Restart system` | Next gameplay system after core loop is working                    |
| `Implement the HUD`                 | Needs MoveCounter + Undo/Restart                                   |
| `/gate-check M1`                    | Formal check that M1 exit criteria are all met before moving to M2 |

---

## ✅ M1 Complete

**Delivered**: 2026-04-01
**Tests**: 241 passing / 529 assertions
**Ready for**: `/gate-check M1` then `/sprint-plan new` (Sprint 2)
