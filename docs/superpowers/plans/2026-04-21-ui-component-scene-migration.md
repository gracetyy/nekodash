# UI Component Scene Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace screen-local reusable UI implementations across NekoDash with dedicated component scenes and component scripts.

**Architecture:** Build a shared scene-based component library first, then migrate each screen to consume those components and remove duplicated styling/structure. Keep runtime system boundaries intact by using parent-driven data flow and semantic component signals.

**Tech Stack:** Godot 4.3, GDScript, `.tscn` scene composition, shared UI assets under `assets/art/ui/`

---

### Task 1: Create Shared Component Library

**Files:**

- Create: `res://scenes/ui/components/**`
- Create: `res://src/ui/components/**`
- Modify: `res://src/ui/shell_theme.gd`

- [x] Add button, panel, status, card, badge, tutorial, and settings-row component scenes.
- [x] Add component scripts with exported properties and semantic signals.
- [x] Keep `ShellTheme` as a token/asset helper for component internals only.

### Task 2: Migrate Low-Risk Static Screens

**Files:**

- Modify: `res://scenes/ui/credits.tscn`
- Modify: `res://src/ui/credits_screen.gd`
- Modify: `res://scenes/ui/loading.tscn`
- Modify: `res://src/ui/loading_screen.gd`
- Modify: `res://scenes/ui/opening.tscn`
- Modify: `res://src/ui/opening_screen.gd`
- Modify: `res://scenes/ui/skin_select.tscn`
- Modify: `res://src/ui/skin_select.gd`

- [x] Replace local shared panel/button usage with component instances.
- [x] Make `skin_select` adapter-ready using `SkinCard` and `BackButton`.

### Task 3: Migrate Main Menu

**Files:**

- Modify: `res://scenes/ui/main_menu.tscn`
- Modify: `res://src/ui/main_menu.gd`

- [x] Replace inline button styling and duplicated stylebox resources with `PillButton` component instances.
- [x] Keep menu cat rig local and preserve navigation behavior.

### Task 4: Migrate Pause and Options

**Files:**

- Modify: `res://scenes/ui/pause_overlay.tscn`
- Modify: `res://src/ui/pause_menu.gd`
- Modify: `res://scenes/ui/options_overlay.tscn`
- Modify: `res://src/ui/options_menu.gd`

- [x] Replace duplicated modal/settings structure with shared components.
- [x] Route manager changes through overlay scripts, not settings-row components.

### Task 5: Migrate Gameplay HUD

**Files:**

- Modify: `res://scenes/gameplay/gameplay.tscn`
- Modify: `res://src/ui/hud.gd`

- [x] Replace move counter, star row, and action buttons with shared components.
- [x] Preserve undo/restart/exit/pause behavior.

### Task 6: Migrate Level Complete

**Files:**

- Modify: `res://scenes/ui/level_complete.tscn`
- Modify: `res://src/ui/level_complete_screen.gd`
- Modify: `res://scenes/ui/level_complete_overlay.tscn`
- Modify: `res://src/ui/level_complete_overlay.gd`

- [x] Replace shared stars, panel, ribbon, badge, and button implementations with components.
- [x] Keep overlay wrapper thin and route-specific.

### Task 7: Migrate World Map

**Files:**

- Modify: `res://scenes/ui/world_map.tscn`
- Modify: `res://src/ui/world_map.gd`

- [x] Replace code-built cards/chips/rows with `WorldCard`, `LevelCard`, `ProgressPill`, and `StarStrip` instances.
- [x] Keep navigation and save reads in `world_map.gd`.

### Task 8: Cleanup and Removal

**Files:**

- Modify: `res://src/ui/*.gd`
- Delete: `res://scenes/ui/ui_theme_editor.tscn`

- [x] Remove obsolete screen-local styling logic.
- [x] Remove dead duplicated subresources and ad hoc UI construction paths.
- [x] Delete `ui_theme_editor.tscn`.

### Task 9: Validate

**Files:**

- Verify: entire project

- [x] Run Godot headless validation.
- [x] Review migrated scenes for component usage and no remaining shared inline styling drift.
- [x] Summarize new components, removed duplications, migrated screens, and intentional one-offs.
