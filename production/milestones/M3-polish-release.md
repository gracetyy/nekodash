# Milestone 3: Polish & Release

**Target Date**: 2026-04-28
**Status**: 🔶 In Progress — Sprint 5 begins 2026-04-03
**Sprints Allocated**: Sprint 5 · Sprint 6 (estimate: 1–2 sprints, 1–2 calendar days each)

---

## Description

M3 delivers a **polished, release-ready jam submission**. Every system in scope is
implemented, integrated, and visually coherent. The player sees the correct visual
design (cream backgrounds, real cat sprite art, warm coverage trail), hears real audio
feedback (SFX + music wired to real assets), and the game is buildable as an exportable
APK/web binary ready for itch.io upload.

M2 delivered a functional, technically-correct build. M3 transforms it from
"functional prototype" into a finished, shipped game. The gap between M2 and M3 is
entirely about polish, content completion, and export readiness — not new systems.

> **Scope discipline**: The MVP-Skins tier (Cosmetic/Skin Database, Skin Unlock
> Tracker, Skin Select Screen) is a **Sprint 5 bonus target** if capacity allows after
> all M3 exit criteria are met. It is explicitly **not required** for a passing M3.
> A second world (World 2) is **Full Vision scope** — not required for M3.

---

## Exit Criteria

All criteria must be ✅ before M3 is declared GO and the build is submitted to the jam.

### Visual Polish

- [ ] **Background colour — all scenes**: `main_menu.tscn`, `world_map.tscn`, and
      `level_complete.tscn` all display the design-spec cream background
      `Color("#F5EDCC")` instead of the current near-black `Color(0.08, 0.08, 0.12)`
      (S4-21 carry-forward)
- [ ] **CatSprite asset swap**: `src/ui/cat_sprite.gd` (and gameplay scene cat) display
      the final kawaii white cat PNG (`design/draft/sprite-cat.png` or delivered art)
      instead of the GDScript-drawn emoji placeholder (S4-22 carry-forward)
- [ ] **Coverage trail colour**: `src/ui/coverage_visualizer.gd` trail is warm amber
      `Color("#F5C842", 0.6)` matching the design spec; paw-stamp texture replacement
      documented as future work (S4-23 carry-forward)
- [ ] **Tile atlas — real art**: `src/core/grid_system.gd` atlas ID mapping replaced with
      final tile art (currently comments as "placeholder mapping — will be updated when
      tile atlas is authored"); walkable and obstacle tiles use final sprites
- [ ] **World Map level cards** — each card shows level number, best star count from
      SaveManager, and a lock/unlock icon (S4-26 carry-forward); plain lock-only cards
      replaced with PanelContainer-styled cards per Component 3.7

### UI Completeness

- [ ] **Level Complete screen — level name**: Level name label added to
      `scenes/ui/level_complete.tscn` and populated in `_populate_results()` from the
      `level_data.level_name` field passed in `receive_scene_params()`; closes the
      M2 playtest finding (medium severity bug, playtest-report-s4-19-m2-loop.md §Bugs)

### Audio

- [ ] **SFX wired with real assets**: `data/sfx_library.tres` `@export` slots populated
      with real (or CC0 placeholder) `AudioStreamOggVorbis` files for all 4 events:
      `slide_move`, `level_complete`, `star_earned`, `button_tap`; no silent SFX slots
      at any wired call site
- [ ] **Music Manager wired with real assets**: `src/core/music_manager.gd`
      screen-to-track mapping (currently "null stubs") populated with at minimum 1 real
      (or CC0 placeholder) background track; gameplay scene plays music; Main Menu plays
      distinct music or same track; no silent music on any screen
- [ ] **Audio round-trip test**: Full game loop (Main Menu → Gameplay → Level Complete)
      produces audible sound output on device; confirmed via manual play or device test

### Release Readiness

- [ ] **Export preset configured**: `export_presets.cfg` exists with at minimum
      Android + Web export targets configured; application name, package name, version,
      and icon set correctly for jam submission
- [ ] **Exportable APK or Web build**: At least one export target (Android APK or Godot
      Web) builds without error from `godot --headless --export-release`; build size
      within reasonable jam limits (≤100 MB)
- [ ] **Jam metadata complete**: `itch.io` project page (or jam submission form) has
      title, description, cover art, and control instructions filled out; game is
      submittable without missing required fields

### Technical Health

- [ ] **TD-004 resolved or deferred with rationale**: Decision recorded on
      `level_coordinator.gd` refactor — either refactored to reduce god-object growth,
      or explicitly re-accepted with documented rationale and a concrete sprint trigger
      (e.g., "re-evaluate when World 2 connects signals to LevelCoordinator")
- [ ] **Commit hygiene audit** (S4-29 carry-forward): Every `feat:` commit in the full
      project history carries the correct `SX-0X` sprint ID; any exceptions documented

### Quality Gates

- [ ] **0 open Severity-1 bugs**
- [ ] **0 open Severity-2 bugs**
- [ ] **GUT tests: ≥610 passing, 0 failing** (carry-forward from M2 baseline)
- [ ] **Automated playtest PASS — visual-confirmed**: Full M2 loop playtest run on the
      polished build; screenshots confirm cream backgrounds, real cat sprite, amber trail,
      level name on Level Complete; all audio confirmed non-silent
- [ ] **No placeholder comments in `src/`**: `grid_system.gd` tile atlas placeholder
      comment removed; `music_manager.gd` null-stub comment removed; no "placeholder"
      or "null stubs" remarks in production code

---

## Systems Delivered by This Milestone

| System                          | M2 Status                        | M3 Target                                     |
| ------------------------------- | -------------------------------- | --------------------------------------------- |
| Visual polish — backgrounds     | ⚠️ Near-black (design mismatch)  | ✅ Cream `#F5EDCC` across all UI scenes       |
| CatSprite — real art            | ⚠️ Emoji placeholder             | ✅ Final kawaii PNG                           |
| Coverage trail colour           | ⚠️ Flat green (design mismatch)  | ✅ Warm amber `#F5C842`                       |
| Tile atlas — real art           | ⚠️ Placeholder mapping comments  | ✅ Final tile sprites wired                   |
| World Map level cards           | ⚠️ Lock-icon only                | ✅ Level number + stars + lock state per card |
| Level Complete — level name     | ❌ Missing (M2 playtest finding) | ✅ Level name displayed                       |
| SFX — real assets               | ⚠️ Null stubs compile-only       | ✅ 4 events wired with real/CC0 files         |
| Music — real assets             | ⚠️ Null stubs compile-only       | ✅ ≥1 background track audible                |
| Export builds                   | ❌ Not configured                | ✅ Android or Web export verified             |
| Jam metadata                    | ❌ Not started                   | ✅ itch.io page/submission form complete      |
| TD-004 refactor / re-acceptance | ⚠️ Accepted with monitor flag    | ✅ Decision recorded                          |
| All M2 systems                  | ✅ Done                          | ✅ Unchanged, no regressions                  |

### Bonus Targets (Sprint 5 capacity permitting — not required for M3 GO)

| System                   | Priority | Rationale                                      |
| ------------------------ | -------- | ---------------------------------------------- |
| Cosmetic / Skin Database | High     | Required before Skin Select or unlock tracking |
| Skin Unlock Tracker      | Medium   | Requires Cosmetic DB + SaveManager integration |
| Skin Select Screen       | Medium   | Requires both above + real cat skin art assets |

### Not In Scope for M3 (Full Vision — post-jam)

| System                     | Rationale                                                   |
| -------------------------- | ----------------------------------------------------------- |
| World 2 (additional world) | New content requiring level authoring + BFS re-verification |
| Haptic feedback            | Platform-specific; not required for jam evaluation          |
| Online leaderboards        | Multiplayer/network scope; out of jam scope                 |
| Rewarded video ads         | Monetisation layer; irrelevant for jam submission           |

---

## Sprint Allocation

| Sprint   | Primary Focus                                                                                          | Estimated Tasks |
| -------- | ------------------------------------------------------------------------------------------------------ | --------------- |
| Sprint 5 | Visual polish (S4-21/22/23/26) · Level name fix · Audio asset wiring · Export config · TD-004 decision | 10–14           |
| Sprint 6 | (Buffer) Jam metadata · Final playtest · Remaining bonus targets · Submission                          | 4–8             |

> **Velocity reference**: Historical delivery is 10–40 tasks/calendar day (Sprints 1–4).
> 10–14 M3 tasks project to ≤1 calendar day at conservative velocity; the 2-sprint window
> provides full buffer to April 28 target.

---

## Risk Assessment

| ID   | Risk                                                                     | Probability | Impact | Mitigation                                                                                                                                                        |
| ---- | ------------------------------------------------------------------------ | ----------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R-06 | Jam deadline scope creep                                                 | Medium      | High   | MVP-Skins and World 2 explicitly excluded from M3. No new systems without producer sign-off.                                                                      |
| R-16 | Audio assets not sourced — SFX/Music still silent at M3 close            | Medium      | Medium | CC0 audio from freesound.org / opengameart.org acceptable; must be wired and audible. Cannot ship silently.                                                       |
| R-17 | Cat sprite art not delivered in time                                     | Medium      | Medium | Fallback: polished GDScript-drawn cat (improved placeholder) ships if final PNG not delivered by Sprint 5 mid.                                                    |
| R-18 | Tile atlas art not delivered — grid renders with dev placeholder tiles   | Medium      | High   | Block: game should not ship with placeholder art. If tile atlas is not delivered, jam submission date may slip.                                                   |
| R-19 | Android export fails certification / SDK configuration gap               | Low         | High   | Use Godot's standard Android export template; verify `export_presets.cfg` against Godot 4.3 Android docs before sprint close. Fallback: Web export as jam target. |
| R-20 | TD-004 `level_coordinator.gd` grows to god object if World 2 added in M3 | Low         | Medium | M3 explicitly excludes World 2; TD-004 decision must be recorded at M3 close regardless.                                                                          |
| R-06 | Level coordinator signal growth if Skins systems land as bonus targets   | Low         | Low    | Skins systems connect only to SaveManager and SceneManager, not LevelCoordinator; no signal growth triggered.                                                     |

---

## Velocity Analysis (projection)

| Metric                           | Value                                                                            |
| -------------------------------- | -------------------------------------------------------------------------------- |
| M2 actual velocity (Sprints 3+4) | 35 tasks / ~1 calendar day                                                       |
| Conservative M3 estimate         | 0.05d/task × 12 tasks = 0.6 calendar days                                        |
| Optimistic M3 estimate           | 0.025d/task × 12 tasks = 0.3 calendar days                                       |
| Buffer to target date            | ~25 calendar days to 2026-04-28; ~38 days to jam deadline (~2026-05-11)          |
| Risk: asset availability         | External dependency — art and audio must land before visual/audio work can close |
