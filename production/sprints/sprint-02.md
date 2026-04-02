# Sprint 2 — 2026-04-02 to 2026-04-08

**Status**: In Progress (Day 1 of 5 — ahead of schedule)
**Last Updated**: 2026-04-02

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

| ID    | Task                                                                                                                                                                                                                                                                                                                                                                                                    | Agent/Owner         | Est. Days | Dependencies               | Acceptance Criteria                                                                                                                                                                                                             |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | --------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S2-01 | Implement `UndoRestart` node — `MoveSnapshot` inner class, unlimited history stack, `undo()` (restores cat pos + coverage + move count in spec order), `restart()` (snap + clear + re-initialize), `can_undo()`, `initialize()`, `undo_applied` + `level_restarted` signals; snapshot on `slide_completed` as **first** connection                                                                      | gameplay-programmer | 0.5       | S1-05, S1-07, S1-08        | ✅ **DONE** — all GUT tests pass; history stack, signal order, freeze-on-complete all validated                                                                                                                                 |
| S2-02 | Implement `StarRatingSystem` node — threshold cache from `LevelData` at `initialize_level()`, locked formula (3→2→1→0), `rating_computed(stars: int, final_moves: int)` signal fires exactly once on `level_completed`                                                                                                                                                                                  | gameplay-programmer | 0.25      | S1-08, S1-04               | ✅ **DONE** — 5 threshold cases + sentinel; fires exactly once; GUT tests pass                                                                                                                                                  |
| S2-03 | Implement `LevelProgression` node — explicit ordered `Array[LevelData]` catalogue, `get_next_level()`, completion-only linear unlock, write record to `SaveManager` on `rating_computed`, emit `level_record_saved(level_id, stars, final_moves)`, `next_level_unlocked`, `world_completed`                                                                                                             | gameplay-programmer | 0.5       | S2-02, S1-03               | ✅ **DONE** — unlock chain, world completion, sentinel, null-last-level; GUT tests pass                                                                                                                                         |
| S2-04 | Implement `HUD` CanvasLayer node — move counter label (`N / M`), coverage label, undo button (enabled/disabled on `can_undo()`), restart button, level name label; locks all interactive elements on `level_completed`                                                                                                                                                                                  | ui-programmer       | 0.5       | S2-01, S1-08, S1-07        | ✅ **DONE** — signal-driven; undo button refresh fixed (moves `can_undo()` check to `_on_move_count_changed`); `MovesPrefix` label added; coverage label hidden by default; GUT tests pass                                      |
| S2-05 | Produce `res://scenes/gameplay/gameplay.tscn` + complete `level_coordinator.gd` wiring — add `@onready` refs for UndoRestart, StarRatingSystem, LevelProgression, HUD; close all 15 TODO comments; insert UndoRestart as first `slide_completed` connection; wire `_on_level_record_saved` → `SceneManager.go_to(Screen.LEVEL_COMPLETE, params)`; delegate `restart_level()` to `UndoRestart.restart()` | godot-specialist    | 1.0       | S2-01, S2-02, S2-03, S2-04 | ✅ **DONE** — scene at `res://scenes/gameplay/gameplay.tscn`; end-to-end loop works; zero TODO comments; `test_level_coordinator.gd` passes; code-reviewed (critical: `_snapshot_previous_bests()` added to `_on_overlay_next`) |

---

### Should Have

| ID    | Task                                                                                                                                                                                                                                         | Agent/Owner   | Est. Days | Dependencies | Acceptance Criteria                                                                                                                                                                                                                                                        |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | --------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S2-06 | Implement `LevelCompleteScreen` — `res://scenes/ui/level_complete.tscn`; reads params from `receive_scene_params()`; displays star count, final moves vs minimum, NEW BEST badge; Next Level / Retry / World Map navigation via SceneManager | ui-programmer | 1.0       | S2-03, S1-03 | 🔶 **PARTIAL** — `src/ui/level_complete_screen.gd` and `tests/test_level_complete_screen.gd` complete and passing. `res://scenes/ui/level_complete.tscn` scene file not yet created. Inline overlay in `level_coordinator.gd` covers the player experience in the interim. |
| S2-07 | S1-06c: Formal mobile swipe accuracy test — 20 swipes on physical device, log each hit/miss, confirm ≥15/20; lock TRANS_QUAD as final or reopen easing decision with recorded data                                                           | qa-tester     | 0.5       | —            | ✅ **DONE** — Poco F6, 20/20 hits (100%). TRANS_QUAD locked as final easing. Artifact: `production/sprints/sprint-02-mobile-accuracy.md`. S1-06 marked fully done in session state.                                                                                        |

---

### Nice to Have

| ID    | Task                                                                                                                                             | Agent/Owner         | Est. Days | Dependencies | Acceptance Criteria                                                                                                                                                   |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------- | --------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S2-08 | `CoverageVisualizer` placeholder — `TileMapLayer`-based tile highlight overlay; subscribes to `tile_covered` signal; resets on `level_restarted` | technical-artist    | 0.5       | S2-05        | ⬜ **NOT STARTED** — Visual coverage is currently handled by `GridRenderer._draw()` (workaround). S2-08 as specified (TileMapLayer-based, no `_draw()`) remains open. |
| S2-09 | Author World 1 expansion levels 4–6 as `.tres` LevelData resources; run `tools/level_solver.gd` on each to verify and bake `minimum_moves`       | gameplay-programmer | 0.5       | S1-09, S1-04 | ⬜ **NOT STARTED** — Only 3 levels currently in `assets/levels/world_1/` (w1_l1, w1_l2, w1_l3).                                                                       |

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

- [x] All Must Have tasks (S2-01 through S2-05) completed and tests passing
- [x] `gameplay.tscn` loads and plays a `.tres` level end-to-end in production architecture
- [x] Undo and restart work correctly in the production scene (not just in unit tests)
- [x] Zero TODO comments remain in `src/gameplay/level_coordinator.gd`
- [x] All new systems are code-reviewed before S2-05 wiring begins
- [x] `test_level_coordinator.gd` passes with all new wiring in place
- [ ] S2-06 (Level Complete Screen) delivered if capacity allows — PARTIAL (gd + tests done; .tscn pending)
- [x] S2-07 (formal mobile accuracy test) resolved — TRANS_QUAD locked
- [ ] Sprint retrospective filed before Sprint 3 kickoff

---

## S2-07 Mobile Swipe Accuracy Test Results

**Date**: 2026-04-01 | **Tester**: Grace | **Device**: Xiaomi Poco F6 (Android)
**Build**: Sprint 1 production build (Android APK, arm64-v8a)

### Test Parameters

| Parameter            | Value                                        |
| -------------------- | -------------------------------------------- |
| Total swipes         | 20                                           |
| Pass threshold       | ≥ 15 / 20                                    |
| Min swipe distance   | 40 px (`InputSystem.min_swipe_distance_px`)  |
| Max swipe duration   | 400 ms (`InputSystem.max_swipe_duration_ms`) |
| Slide speed (mobile) | 25 tiles/s                                   |
| Easing under test    | `TRANS_QUAD` + `EASE_OUT`                    |
| Fallback (if fail)   | `TRANS_EXPO`                                 |

### Tally

| #   | Intended Direction | Direction Fired | Hit? |
| --- | ------------------ | --------------- | ---- |
| 1   | Right              | Right           | ✅   |
| 2   | Up                 | Up              | ✅   |
| 3   | Left               | Left            | ✅   |
| 4   | Down               | Down            | ✅   |
| 5   | Right              | Right           | ✅   |
| 6   | Down               | Down            | ✅   |
| 7   | Up                 | Up              | ✅   |
| 8   | Left               | Left            | ✅   |
| 9   | Down               | Down            | ✅   |
| 10  | Right              | Right           | ✅   |
| 11  | Up                 | Up              | ✅   |
| 12  | Left               | Left            | ✅   |
| 13  | Right              | Right           | ✅   |
| 14  | Down               | Down            | ✅   |
| 15  | Up                 | Up              | ✅   |
| 16  | Left               | Left            | ✅   |
| 17  | Right              | Right           | ✅   |
| 18  | Up                 | Up              | ✅   |
| 19  | Left               | Left            | ✅   |
| 20  | Down               | Down            | ✅   |

### Result

| Metric      | Value       |
| ----------- | ----------- |
| Hits        | 20          |
| Misses      | 0           |
| Accuracy    | 100%        |
| **Verdict** | **PASS** ✅ |

**TRANS_QUAD locked as final easing.** 20/20 accuracy on first run on physical hardware
(Poco F6). No floatiness, no missed inputs, no false triggers. Easing feels responsive
and snappy at 25 t/s mobile speed. TRANS_EXPO fallback is not needed.

S1-06 is now **fully complete** — both qualitative prototype validation (Sprint 1) and
formal accuracy count (S2-07) are satisfied.

---

## Status Report — 2026-04-02 (Day 1 of 5)

# Sprint 2 Status — 2026-04-02

## Progress: 6/9 tasks complete (67%) + 6 scope-addition bug fixes delivered

### Completed

| Task  | Completed By        | Notes                                                                                                                  |
| ----- | ------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| S2-01 | gameplay-programmer | UndoRestart fully implemented and code-reviewed. GUT tests pass.                                                       |
| S2-02 | gameplay-programmer | StarRatingSystem fully implemented. All threshold cases + sentinel tested.                                             |
| S2-03 | gameplay-programmer | LevelProgression fully implemented. Unlock chain, world completion, null-last-level tested.                            |
| S2-04 | ui-programmer       | HUD fully implemented and code-reviewed. 4 post-playtest UX fixes applied (see Unplanned Work below).                  |
| S2-05 | godot-specialist    | `gameplay.tscn` wired end-to-end. Code-reviewed. Critical: `_snapshot_previous_bests()` in `_on_overlay_next()` fixed. |
| S2-07 | qa-tester           | TRANS_QUAD locked. 20/20 swipe accuracy on Poco F6.                                                                    |

### In Progress

| Task  | Owner         | % Done | Blockers                                                                                                                                                                                             |
| ----- | ------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S2-06 | ui-programmer | 80%    | `level_complete_screen.gd` + `test_level_complete_screen.gd` complete and passing. `res://scenes/ui/level_complete.tscn` scene file not created. Inline overlay covers player experience in interim. |

### Not Started

| Task  | Owner               | At Risk? | Notes                                                                                                    |
| ----- | ------------------- | -------- | -------------------------------------------------------------------------------------------------------- |
| S2-08 | technical-artist    | No       | Nice to Have. Visual coverage working via `GridRenderer._draw()`. TileMapLayer spec version not started. |
| S2-09 | gameplay-programmer | No       | Nice to Have. Only 3 levels exist. Remaining capacity available to pursue this.                          |

### Unplanned Work Completed (Scope Additions — April 2)

| Item                                         | Trigger                | Outcome                                                           |
| -------------------------------------------- | ---------------------- | ----------------------------------------------------------------- |
| Automated playtest (3 levels, 455 tests)     | Post-delivery QA       | 3/3 PASS, ★★★ each. `REPORT_COPILOT.md` filed.                    |
| Player playtest report (REPORT_PLAYER.md)    | Player feedback review | 4 issues identified and prioritized.                              |
| Bug: Undo button disabled after first move   | Playtest finding       | Fixed in `hud.gd` `_on_move_count_changed`. 455/455 tests pass.   |
| Bug: Instant level-complete transition       | Playtest finding       | Fixed: 0.6s delay + `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` constant.  |
| Bug: Missing "Moves:" HUD label              | Playtest finding       | Fixed: `MovesPrefix` node in `gameplay.tscn`.                     |
| Bug: Undo doesn't roll back tile colors      | Playtest finding       | Fixed: `tile_uncovered` wired to `GridRenderer.mark_uncovered()`. |
| Code review: hud.gd, level_coordinator, tscn | Post-fix review        | 1 critical + 3 suggestions fixed. GDD docs updated to match.      |

---

## Burndown Assessment

**AHEAD OF SCHEDULE.** All 5 Must Have tasks and S2-07 completed on Day 1 of a 5-day sprint. 6 unplanned bug fixes absorbed within buffer capacity. ~3 net days + 1 buffer day remain.

Remaining capacity plan:

1. **S2-06 scene file** — create `res://scenes/ui/level_complete.tscn` to close the last open task (~0.5 days)
2. **S2-09** — author levels 4–6 (~0.5 days)
3. **S2-08** — TileMapLayer coverage visualizer (~0.5 days)
4. **Sprint retrospective** — file before Sprint 3 kickoff
5. **Sprint 3 planning** — if time allows

## Emerging Risks

- **R-11 (NEW)**: `GridRenderer` uses `_draw()` for coverage overlay — this conflicts with S2-08's explicit requirement of no `_draw()` placeholder in production. If S2-08 is pursued this sprint, `GridRenderer` rendering approach needs to be superseded, not layered. Patch: treat S2-08 as a replacement (remove `_draw()` coverage path when TileMapLayer is wired). Probability: Medium. Impact: Medium.
- **R-12 (NEW)**: `level_complete.tscn` scene absent — `SceneManager.go_to(Screen.LEVEL_COMPLETE, ...)` is registered synchronously in tests but the scene route has no scene to load. If integration testing or a real SceneManager is wired in future, this will error. Low probability now (stub SceneManager), but closes when S2-06 scene file is created.
