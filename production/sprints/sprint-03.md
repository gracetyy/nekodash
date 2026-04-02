# Sprint 3 — 2026-04-02 to 2026-04-08

**Status**: Not Started
**Last Updated**: 2026-04-02

## Sprint Goal

Complete all technical debt clearance, implement SaveManager real disk I/O, deliver the World Map scene, and fix the two outstanding player-facing bugs — leaving Sprint 4 free to focus entirely on new content and audio.

## Capacity

- Total days: 5 (Thu Apr 2 – Wed Apr 8)
- Buffer (20%): 1 day reserved for unplanned work / integration issues
- Available: 4 net days

> **Velocity note**: Sprints 1 and 2 both delivered at ~30% of allocated calendar time, completing
> in ~1–1.5 days. Baseline per task is **0.25d**. 16 tasks fill 4 net days conservatively.
> Actual delivery is expected within 1–2 calendar days. Remaining time absorbs NTH tasks.

---

## Tasks

### Must Have (Critical Path)

| ID    | Task                                                                                                                                                                                                                                                                                                        | Agent/Owner               | Est. Days | Dependencies | Acceptance Criteria                                                                                                                                                                               |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | --------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S3-01 | **TD-001**: Fix `tests/test_level_data.gd:243` — change `var tile: Node` to `var tile: GridSystem.GridTileData`; confirm zero SCRIPT ERRORs on full GUT test run                                                                                                                                            | godot-gdscript-specialist | 0.25      | —            | Zero SCRIPT ERRORs produced at test suite startup; all existing tests continue to pass; the fix is a single type annotation change, not a logic change                                            |
| S3-02 | **TD-002**: Remove dead overlay code block from `src/gameplay/level_coordinator.gd` — delete `LEVEL_COMPLETE_OVERLAY_DELAY_SEC`, `var _overlay`, `_show_level_complete_overlay()`, `_on_overlay_retry()`, `_on_overlay_next()` (~122 lines)                                                                 | gameplay-programmer       | 0.25      | —            | All 5 dead symbols removed; `level_coordinator.gd` passes all existing tests with no regressions; no unreachable code paths remain referencing the overlay pattern                                |
| S3-03 | **TD-003 + SaveManager**: Implement real disk I/O in `SaveManager` — `save()` / `load()` read-write `user://nekodash_save.json` (JSON); version field `"version": 1`; immediate-write on every setter; graceful corruption recovery to fresh save                                                           | godot-gdscript-specialist | 0.5       | —            | `save_game()` and `load_game()` persist level records and star ratings across app restart; stub warning removed; corruption test passes (bad JSON renamed to `.corrupt.json`, fresh save written) |
| S3-04 | **WorldMap scene**: Create `res://scenes/ui/world_map.tscn` + `src/ui/world_map.gd` — `LevelCatalogue` loaded from `res://data/level_catalogue.tres`; level buttons rendered per world; unlock state + best star count read from SaveManager; tap navigates to gameplay; back button navigates to Main Menu | ui-programmer             | 0.5       | S3-03        | Scene exists at canonical path; level 1 always unlocked; subsequent levels unlock when previous is completed in save; star count displays from best record; navigation via `SceneManager.go_to()` |
| S3-05 | **Bug #3**: Wire "World Map" button in `LevelCompleteScreen` to `SceneManager.go_to(Screen.WORLD_MAP)` — confirm `Screen.WORLD_MAP` enum value exists before wiring                                                                                                                                         | ui-programmer             | 0.25      | S3-04        | Tapping "World Map" on Level Complete screen transitions to `world_map.tscn`; no crash if previous level record was not saved; GUT test for navigation signal added                               |
| S3-06 | **Bug #5**: Enlarge and recolor star icons in `LevelCompleteScreen` — ≥48×48 logical px; gold/yellow texture when earned, grey when unearned                                                                                                                                                                | ui-programmer             | 0.25      | —            | Stars ≥48×48px; earned stars render gold; unearned stars render grey; no regression in star count display logic; visual confirmed via automated playtest screenshot                               |
| S3-07 | **LevelCatalogue canonical path**: Confirm `LevelCoordinator` loads `LevelCatalogue` from `res://data/level_catalogue.tres` (matching World Map path contract from GDD); update path constant if it differs                                                                                                 | godot-specialist          | 0.25      | —            | Both `WorldMap` and `LevelCoordinator` load from the same `res://data/level_catalogue.tres` path; path constant documented in code comment referencing World Map GDD                              |

---

### Should Have

| ID    | Task                                                                                                                                                                                                                                      | Agent/Owner               | Est. Days | Dependencies | Acceptance Criteria                                                                                                                                                             |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | --------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S3-08 | **SaveManager GUT tests**: Write `tests/test_save_manager.gd` — cover save/load roundtrip, missing file (fresh init), corrupted file (recovery), version mismatch, best_stars never-decrement rule, best_moves update-on-improvement rule | godot-gdscript-specialist | 0.25      | S3-03        | ≥8 test cases covering all core rules from GDD; all pass; suite total ≥500 passing tests                                                                                        |
| S3-09 | **WorldMap GUT tests**: Write `tests/test_world_map.gd` — cover unlock derivation logic (first level always unlocked, subsequent gates), star count read from SaveManager stub, navigation signal emission                                | ui-programmer             | 0.25      | S3-04        | ≥5 test cases; unlock logic independently testable without scene tree; all pass                                                                                                 |
| S3-10 | **Star threshold balance pass**: Audit w1_l4, w1_l5, w1_l6 — verify 3-star threshold is achievable without perfect foreknowledge; adjust `star_3_moves` offset by +1–2 where needed; re-run BFS solver to confirm                         | gameplay-programmer       | 0.25      | —            | 3-star threshold achievable on all three levels with deliberate but non-perfect play; `minimum_moves` values re-verified by BFS solver after any edits; `.tres` files committed |
| S3-11 | **TD-006**: Record ownership decision for `tools/playtest_capture.gd` and `tools/playtest_runner.gd` — add file-header comment block stating owner, maintenance contract, and usage instructions; close TD-006 in tech debt register      | tools-programmer          | 0.25      | —            | Both files have a standardised ownership header; `docs/tech-debt-register.md` marks TD-006 resolved; no new maintenance tasks created unless explicitly decided                 |

---

### Nice to Have

| ID    | Task                                                                                                                                                                                                                   | Agent/Owner               | Est. Days | Dependencies | Acceptance Criteria                                                                                                                                              |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- | --------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S3-12 | **Automated playtest — full loop**: Run `PlaytestCapture` + `mcp_godot_run_project` through the World Map → level → complete → World Map return loop; capture screenshot of World Map with updated star display        | qa-tester                 | 0.25      | S3-04, S3-05 | At least one screenshot saved to playtest output path showing World Map with completed level star count; no crashes logged in debug output                       |
| S3-13 | **SceneManager.Screen audit**: Enumerate all `Screen.*` enum values in `SceneManager`; confirm `WORLD_MAP` and `MAIN_MENU` are defined; stub routes or assert-fail for any screen that has no `.tscn` yet              | engine-programmer         | 0.25      | —            | All `Screen.*` values map to a `.tscn` path or a documented stub; no silent no-ops remain in `go_to()`; `test_scene_manager.gd` updated to cover new enum values |
| S3-14 | **`level_complete_screen.gd` — snapshot previous bests**: Confirm `_snapshot_previous_bests()` call in `_on_overlay_next()` is correct and covered by test; cross-reference `feat: S2-05` commit note from code review | godot-gdscript-specialist | 0.25      | —            | `_snapshot_previous_bests()` has at least one test exercising pre/post comparison; no regression on level-complete navigation flow                               |
| S3-15 | **GUT suite 500-test milestone**: If test count is below 500 after S3-08 + S3-09, identify the largest untested surface and add a targeted test file to reach ≥500                                                     | qa-tester                 | 0.25      | S3-08, S3-09 | `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gprefix=test_ -gexit` output reports ≥500 passing, 0 failing                                    |
| S3-16 | **`playtest_runner.gd` autoload cleanup**: Confirm `PlaytestRunner` is not in `project.godot` autoload list (per AGENTS.md: remove after test run unless persistent CI is intentional)                                 | devops-engineer           | 0.25      | —            | `project.godot` does not list `PlaytestRunner` as an autoload; `PlaytestCapture` autoload remains if still registered                                            |

---

## Carryover from Sprint 2

None. All Sprint 2 tasks completed before sprint close.

| Action Items Carried Forward                         | Source                          | Status              |
| ---------------------------------------------------- | ------------------------------- | ------------------- |
| Fix `test_level_data.gd:243` SCRIPT ERROR            | Sprint 1 retro + Sprint 2 retro | → S3-01 (scheduled) |
| Remove dead overlay code from `level_coordinator.gd` | Sprint 2 retro                  | → S3-02 (scheduled) |

---

## Risks

| Risk                                                                                                                                                    | Probability | Impact | Mitigation                                                                                                      |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ------ | --------------------------------------------------------------------------------------------------------------- |
| R-13: Obstacle System integration (Sprint 4) touches GridSystem + LevelData — not blocked by Sprint 3 but coordination needed early                     | Medium      | Medium | Sprint 3 must not alter GridSystem or LevelData API shape; additive-only changes permitted                      |
| R-14: Level threshold adjustments (S3-10) re-validate incorrectly — BFS solver returns wrong minimum                                                    | Low         | Medium | Re-run `godot --headless -s tools/level_solver.gd` on each edited `.tres` before commit                         |
| R-15: SaveManager real I/O introduces corruption or migration edge case not covered by tests                                                            | Low         | High   | Corruption test case required in S3-08 before S3-03 is considered done                                          |
| R-16: Audio assets unavailable for Sprint 4 — SFX Manager will compile but produce no sound                                                             | Medium      | Low    | SfxManager must not crash on missing audio; stubs acceptable for jam submission                                 |
| R-17 (new): World Map scene discovers missing `Screen.WORLD_MAP` enum value in `SceneManager` — Bug #3 wiring blocked                                   | Medium      | Medium | S3-13 (Screen audit) can be pulled forward to Must Have if S3-05 wiring is blocked; add enum value as ≤0.1d fix |
| R-18 (new): Sprint 3 velocity matches historical pace (~1.5d actual) — NTH tasks fill remaining days and Sprint 4 planning begins earlier than expected | High        | Low    | NTH tasks (S3-12–S3-16) are independent scaffolding for Sprint 4 readiness; completing them early is desirable  |

---

## Dependencies on External Factors

- `SaveManager` disk I/O (S3-03) must land before `WorldMap` scene (S3-04) — the World Map reads live save data to derive unlock state and star counts.
- `SceneManager.Screen.WORLD_MAP` enum value must exist before Bug #3 (S3-05) can be wired. S3-13 confirms this; if missing, the enum value is a ≤0.1d add.
- No physical device required this sprint — all validatable in editor or via automated playtest.

---

## Definition of Done for this Sprint

- [ ] All Must Have tasks (S3-01 through S3-07) completed and tests passing
- [ ] Zero SCRIPT ERRORs on full GUT test run (TD-001 resolved)
- [ ] Dead overlay code removed from `level_coordinator.gd` (TD-002 resolved)
- [ ] SaveManager reads and writes `user://nekodash_save.json` across restart (TD-003 resolved)
- [ ] `res://scenes/ui/world_map.tscn` navigable from Level Complete screen and Main Menu stub
- [ ] Bug #3 (World Map button) and Bug #5 (star icons) fixed and visually confirmed
- [ ] Each sprint sub-task committed individually as `feat: S3-0X PascalCaseTaskName`
- [ ] Sprint retrospective filed within 24h of all-tasks-complete
