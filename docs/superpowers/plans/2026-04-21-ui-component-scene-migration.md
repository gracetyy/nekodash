# UI Component Scene Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace screen-owned reusable UI implementations across NekoDash with dedicated component scenes and component scripts.

**Architecture:** Build a shared scene-based component library first, then migrate each screen to consume those components and remove duplicated styling/structure. Keep runtime system boundaries intact by using parent-driven data flow and semantic component signals.

**Tech Stack:** Godot 4.3, GDScript, `.tscn` scene composition, shared UI assets under `assets/art/ui/`

---

### Task 1: Create Shared Component Library

**Files:**

- Create: `res://scenes/ui/components/**`
- Create: `res://src/ui/components/**`
- Modify: `res://src/ui/shell_theme.gd`

- [ ] Add button, panel, status, card, badge, tutorial, and settings-row component scenes.
- [ ] Add component scripts with exported properties and semantic signals.
- [ ] Keep `ShellTheme` as a token/asset helper for component internals only.

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

- [ ] Replace local shared panel/button usage with component instances.
- [ ] Make `skin_select` adapter-ready using `SkinCard` and `BackButton`.

### Task 3: Migrate Main Menu

**Files:**

- Modify: `res://scenes/ui/main_menu.tscn`
- Modify: `res://src/ui/main_menu.gd`

- [ ] Replace inline button styling, duplicated stylebox resources, and theme overrides with `PillButton` component instances.
- [ ] Keep menu cat rig local and preserve navigation behavior.

### Task 4: Migrate Pause and Options

**Files:**

- Modify: `res://scenes/ui/pause_overlay.tscn`
- Modify: `res://src/ui/pause_menu.gd`
- Modify: `res://scenes/ui/options_overlay.tscn`
- Modify: `res://src/ui/options_menu.gd`

- [ ] Replace duplicated modal/settings structure with shared components.
- [ ] Route manager changes through overlay scripts, not settings-row components.

### Task 5: Migrate Gameplay HUD

**Files:**

- Modify: `res://scenes/gameplay/gameplay.tscn`
- Modify: `res://src/ui/hud.gd`

- [ ] Replace move counter, star row, and action buttons with shared components.
- [ ] Preserve undo/restart/exit/pause behavior.

### Task 6: Migrate Level Complete

**Files:**

- Modify: `res://scenes/ui/level_complete.tscn`
- Modify: `res://src/ui/level_complete_screen.gd`
- Modify: `res://scenes/ui/level_complete_overlay.tscn`
- Modify: `res://src/ui/level_complete_overlay.gd`

- [ ] Replace shared stars, panel, ribbon, badge, and button implementations with components.
- [ ] Keep overlay wrapper thin and route-specific.

### Task 7: Migrate World Map

**Files:**

- Modify: `res://scenes/ui/world_map.tscn`
- Modify: `res://src/ui/world_map.gd`

- [ ] Replace code-built cards/chips/rows with `WorldCard`, `LevelCard`, `ProgressPill`, and `StarStrip` instances.
- [ ] Keep navigation and save reads in `world_map.gd`.

### Task 8: Cleanup and Removal

**Files:**

- Modify: `res://src/ui/*.gd`
- Delete: `res://scenes/ui/ui_theme_editor.tscn`

- [ ] Remove obsolete screen-owned styling logic and inline theme overrides.
- [ ] Remove dead duplicated subresources and ad hoc UI construction paths.
- [ ] Delete `ui_theme_editor.tscn`.

### Task 9: Validate

**Files:**

- Verify: entire project

- [ ] Run Godot headless validation.
- [ ] Review migrated scenes for component usage and no remaining shared screen-owned styling drift.
- [ ] Summarize new components, removed duplications, migrated screens, and intentional one-offs.
