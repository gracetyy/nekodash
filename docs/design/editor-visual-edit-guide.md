# NekoDash Editor Visual Edit Guide

## Goal

This guide is for a split workflow:

- You: visual/layout polish in Godot editor.
- Copilot: core systems, logic, refactors, and regression safety.

It is written as step-by-step actions you can run directly in the editor.

## Quick Decision

- I want to edit a reusable UI component: Open the matching scene under `res://scenes/ui/components/` and tune that component in one place.
- I want global change: Open `res://scenes/ui/global_cat_editor.tscn` and edit with 2D handles.
- I want per-screen change: Select the host node (`MainMenu` or `SlidingMovement`), set its host toggle to `true`, then edit host override properties.
- I want one-off local tweak: Select the child `CatPartRig` node (`MenuCatRig` or `CatSprite`), enable only the needed local override category, then tune local values.

## Global Cat Rig Defaults (Single Source)

Baseline cat rig tuning now comes from one shared profile resource:

- `res://data/cat_rig_defaults.tres`

All `CatPartRig` instances inherit from this profile by default (`use_global_profile = true`) unless local override categories are enabled.

Use this when you want one place to tune default cat behavior across gameplay and UI.

### How to edit global defaults

1. Open `res://scenes/ui/global_cat_editor.tscn`.
2. Select and drag these handles in the 2D editor:
   - `DisplayOffsetHandle`: moves full cat origin.
   - `TailPivotHandle`: sets tail rotation anchor.
   - `HeadPivotHandle`: sets head rotation anchor.
   - `BreathingHandle` (under `HeadPivotHandle`): sets head breathing amplitude (up/down travel).
3. Select `GlobalCatRig`, then edit `local_profile_override` values in Inspector for non-handle fields (`display_size_px`, idle values, `idle_head_breath_period_sec`, default skin, face variant).
4. If you changed profile values numerically, toggle `sync_handles_from_profile_now` on root `GlobalCatEditor` to snap handles back to current profile values.
5. Save `res://data/cat_rig_defaults.tres` (or toggle `save_profile_now` on `GlobalCatEditor`).

## Reusable UI Component Editing

Reusable buttons, panels, cards, badges, HUD pills, and status widgets now live in
dedicated component scenes under `res://scenes/ui/components/`. Edit the owning scene
directly when you need to change shared visuals or behavior.

### What it includes

- Pill button states (primary, secondary, tertiary, danger)
- Live button samples for component-scene validation
- Circular icon buttons with normal/hover/pressed/disabled textures
- Panels and ribbons (`NinePatchRect` + `TextureRect`)
- Slider/checkbox visual assets used by options and pause menus
- Stars, badges, HUD pills, and icon interiors
- World map level card textures + lock icon
- Cat peek texture used by overlay compositions

### How to use it

1. Open the reusable component scene you want to change.
2. Tune values in the Inspector or component script rather than copying the styling into each screen.
3. If a screen still needs a temporary local override during migration, keep it isolated to that screen and plan to move the shared styling into the component scene.
4. Run UI snapshot capture after edits to guard against regressions.

## Cat Inheritance Pattern (Identical Across Hosts)

For every cat host, use the same flow:

1. Start with global defaults in `cat_rig_defaults.tres`.
2. On host node, use the host toggle:
   - `false` = inherit global profile.
   - `true` = host exports override selected categories.
3. Only edit child `CatPartRig` node directly for one-off local overrides.

Current hosts using this pattern:

- Main menu host: root `MainMenu` (`menu_cat_override_global_defaults`).
- Gameplay host: `SlidingMovement` (`cat_override_global_defaults`).

## Safe Workflow (Always)

1. Open the target scene in Godot and make the visual change.
2. Save scene/resource files.
3. Run one quick play pass from that scene.
4. Run verification commands before considering the change done.

Recommended verification commands:

```powershell
& "C:\Users\Grace\AppData\Local\Godot_v4.3\godot.exe" --headless --path . res://scenes/ui/main_menu.tscn --quit-after 1 2>&1 | Out-String
& "C:\Users\Grace\AppData\Local\Godot_v4.3\godot.exe" --headless --path . res://scenes/gameplay/gameplay.tscn --quit-after 1 2>&1 | Out-String
& "C:\Users\Grace\AppData\Local\Godot_v4.3\godot.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gprefix=test_main_menu_shell -gexit 2>&1 | Out-String
& "C:\Users\Grace\AppData\Local\Godot_v4.3\godot.exe" --path . --script tools/ui_snapshot_capture.gd 2>&1 | Out-String
```

## 1) Main Menu Visuals

Target scene: `res://scenes/ui/main_menu.tscn`

### Edit layout/spacing/buttons

1. Open `main_menu.tscn`.
2. Expand `MarginContainer/Content/HeroCard/CardMargin/CardBody`.
3. Tune spacing in:
   - `CardBody` (`theme_override_constants/separation` on the screen-owned composition container)
   - `Buttons` (`theme_override_constants/separation` on the screen-owned composition container)
4. Adjust card margins in `CardMargin`.
5. Adjust title image sizing in `TitleLabel` (`custom_minimum_size`).

### Edit menu cat placement (Inspector, no code change needed)

1. Select root node `MainMenu`.
2. In Inspector, open script properties under `Menu Cat`.
3. Host Toggle Property (`menu_cat_override_global_defaults`):
   - `false`: inherit from `cat_rig_defaults.tres`.
   - `true`: use root host values below.
4. Host Override Properties (when host toggle = `true`):
   - `menu_cat_size_px`
   - `menu_cat_vertical_anchor_ratio`
   - `menu_cat_offset`
   - `menu_cat_face_variant`
   - `menu_cat_idle_tail_swing_degrees`
   - `menu_cat_idle_tail_swing_period_sec`
5. Run scene and iterate.

## 2) Cat Rig (Gameplay)

Target scene: `res://scenes/gameplay/gameplay.tscn`
Target host node: `SlidingMovement`
Target local rig node: `SlidingMovement/CatSprite`

### Gameplay Host Override (same pattern as Main Menu)

1. Select `SlidingMovement`.
2. In Inspector, open `Cat Rig Host`.
3. Host Toggle Property (`cat_override_global_defaults`):
   - `false`: gameplay cat inherits `cat_rig_defaults.tres`.
   - `true`: gameplay host exports override display/idle/face categories.
4. Host Override Properties (when host toggle = `true`):
   - `cat_display_size_px`
   - `cat_display_offset`
   - `cat_face_variant`
   - `cat_idle_tail_swing_degrees`
   - `cat_idle_tail_swing_period_sec`

### Tune local gameplay-only pivots and scale (optional)

1. Open `gameplay.tscn`.
2. Select `SlidingMovement/CatSprite`.
3. In Inspector (`CatPartRig`), set `override_pivots_locally = true`.
4. Tune local pivot values:
   - `display_size_px`
   - `display_offset`
   - `tail_pivot_source_px`
   - `head_pivot_source_px`
5. For quick pivot iteration:
   - Move `tail_pivot_source_px.x` left/right until swing anchors at tail base.
   - Move `tail_pivot_source_px.y` up/down until rotation feels natural.
   - Repeat for `head_pivot_source_px` if head tilt looks off-center.

### Tune gameplay slide head-tilt behavior

1. Keep `SlidingMovement/CatSprite` selected.
2. In `Slide Head Tilt` properties, tune:
   - `head_slide_tilt_degrees`
   - `head_tilt_in_sec`
   - `head_tilt_out_sec`
3. Test with left/right slides and blocked moves.

## 3) Cat Rig (Main Menu)

Target scene: `res://scenes/ui/main_menu.tscn`
Target host node: root `MainMenu`
Target local rig node: `CatIllustration/MenuCatRig`

1. Open `main_menu.tscn`.
2. Select root `MainMenu` for normal host-level editing.
3. Host Toggle Property (`menu_cat_override_global_defaults`):
   - `false`: fully inherit global profile defaults.
   - `true`: root menu exports drive display/idle/face in menu only.
4. Select `MenuCatRig` only for one-off local rig edits.
5. If editing `MenuCatRig` directly, enable local override categories there first (for example `override_pivots_locally`).

### Precedence (MainMenu root vs MenuCatRig child vs global)

1. **Global baseline**: `MenuCatRig` inherits `cat_rig_defaults.tres`.
2. **MainMenu root override**: when `menu_cat_override_global_defaults = true`, root `MainMenu` exports push local display/idle/face values into `MenuCatRig`.
3. **Inherited mode**: when `menu_cat_override_global_defaults = false`, `MenuCatRig` uses global profile defaults for those categories.
4. **Child local edits**: editing `MenuCatRig` directly changes that node instance; root exports apply again when root values change.

## 4) World Map Visuals

Target scene: `res://scenes/ui/world_map.tscn`
Target script node: root `WorldMap`

### Edit static shell/header layout

1. Open `world_map.tscn`.
2. Tune margin containers:
   - `MarginContainer`
   - `HeaderOuterMargin`
   - `ListOuterMargin`
3. Adjust title typography via `TitleLabel` theme overrides.

### Edit generated level-card layout/motion (Inspector)

1. Select root `WorldMap`.
2. In Inspector, tune script exports:
   - `grid_min_columns`
   - `grid_max_columns`
   - `level_card_min_width`
   - `level_card_gap`
   - `world_card_inner_horizontal_padding`
   - `level_card_hover_scale`
   - `level_card_hover_duration_sec`
   - `lock_jiggle_rotation_degrees`
3. Run `world_map.tscn` to validate responsiveness on resize.

## 5) Level Complete Screen

Target scene: `res://scenes/ui/level_complete.tscn`

1. Open `level_complete.tscn`.
2. Tune visual composition in:
   - `MarginContainer` scene margins.
   - `ResultsCard/CardMargin` offsets.
   - `StarRow` star placements (`Star1`, `Star2`, `Star3`).
   - `RibbonSlot/Ribbon` sizing and `LevelNameLabel` style.
   - `CatIllustration` size.
3. Keep button row labels and hierarchy unchanged unless intentionally redesigning flow.

## 6) Options Overlay

Target scene: `res://scenes/ui/options_overlay.tscn`

1. Open `options_overlay.tscn`.
2. Adjust panel/ribbon composition:
   - `Backdrop/Panel` size and position.
   - `Backdrop/Ribbon` size and offsets.
   - `Backdrop/CatPeek` composition.
   - Use `res://assets/art/cats/cat_default_peek.png` for `Backdrop/CatPeek` and keep a **42px** bottom overlap against `Backdrop/Panel` top edge.
3. For row spacing and alignment, tune containers under `Backdrop/Panel/Margin/VBox`.
4. Keep node names stable (`MusicSlider`, `ReduceMotionToggle`, etc.) so script auto-discovery continues to work.

## 7) Pause Overlay

Target scene: `res://scenes/ui/pause_overlay.tscn`

1. Open `pause_overlay.tscn`.
2. Tune blur and dim look in `Backdrop` material (`shader_parameter/*`).
3. Adjust ribbon/panel/cat-peek offsets.
4. Use `res://assets/art/cats/cat_default_peek.png` for `Backdrop/CatPeek` and keep a **42px** bottom overlap against `Backdrop/Panel` top edge.
5. Tune icon button row spacing under `ButtonStack/IconRow`.
6. Preserve control node names to avoid script binding regressions.

## 8) HUD (Gameplay UI)

Target scene: `res://scenes/gameplay/gameplay.tscn`
Target hierarchy: `HUD/MarginContainer/TopRow`

1. Open `gameplay.tscn`.
2. Expand HUD nodes.
3. Tune:
   - `MarginContainer` offsets for top insets.
   - `TopRow` separation.
   - `MoveCounter` min size and label font sizes.
   - `CenterPill` and `StarRow` icon sizing.
   - `ButtonRow` spacing and per-button min size.
4. Run gameplay scene and verify no clipping at multiple resolutions.

## 9) Level Content and Puzzle Data

Target files: `res://data/levels/world*/w*_l*.tres`

1. In FileSystem dock, open a level `.tres`.
2. Edit puzzle values in Inspector (`grid_width`, `grid_height`, `obstacle_tiles`, move targets).
3. Save and run gameplay.
4. If you changed puzzle balance, re-run solver and relevant playtests.

## 10) What To Avoid In Visual Edits

- Do not rename scripted node paths casually (many screens use auto-discovery by node name).
- Do not remove expected buttons/toggles without updating corresponding scripts/tests.
- Do not change scene ownership flow in SceneManager from editor-only changes.

## Hand-off Rule (Visual + Core)

When you finish visual edits, send:

1. Scene/resource files changed.
2. What visual intent changed.
3. Any node renames you made.

Then Copilot can handle:

1. Any script adaptation required.
2. Regression checks.
3. Test updates if needed.
