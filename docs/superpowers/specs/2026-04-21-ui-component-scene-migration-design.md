# NekoDash UI Component Scene Migration Design

> **Status**: Approved for implementation
> **Date**: 2026-04-21
> **Scope**: Repo-wide UI architecture migration

## Goal

Refactor the NekoDash UI so every reusable UI element is owned by a dedicated Godot scene and, when needed, a dedicated component script. Screen scenes must become composition-oriented and delegate shared visuals, node trees, and behavior to dedicated component scenes instead of recreating them with inline `theme_override_*`, scene-local styleboxes, or script-built ad hoc controls.

## Scope Boundary

- This migration is strictly a UI architecture refactor.
- It does not introduce missing runtime subsystems such as `CosmeticDatabase`, `SkinData`, or `SkinDatabase`.
- Screens that are expected to consume those systems later must be left adapter-ready through exported properties, setters, and semantic signals.

## Chosen Approach

Adopt a shared component-scene library under:

- `res://scenes/ui/components/`
- `res://src/ui/components/`

Rules:

- Any reusable UI that appears on multiple screens becomes a standalone scene.
- Component scenes own reusable structure, visuals, state styling, and default interaction behavior.
- Screen scenes own composition, layout, and orchestration.
- Parent screens configure component instances through exported properties and semantic setters rather than applying `theme_override_*` directly to screen-owned controls.
- Shared styling may still use `ShellTheme` as a token and asset utility, but only from within component scripts.
- Screen scripts must stop calling `ShellTheme.apply_*` on raw screen-owned controls.

## Component Catalog

### Buttons

- `res://scenes/ui/components/buttons/PillButton.tscn`
- `res://scenes/ui/components/buttons/IconCircleButton.tscn`
- `res://scenes/ui/components/buttons/BackButton.tscn`

### Panels and Headers

- `res://scenes/ui/components/panels/ModalPanel.tscn`
- `res://scenes/ui/components/panels/RibbonHeader.tscn`

### Status and HUD

- `res://scenes/ui/components/status/StarStrip.tscn`
- `res://scenes/ui/components/status/HUDMoveCounter.tscn`
- `res://scenes/ui/components/status/ProgressPill.tscn`

### Cards

- `res://scenes/ui/components/cards/LevelCard.tscn`
- `res://scenes/ui/components/cards/WorldCard.tscn`
- `res://scenes/ui/components/cards/SkinCard.tscn`

### Badges

- `res://scenes/ui/components/badges/BadgeNewBest.tscn`
- `res://scenes/ui/components/badges/BadgeEquipped.tscn`

### Tutorial

- `res://scenes/ui/components/tutorial/TutorialBubble.tscn`

### Settings Rows

- `res://scenes/ui/components/settings/SliderSettingRow.tscn`
- `res://scenes/ui/components/settings/ToggleSettingRow.tscn`
- `res://scenes/ui/components/settings/OptionSettingRow.tscn`

## Ownership Rules

- `PillButton` owns pill textures, label/icon layout, font assignment, disabled state, hover feedback, and pressed-depth visuals.
- `IconCircleButton` owns circular texture variants, disabled state, hover scale, and pressed state visuals.
- `BackButton` is a dedicated scene that wraps the shared circular button behavior while preserving a single source of truth for the back affordance.
- `ModalPanel` owns the modal nine-patch chrome and shared sizing/padding defaults.
- `RibbonHeader` owns ribbon textures, title styling, and ribbon variants.
- `StarStrip` owns star-tier assets, earned/empty/hollow rendering, and optional animation hooks.
- `HUDMoveCounter` owns the move-counter pill background and label/value presentation.
- `ProgressPill` owns compact pill-style icon-plus-value displays.
- `LevelCard`, `WorldCard`, and `SkinCard` own their shared structure, shared state visuals, and interaction affordances.
- `BadgeNewBest` and `BadgeEquipped` own their badge visuals and visibility surfaces.
- Settings-row components own the repeated label + input layout duplicated across settings overlays.

## Data Flow Contracts

- `PillButton`: exported presentation properties only, emits `pressed`.
- `IconCircleButton`: exported presentation properties only, emits `pressed`.
- `BackButton`: no navigation logic, emits `pressed`.
- `ModalPanel`: no navigation or persistence logic, styling only.
- `RibbonHeader`: presentation only.
- `StarStrip`: accepts data through exports/setters, emits no scene-navigation actions.
- `HUDMoveCounter`: accepts values from parent/controller code, does not query gameplay systems directly.
- `ProgressPill`: accepts display values from parent/controller code.
- `BadgeNewBest`: presentation only.
- `BadgeEquipped`: presentation only.
- `LevelCard`: accepts `level_id`, state values, and emits `pressed(level_id)` / `locked_pressed(level_id)`.
- `WorldCard`: accepts world metadata and exposes methods for injecting child `LevelCard` instances.
- `SkinCard`: accepts `skin_id`, state values, and emits `pressed(skin_id)`.
- `TutorialBubble`: presentation only.
- `SliderSettingRow`: emits semantic value/mute signals rather than mutating managers directly.
- `ToggleSettingRow`: emits `toggled`.
- `OptionSettingRow`: emits `item_selected`.

## Migration Map

### Main Menu

- Replace inline-styled menu buttons with `PillButton` instances.
- Remove inline `StyleBoxTexture` resources and per-button `theme_override_*`.
- Keep title art and menu cat rig local.

### World Map

- Replace the back button with `BackButton`.
- Replace the header progress chip with `ProgressPill`.
- Replace script-built world sections with `WorldCard` instances.
- Replace script-built level tiles with `LevelCard` instances.
- Replace script-built star rows with `StarStrip`.

### Gameplay HUD

- Replace the move-counter block with `HUDMoveCounter`.
- Replace star row with `StarStrip`.
- Replace icon buttons with `IconCircleButton`.

### Level Complete

- Replace shared panel/ribbon/badge/button/star structures with `ModalPanel`, `RibbonHeader`, `BadgeNewBest`, `PillButton`, and `StarStrip`.

### Pause and Options

- Replace duplicate settings modal structure with `ModalPanel`, `RibbonHeader`, `IconCircleButton`, and shared settings-row components.

### Opening, Loading, Credits

- Replace local panel/button patterns with `ModalPanel` and `PillButton`.
- Keep unique screen art and copy local.

### Skin Select

- Replace placeholder local button/layout with `BackButton` and `SkinCard`.
- Keep the screen adapter-ready for future cosmetic-runtime integration.

### Level Complete Overlay

- Keep as a thin wrapper scene around reusable content.

### Theme Editor

- Delete `res://scenes/ui/ui_theme_editor.tscn` after migration.

## Migration Order

1. Build primitive component scenes and scripts.
2. Build card, badge, and tutorial components.
3. Migrate lower-risk static screens: credits, loading, opening, skin select.
4. Migrate main menu.
5. Migrate options and pause overlays together.
6. Migrate gameplay HUD.
7. Migrate level complete content and keep overlay wrapper thin.
8. Migrate world map.
9. Remove dead styling helpers/usages and delete `ui_theme_editor.tscn`.

## Intentional Screen-Specific Exceptions

- Decorative cat rig compositions remain screen-specific.
- Background rendering via `paw_background.gd` remains a shared utility, not a component scene.
- Title wordmark art remains screen-specific.
- `level_complete_overlay.tscn` remains a thin route wrapper.
- `global_cat_editor.tscn` remains editor-only and outside the runtime component library.
- One-off copy layout remains local once shared panel/button primitives are extracted.

## Validation Strategy

- Parse-check the project with Godot headless validation.
- Verify all refactored scenes still load.
- Confirm reused visuals now live in component scenes instead of duplicated screen-owned styling.
- Confirm screen scripts orchestrate components rather than building reusable UI with `*.new()`.
- Confirm `ui_theme_editor.tscn` is removed at the end of migration.
