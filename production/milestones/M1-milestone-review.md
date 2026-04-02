# Milestone Review: M1 — Core Loop Playable

## Overview

| Field                | Value                                               |
| -------------------- | --------------------------------------------------- |
| **Target Date**      | 2026-04-07                                          |
| **Current Date**     | 2026-04-02                                          |
| **Days Remaining**   | 5                                                   |
| **Sprints in M1**    | Sprint 1 (2026-04-01) · Sprint 2 (2026-04-01 to 02) |
| **Sprints Complete** | 2 / 2                                               |
| **Status**           | ✅ All exit criteria met — 5 days ahead of target   |

M1 exit criteria were fully satisfied on **2026-04-01 (Day 1 of Sprint 1)**, five days before
the 2026-04-07 target. Sprint 2, completed 2026-04-02, delivered systems beyond M1 scope,
bringing the project significantly ahead of its milestone plan.

---

## Feature Completeness

### Fully Complete — M1 Required Systems

| Feature                          | Acceptance Criteria Met                                                               | Tests |
| -------------------------------- | ------------------------------------------------------------------------------------- | ----- |
| GridSystem autoload              | `is_walkable()`, `grid_to_pixel()`, `load_from_level_data()` — all live               | 27    |
| InputSystem autoload             | `slide_requested` fires once/input; opposite-axis rejection; no queue duplication     | 22    |
| SaveManager stub                 | `save_game()` / `load_game()` callable without crash; correct autoload load order     | 24    |
| SceneManager (stub → production) | `go_to()` loads PackedScene, delivers params before `_ready()`, replaces scene        | 14    |
| LevelDataFormat + 6 levels       | `.tres` resources load and populate GridSystem; BFS-verified `minimum_moves`          | 33    |
| SlidingMovement production node  | Cat slides on LevelData grid; LOCKED state; `slide_completed` signal correct          | 40    |
| Mobile validation (TRANS_QUAD)   | 20/20 swipe accuracy on Poco F6; easing locked; platform-adaptive speed confirmed     | —     |
| CoverageTracking                 | Bitmask coverage; `coverage_changed`; `coverage_completed` fires once at 100%         | 35    |
| MoveCounter                      | Increments on slide; resets on `level_restarted`; `move_count_changed` signal correct | 27    |

### Fully Complete — Beyond M1 Scope (Sprint 2 Bonus Delivery)

| Feature                  | Acceptance Criteria Met                                                                  | Tests |
| ------------------------ | ---------------------------------------------------------------------------------------- | ----- |
| BFS Minimum Solver       | Correct `minimum_moves` for all 6 levels; graceful abort on oversized grids              | 19    |
| UndoRestart              | Unlimited history; undo restores position + coverage + move count; first-connection spec | —     |
| StarRatingSystem         | Locked formula (3→2→1→0); `rating_computed` fires exactly once on `level_completed`      | —     |
| LevelProgression         | Linear unlock; `level_record_saved` signal; world completion detection                   | —     |
| HUD CanvasLayer          | Move counter (`N / M`), undo button (enabled/disabled), restart; locks on completion     | —     |
| GameplayScene production | `gameplay.tscn` end-to-end wired; zero TODO comments; all systems integrated             | —     |
| LevelCompleteScreen      | Star display, moves vs minimum, NEW BEST badge, Next/Retry/WorldMap navigation           | —     |
| CoverageVisualizer       | Node2D signal-driven overlay; `GridRenderer` coverage path fully removed                 | 9     |
| World 1 Levels 4–6       | "Side Step" (min=4), "Double S" (min=5), "Three Turn" (min=6); BFS-verified              | —     |

**Total GUT tests at milestone close: 464 / 464 passing**

### Partially Complete

| Feature  | % Done | Remaining Work | Risk to Milestone |
| -------- | ------ | -------------- | ----------------- |
| _(none)_ | —      | —              | —                 |

All M1 exit criteria are fully satisfied. No partial features within M1 scope.

### Not Started (M1 Scope)

_(None — every M1 feature is complete.)_

---

## Quality Metrics

- **Open Severity-1 Bugs**: 0
- **Open Severity-2 Bugs**: 0
- **Open Severity-3 / Latent Issues**: 1
  - `test_level_data.gd line 243` — `SCRIPT ERROR: RefCounted assigned to Node variable` fires
    on every test run but does not cause a test failure. Carried from Sprint 1 retro (Medium,
    Day 2 deadline) through Sprint 2 without resolution. Flagged as High priority for Sprint 3.
- **Test Pass Rate**: 464 / 464 (100%)
- **Source files with dedicated test coverage**: 15 / 18 (83%)
  - Untested: `cat_sprite.gd` (visual only), `grid_renderer.gd` (visual only),
    `level_catalogue.gd` (thin wrapper, indirectly covered via `test_level_coordinator.gd`)
- **Playtest validation**: ✅ Automated (3 levels, 455 tests) + manual player playtest
  (4 issues identified and fixed before close)
- **Performance**: Within budget. No frame-rate issues. Mobile swipe latency acceptable
  (TRANS_QUAD, 25 t/s mobile / 15 t/s desktop).

---

## Code Health

- **TODO count**: **0** (Sprint 1 opened 15, Sprint 2 closed all 15)
- **FIXME count**: **0**
- **HACK count**: **0**
- **Dead code**: `LEVEL_COMPLETE_OVERLAY_DELAY_SEC = 0.6` constant in
  `src/gameplay/level_coordinator.gd` — the overlay code path it was used in is now
  unreachable since `SceneManager.go_to()` performs a real scene swap. Scheduled for
  Sprint 3 removal.
- **Technical debt items**:
  1. `test_level_data.gd:243` SCRIPT ERROR — latent type mismatch, low blast radius but
     noisy and carried twice. Must ship as an explicit Sprint 3 task.
  2. `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` dead constant — trivial 2-line removal.
  3. No test file for `cat_sprite.gd` or `grid_renderer.gd` — both are visual-only nodes
     with no game-logic state; risk is low but coverage gap is noted.

**Overall code health: Excellent.** Zero TODO/FIXME/HACK, 100% test pass rate, 464 tests.
The codebase is healthier at this milestone than many projects achieve at 1.0 release.

---

## Risk Assessment

| ID   | Risk                                                          | Status    | Impact if Realized | Mitigation                                                                                                                                                                     |
| ---- | ------------------------------------------------------------- | --------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| R-01 | TRANS_QUAD easing floaty on mobile                            | ✅ CLOSED | —                  | 20/20 accuracy locked. No action needed.                                                                                                                                       |
| R-02 | LevelDataFormat API instability                               | ✅ CLOSED | —                  | 33 tests lock contract.                                                                                                                                                        |
| R-03 | BFS Solver not delivered                                      | ✅ CLOSED | —                  | Delivered in Sprint 1 NTH.                                                                                                                                                     |
| R-04 | No test device for mobile validation                          | ✅ CLOSED | —                  | Completed in prototype + S2-07.                                                                                                                                                |
| R-05 | Autoload boot null-refs                                       | ✅ CLOSED | —                  | ADR-001 load order; 160+ tests confirm.                                                                                                                                        |
| R-06 | Jam deadline — scope creep crowds out MVP systems             | **Open**  | High               | All 22 GDDs pre-approved; no new systems without producer sign-off. Velocity is running at 5× plan, which gives schedule buffer. Still requires Sprint 3+ planning discipline. |
| R-11 | GridRenderer `_draw()` conflicts with CoverageVisualizer spec | ✅ CLOSED | —                  | Replaced entirely in S2-08.                                                                                                                                                    |
| R-12 | `level_complete.tscn` absent — SceneManager route broken      | ✅ CLOSED | —                  | Scene created in S2-06; SceneManager promoted.                                                                                                                                 |

**Net open risks: 1 (R-06 — scope creep / jam deadline)**. This is the principal risk
remaining for the project. Current velocity is high enough that it is manageable, but
it requires active scope discipline in Sprint 3 onwards.

---

## Velocity Analysis

| Sprint       | Planned Tasks | Completed (incl. unplanned) | Calendar Days Used | Allocated Days |
| ------------ | ------------- | --------------------------- | ------------------ | -------------- |
| Sprint 1     | 9             | 11 (+2 unplanned)           | ~1                 | 5              |
| Sprint 2     | 9             | 18 (+9 unplanned)           | ~1.5               | 5              |
| **M1 Total** | **18**        | **29 (+11 unplanned)**      | **~2.5**           | **10**         |

- **Planned vs Completed**: 18 planned / 18 completed = **100%** (+ 11 unplanned items)
- **Total calendar days used**: ~2.5 of 10 allocated (**75% under-utilised**)
- **Tests written**: 464 total (0 → 256 in Sprint 1, +208 in Sprint 2)
- **Commits**: 30 across both sprints
- **Trend**: Stable — two consecutive 100% delivery sprints. Effective velocity is ~5×
  the planned allocation.
- **Adjusted estimate for remaining M1 work**: N/A — milestone complete.
- **Implication for schedule**: With 5 days remaining before the 2026-04-07 target and
  the milestone already complete, Sprint 3 can begin immediately and target M2 systems.
  At this velocity, M2 ("Progression + Economy + Polish") should be achievable within
  1–2 sprints rather than the originally-budgeted 3.

---

## Scope Recommendations

### Protect (Must ship for M1 — already satisfied)

- Core loop (grid, input, sliding, coverage, move counter) — **DONE**
- At least 3 playable levels — **DONE** (6 levels delivered)
- Mobile validation — **DONE**

### At Risk

_(None. No M1 features are at risk. The milestone is complete.)_

### Cut Candidates (Systems beyond M1 already delivered anyway)

All M2-category systems are delivered ahead of schedule. Nothing needs cutting.
The only pruning concern is future scope: R-06 (jam deadline) should gate
Sprint 3+ feature additions.

---

## Go/No-Go Assessment

**Recommendation: GO ✅**

**Rationale**: Every M1 exit criterion is met with 5 days to spare. The team has
achieved 100% task completion across both sprints, 464 passing tests, 0 TODO/FIXME/HACK
markers, a successful mobile validation, and a fully playable end-to-end production
scene — plus the complete set of M2-category systems (undo/restart, star rating,
level complete screen, HUD, 6 levels). There are no open blockers, no failed tests,
and no incomplete M1 features. The project is ready to advance to M2 planning
immediately.

**Open items to carry into Sprint 3 (not blocking GO):**

1. Fix `test_level_data.gd:243` SCRIPT ERROR — latent type mismatch, non-blocking
   but noisy on every test run. Two sprints without resolution elevates this to
   a scheduled task.
2. Remove dead `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` constant from `level_coordinator.gd`.
3. Sprint 3 must be planned with at minimum 16 tasks (velocity data demands it).

---

## Action Items

| #   | Action                                                                                                  | Owner                     | Deadline           |
| --- | ------------------------------------------------------------------------------------------------------- | ------------------------- | ------------------ |
| 1   | Begin Sprint 3 planning — target ≥16 tasks at 0.25d baseline per system                                 | producer                  | 2026-04-02 (today) |
| 2   | Fix `test_level_data.gd:243` SCRIPT ERROR as explicit Sprint 3 Day 1 task                               | godot-gdscript-specialist | Sprint 3, Day 1    |
| 3   | Remove dead `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` constant from `level_coordinator.gd`                     | gameplay-programmer       | Sprint 3, Day 1    |
| 4   | Define M2 milestone: write exit criteria, target date, and sprint allocation before Sprint 3 kickoff    | producer                  | 2026-04-02 (today) |
| 5   | Add `test_cat_sprite.gd` and `test_grid_renderer.gd` or explicitly document "visual-only, no test file" | godot-gdscript-specialist | Sprint 3           |
