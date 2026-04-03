# Milestone Review: M3 — Polish & Release

## Overview

- **Target Date**: 2026-04-28
- **Current Date**: 2026-04-03
- **Days Remaining**: 25
- **Sprints Completed**: 0 / 2 (Sprint 5 not started · Sprint 6 not started)
- **Exit Criteria Met**: 0 / 16 (0%) — M3 opens at Sprint 5 kickoff
- **Current Stage**: `Polish` (advanced from `Production` at M2 gate check)

---

## Feature Completeness

### Fully Complete

_(All items below were completed during M2 and are carry-forwards with no regressions
permitted.)_

| Feature                             | Acceptance Criteria                                                                        | Test Status                 |
| ----------------------------------- | ------------------------------------------------------------------------------------------ | --------------------------- |
| SaveManager disk persistence        | `nekodash_save.json` round-trips across restart; corruption recovery                      | 35 tests clean              |
| Obstacle System                     | Static walls block movement; 6/8 levels use obstacles; BFS verified                       | S4-15 + 610 total           |
| World Map navigation                | Unlock state, star count, level tap, back button                                           | 13 tests clean              |
| Main Menu entry point               | Play / Skins buttons; NekoDash title; cat sprite placeholder                               | Visual confirmed S4-19      |
| SFX Manager                         | Autoload; pool; 4 wired call sites; null guard; bus routing                                | S4-16 + 610 total           |
| Music Manager                       | Autoload; transition_completed subscribed; null guard; cross-fade framework                | S4-17 + 610 total           |
| 8 World 1 levels (BFS-verified)     | w1_l1–w1_l8; minimum_moves confirmed; route forks in l4–l8                                | test_level_data 610 total   |
| GUT test suite ≥610                 | 610 passing / 0 failing / all 21 scripts                                                   | ✅ confirmed                 |
| All TD-001/002/003/006 resolved     | Zero SCRIPT ERRORs; zero dead overlay code; real save I/O; playtest tool ownership        | Confirmed at M2 gate check  |

### Partially Complete

| Feature                            | % Done | Remaining Work                                                                                               | Risk to Milestone |
| ---------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------ | ----------------- |
| Visual polish — backgrounds        | 0%     | Swap near-black → cream `#F5EDCC` in `main_menu.tscn`, `world_map.tscn`, `level_complete.tscn` (S4-21)     | Low — code change only; blocked on producer confirmation of colour spec |
| CatSprite final art                | 10%    | Replace emoji placeholder with final PNG; keep GDScript fallback behind debug flag (S4-22)                  | Medium — blocked on art asset delivery |
| Coverage trail colour              | 0%     | `coverage_visualizer.gd` trail `Color("#F5C842", 0.6)`; paw stamp documented as future (S4-23)             | Low — code change only; 1-line edit |
| Tile atlas — real art              | 5%     | `grid_system.gd` placeholder mapping replaced with final tile atlas sprites                                  | High — blocked on art asset delivery; no art = cannot ship |
| World Map level cards              | 30%    | Unlock state + lock icon ✅; level number ✅ (partial — L1 and L8 only in screenshots); star count per card; PanelContainer styling (S4-26) | Low — code work only; no asset dependency |
| SFX — real assets                  | 20%    | `sfx_library.tres` 4 null slots need real/CC0 AudioStream files wired; SfxManager framework is complete     | Medium — blocked on audio file sourcing |
| Music — real assets                | 10%    | `music_manager.gd` null stubs need real/CC0 track(s); framework is complete; signal subscription live       | Medium — blocked on audio file sourcing |
| Export builds                      | 0%     | `export_presets.cfg` needs Android + Web targets; one verified export build                                  | Low — well-documented in Godot 4.3 docs |
| Jam metadata                       | 0%     | itch.io page title, description, cover art, controls; submission form                                        | Low — external task |

### Not Started

| Feature                          | Priority    | Can Cut?                                                                       | Impact of Cutting                                                         |
| -------------------------------- | ----------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| Level Complete — level name      | High        | **No** — medium severity bug from M2 playtest report; data already in params   | Players lose positional context on Level Complete across back-to-back runs |
| TD-004 decision (LevelCoordinator) | Medium    | **No** — must be recorded (refactor or re-accept with rationale)               | Unrecorded debt risks unnoticed god object growth if bonus systems land    |
| Commit hygiene audit (S4-29)     | Low         | **Yes** — process only; no impact on shipped game                              | Missing sprint IDs in history; does not affect players                     |
| Cosmetic / Skin Database (bonus) | High (bonus) | **Yes** — explicitly excluded from M3 required criteria                       | No skin selection on Skins button; Screen.SKIN_SELECT stubs to no-op       |
| Skin Unlock Tracker (bonus)      | Medium (bonus) | **Yes** — requires Cosmetic DB                                               | No milestone-based skin unlocks                                            |
| Skin Select Screen (bonus)       | Medium (bonus) | **Yes** — requires both above + art assets                                   | Skins button on Main Menu navigates to no-op stub                          |

---

## Quality Metrics

- **Open S1 Bugs**: 0
- **Open S2 Bugs**: 0
- **Open S3 Bugs**: 0 (level name absent on Level Complete is Medium severity — tracked as S3 in M3 context)
- **Test Count**: 610 passing / 0 failing (M2 close baseline)
- **Test Coverage**: 22 / 24 production source files have dedicated test coverage (92%)
  - Untested: `cat_sprite.gd` (visual only — TD-005), `grid_renderer.gd` (visual only — TD-005)
- **Performance**: Within budget — TRANS_QUAD 15 t/s desktop / 25 t/s mobile locked and
  validated; no regressions reported in Sprint 4

---

## Code Health

- **TODO count**: 0 across `src/`, `tests/`
- **FIXME count**: 0
- **HACK count**: 0
- **Placeholder comments**: 3 (all intentional, all tracked)
  - `src/core/grid_system.gd:194` — "Atlas IDs are placeholders until Art Director defines the tile atlas" ← blocked on art
  - `src/core/music_manager.gd:37` — "Screen-to-track mapping (null stubs — awaiting real audio assets)" ← blocked on audio
  - `src/ui/level_complete_screen.gd:77` — "Stub SFX stream for star earned (replace with real audio asset later)" ← blocked on audio
- **Technical debt items open**:
  - **TD-004** (Medium) — `level_coordinator.gd` 530+ lines; _connect_signals / _disconnect_signals will grow with each new system. Decision required at M3 close.
  - **TD-005** (Low) — No test files for `cat_sprite.gd` or `grid_renderer.gd`. Backlog.

---

## Risk Assessment

| Risk                                                | Status  | Impact if Realized                                                       | Mitigation Status                                                                      |
| --------------------------------------------------- | ------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| R-06: Jam deadline scope creep                      | Open    | MVP-Skins or World 2 bloats Sprint 5, audio/polish slips                 | Skins and World 2 explicitly excluded from M3 required criteria                        |
| R-16: Audio assets not sourced                      | Open    | All SFX/music remain silent at jam submission                            | CC0 assets from freesound.org / opengameart.org defined as acceptable fallback         |
| R-17: Cat sprite art not delivered                  | Open    | Emoji placeholder at submission; "prototype" perception                  | Fallback: polished GDScript cat acceptable if PNG unavailable; confirm with art director |
| R-18: Tile atlas art not delivered                  | Open    | Dev placeholder tiles in shipped game; hard-blocker for M3 GO            | No fallback — must be resolved; highest external dependency risk                        |
| R-19: Android export fails                          | Open    | Cannot produce APK; must fall back to Web export for jam                 | Web export is pre-defined fallback; Godot 4.3 Web export is well-tested                |
| R-20: TD-004 grows to god object (World 2 path)     | Low     | LevelCoordinator becomes unmaintainable at World 2                       | World 2 excluded from M3; TD-004 decision must be recorded regardless                  |
| R-13: Obstacle System API stability                 | Closing | Sprint 4 confirmed no breakage; risk reduces to monitoring only          | 610 tests as regression guard; no further changes to is_walkable() API planned         |
| R-14: Level redesign invalidates BFS min_moves       | Closed  | No level redesigns planned for M3                                        | ✅ Closed — no content changes in scope                                                 |
| R-15: SaveManager corruption edge cases             | Closed  | 35 tests including corruption + version mismatch cover all paths         | ✅ Closed — confirmed at M2 gate check                                                  |

---

## Velocity Analysis

- **Planned vs Completed** (Sprints 1–4): 62 / 62 Must-Have tasks = **100%**; 73% total
  including Nice-to-Have
- **Trend**: Stable for all Must-Have delivery; Nice-to-Have rate blocked only by external
  asset availability (not velocity regression)

| Sprint   | Planned | Completed         | Actual Days | Ratio |
| -------- | ------- | ----------------- | ----------- | ----- |
| Sprint 1 | 9       | 11 (+2 unplanned) | <1          | ~10×  |
| Sprint 2 | 9       | 18 (+9 unplanned) | 1.5         | ~3×   |
| Sprint 3 | 16      | 16                | 0.4         | ~12×  |
| Sprint 4 | 26      | 19 committed      | ~0.44       | ~3×   |

- **Effective Must-Have velocity**: 0.025–0.05d/task
- **Sprint 5 workload estimate**: 10–14 tasks at 0.05d/task = 0.5–0.7 calendar days
- **Critical path**: Art and audio asset delivery is the only external dependency that
  could delay M3. Code work alone projects to <1 day at historical velocity.

---

## Scope Recommendations

### Protect (Must ship with M3)

- **All visual polish items** (S4-21/22/23/26 carry-forwards) — directly visible to jam
  judges; the gap between a polished and unpolished entry is the difference between a
  strong score and an obvious prototype impression
- **Level name on Level Complete screen** — medium severity UX gap confirmed in M2 playtest;
  trivial to implement; data already in params
- **Audio wiring** (real or CC0 assets) — a silent game at jam submission signals
  incompleteness regardless of puzzle quality; must not ship with null stubs
- **Export build** — non-negotiable; jam requires a playable build

### At Risk (May need a fallback plan)

- **Tile atlas art** (R-18) — highest external dependency; no code fallback; if art is
  not delivered, jam submission may need to use placeholder tiles explicitly noted in the
  game description
- **CatSprite final art** (R-17) — polished GDScript draw approach is acceptable fallback;
  confirm with art director before Sprint 5 mid-point
- **Real audio assets** (R-16) — CC0 sourcing from freesound.org / opengameart.org is
  a confirmed viable path; allocate sourcing time in Sprint 5

### Cut Candidates (Deferring does not compromise M3)

- **MVP-Skins tier** (CosmeticDB, SkinUnlockTracker, SkinSelectScreen) — explicitly
  deferred; Skins button stubs to no-op; no player impact on jam evaluation of core gameplay
- **TD-005 test coverage** (cat_sprite, grid_renderer) — visual-only code; regression
  visible in playtest; not a blocking concern for submission
- **S4-29 commit hygiene audit** — internal process; zero player impact

---

## Go/No-Go Assessment

**Recommendation**: 🟡 CONDITIONAL GO — Sprint 5 not yet started

**Conditions** (must all be met before M3 can be declared GO):

1. Visual polish items S4-21/22/23/26 shipped with correct colours and real/polished assets
2. Level Complete screen shows level name
3. At least 4 SFX events and 1 music track wired with audible (real or CC0) audio files
4. At least one export build (Android or Web) verified to load and play without crash
5. Jam submission metadata (itch.io page) complete
6. 0 open S1/S2 bugs; GUT tests ≥610/0
7. TD-004 decision recorded (refactor or re-accept with rationale)

**Rationale**: M3 opened at Sprint 5 Day 0 with 0/16 criteria met. All 7 conditions are
achievable within Sprint 5 at historical velocity assuming art/audio assets are delivered.
The primary risk to GO is external asset dependencies (tile art, cat sprite PNG, audio files),
not development capacity. If assets slip, the export target (Android→Web fallback) and a
polished-placeholder art pass are the contingency path.

---

## Action Items

| # | Action                                                        | Owner              | Deadline             |
|---|---------------------------------------------------------------|--------------------|----------------------|
| 1 | Confirm art asset delivery ETA (tile atlas, cat sprite PNG)   | Art Director       | Before Sprint 5 start |
| 2 | Source CC0 or final audio files for 4 SFX events + 1 BG track | Audio Director     | Sprint 5 mid         |
| 3 | Implement S4-21 background colour fix                         | ui-programmer      | Sprint 5             |
| 4 | Implement S4-22 CatSprite asset swap (or polished fallback)   | technical-artist   | Sprint 5             |
| 5 | Implement S4-23 coverage trail colour                         | technical-artist   | Sprint 5             |
| 6 | Implement S4-26 World Map level card visual upgrade           | ui-programmer      | Sprint 5             |
| 7 | Add level name label to Level Complete screen                 | ui-programmer      | Sprint 5             |
| 8 | Wire audio assets into SfxLibrary + MusicManager              | audio-director     | Sprint 5             |
| 9 | Wire tile atlas art into GridSystem                           | technical-artist   | Sprint 5 (blocked on art delivery) |
| 10 | Configure export presets + verify one export build            | devops-engineer    | Sprint 5             |
| 11 | Create/update itch.io project page for jam submission         | producer           | Sprint 5 or 6        |
| 12 | Record TD-004 decision (refactor or re-accept)                | lead-programmer    | Sprint 5             |
| 13 | Run S4-29 commit hygiene audit                                | devops-engineer    | Sprint 5             |
| 14 | Run automated M3 playtest + capture screenshots               | qa-tester          | Sprint 5 close       |
