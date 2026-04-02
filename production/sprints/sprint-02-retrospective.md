## Retrospective: Sprint 2

Period: 2026-04-01 — 2026-04-02
Generated: 2026-04-02

---

### Metrics

| Metric                    | Planned              | Actual                | Delta |
| ------------------------- | -------------------- | --------------------- | ----- |
| Tasks (Must Have)         | 5                    | 5                     | 0     |
| Tasks (Should Have)       | 2                    | 2                     | 0     |
| Tasks (Nice to Have)      | 2                    | 2                     | 0     |
| Total Tasks               | 9                    | 9                     | 0     |
| Completion Rate           | —                    | 100%                  | —     |
| Effort Days Allocated     | 5 (4 net + 1 buffer) | ~1.5 actual           | −3.5d |
| Carryover Tasks           | 1 (S1-06c)           | 0 (resolved as S2-07) | −1    |
| Bugs Found (playtest)     | —                    | 4                     | —     |
| Bugs Fixed                | —                    | 4                     | —     |
| Unplanned Tasks Added     | —                    | 9                     | —     |
| GUT Tests at Sprint Close | ~250 (est)           | 464 (+208 vs S1)      | +208  |
| Commits                   | —                    | 14                    | —     |

---

### Velocity Trend

| Sprint   | Planned Tasks | Completed         | Rate |
| -------- | ------------- | ----------------- | ---- |
| Sprint 1 | 9             | 9 (+ 2 unplanned) | 100% |
| Sprint 2 | 9             | 9 (+ 9 unplanned) | 100% |

**Trend**: Stable at sustained maximum velocity.
Both sprints delivered 100% of planned tasks in approximately Day 1 of a 5-day allocation.
Unplanned work absorbed is growing (2 items → 9 items), indicating the team's effective
capacity is substantially larger than sprint plans reflect.

---

### What Went Well

- **9/9 tasks completed in ~1.5 days** against a 5-day plan. All Must Have, Should Have,
  and Nice to Have tiers were delivered, including two NTH tasks (S2-08 CoverageVisualizer,
  S2-09 Levels 4–6) that were classified as stretch goals.
- **Playtest-driven development paid off**: a same-session playtest cycle identified 4
  player-facing bugs (undo button, transition flash, missing label, visual rollback) and
  all 4 were fixed before sprint close, raising quality without a formal QA delay.
- **CoverageVisualizer architecture was correct**: replacing `GridRenderer._draw()` with
  a dedicated `CoverageVisualizer` Node2D was cleaner than the original TileMapLayer spec.
  The result is a fully isolated, signal-driven component with 9 dedicated tests and zero
  coupling to grid rendering. The "replace, not layer" decision from R-11 proved correct.
- **SceneManager promoted without test breakage**: upgrading `go_to()` from a stub to a
  real scene swapper mid-sprint did not break any of the 464 tests. The contract
  (`_deliver_params()` before `_ready()`) was introduced and validated cleanly.
- **4 of 5 Sprint 1 action items resolved**: S1-06c (swipe test), gameplay.tscn, all 15
  LevelCoordinator TODOs, and the 50% estimate cut were all addressed.
- **Code reviews caught real issues**: two rounds of code review found dead code after
  `SceneManager.go_to()`, a stale `render_grid()` docstring, unused `_grid_width`/
  `_grid_height` fields in CoverageVisualizer, and a leftover temp verification script.
  All were fixed before close.

---

### What Went Poorly

- **Systematic overestimation continues, unchanged**: Sprint 1 retro identified that every
  task was completed 50–75% faster than estimated and recommended halving estimates.
  Sprint 2 actuals show 60–80% overestimation on every task again. Delivery in ~30% of
  calendar time means Sprint 3 will be under-planned unless task count is tripled.
- **S1 action item #3 (test_level_data.gd:243 SCRIPT ERROR) not addressed**: This
  `RefCounted` vs `Node` type mismatch fires on every test run. It was called out in the
  Sprint 1 retrospective with a Medium priority / Sprint 2 Day 2 deadline. It carries a
  second time. A task that is deprioritised twice starts to become permanent technical debt.
- **S2-03 LevelProgression bundled into the S2-05 commit**: `level_progression.gd` was
  delivered inside the `feat: S2-05 GameplaySceneWiring` commit, violating the
  `feat: [Sprint-SubtaskID] [PascalCaseTaskName]` auto-commit convention. This makes it
  harder to bisect history if a LevelProgression regression is introduced later.
- **Sprint retrospective nearly missed as a DoD item**: It was the last unchecked DoD
  checkbox and only filed because it was explicitly tracked. Retrospectives filed under
  pressure tend to be shallower. It should be scheduled as the first action after sprint
  delivery confirmation, not an afterthought.

---

### Blockers Encountered

| Blocker                                                                                   | Duration | Resolution                                                                               | Prevention                                                                                           |
| ----------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `SceneManager.go_to()` was a stub — `LevelCompleteScreen` navigation silently did nothing | ~0.5h    | Promoted `go_to()` to real scene-swapper in-sprint; audited for dead code after the call | When a stub is relied upon by a sprint task, add "promote stub → production" as an explicit sub-task |
| Context/token budget interrupted sprint doc update mid-session                            | ~minutes | Continued in new session; conversation summary mechanism reconstructed state accurately  | No structural change needed; summary mechanism worked correctly                                      |

---

### Estimation Accuracy

| Task                      | Estimated | Actual | Variance | Likely Cause                                                                                 |
| ------------------------- | --------- | ------ | -------- | -------------------------------------------------------------------------------------------- |
| S2-05 GameplaySceneWiring | 1.0d      | ~0.3d  | −70%     | 15 TODO placeholders had clear contracts; wiring was mechanical, not design work             |
| S2-06 LevelCompleteScreen | 1.0d      | ~0.3d  | −70%     | GDD specified exact UI structure; `_auto_discover_ui_nodes()` pattern eliminated boilerplate |
| S2-08 CoverageVisualizer  | 0.5d      | ~0.1d  | −80%     | Node2D signal-driven approach simpler than TileMapLayer spec suggested                       |
| S2-09 Levels 4–6          | 0.5d      | ~0.2d  | −60%     | BFS solver automated verification; `.tres` authoring is mechanical once format is known      |

**Overall estimation accuracy**: 0% of tasks within +/−20% of estimate.
All tasks were completed 60–80% faster than estimated. The pattern is structurally
consistent with Sprint 1. The root cause is that task estimates assume design ambiguity,
but all 22 GDDs are approved and all API contracts are pre-established. When the task is
"implement this spec," the implementation time is small. Sprint 3 should set **0.25d as the
maximum baseline per system** and plan enough systems to genuinely fill 4 net days (i.e.,
16 tasks minimum, not 9).

---

### Carryover Analysis

| Task                                  | Original Sprint | Times Carried | Reason                                               | Action                                             |
| ------------------------------------- | --------------- | ------------- | ---------------------------------------------------- | -------------------------------------------------- |
| `test_level_data.gd:243` SCRIPT ERROR | Sprint 1        | 2             | Consistently deprioritised in favour of feature work | **Must be scheduled as an explicit Sprint 3 task** |

No sprint tasks carried over from Sprint 2 into Sprint 3.

---

### Technical Debt Status

- Current TODO count: **0** (previous: 15)
- Current FIXME count: **0** (previous: 0)
- Current HACK count: **0** (previous: 0)
- Trend: **Shrinking** — all 15 Sprint 1 TODOs resolved by S2-05
- **Latent items to address in Sprint 3**:
  - `test_level_data.gd:243`: `SCRIPT ERROR: Trying to assign value of type 'RefCounted' to a
variable of type 'Node'` — fires every test run, does not cause test failure, but masks a
    real bug in either the test or the system under test. Carried twice.
  - `LEVEL_COMPLETE_OVERLAY_DELAY_SEC = 0.6` constant in `level_coordinator.gd` is dead code:
    the overlay path that used it is unreachable now that `SceneManager.go_to()` does a real
    scene swap. Should be removed to avoid confusion.

---

### Previous Action Items Follow-Up

| Action Item (from Sprint 1)                                      | Status      | Notes                                                                                           |
| ---------------------------------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------- |
| Complete S1-06c formal 20-swipe accuracy test, lock TRANS_QUAD   | ✅ Done     | S2-07: 20/20 hits on Poco F6. TRANS_QUAD locked as final.                                       |
| Create `scenes/gameplay/gameplay.tscn`, wire to LevelCoordinator | ✅ Done     | S2-05: full production scene delivered, all 15 TODOs closed.                                    |
| Fix `test_level_data.gd:243` SCRIPT ERROR                        | ❌ Not Done | Carries for second sprint. Must become an explicit scheduled task in Sprint 3.                  |
| Cut Sprint 2 task estimates by ~50% from Sprint 1 baseline       | ⚠️ Partial  | Estimates were reduced but still overestimated by 60–80%. Velocity data now supports a 75% cut. |
| Close all 15 LevelCoordinator TODOs by Sprint 2 close            | ✅ Done     | All 15 closed in S2-05 GameplaySceneWiring.                                                     |

---

### Action Items for Next Iteration

| #   | Action                                                                                                  | Owner                     | Priority | Deadline          |
| --- | ------------------------------------------------------------------------------------------------------- | ------------------------- | -------- | ----------------- |
| 1   | Schedule and fix `test_level_data.gd:243` SCRIPT ERROR as an explicit sprint task — not a suggestion    | godot-gdscript-specialist | High     | Sprint 3, Day 1   |
| 2   | Plan Sprint 3 with at minimum 16 tasks (≥3× Sprint 2 count) — baseline 0.25d/task, re-calibrate after   | producer                  | High     | Sprint 3 kickoff  |
| 3   | Remove dead `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` constant and overlay code path in `level_coordinator.gd` | gameplay-programmer       | Low      | Sprint 3, Day 1   |
| 4   | Enforce one-commit-per-sprint-sub-task policy — no bundling (S2-03 was swallowed by S2-05)              | all                       | Medium   | Sprint 3 kickoff  |
| 5   | Run sprint retrospective within 24h of all-tasks-complete, not as a DoD checkbox at the end             | producer                  | Low      | Sprint 3 planning |

---

### Process Improvements

- **Sprint sizing must triple**: Both Sprint 1 and Sprint 2 were completed in Day 1 of a
  5-day sprint. Back-to-back evidence confirms this isn't luck — it's a structural mismatch
  between planned task count and actual capacity. Sprint 3 should target 16–20 tasks, then
  use post-close actuals to set Sprint 4's baseline more precisely.
- **Stub promotion must be an explicit task**: When a system ships as a stub (SceneManager,
  SaveManager), any sprint that depends on production behaviour must include "promote
  [System] stub to production" explicitly in the task list. Discovering it mid-task (as
  happened with S2-06) compresses the available debugging window and creates a dead-code
  risk in callers.

---

### Summary

Sprint 2 matched Sprint 1's 100% completion rate and again finished on Day 1 of a 5-day
allocation — delivering all 9 planned tasks, 9 unplanned items, 4 playtest bug fixes,
2 rounds of code review, a SceneManager promotion, and the full test suite growing by 208
tests to 464. The single most important change for Sprint 3 is to **triple the planned task
count**: two consecutive sprints have proven the team consistently delivers at 4–5× its
planned capacity, and continuing to under-plan wastes development time and compresses the
milestone schedule.
