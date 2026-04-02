## Retrospective: Sprint 3

Period: 2026-04-02 — 2026-04-02 (all tasks completed Day 1 of 5-day allocation)
Generated: 2026-04-02

---

### Metrics

| Metric                    | Planned              | Actual          | Delta   |
| ------------------------- | -------------------- | --------------- | ------- |
| Tasks (Must Have)         | 7                    | 7               | 0       |
| Tasks (Should Have)       | 4                    | 4               | 0       |
| Tasks (Nice to Have)      | 5                    | 5               | 0       |
| Total Tasks               | 16                   | 16              | 0       |
| Completion Rate           | —                    | 100%            | —       |
| Effort Days Allocated     | 5 (4 net + 1 buffer) | ~0.4 actual     | −4.6d   |
| Carryover Tasks IN        | 2 (from S2 retro)    | 0 (both closed) | −2      |
| Unplanned Tasks Added     | —                    | 0               | —       |
| GUT Tests at Sprint Close | ~500 (milestone)     | 503             | +3      |
| Tests Delta vs Sprint 2   | —                    | +39 (464 → 503) | —       |
| Bugs Fixed                | —                    | 2 (Bug #3, #5)  | —       |
| TD Items Resolved         | —                    | 4 (TD-001–003, TD-006) | —  |
| Commits (sprint tasks)    | —                    | 13              | —       |

---

### Velocity Trend

| Sprint        | Planned Tasks | Completed                  | Rate |
| ------------- | ------------- | -------------------------- | ---- |
| Sprint 1      | 9             | 11 (+ 2 unplanned)         | 100% |
| Sprint 2      | 9             | 18 (+ 9 unplanned)         | 100% |
| Sprint 3      | 16            | 16 (+ 0 unplanned)         | 100% |

**Trend**: Stable at 100% completion rate.
Three consecutive sprints at 100% completion, all delivered in Day 1 of a 5-day window.
Sprint 3 was properly sized to 16 tasks (as recommended by S2 retro) and still concluded in
~4 hours — confirming the structural gap between plan-time and actual capacity is not
narrowing. With zero unplanned absorption for the first time, Sprint 3 also confirms the
team is no longer generating organic scope expansion; the backlog is well-defined.

---

### What Went Well

- **16/16 tasks completed in ~4 hours** (14:02–18:10 on April 2). All three tiers — Must
  Have, Should Have, and Nice to Have — fully delivered on the first calendar day of a
  5-day sprint for the third consecutive sprint.
- **Sprint 2 action items largely resolved (4/5)**: `test_level_data.gd:243` SCRIPT ERROR
  fixed (S3-01, carried twice from S1), dead overlay code removed (S3-02), sprint sized to
  16 tasks as recommended, and sprint retrospective filed on the same day as delivery.
- **Full technical debt clearance**: TD-001, TD-002, TD-003, and TD-006 all resolved and
  closed in the tech-debt register. Zero TODO/FIXME/HACK comments remain in the entire
  codebase — a clean slate heading into Sprint 4.
- **Automated playtest confirmed full loop integrity**: PlaytestRunner ran all 6 World 1
  levels in sequence, achieving 3-star on every level, capturing 37 screenshots with zero
  crashes. World Map star display confirmed via `--write-movie` screenshot. The automated
  playtest infrastructure is now end-to-end validated.
- **SaveManager real I/O shipped with 11 persistence tests**: roundtrip, corruption
  recovery, version mismatch, and sentinel cases all covered. This was the highest-risk
  task (R-15: corruption edge case) and was delivered with dedicated test coverage.
- **503 GUT tests, 984 asserts, zero failures**: The 500-test milestone (S3-15) was
  reached organically, arriving at 503 without needing a dedicated test-writing push.
- **One-commit-per-subtask convention mostly held**: 13 of 16 tasks that required code
  changes each received a properly named `feat: S3-0X PascalCaseName` commit. Improvement
  from Sprint 2 where LevelProgression was swallowed by a different commit entirely.

---

### What Went Poorly

- **S3-05 bundled into "S3-04 BugFixesAndExitButton" commit**: Sprint 2 action item #4
  explicitly called out "enforce one-commit-per-sprint-sub-task — no bundling." Despite
  this, S3-05 (Wire World Map button in LevelCompleteScreen) was delivered inside a commit
  labeled `S3-04`. The commit message names the wrong task ID and doesn't surface S3-05 in
  `git log`. This is a direct recurrence of the issue that generated the action item.
  Impact: minor for this sprint, but bisecting a future LevelCompleteScreen regression
  would require inspecting the wrong commit.
- **Systematic overestimation remains uncorrected**: Sprint 2 retro explicitly stated 0%
  of tasks were within ±20% of estimate and recommended a 75% cut. Sprint 3 allocated
  4 net days for 16 × 0.25d tasks; actual delivery was ~0.4 days. That is a 10× gap,
  worse than Sprint 2's 3–5× gap because the task count tripled but the calendar time did
  not increase proportionally. The 0.25d/task baseline is no longer empirically defensible.
- **WorldMap scene required a follow-up fix commit in the same session**: `feat: S3-04
  WorldMapScene` was committed at 16:04, then `feat: S3-04 BugFixesAndExitButton` arrived
  at 16:50 — 46 minutes later — to complete exit-button wiring and Bug #3. This suggests
  the initial WorldMap delivery was incomplete at commit time; the acceptance criteria
  (back button wiring) was not verified end-to-end before the first commit.
- **S3-12 acceptance criteria gap identified mid-review**: The playtest ran
  gameplay → level_complete × 6 but never navigated to World Map, missing the acceptance
  requirement for "screenshot showing World Map with completed level star count." The gap
  was caught in code review and remedied with a `--write-movie` capture, but it should
  have been caught during implementation.

---

### Blockers Encountered

| Blocker                                                     | Duration  | Resolution                                                                 | Prevention                                                                   |
| ----------------------------------------------------------- | --------- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `godot --headless` silently exited with no output for S3-12 | ~10 min   | Ran in windowed mode (non-headless) using async terminal; full output captured | Add headless-vs-windowed check to playtest workflow documentation              |
| S3-12 acceptance gap: no World Map screenshot in run        | ~5 min    | `--write-movie` capture of world_map.tscn after save data was populated   | Always read acceptance criteria verbatim before marking a task complete        |

---

### Estimation Accuracy

| Task                             | Estimated | Actual | Variance | Likely Cause                                                            |
| -------------------------------- | --------- | ------ | -------- | ----------------------------------------------------------------------- |
| S3-03 SaveManagerDiskIO          | 0.5d      | ~0.08d | −84%     | JSON format and error recovery pattern both pre-specified in GDD        |
| S3-04 WorldMapScene              | 0.5d      | ~0.1d  | −80%     | LevelCatalogue API and SceneManager contract were fully defined         |
| S3-01 FixTestLevelDataTypeError  | 0.25d     | ~0.02d | −92%     | Single type annotation change — smallest possible fix                   |
| S3-08 SaveManagerPersistenceTests| 0.25d     | ~0.05d | −80%     | Test pattern established; 11 cases written quickly against known API    |
| All tasks (aggregate)            | 4.0d      | ~0.4d  | −90%     | All systems have approved GDDs; implementation is mechanical not design |

**Overall estimation accuracy**: 0% of tasks within ±20% of estimate (third consecutive sprint).
The pattern is now unambiguously structural: every task is completed in 8–15% of its
estimated time. The 0.25d/task floor was set conservatively in Sprint 1 and has never been
revised despite three sprints of data. The working hypothesis is that `0.025d` (~12 minutes)
is a more accurate per-task baseline for well-specified implementation work. Sprint 4
planning should model at ~0.05d/task (adding a 2× buffer) and plan for 40–80 tasks to
fill a nominal 4-day sprint, or shift to a milestone-driven continuous-delivery model
rather than time-boxed sprints.

---

### Carryover Analysis

| Task                                 | Original Sprint | Times Carried | Reason                                         | Action                    |
| ------------------------------------ | --------------- | ------------- | ---------------------------------------------- | ------------------------- |
| test_level_data.gd:243 SCRIPT ERROR  | Sprint 1        | 2             | Deprioritised twice in favour of feature work  | ✅ Resolved as S3-01      |
| Dead overlay code in level_coordinator | Sprint 2      | 1             | Explicit S2 retro action item                  | ✅ Resolved as S3-02      |

No tasks carry over from Sprint 3 into Sprint 4. Carryover rate: 0%.

---

### Technical Debt Status

- Current TODO count: **0** (previous Sprint 2 close: ~0 in tracked files, 0 in src/)
- Current FIXME count: **0**
- Current HACK count: **0**
- TD register: 4 items resolved this sprint (TD-001, TD-002, TD-003, TD-006)
- Trend: **Shrinking → Clean**
- No open tech debt items remain in the register. Codebase enters Sprint 4 with a clean
  slate. New debt will likely be introduced when audio (SfxManager stub) and obstacle
  systems are scaffolded in Sprint 4.

---

### Previous Action Items Follow-Up

| Action Item (from Sprint 2)                                                        | Status         | Notes                                                                                           |
| ---------------------------------------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------- |
| Fix `test_level_data.gd:243` SCRIPT ERROR as explicit sprint task                 | ✅ Done        | S3-01 resolved with single type-annotation fix; zero SCRIPT ERRORs on full test run            |
| Plan Sprint 3 with ≥16 tasks (0.25d/task baseline)                                | ✅ Done        | Sprint 3 shipped with exactly 16 tasks; recommendation followed precisely                       |
| Remove dead overlay code in `level_coordinator.gd`                                | ✅ Done        | S3-02 removed all 5 dead symbols (~122 lines); no regressions                                  |
| Enforce one-commit-per-sprint-sub-task policy (no bundling)                       | ⚠️ Partial     | 13/14 code tasks had correct commits; S3-05 was bundled into S3-04 commit, a direct recurrence |
| Run sprint retrospective within 24h of all-tasks-complete                         | ✅ Done        | Filed same day (April 2), ~2 hours after final commit                                          |

---

### Action Items for Next Iteration

| #   | Action                                                                                                                            | Owner                     | Priority | Deadline         |
| --- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | -------- | ---------------- |
| 1   | Rethink sprint planning model: shift to 40–80 tasks OR milestone-driven continuous delivery; the 16-task / 5-day box is exhausted | producer                  | High     | Sprint 4 kickoff |
| 2   | Enforce S3-05 lesson: verify acceptance criteria end-to-end before committing; confirm commit ID matches sprint task ID           | all                       | High     | Sprint 4 Day 1   |
| 3   | Scaffold SfxManager as a proper stub (not-crash on missing audio) before Sprint 4 audio implementation begins; document the stub contract | audio-director    | Medium   | Sprint 4 Day 1   |
| 4   | Add a pre-commit checklist item: "commit message contains correct sprint subtask ID (not a related task's ID)"                    | devops-engineer           | Low      | Sprint 4 kickoff |

---

### Process Improvements

- **Retire the 0.25d/task estimate baseline**: Three sprints of actuals show 0.02–0.08d per
  well-specified task. Keep 0.25d as a planning slot size but acknowledge it represents 3–5
  implementation tasks, not one. Sprint 4 should be planned as a continuous delivery queue
  with explicit milestone gates rather than a time-boxed sprint with fixed task counts.
- **Acceptance-criteria-first commitment**: Before committing a task as complete, read the
  acceptance criteria verbatim and verify each bullet. The S3-12 gap (World Map screenshot
  missing from playtest output) was caught in code review rather than during implementation
  because the acceptance criteria wasn't checked until review. This could have been a miss.

---

### Summary

Sprint 3 is the cleanest sprint to date: 16/16 tasks at 100% completion, zero carryover
into Sprint 4, four technical debt items closed, and the codebase now has zero TODO/FIXME
comments. The Sprint 2 retro recommendation to triple task count was followed precisely and
still delivered in ~4 hours — confirming the velocity gap is structural, not incidental.
The single most important change for Sprint 4 is to **abandon time-boxed sprints in favour
of a milestone-driven continuous delivery queue**: three sprints of data prove that
task-count planning consistently under-fills available capacity by 10×, wasting planning
overhead on a model that no longer reflects how the team actually works.
