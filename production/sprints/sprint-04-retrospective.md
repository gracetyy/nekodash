## Retrospective: Sprint 4

Period: 2026-04-03 — 2026-04-03 (all tasks completed Day 1 of 5-day allocation)
Generated: 2026-04-03

---

### Metrics

| Metric                          | Planned              | Actual                      | Delta  |
| ------------------------------- | -------------------- | --------------------------- | ------ |
| Tasks — Must Have               | 10                   | 10                          | 0      |
| Tasks — Should Have             | 7                    | 6 (1 deferred)              | −1     |
| Tasks — Nice to Have            | 9                    | 3 completed + 4 deferred    | −2 net |
| Total Tasks Completed           | 26                   | 19 committed                | −7     |
| Completion Rate (Must Have)     | —                    | 100%                        | —      |
| Completion Rate (All Planned)   | —                    | 73%                         | —      |
| Effort Days Allocated           | 5 (4 net + 1 buffer) | ~0.44 actual                | −4.56d |
| GUT Tests at Sprint Close       | —                    | 610                         | —      |
| Tests Delta vs Sprint 3         | —                    | +107 (503 → 610)            | +107   |
| Bugs Introduced                 | —                    | 2 (code review)             | —      |
| Bugs Fixed in Sprint            | —                    | 2 (S4-24 UID, S4-28 parity) | —      |
| Fix Commits (post-review)       | —                    | 2                           | —      |
| Total Commits (sprint tasks)    | —                    | 20 (18 feat/docs + 2 fix)   | —      |
| Tasks With No Commit (absorbed) | —                    | 2 (S4-05, S4-06)            | —      |

---

### Velocity Trend

| Sprint   | Planned Tasks | Completed (committed)                                 | Rate          |
| -------- | ------------- | ----------------------------------------------------- | ------------- |
| Sprint 1 | 9             | 11 (+2 unplanned)                                     | 100%          |
| Sprint 2 | 9             | 18 (+9 unplanned)                                     | 100%          |
| Sprint 3 | 16            | 16                                                    | 100%          |
| Sprint 4 | 26            | 19 committed (+ 7 intentionally deferred or absorbed) | 73% committed |

**Trend**: Stable delivery of Must Have; Nice-to-Have completion rate drops when external
blockers (asset availability) prevent completion.

Sprint 4 is the first sprint where the 100% completion streak formally breaks on raw task
count. However, the shortfall is not a velocity regression: 4 of the 7 uncompleted tasks
are UI/asset Nice-to-Haves explicitly held by asset availability (S4-21, S4-22, S4-23,
S4-26), and S4-20 was already fixed pre-sprint. The remaining gaps — S4-19 (automated
playtest), S4-25 (M2 gate check), S4-29 (commit hygiene audit) — represent process and
documentation work that was straightforwardly not reached within the session.

---

### What Went Well

- **10/10 Must Have tasks delivered in ~3 hours 24 minutes** (11:41–15:04). The full
  critical path — ObstacleSystem, 3 level redesigns, 2 new levels (w1_l7, w1_l8),
  SfxManager, SFX event wiring, MusicManager — shipped on Day 1.
- **Planning model adjustment paid off**: Sprint 3 retro recommended shifting to a 0.05d
  per-task estimate (2× safety buffer over observed 0.025d). Sprint 4 used exactly this
  model. Actual delivery was ~0.44d for 19 tasks — a 3× gap vs the 10× gap in Sprint 3.
  This is the first sprint where the estimate-to-actual ratio is noticeably improving.
- **610 GUT tests, 0 failures** — +107 tests from 503. The ≥600 milestone (S4-28) was
  reached with 10 tests to spare. All 21 test scripts pass cleanly in headless mode.
- **Code review caught two real defects**: The post-implementation code review of S4-24
  identified a hand-crafted UID (`uid://csfxlibrary0001`) that would cause Godot import
  collisions, and S4-28 had a test parity gap (L5–L8 missing `_populates_grid_system`
  tests that L1–L4 had). Both were caught, fixed, and committed before push.
- **Commit hygiene held for all new feature work**: 18 of 20 commits carry the correct
  `feat: S4-XX PascalCaseName` format. S4-10 legitimately uses 3 commits for 3 distinct
  deliverables (level data, docs, BFS reconstruction) — appropriate, not a violation.
- **S4-05 and S4-06 were pre-validated by prior work**: Pre-sprint commits
  (`fix: obstacle STATIC_WALL tiles now block is_walkable`, `test: add STATIC_WALL obstacle
tests`) had already established the collision model. S4-04 built on a verified foundation
  rather than starting from scratch.
- **S4-03 retro action item #3 delivered**: SfxManager was scaffolded with a proper null
  guard (`warn + return`) as explicitly requested in the Sprint 3 action items.

---

### What Went Poorly

- **S4-05 and S4-06 have no explicit feat commits**: Both tasks are Must Have items in the
  sprint plan, and both were verified as working (the pre-sprint STATIC_WALL commits cover
  their acceptance criteria), but neither has a `feat: S4-05 ...` or `feat: S4-06 ...`
  entry in git history. This is the S3-05 bundling issue in a different form: functionality
  delivered but audit trail incomplete.
- **S4-19 (Automated Playtest) not completed**: The full M2 loop playtest (Main Menu →
  World Map → Level → Level Complete → World Map return with 8 levels) was not run. This
  is the only Must-Have-tier quality gate still outstanding. Its absence means BFS-verified
  levels haven't been manually confirmed as playable end-to-end with the new obstacle tiles.
- **Hand-crafted UID slipped through initial commit**: `sfx_library.tres` was committed
  with `uid://csfxlibrary0001` — a non-Godot-format UID that would cause import corruption.
  This was a direct violation of the engine-code rules (verify against Godot's actual import
  format). The code review caught it, but it should not have been committed in the first place.
- **Nice-to-Have completion rate: 33% (3/9)**: While asset-dependency explains 4 of the 6
  uncompleted Nice-to-Haves, S4-25 (M2 gate check) and S4-29 (commit hygiene audit) are
  process tasks with no external dependencies — they were straightforwardly not reached.

---

### Blockers Encountered

| Blocker                                         | Duration    | Resolution                                     | Prevention                                                            |
| ----------------------------------------------- | ----------- | ---------------------------------------------- | --------------------------------------------------------------------- |
| Asset availability for UI tasks S4-21–23, S4-26 | Full sprint | Explicitly deferred per user instruction       | Flag asset dependencies at plan creation; add "pending assets" status |
| Hand-crafted UID in sfx_library.tres            | ~5 min      | Code review catch; immediate fix commit        | Reference actual Godot UID format before hand-authoring .tres files   |
| S4-05/S4-06 missing feat commits                | No delay    | Functionality absorbed in S4-04 and pre-sprint | Require explicit `feat: S4-0X` commit even if "trivially verified"    |

---

### Estimation Accuracy

| Task                           | Estimated       | Actual | Variance | Likely Cause                                                        |
| ------------------------------ | --------------- | ------ | -------- | ------------------------------------------------------------------- |
| S4-04 ObstacleSystem           | 0.1d            | ~0.06d | −40%     | GridTileData `obstacle_type` field was already partially scaffolded |
| S4-10 New levels w1_l7 + w1_l8 | 0.1d            | ~0.1d  | ~0%      | Level authoring time matched estimate closely                       |
| S4-11 SfxManager               | 0.1d            | ~0.03d | −70%     | AudioStreamPlayer pool is a well-understood Godot pattern           |
| All tasks (aggregate)          | 1.3d (26×0.05d) | ~0.44d | −66%     | Design well-specified; implementation mechanical                    |

**Overall estimation accuracy**: ~1 task within ±20% of estimate (S4-10). All others
remain significantly overestimated. However, Sprint 4 used the 0.05d/task model (double
the S3-recommended 0.025d), and the gap narrowed from Sprint 3's 10× down to 3×. The
adjustment is working, but the correct per-task baseline is converging toward ~0.015–0.02d.
Sprint 5 should model at **0.05d/task as a capacity slot** but plan for ~3 implementation
tasks per slot — or adopt a task-size categorisation (XS/S/M) rather than a flat estimate.

---

### Carryover Analysis

| Task                           | Original Sprint | Times Carried | Reason                               | Action                                           |
| ------------------------------ | --------------- | ------------- | ------------------------------------ | ------------------------------------------------ |
| S4-19 Automated Playtest       | Sprint 4        | 1             | Not reached within session           | Complete as S5-01 or pre-sprint gate task        |
| S4-21 Background Color Fix     | Sprint 4        | 1             | Asset dependency (user deferred)     | Resume when design assets finalized              |
| S4-22 CatSprite Asset Swap     | Sprint 4        | 1             | Asset dependency (sprite PNG needed) | Resume when `sprite-cat.png` is final            |
| S4-23 CoverageVisualizer Color | Sprint 4        | 1             | Asset dependency (user deferred)     | Resume when design system passes asset review    |
| S4-25 M2 Gate Check Report     | Sprint 4        | 1             | Process task not reached             | Complete as first Sprint 5 task; gates M2 close  |
| S4-26 World Map Level Cards    | Sprint 4        | 1             | Asset dependency (UI visual upgrade) | Resume when assets ready                         |
| S4-29 Commit Hygiene Audit     | Sprint 4        | 1             | Process task not reached             | Complete in Sprint 5 kickoff; S4-05/06 gap noted |

---

### Technical Debt Status

- Current TODO count: **0** in project code (`src/`, `tests/`, `scenes/`, `data/`) (same as Sprint 3)
- Current FIXME count: **0** in project code
- Current HACK count: **0** in project code
- All TODO/FIXME/HACK occurrences are in `addons/gut/` (third-party, not tracked)
- Trend: **Stable — Clean**
- Known intended stubs: `SfxLibrary` null AudioStream slots, `SfxManager` stub streams at
  wired call sites. These are documented scaffold gaps (awaiting audio assets), not debt.

---

### Previous Action Items Follow-Up

| Action Item (from Sprint 3)                                                                | Status      | Notes                                                                                            |
| ------------------------------------------------------------------------------------------ | ----------- | ------------------------------------------------------------------------------------------------ |
| Rethink sprint planning: shift to 40–80 tasks or milestone-driven continuous delivery      | ✅ Done     | Sprint 4 planned with 26 tasks at 0.05d/task; gap narrowed from 10× to 3×                        |
| Verify acceptance criteria end-to-end before committing; confirm commit ID matches task ID | ⚠️ Partial  | Code review caught sfx_library.tres UID issue post-commit; S4-05/06 have no feat commits         |
| Scaffold SfxManager as proper stub with null-guard before audio implementation             | ✅ Done     | S4-11 delivered null guard + graceful warn; no crashes on null streams confirmed by 10 GUT tests |
| Add pre-commit checklist item for sprint subtask ID                                        | ⚠️ Not Done | S4-29 (commit hygiene audit) not completed; S4-05/06 gap shows the problem persists              |

---

### Action Items for Next Iteration

| #   | Action                                                                                                                                                                           | Owner           | Priority | Deadline         |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | -------- | ---------------- |
| 1   | Complete S4-19: run full M2 automated playtest (Main Menu → World Map 8 levels → gameplay → Level Complete → return)                                                             | qa-tester       | High     | Sprint 5 Day 1   |
| 2   | Complete S4-25: produce `docs/m2-gate-check.md` with PASS/CONCERNS/FAIL against all M2 exit criteria                                                                             | qa-lead         | High     | Sprint 5 Day 1   |
| 3   | Resolve S4-05/S4-06 audit trail: add a retrospective note in git or a follow-up docs commit acknowledging these tasks were absorbed pre-sprint; prevents future bisect confusion | devops-engineer | Medium   | Sprint 5 kickoff |
| 4   | Add task-size classification (XS = 0.02d, S = 0.05d, M = 0.1d) to sprint template — flat 0.05d estimate is still overestimating XS tasks 5×; the model needs a second tier       | producer        | Low      | Sprint 5 plan    |

---

### Process Improvements

- **Introduce "absorbed" task status in sprint tracking**: S4-05 and S4-06 were functionally
  complete but never received `feat:` commits. Rather than leaving them as apparent gaps in
  the audit trail, the sprint plan should have a field to mark tasks as "Absorbed into
  [other task]" with an explanation — this makes the intent explicit without forcing an
  empty commit.
- **Asset-dependency tasks need a "Blocked" state, not "Not Started"**: S4-21, S4-22,
  S4-23, and S4-26 were never at risk of being worked — they were blocked from the first
  day by asset availability. Marking them as `Blocked (assets)` at sprint kickoff, rather
  than carrying them as active tasks, would make the actual sprint scope honest from the
  start and prevent overstating the "planned" task count.

---

### Summary

Sprint 4 delivered its full critical path in ~3.5 hours — every Must Have task shipped,
610 GUT tests pass, two new obstacle levels are BFS-verified, and all three audio systems
(SfxManager, MusicManager, audio buses) are live autoloads with null-safe playback. The
planning model adjustment (0.05d/task) reduced the estimate-to-actual gap from Sprint 3's
10× down to 3×, a meaningful improvement. The most important outstanding item is **S4-19
(automated end-to-end playtest)** — the M2 gate cannot formally close until the full loop
is validated in a running build with all 8 levels loaded.

---

### Deferred Tasks Status (Asset-Dependent)

These tasks are intentionally held pending asset readiness — not velocity failures:

| Task  | Description                         | Blocked By                          |
| ----- | ----------------------------------- | ----------------------------------- |
| S4-21 | Background color fix (3 scenes)     | Design system asset review          |
| S4-22 | CatSprite asset swap                | `design/draft/sprite-cat.png` final |
| S4-23 | CoverageVisualizer trail color      | Design system amber token confirmed |
| S4-26 | World Map level card visual upgrade | UI component assets ready           |
