# Technical Debt Register

**Project**: NekoDash
**Last Updated**: 2026-04-02 (post-Sprint-2 scan — pre-M2 baseline)
**Total Items**: 6 (2 open, 4 resolved) | **Estimated Total Effort**: S + S + M + M + S + S = ~3–4 days

> **Policy**: Every item explains _why_ the debt was accepted. Items older than
> 3 sprints without action must be fixed or explicitly re-accepted with a new reason.

---

## Register

| ID     | Category           | Description                                                                                                                                                                                                                                                                                                                                                                                   | Files                                                   | Effort | Impact | Priority Score                                                                                          | Added           | Fix Sprint                          |
| ------ | ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- | ------ | ------ | ------------------------------------------------------------------------------------------------------- | --------------- | ----------------------------------- |
| TD-001 | Test Debt          | `test_level_data.gd:243` — `var tile: Node = _grid.get_tile(Vector2i(2, 2))` assigns a `GridTileData` (implicitly `RefCounted`) to a `Node` variable. Fires `SCRIPT ERROR` on every test run; does not block pass/fail.                                                                                                                                                                       | `tests/test_level_data.gd:243`                          | S      | Medium | **HIGH** — fires every run, erodes signal-to-noise of test output                                       | 2026-04-01 (S1) | Sprint 3, Day 1                     |
| TD-002 | Code Quality Debt  | Dead overlay system in `level_coordinator.gd` — `_show_level_complete_overlay()` (101 lines), `_on_overlay_retry()`, `_on_overlay_next()`, `var _overlay`, and `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` constant are all unreachable. `SceneManager.go_to()` replaced this code path; nothing calls `_show_level_complete_overlay()`.                                                               | `src/gameplay/level_coordinator.gd` L70, L83, L409–L530 | S      | Medium | **HIGH** — 122 lines of dead code in the most complex file in the project; misleads future contributors | 2026-04-02 (S2) | Sprint 3, Day 1                     |
| TD-003 | Architecture Debt  | `SaveManager` is a stub — `load_game()` / `save_game()` emit `push_warning()` and do nothing to disk. Progress is held in-memory only and lost on restart. The full save/load GDD (`design/gdd/save-load-system.md`) specifies a `ConfigFile`-based persistence layer that has not been implemented.                                                                                          | `src/core/save_manager.gd` L67–L83                      | M      | High   | **HIGH** — any level completion or skin unlock is silently discarded on app restart                     | 2026-04-01 (S1) | Sprint 3                            |
| TD-004 | Architecture Debt  | `level_coordinator.gd` is a 530-line orchestrator growing toward a god object. `_connect_signals()` (45 lines) and `_disconnect_signals()` (55 lines) are parallel mirrored methods that will double in length with every new system added. 34 `connect`/`disconnect` call sites in one file. The pattern couples every system directly to one coordinator.                                   | `src/gameplay/level_coordinator.gd`                     | M      | Medium | **MEDIUM** — acceptable now at 6 systems; will become unsustainable at 10+                              | 2026-04-02 (S2) | Sprint 4 (or when adding 3rd world) |
| TD-005 | Test Debt          | No dedicated test file for `cat_sprite.gd` (91 lines, visual sprite controller) or `grid_renderer.gd` (109 lines, grid draw system). Both have logic that could regress silently — `grid_renderer` computes centring offset used by the whole gameplay scene; `cat_sprite` manages animation states. Two sprint code reviews have not flagged these as requiring tests.                       | `src/ui/cat_sprite.gd`, `src/ui/grid_renderer.gd`       | S      | Low    | **LOW** — visual-only code; no game-logic state; regression would be visible immediately in playtests   | 2026-04-02 (S2) | Backlog                             |
| TD-006 | Documentation Debt | `tools/playtest_capture.gd` (214 lines) and `tools/playtest_runner.gd` (199 lines) were added as unplanned `feat:` commits with no sprint task, no GDD, no tests, and no declared ownership. They are referenced in `AGENTS.md` and `CLAUDE.md` as the canonical AI playtest workflow but have no maintenance contract. If these silently break, AI-assisted playtests produce false results. | `tools/playtest_capture.gd`, `tools/playtest_runner.gd` | S      | Medium | **MEDIUM** — tooling debt; does not affect shipped game but affects development workflow reliability    | 2026-04-02 (S2) | Sprint 3 (ownership decision)       |

---

## Resolved Items

| ID  | Resolution                                                                 | Resolved   | Sprint       |
| --- | -------------------------------------------------------------------------- | ---------- | ------------ |
| TD-001 | Type annotation fix in `test_level_data.gd:243`                       | 2026-04-02 | S3-01        |
| TD-002 | Dead overlay code removed from `level_coordinator.gd`                 | 2026-04-02 | S3-02        |
| TD-003 | SaveManager disk I/O implemented                                      | 2026-04-02 | S3-03        |
| TD-006 | Ownership headers added to `playtest_capture.gd` and `playtest_runner.gd` | 2026-04-02 | S3-11    |
| —   | 15 LevelCoordinator TODO placeholders closed                               | 2026-04-02 | S2-05        |
| —   | GridRenderer coverage duplication removed (R-11)                           | 2026-04-02 | S2-08        |
| —   | Dead code after `SceneManager.go_to()` removed                             | 2026-04-02 | S2-06 review |
| —   | Unused `_grid_width`/`_grid_height` fields removed from CoverageVisualizer | 2026-04-02 | S2-08 review |
| —   | Stale `render_grid()` docstring corrected                                  | 2026-04-02 | S2-08 review |
| —   | Temp `tools/verify_new_levels.gd` deleted                                  | 2026-04-02 | S2-09 review |

---

## Trend

| Sprint | Open Items | Added | Resolved   | Net |
| ------ | ---------- | ----- | ---------- | --- |
| S1     | 2          | 2     | 0          | +2  |
| S2     | 6          | 6     | 6 (ad-hoc) | +4  |
| S3     | 2          | 0     | 4          | −4  |

**Direction**: Shrinking — Sprint 3 resolved 4 items with 0 added. 2 items remain
(TD-004 structural debt, TD-005 test coverage for visual code).

---

## Priority Queue for Sprint 3

| Priority | Item   | Rationale                                                                                                                   |
| -------- | ------ | --------------------------------------------------------------------------------------------------------------------------- |
| 1        | TD-001 | Fires every test run; 2 sprints without resolution; S-effort fix                                                            |
| 2        | TD-002 | 122 lines of dead code in the largest source file; misleads contributors; S-effort                                          |
| 3        | TD-003 | SaveManager stub means zero persistence; will block user-testing and any future playtest that requires remembering progress |
| 4        | TD-006 | Ownership decision needed before Sprint 3 test automation relies on these tools                                             |
| 5        | TD-004 | Low urgency now; watch at Sprint 4 when systems count grows                                                                 |
| 6        | TD-005 | Backlog; visual-only code; not a blocking concern                                                                           |

---

## Scan Notes (2026-04-02)

- **TODO/FIXME/HACK**: **0** across all `src/`, `tests/`, `tools/` (0 in S1 source; 15 S1 TODOs in coordinator were all closed by S2-05)
- **Files over 500 lines**: `level_coordinator.gd` (530) — only production source file above threshold
- **Test files over 500 lines**: 4 (normal for comprehensive GUT test suites — not debt)
- **Functions over 50 lines**: `_show_level_complete_overlay()` (101 lines — dead code, TD-002); `_disconnect_signals()` (55 lines — structural debt, TD-004)
- **Deprecated API usage**: None found
- **Duplicate code patterns**: `_connect_signals()` / `_disconnect_signals()` are structural mirrors (17 paired signal operations); acceptable now, monitor at system count growth (TD-004)
