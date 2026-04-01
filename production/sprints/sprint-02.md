# Sprint 2 — 2026-04-02 to 2026-04-08

**Status**: Planning

## Sprint Goal

Implement Undo/Restart, StarRatingSystem, LevelProgression, and HUD; wire them
into a production `gameplay.tscn` scene so the game can be played end-to-end
at production quality without the prototype. Deliver the Level Complete Screen
as the visual punctuation mark closing the core loop.

## Capacity

- Total days: 5 (Thu Apr 2 – Wed Apr 8)
- Buffer (20%): 1 day reserved for unplanned work / scene integration issues
- Available: 4 net days

---

## Tasks

### Must Have (Critical Path)

| ID    | Task                                                                                                                                                                                                                                                                                                                                                                                                    | Agent/Owner         | Est. Days | Dependencies               | Acceptance Criteria                                                                                                                                                                                                                                                                                                                                                                                  |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | --------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S2-01 | Implement `UndoRestart` node — `MoveSnapshot` inner class, unlimited history stack, `undo()` (restores cat pos + coverage + move count in spec order), `restart()` (snap + clear + re-initialize), `can_undo()`, `initialize()`, `undo_applied` + `level_restarted` signals; snapshot on `slide_completed` as **first** connection                                                                      | gameplay-programmer | 0.5       | S1-05, S1-07, S1-08        | `undo()` restores all three systems to pre-slide state in correct order; `undo()` on empty stack is a logged no-op; `restart()` snaps cat, clears coverage, resets counter, then re-initializes in spec order; `level_completed` freezes history (undo becomes no-op after); `can_undo()` returns false on empty stack; GUT tests cover all 7 design rules per GDD                                   |
| S2-02 | Implement `StarRatingSystem` node — threshold cache from `LevelData` at `initialize_level()`, locked formula (3→2→1→0), `rating_computed(stars: int, final_moves: int)` signal fires exactly once on `level_completed`                                                                                                                                                                                  | gameplay-programmer | 0.25      | S1-08, S1-04               | Correct star (0–3) for each threshold band; `minimum_moves == 0` levels fire `stars == -1`; `rating_computed` fires exactly once per attempt; signal is inert until next `initialize_level()`; GUT tests cover all 5 threshold cases plus sentinel                                                                                                                                                   |
| S2-03 | Implement `LevelProgression` node — explicit ordered `Array[LevelData]` catalogue, `get_next_level()`, completion-only linear unlock, write record to `SaveManager` on `rating_computed`, emit `level_record_saved(level_id, stars, final_moves)`, `next_level_unlocked`, `world_completed`                                                                                                             | gameplay-programmer | 0.5       | S2-02, S1-03               | `level_record_saved` fires after `SaveManager.set_level_record()` write; next level unlocks on completion (0 stars sufficient); first level always unlocked regardless of save state; `get_next_level()` returns null for last level in catalogue; `stars == -1` sentinel writes `completed=true, stars=0`; GUT tests cover unlock chain, world completion, sentinel                                 |
| S2-04 | Implement `HUD` CanvasLayer node — move counter label (`N / M`), coverage label, undo button (enabled/disabled on `can_undo()`), restart button, level name label; locks all interactive elements on `level_completed`                                                                                                                                                                                  | ui-programmer       | 0.5       | S2-01, S1-08, S1-07        | All displays update via signals (no polling); undo button disabled when history empty, re-enabled after any move; `minimum_moves == 0` suppresses `/ M` denominator; all buttons locked (hidden + `mouse_filter = IGNORE`) after `level_completed`; restart and undo button presses call `UndoRestart.restart()` / `UndoRestart.undo()` directly; GUT tests cover enabled/disabled state transitions |
| S2-05 | Produce `res://scenes/gameplay/gameplay.tscn` + complete `level_coordinator.gd` wiring — add `@onready` refs for UndoRestart, StarRatingSystem, LevelProgression, HUD; close all 15 TODO comments; insert UndoRestart as first `slide_completed` connection; wire `_on_level_record_saved` → `SceneManager.go_to(Screen.LEVEL_COMPLETE, params)`; delegate `restart_level()` to `UndoRestart.restart()` | godot-specialist    | 1.0       | S2-01, S2-02, S2-03, S2-04 | Scene file exists at `res://scenes/gameplay/gameplay.tscn`; scene loads without errors in Godot headless; level plays end-to-end (load → slide → coverage → moves → completion → Level Complete params built); undo and restart work in-scene; HUD updates correctly from all signals; zero TODO comments remain in `level_coordinator.gd`; `test_level_coordinator.gd` passes in full               |

---

### Should Have

| ID    | Task                                                                                                                                                                                                                                         | Agent/Owner   | Est. Days | Dependencies | Acceptance Criteria                                                                                                                                                                                                                                                                                                                     |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | --------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S2-06 | Implement `LevelCompleteScreen` — `res://scenes/ui/level_complete.tscn`; reads params from `receive_scene_params()`; displays star count, final moves vs minimum, NEW BEST badge; Next Level / Retry / World Map navigation via SceneManager | ui-programmer | 1.0       | S2-03, S1-03 | Screen loads from params dict without errors; NEW BEST badge appears when `final_moves < prev_best_moves && was_previously_completed`; Next Level button disabled/hidden when `next_level_data == null`; all three nav buttons call correct `SceneManager.go_to()` routes; GUT tests cover new-best logic and null next-level edge case |
| S2-07 | S1-06c: Formal mobile swipe accuracy test — 20 swipes on physical device, log each hit/miss, confirm ≥15/20; lock TRANS_QUAD as final or reopen easing decision with recorded data                                                           | qa-tester     | 0.5       | —            | Accuracy count recorded as artifact in `production/sprints/sprint-02-mobile-accuracy.md`; if ≥15/20 → S1-06 marked fully done in session state; if <15/20 → easing decision formally reopened with data and R-01 re-opened in risk register                                                                                             |

---

### Nice to Have

| ID    | Task                                                                                                                                             | Agent/Owner         | Est. Days | Dependencies | Acceptance Criteria                                                                                                                                             |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------- | --------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S2-08 | `CoverageVisualizer` placeholder — `TileMapLayer`-based tile highlight overlay; subscribes to `tile_covered` signal; resets on `level_restarted` | technical-artist    | 0.5       | S2-05        | Covered tiles visible in-scene; overlay clears on restart; no `_draw()` placeholder rendering in production gameplay scene; uses `TileMapLayer` (not `TileMap`) |
| S2-09 | Author World 1 expansion levels 4–6 as `.tres` LevelData resources; run `tools/level_solver.gd` on each to verify and bake `minimum_moves`       | gameplay-programmer | 0.5       | S1-09, S1-04 | 3 new `.tres` files in `assets/levels/world_1/`; BFS solver confirms correct `minimum_moves` for each; all three levels load into gameplay scene without errors |

---

## Carryover from Sprint 1

| Task   | Reason                                                                                                            | New Estimate     |
| ------ | ----------------------------------------------------------------------------------------------------------------- | ---------------- |
| S1-06c | Formal swipe accuracy count deferred — physical device unavailable during Sprint 1; qualitative validation passed | 0.5 days → S2-07 |

---

## Risks

| Risk                                                                                                                  | Probability | Impact | Mitigation                                                                                                                                                                                   |
| --------------------------------------------------------------------------------------------------------------------- | ----------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R-06: Scope creep — LevelProgression + HUD + LevelComplete collectively exceed estimates                              | Medium      | High   | S2-06 (Level Complete Screen) is Should Have; can slip to Sprint 3 if S2-05 takes longer. Core path is S2-01 through S2-05 only.                                                             |
| R-07: `gameplay.tscn` scene wiring reveals undiscovered integration issues between new systems                        | Medium      | High   | S2-05 is scheduled last (all its dependencies must be complete first); it has the largest estimate (1.0 day) and the buffer day backs it up.                                                 |
| R-08: Mobile test (S2-07) blocked again by device unavailability                                                      | Low         | Medium | Same risk as sprint 1 S1-06. If blocked: defer to Sprint 3; add device-availability check to sprint kickoff checklist (action item from retrospective).                                      |
| R-09: LevelProgression catalogue ordering leaks into save data format and breaks future level additions               | Low         | High   | Catalogue is an explicit ordered `Array[LevelData]`; order is not auto-discovered. Level IDs are strings, not indices. SaveManager keyed on `level_id`. Stable.                              |
| R-10: UndoRestart signal connection order conflicts with existing `_connect_signals()` bind order in LevelCoordinator | Medium      | Medium | Retrospective lesson: signal order is critical. S2-01 acceptance criteria explicitly requires UndoRestart as **first** `slide_completed` connection. Validated in tests before S2-05 wiring. |

---

## Dependencies on External Factors

- Physical mobile device (iOS or Android) required for S2-07 (S1-06c carryover)
- `SceneManager.go_to()` must support `Screen.LEVEL_COMPLETE` enum value (stub in S1-03 — confirm enum is defined before S2-06 wiring)

---

## Definition of Done for this Sprint

- [ ] All Must Have tasks (S2-01 through S2-05) completed and tests passing
- [ ] `gameplay.tscn` loads and plays a `.tres` level end-to-end in production architecture
- [ ] Undo and restart work correctly in the production scene (not just in unit tests)
- [ ] Zero TODO comments remain in `src/gameplay/level_coordinator.gd`
- [ ] All new systems are code-reviewed before S2-05 wiring begins
- [ ] `test_level_coordinator.gd` passes with all new wiring in place
- [ ] S2-06 (Level Complete Screen) delivered if capacity allows
- [ ] S2-07 (formal mobile accuracy test) resolved — decision locked or formally reopened
- [ ] Sprint retrospective filed before Sprint 3 kickoff
