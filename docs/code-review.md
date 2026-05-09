# NekoDash Code Review Report

**Date:** April 30, 2026
**Reviewer:** Gemini CLI

## Executive Summary

The NekoDash codebase demonstrates a solid architectural foundation with clear manager patterns (Autoloads) and adherence to signal-driven decoupling. However, it currently carries significant "hardcoding debt" and several best-practice violations that could lead to maintenance challenges, performance bottlenecks, and production bugs if not addressed before launch.

> Status correction on May 9, 2026: the original `PlaytestCapture autoload` finding below is stale. `PlaytestCapture` is no longer registered in the live `project.godot` autoload list. Shipping `Windows Desktop` and `Web` exports were also cleaned up in this session: fresh rebuilds no longer package the excluded test/editor/dev-capture files, and Web capture routing now requires the dedicated `dev_capture` feature via the `Web Dev Capture` preset. Android remains operationally unverified because the current `android/build/nekodash.apk` on disk predates the preset cleanup. See `docs/export-capture-audit.md` for the current verified matrix.

---

## 1. Hardcoded Values & Paths

The most prevalent issue is the manual management of strings and literal values instead of using Godot's resource-driven data model.

### 1.1 Hardcoded Paths (`res://` and `user://`) - [PARTIALLY FIXED]

There are **over 194 instances** of hardcoded paths inside logic outside of proper constant or export definitions.

- **Scene Navigation:** `src/core/scene_manager.gd` hardcodes paths for all screens and overlays (e.g., `res://scenes/ui/main_menu.tscn`).
- **Audio Routing:** [FIXED] `src/core/music_manager.gd` now uses `GlobalAudioSettings` resource.
- **Tutorial Logic:** [FIXED] `src/gameplay/tutorial_system.gd` now uses `TutorialData` resource via `@export`.
- **World Map:** [FIXED] `src/ui/world_map.gd` now uses `catalogue_override` or default path via `ResourceLoader`.

### 1.2 Magic Numbers & Metadata - [PARTIALLY FIXED]

- **World Metadata:** [FIXED] Moved from `world_map.gd` to `WorldData` resources inside `LevelCatalogue`.
- **Tutorial Triggers:** [FIXED] Moved from `tutorial_system.gd` to `TutorialData.tres`.
- **UI Colors & Sizes:** `src/ui/shell_theme.gd` acts as a central repository for magic colors (e.g., `CREAM`, `PLUM`, `GOLD`) and layout dimensions rather than using a formal `.tres` Theme.

---

## 2. Best Practice Violations

### 2.1 Production Integrity

- **Capture Tool Leakage:** This is now partially fixed. Fresh May 9 Windows/Web rebuilds no longer package the excluded capture, test, or editor-only files. The remaining always-shipped capture-adjacent script is `src/ui/web_capture_router.gd`, which stays autoloaded but now only routes snapshots when the build has `dev_capture`. Android still needs a fresh rebuilt APK before the same cleanup can be confirmed there.
- **Debug Leftovers:** There are **over 100 `print()` statements** in the `src/` directory. These should be removed or converted to `push_warning`/`push_error` for proper log handling in production.

### 2.2 Architectural Deviations

- **Bypassing Managers:** `LevelCoordinator.gd` preloads and plays `level_complete.wav` directly, bypassing the `SfxManager` autoload. This breaks centralized volume control, bus routing, and SFX pooling.
- **Node vs. Autoload:** `LevelProgression` is a local node in the gameplay scene. This makes it difficult for UI screens (like the World Map) to query progression state without the gameplay scene being active, violating the intent of **ADR-0001 (Autoload Architecture)**.
- **Manual UI Scaling:** Multiple components manually calculate scaling and positions (e.g., `TutorialSystem.gd` skip button) instead of using Godot's container and anchor system.

---

## 3. Static Analysis & Type Safety

### 3.1 Missing Type Hints

Over **40 variables and function signatures** lack explicit type hints, disabling Godot 4's static analysis benefits.

- **Affected Files:** `src/core/save_manager.gd`, `src/core/scene_manager.gd`, `src/gameplay/tutorial_system.gd`, `src/ui/hud.gd`, `src/ui/level_complete_screen.gd`.

### 3.2 Large Files (>500 lines)

The following files exceed the recommended size for single-responsibility modules:

- `src/ui/shell_theme.gd` (829 lines)
- `src/ui/home_tile_art.gd` (745 lines)
- `src/ui/cat_part_rig.gd` (652 lines)
- `src/gameplay/level_coordinator.gd` (632 lines)
- `src/ui/level_complete_screen.gd` (596 lines)
- `src/ui/world_map.gd` (595 lines)
- `src/gameplay/sliding_movement.gd` (507 lines)

---

## 4. Incomplete Items (TODOs & HACKs)

There are **35 unresolved debt markers** across the codebase:

- **LevelCoordinator:** Stub handlers for `_on_move_count_changed` and `_on_coverage_updated`.
- **UI Design Tool Addon:** Multiple TODOs regarding font weight fallbacks, bbcode support, and undo/redo efficiency.
- **Godot 4 Migration:** `addons/gut/` and `addons/ui_design_tool/` contain numerous `# TODOGODOT4` markers regarding missing directory listing arguments.

---

## 5. Technical Recommendations

1. **Resource Refactor:** Create a `WorldData` resource and update `LevelCatalogue` to store an array of worlds instead of a flat list of levels. Move hardcoded titles and audio mappings there. [DONE]
2. **Theme Migration:** Convert the magic numbers in `shell_theme.gd` into a formal `.tres` Godot Theme.
3. **Manager Alignment:** Force all gameplay systems to use `SfxManager` for audio and `MusicManager` for BGM to ensure bus settings are respected.
4. **Build Cleanup:** Maintain the new shipping preset excludes and the dedicated `Web Dev Capture` preset. The remaining gap is Android verification, not Windows/Web policy.
5. **Type Pass:** Conduct a comprehensive pass to add missing `: Type` and `-> Type` hints to all variables and functions.

---

## 6. Fixes & Verification (Post-Review Update)

### 6.1 Issue #1: Hardcoded Path Refactoring

The following major hardcoding issues were resolved to align with Godot's resource-driven architecture:

- **World Map:** Removed `CATALOGUE_PATH` constant. Replaced with `@export var catalogue_override: LevelCatalogue`. The system now dynamically groups `LevelData` into `WorldData` objects, allowing for scalable world metadata.
- **Tutorial System:** Removed `TUTORIAL_DATA_PATH`. Exposed `tutorial_data: TutorialData` as an export, moving trigger levels and UI asset paths to a `.tres` file.
- **Music Manager:** Eliminated hardcoded screen-to-track dictionaries. The manager now interfaces with the `GlobalAudioSettings` resource for all BGM routing.
- **Data Model:** Updated `LevelCatalogue` and `LevelProgression` to support the new `WorldData` resource structure.

### 6.2 Smoke Test & Regression Results

A comprehensive smoke test suite (`tests/test_all_screens_smoke.gd`) was executed using the headless Godot runtime to verify the stability of the changes.

- **Screen Validation:** All screens (`Main Menu`, `World Map`, `Gameplay`, `Skin Select`, `Loading`, `Opening`, `Credits`) and overlays (`Options`, `Pause`, `Level Complete`) successfully instantiated without script errors or path resolution failures.
- **GUT Test Suite:**
  - **Total Tests:** 683
  - **Passing:** 629
  - **Failing:** 19 (Note: All failing tests were pre-existing and related to Level Design obstacle count mismatches in World 1, confirming no new regressions from architectural changes).
  - **Performance:** Full suite completed in ~13.3 seconds.
