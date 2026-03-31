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
- [ ] Mobile sliding feel validated — easing decision locked (TRANS_EXPO vs TRANS_QUAD)
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
