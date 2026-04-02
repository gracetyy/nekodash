# Milestone Review: M2 — Submission Ready

## Overview

- **Target Date**: 2026-04-14
- **Current Date**: 2026-04-02
- **Days Remaining**: 12
- **Sprints Completed**: 1 / 2 (Sprint 3 ✅ · Sprint 4 not started)
- **Exit Criteria Met**: 14 / 20 (70%)

---

## Feature Completeness

### Fully Complete

| Feature                             | Acceptance Criteria                                                                                                                         | Test Status                                    |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| SaveManager disk persistence        | `save_game()` / `load_game()` persist to `user://nekodash_save.json`; version 1; corruption recovery to fresh save + `.corrupt.json` rename | 35 tests (S3-03, S3-08)                        |
| World Map scene                     | `res://scenes/ui/world_map.tscn` navigable; unlock state + star count from SaveManager; tap → gameplay; back → Main Menu stub               | 13 tests (S3-04, S3-09)                        |
| World Map button (Bug #3)           | "World Map" on Level Complete screen routes to `world_map.tscn` via `SceneManager.go_to(Screen.WORLD_MAP)`                                  | Covered in test_level_coordinator              |
| Star icons — size + colour (Bug #5) | ≥48×48 logical px; gold when earned, grey when unearned                                                                                     | Visual confirmed via S3-12 playtest screenshot |
| Star rating thresholds balanced     | 3-star threshold achievable without perfect foreknowledge on w1_l4–w1_l6; `star_3_moves` offsets adjusted; BFS re-verified                  | S3-10; BFS solver confirmed                    |
| TD-001                              | `test_level_data.gd:243` type annotation fixed; zero SCRIPT ERRORs on full GUT run                                                          | 509/509 tests clean                            |
| TD-002                              | Dead overlay block (~122 lines) removed from `level_coordinator.gd`                                                                         | No regression in 24 coordinator tests          |
| TD-003                              | SaveManager real disk I/O (replaces stub)                                                                                                   | Same as SaveManager row above                  |
| TD-006                              | Ownership headers on `playtest_capture.gd` and `playtest_runner.gd`; tech-debt register updated                                             | S3-11                                          |
| 0 open Severity-1 bugs              | None open                                                                                                                                   | —                                              |
| 0 open Severity-2 bugs              | None open                                                                                                                                   | —                                              |
| GUT tests ≥500 passing              | 509 passing, 0 failing, 998 asserts                                                                                                         | Current run (post-obstacle fix)                |
| Automated playtest all levels PASS  | 6/6 World 1 levels: 3-star; 37 screenshots; World Map star display confirmed                                                                | S3-12                                          |
| 0 TODO/FIXME/HACK in src + tests    | Confirmed 0 via grep across all `.gd` files                                                                                                 | Sprint 3 + code review verified                |

### Partially Complete

| Feature                        | % Done | Remaining Work                                                                                                                                                                                                                                  | Risk to Milestone                                                                                       |
| ------------------------------ | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Obstacle System — static walls | ~55%   | `is_walkable()` and `LevelSolver._is_walkable()` now block STATIC_WALL tiles (fixed in today's code review). **Remaining**: ≥2 World 1 levels authored with STATIC_WALL placements; BFS-verified `minimum_moves` re-calculated for those levels | Medium — requires level design decisions + BFS verification; time-boxed by available creative bandwidth |

### Not Started

| Feature                             | Priority | Can Cut?                                                                             | Impact of Cutting                                                                                                  |
| ----------------------------------- | -------- | ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Main Menu scene                     | Critical | **No** — it is an M2 exit criterion and the game's entry point                       | Players boot into gameplay.tscn directly; game is not submittable as a jam entry without an entry-point scene      |
| w1_l4–w1_l6 route-fork redesign     | High     | **No** — required for M2 level content criterion                                     | Levels currently have no meaningful choice points; 3-star is achievable by rote; design quality criterion unmet    |
| 8+ total levels (currently 6)       | High     | **Conditional** — can cut to "levels with obstacles" if obstacle levels count as 7+8 | If 2 new obstacle-using levels are authored, this criterion is met concurrently with the Obstacle System criterion |
| SFX Manager (≥4 SFX wired)          | High     | **No** — explicit M2 exit criterion                                                  | Submission is playable but silent; acceptable for jam only if noted in description; judge perception risk          |
| Music Manager (≥1 background track) | Medium   | **Conditional** — M2 says "stub or production"                                       | A no-op autoload that compiles cleanly satisfies the criterion; audio _assets_ can be deferred                     |

---

## Quality Metrics

- **Open S1 Bugs**: 0
- **Open S2 Bugs**: 0
- **Open S3 Bugs**: 0
- **Test Count**: 509 passing / 0 failing / 998 asserts (as of 2026-04-02 post-obstacle code review)
- **Test Coverage**: 17 / 19 production source files have dedicated test coverage (89%)
  - Untested: `cat_sprite.gd` (visual only), `grid_renderer.gd` (visual only) — both TD-005, backlog-priority
- **Performance**: Within budget — no frame-rate issues reported; mobile swipe (TRANS_QUAD, 25 t/s mobile) locked and validated in Sprint 2

---

## Code Health

- **TODO count**: **0** across src, tests, tools
- **FIXME count**: **0**
- **HACK count**: **0**
- **Technical debt items open**:
  - **TD-004** (Medium priority): `level_coordinator.gd` is 530 lines; `_connect_signals()` / `_disconnect_signals()` are structural mirrors with 17 paired signal operations each. Not blocking M2; monitor at Sprint 4 when audio + nav systems connect signals.
  - **TD-005** (Low priority): No dedicated test file for `cat_sprite.gd` or `grid_renderer.gd` (visual-only nodes). Backlog; does not affect M2 criteria.

---

## Risk Assessment

| Risk                                                          | Status                 | Impact if Realized                                                      | Mitigation Status                                                                                                                                     |
| ------------------------------------------------------------- | ---------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| R-06: Jam deadline scope creep                                | Open                   | Skins tier or new systems slip into Sprint 4 and crowd out audio/levels | MVP-Skins explicitly excluded from M2; no new systems without producer sign-off                                                                       |
| R-13: Obstacle System touches GridSystem + LevelData          | **Partially resolved** | Breaking change to 509 tests                                            | `is_walkable()` and `LevelSolver._is_walkable()` fixed additively today; all 509 tests pass; remaining work is level content, not API                 |
| R-14: Level redesign invalidates BFS-verified `minimum_moves` | Open — Sprint 4 action | Obstacle levels ship with wrong `minimum_moves`; 3-star threshold wrong | Fixed solver ready; must run `godot --headless -s tools/level_solver.gd` on every redesigned `.tres` before commit                                    |
| R-15: SaveManager corruption/migration edge cases             | **Resolved**           | Save corruption on launch; player loses progress                        | 35 tests including corruption recovery, version mismatch, sentinel; graceful fallback implemented                                                     |
| R-16: Audio assets unavailable                                | Open                   | SfxManager and MusicManager compile but produce silence                 | M2 criterion allows "stub or production" for Music; SFX Manager must not crash on missing assets; CC0 placeholders on itch.io are acceptable fallback |

---

## Velocity Analysis

- **Planned vs Completed** (across Sprint 1–3): 43 / 43 tasks = **100%** across all three sprints
- **Trend**: Stable at 100% — three consecutive sprints all delivered on Day 1 of a 5-day window

| Sprint   | Planned | Completed         | Actual Days | Allocated Days | Ratio |
| -------- | ------- | ----------------- | ----------- | -------------- | ----- |
| Sprint 1 | 9       | 11 (+2 unplanned) | <1          | 5              | ~10×  |
| Sprint 2 | 9       | 18 (+9 unplanned) | 1.5         | 5              | ~3×   |
| Sprint 3 | 16      | 16                | 0.4         | 5              | ~12×  |

- **Effective velocity**: ~10–40 tasks/actual calendar day
- **Sprint 4 workload estimate**: 10–14 tasks (Main Menu, 2+ obstacle levels, 2 new levels, SFX Manager, Music Manager stub, route-fork redesigns, BFS re-verification, tests) — at historical velocity, **0.5–1.5 actual days to complete**
- **Adjusted estimate for remaining work to M2 close**: 1–2 calendar days, leaving 10+ days of buffer before April 14 target

---

## Scope Recommendations

### Protect (Must ship with milestone)

- **Obstacle System levels** — the code fix is in; the content is not. Two obstacle-using levels are the only tangible evidence of the M2 "Obstacle System" criterion being met for a judge/player. Cannot cut.
- **Main Menu scene** — game entry point. A submittable jam build starts here. Without it, the game is reached only by running `gameplay.tscn` directly.
- **SFX Manager** — 4 SFX wired is a low-effort, high-perception item. Slide sound alone transforms the feel of the game. Pre-built Godot `AudioStreamPlayer` + CC0 `.ogg` file takes under 30 minutes. Risk of cutting: silent game at jam.

### At Risk (May need to cut or simplify)

- **w1_l4–w1_l6 route-fork redesign** — requires creative design judgment, not just code. If fork design adds a day of iteration, the criterion may arrive after obstacle levels and crowd Sprint 4. Strategy: treat this as "add one meaningful fork per level" rather than full redesign; current grid sizes support this without rethinking layout.
- **Music Manager with actual audio** — the M2 criterion explicitly allows a stub. A no-op `MusicManager` autoload (emits signals, plays nothing) satisfies the criterion. Audio assets remain a nice-to-have.

### Cut Candidates (Can defer without compromising milestone)

- **TD-004 refactor** (`level_coordinator.gd` signal pairing) — not an M2 criterion; healthy at current scale; defer to Sprint 5 or World 2 expansion
- **TD-005 visual tests** (`cat_sprite.gd`, `grid_renderer.gd`) — backlog; visual regressions caught by playtest screenshot review
- **MVP-Skins tier** (Cosmetic DB, Skin Unlock, Skin Select Screen) — explicitly excluded from M2 by milestone definition; confirmed cut for this milestone

---

## Go/No-Go Assessment

**Recommendation**: **CONDITIONAL GO**

**Conditions** (must all be met before M2 is declared GO):

1. `res://scenes/ui/main_menu.tscn` exists as game entry point with a functional "Play → World Map" route
2. At least 2 World 1 levels include authored STATIC_WALL obstacle placements, each BFS-verified post-edit
3. Total level count reaches ≥8 (currently 6; 2 new obstacle-featuring levels satisfy this concurrently with condition 2)
4. `SfxManager` autoload exists and plays at minimum `slide_move` + `level_complete` without crashing on missing audio files
5. `MusicManager` autoload exists and compiles cleanly (stub acceptable per M2 definition)
6. w1_l4–w1_l6 each have at least one documented route fork in their `.tres` or level-design notes

**Rationale**: Sprint 3 delivered 16/16 tasks at 100% on Day 1 of a 5-day window. 14 of 20 M2 exit criteria are fully met. The 6 remaining criteria are all Sprint 4 scope — none depend on unsolved technical problems. The Obstacle System code blocker (the `is_walkable()` bug) that was identified in the gate check is now fixed. At historical velocity, Sprint 4 completes all remaining work in 1–2 actual days, leaving ≥10 days of buffer before the April 14 target. The only genuine uncertainty is audio asset sourcing (R-16), which is mitigated by the M2 definition explicitly allowing stubs.

---

## Action Items

| #   | Action                                                                                                                                                    | Owner                           | Deadline                          |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | --------------------------------- |
| 1   | Plan Sprint 4 — scope Main Menu, obstacle levels (×2), total levels ≥8, SFX Manager, Music stub, route-fork redesigns, BFS re-verification                | Producer                        | Before first Sprint 4 task starts |
| 2   | Source or create CC0 SFX assets (`slide_move`, `level_complete`, `star_earned`, `button_tap`) — at minimum generate placeholder silence-free `.ogg` files | Audio Director / Sound Designer | Sprint 4 Day 1                    |
| 3   | Design 2 World 1 obstacle levels with STATIC_WALL placements; run BFS solver to verify `minimum_moves` before committing `.tres`                          | Game Designer + Level Designer  | Sprint 4                          |
| 4   | Add route-fork choice point to w1_l4, w1_l5, w1_l6 — each level must have ≥1 path branch where a suboptimal route is reachable                            | Level Designer                  | Sprint 4                          |
| 5   | Implement `Main Menu` scene at `res://scenes/ui/main_menu.tscn` — Play → World Map route; game title + icon                                               | UI Programmer                   | Sprint 4                          |
| 6   | Monitor TD-004 at Sprint 4 close — if `level_coordinator.gd` grows past 600 lines from audio/nav signal connections, schedule refactor for Sprint 5       | Lead Programmer                 | Sprint 4 close                    |
| 7   | Update risk register: close R-13 (partially resolved), update R-14 status when obstacle levels are authored                                               | Producer                        | Sprint 4 close                    |
