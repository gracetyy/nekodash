# Sprint 5 — 2026-04-03 to 2026-04-09

**Status**: Not Started
**Last Updated**: 2026-04-03

## Sprint Goal

Transform the M2 functional build into a polished release candidate: fix all visual
design gaps, source and wire audio, swap in final cat sprites, configure export targets,
and produce a verified exportable build ready for jam submission.

## Capacity

- Total days: 5 (Thu Apr 3 – Wed Apr 9)
- Buffer (20%): 1 day reserved for integration issues and art/audio sourcing blockers
- Available: 4 net days

> **Velocity note**: Sprint 4 retro revised the per-task estimate to 0.05d/task
> (aggregate actual ~0.015–0.02d/task). Sprint 5 uses the same 0.05d/task floor.
> At conservative velocity, 15 tasks project to ~0.75 actual days, well within the
> 4-day window. S5-14 is still blocked on tile atlas art delivery and can slip to
> Sprint 6 without endangering M3 GO.

---

## Tasks

### Must Have (Critical Path)

| ID    | Task                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Agent/Owner      | Est. Days | Dependencies | Acceptance Criteria                                                                                                                                                                                                                                                                                                                                     |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | --------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S5-01 | **Full design system colour pass — all UI scenes**: Apply every colour token from `docs/design/design-system.md` across all three UI scenes (`scenes/ui/main_menu.tscn`, `scenes/ui/world_map.tscn`, `scenes/ui/level_complete.tscn`) and their GDScript controllers. See `docs/design-system.md` for details. (S4-21 carry, scope expanded)                                                                                                              | ui-programmer    | 0.2       | —            | All three scenes display cream background; all button nodes use the 3-colour intent system (primary/secondary/tertiary); all text/label nodes use correct colour tokens; star nodes use filled/empty token colours; HUD move-counter pill uses dark background with white text; no near-black or off-palette colours visible in M3 playtest screenshots |
| S5-04 | **World Map level cards — visual upgrade (S4-26 carry)**: Replace existing plain `Button` creation in `src/ui/world_map.gd`'s level-card builder with `PanelContainer`-styled cards; each card shows level index number, best star count (☆☆☆ / ★★★ format, reading from SaveManager), and lock icon (🔒) for locked levels                                                                                                                               | ui-programmer    | 0.1       | —            | World Map screenshots show level number, star state, and lock icon per card; unlocked levels show their number; star count persisted from SaveManager displays after completing a level; S4-19 playtest equivalent passes                                                                                                                               |
| S5-05 | **TD-004 decision — record refactor or re-acceptance**: Read current `src/gameplay/level_coordinator.gd` line count and `_connect_signals()` growth profile; decide: (A) refactor `_connect_signals` and `_disconnect_signals` into a data-driven signal table, OR (B) re-accept with explicit trigger ("refactor when a 4th world context connects signals"); write the decision + rationale to `docs/architecture/adr-004-level-coordinator-signals.md` | lead-programmer  | 0.05      | —            | `docs/architecture/adr-004-level-coordinator-signals.md` exists with a concrete GO or NO-GO decision + rationale; if GO, refactor implemented with no regression in 610 tests; if NO-GO, re-acceptance trigger is specific and dated                                                                                                                    |


---

### Should Have

| ID    | Task                                                                                                                                                                                                                                                                                                                                                                                                | Agent/Owner     | Est. Days | Dependencies               | Acceptance Criteria                                                                                                                                                                                                |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | --------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| S5-07 | **Source CC0 SFX assets**: Locate and commit CC0-licensed audio files for the 4 wired SFX events: `slide_move` (soft whoosh, <0.5s), `level_complete` (celebratory chime, 1–2s), `star_earned` (sparkle hit, <0.3s), `button_tap` (soft click, <0.1s); place in `assets/audio/sfx/` as `.ogg` files; update `assets/credits.txt` with attribution                                                   | sound-designer  | 0.1       | —                          | 4 `.ogg` files exist in `assets/audio/sfx/`; `assets/credits.txt` updated with source URLs and CC0 licence confirmation; files are ≤200 KB total                                                                   |
| S5-08 | **Wire SFX assets into SfxLibrary**: Open `data/sfx_library.tres` in Godot editor; assign the 4 sourced `.ogg` files to the `@export` slots (`slide_move`, `level_complete`, `star_earned`, `button_tap`); remove null-stub guard comment from `src/ui/level_complete_screen.gd:77`                                                                                                                 | sound-designer  | 0.05      | S5-07                      | `sfx_library.tres` four slots are non-null `AudioStreamOggVorbis` resources; playing the game produces audible SFX at each call site; `SfxManager.play(null, ...)` warning path is NOT triggered at any wired site |
| S5-09 | **Source + wire CC0 music track**: Locate and commit one CC0 background music track (ambient/puzzle genre, loop-friendly, 1–3 min); place in `assets/audio/music/` as `.ogg`; update `assets/credits.txt`; populate `src/core/music_manager.gd` screen-to-track map constant so gameplay + main menu use the track; remove "null stubs" comment                                                     | audio-director  | 0.1       | —                          | One `.ogg` file in `assets/audio/music/`; `credits.txt` attribution present; gameplay scene plays music; Main Menu plays same or distinct track; `music_manager.gd` null-stubs comment removed; no silent playback |
| S5-10 | **Export presets configuration**: Create `export_presets.cfg` with Android and Web export targets; set `application/name = "NekoDash"`, version string, correct package name (`io.itch.nekodash` or similar), and icon path (`res://icon.svg`); configure Android to use the Godot 4.3 export template; confirm the icon renders correctly                                                          | devops-engineer | 0.1       | —                          | `export_presets.cfg` exists with two targets; application name, version, and icon are correct; no missing-field warnings on `godot --headless --export-release`                                                    |
| S5-11 | **Verify export build**: Run `godot --headless --export-release "Web" ./build/nekodash_web.zip` (or Android APK equivalent); confirm build completes without error; check ZIP/APK size is ≤100 MB; verify the exported build loads and reaches Main Menu on a browser or device                                                                                                                     | devops-engineer | 0.05      | S5-10                      | Build completes without error; output file ≤100 MB; Main Menu renders correctly in exported build; no crash on launch                                                                                              |
| S5-12 | **Automated M3 playtest — polished loop**: Run a full M3 playtest loop identical to S4-19 but against the polished build; capture screenshots confirming: cream background on Main Menu + World Map, amber coverage trail in gameplay, cat sprite visible in gameplay and Main Menu, audible SFX; create `docs/playtest-report-s5-m3-loop.md` | qa-tester       | 0.05      | S5-01, S5-08 | ≥5 screenshots; cream background confirmed in ≥2 screenshots; amber trail in gameplay screenshot; cat sprite visible in at least one gameplay screenshot; zero crashes                                             |

---

### Nice to Have

| ID    | Task                                                                                                                                                                                                                                                                                             | Agent/Owner         | Est. Days | Dependencies        | Acceptance Criteria                                                                                                                                                                                                  |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------- | --------- | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S5-13 | **CatSprite asset swap (S4-22 carry — UNBLOCKED)**: In `src/ui/cat_sprite.gd`, replace GDScript-drawn emoji placeholder with `res://assets/art/cats/cat_default_idle.png`; keep GDScript draw path behind `const DEBUG_DRAW: bool = false` flag; update `src/gameplay/*.gd` gameplay cat node to use same texture; wire `res://assets/art/cats/cat_640px.png` as the high-res cat on the Main Menu splash | technical-artist    | 0.05      | — | Cat sprite shows PNG everywhere in gameplay; `cat_640px.png` used in Main Menu; orange emoji absent; `DEBUG_DRAW = false` by default; falls back gracefully if PNG missing; 610 tests still pass                    |
| S5-14 | **Tile atlas real art wiring**: Replace placeholder atlas constants in `src/core/grid_system.gd` (lines 194–200) with final walkable, obstacle, and empty tile sprite IDs; update `TileMapLayer` atlas setup in gameplay scene; remove `# Placeholder mapping` comment                           | technical-artist    | 0.1       | art asset delivered | Gameplay scene renders with final tile sprites; obstacle tiles visually distinct from walkable; placeholder comment removed; 610 tests still pass                                                                    |
| S5-15 | **Jam metadata — itch.io submission**: Prepare or update the itch.io project page: game title "NekoDash", 1–2 sentence description, cover art (screenshot or promotional), control instructions (swipe / WASD / arrow keys), genre tags (puzzle, mobile), jam link                               | producer            | 0.05      | S5-11               | itch.io project page is publicly visible or in draft-ready state; all mandatory jam submission fields are populated; game is linkable to jam submission                                                              |
| S5-16 | **Cosmetic/Skin Database (bonus)**: Create `src/core/cosmetic_database.gd` — `SkinDatabase` resource class with static skin registry; `get_skin_def(skin_id)` returns `SkinDefinition` record; default "nekochan" skin defined with placeholder texture; register as autoload `CosmeticDatabase` | gameplay-programmer | 0.1       | —                   | `CosmeticDatabase.get_skin_def("nekochan")` returns a valid `SkinDefinition`; autoload registered; Main Menu resolves default skin texture without SCRIPT ERROR; `SKIN_SELECT` screen no-op stub logs warning on tap |
| S5-17 | **Skin Unlock Tracker (bonus)**: Create `src/core/skin_unlock_tracker.gd` — subscribes to `SaveManager`; `is_skin_unlocked(skin_id)` queries save data; default "nekochan" always unlocked; stub milestone checks for future skins                                                               | gameplay-programmer | 0.05      | S5-16               | `SkinUnlockTracker.is_skin_unlocked("nekochan")` returns `true`; non-default skins return `false` until milestone criteria met; does not crash when SaveManager has no skin data                                     |
| S5-18 | **Skin Select Screen (bonus)**: Create `scenes/ui/skin_select.tscn` + `src/ui/skin_select.gd` — loads skin list from `CosmeticDatabase`; shows locked skins as greyed silhouettes with unlock hint; tapping an unlocked skin calls `SaveManager.set_equipped_skin()`; back → Main Menu           | ui-programmer       | 0.1       | S5-16, S5-17        | Skins button on Main Menu navigates to Skin Select screen; default skin equippable; back button returns to Main Menu; locked skins shown greyed; no SCRIPT ERROR on empty CosmeticDatabase                           |

---

## Carryover from Sprint 4

| Task                      | Sprint 4 ID | Reason Carried                                         | Sprint 5 ID | New Estimate                                            |
| ------------------------- | ----------- | ------------------------------------------------------ | ----------- | ------------------------------------------------------- |
| Background colour fix     | S4-21       | Producer deferred — awaiting asset/design confirmation | S5-01       | 0.2d (scope expanded to full design system colour pass) |
| CatSprite asset swap      | S4-22       | Art asset not yet available                            | S5-13       | 0.05d (now unblocked — assets delivered)                |
| CoverageVisualizer colour | S4-23       | Merged into S5-01 design system pass                   | S5-01       | (absorbed)                                              |
| World Map level cards     | S4-26       | Producer deferred — awaiting visual design assets      | S5-04       | 0.1d                                                    |
| Commit hygiene audit      | S4-29       | Manually verified by producer                          | —           | (closed — no task needed)                               |

> **Note**: S5-01 covers the full design system colour pass (background, text, buttons,
> stars, HUD) — the S4-23 coverage trail colour change is absorbed into this task.
> S5-13 is now unblocked: `assets/art/cats/cat_default_idle.png` (gameplay) and
> `assets/art/cats/cat_640px.png` (Main Menu HD) are available. S5-14 (tile atlas)
> remains blocked on tile art delivery and can slip to Sprint 6.

---

## Risks

| Risk                                                    | Probability | Impact | Mitigation                                                                                                             |
| ------------------------------------------------------- | ----------- | ------ | ---------------------------------------------------------------------------------------------------------------------- |
| R-18: Tile atlas art not delivered (S5-14 blocked)      | Medium      | High   | Confirm art ETA before sprint start; if not delivered by Sprint 5 mid, ship with cleaner placeholder + comment removed |
| R-16: CC0 audio sourcing takes longer than estimated    | Low         | Medium | freesound.org search + download is fast; allocate 30 min for sourcing; `.ogg` export is single-step                    |
| R-19: Android export SDK not installed on build machine | Medium      | Medium | Web export is pre-qualified fallback for jam; Godot 4.3 Web export is well-tested; fallback does not require SDK       |
| R-06: Skins tier bonus draws scope from Must Have items | Low         | Low    | Skins tier (S5-16–18) is explicitly blocked until S5-01 through S5-12 are done                                         |

---

## Dependencies on External Factors

- **Art asset delivery** (tile atlas sprites) — required for S5-14 only; S5-13 cat sprites
  are now available at `assets/art/cats/`; S5-14 tile atlas must be received before Sprint 5
  close or carried to Sprint 6
- **Android SDK** — required for APK export target (S5-11); Web export is the qualified
  fallback if SDK is unavailable
- **itch.io account access** — required for S5-15 (jam metadata); non-blocking for code sprint

---

## Definition of Done for this Sprint

- [ ] S5-01, S5-04, S5-05 all completed, committed, and tests passing (Must Have)
- [ ] Coverage trail is amber, backgrounds are cream, World Map cards show stars + numbers
- [ ] TD-004 decision recorded at `docs/architecture/adr-004-level-coordinator-signals.md`
- [ ] Zero SCRIPT ERRORs on `godot --headless` GUT run; ≥610 passing, 0 failing
- [ ] No `placeholder`, `null stubs`, or asset-pending comments in `src/` after art/audio lands
- [ ] At least one export build (Web or Android) verified and ≤100 MB (Should Have)
- [ ] Audio wired: 4 SFX + 1 music track audible (Should Have)
- [ ] Automated M3 playtest screenshots confirm all polish criteria (Should Have)
- [ ] Each sprint sub-task committed individually as `feat: S5-0X PascalCaseTaskName`
- [ ] Sprint retrospective filed within 24h of all-tasks-complete
