# Export Tooling Audit

**Date:** May 9, 2026

This audit now covers both capture-related tooling and the broader non-game files that were leaking into shipping exports. It reflects the current preset configuration in `export_presets.cfg`, fresh Windows and Web rebuilds performed on May 9, 2026, browser-based verification of the new Web capture split, and the still-stale Android APK currently checked into `android/build/nekodash.apk`.

## Pre-Ship Checklist

- Rebuild every shipping target that is part of the release: `Windows Desktop`, `Web`, and `Android` when Android is shipping.
- Review each fresh exporter log for `savepack: end` and verify there are no `Storing File:` entries for `tests/**`, `addons/gut/**`, `addons/ui_design_tool/**`, `addons/gui_auto_layout/**`, or the excluded dev-only `tools/*.gd` helpers.
- Serve the shipping Web export and confirm `capture_ui=1&screen=options` stays inert instead of routing away from the normal main-menu flow.
- Serve the `Web Dev Capture` export and confirm the same URL opens the requested capture screen, which verifies the `dev_capture` split still works.
- Run the full GUT suite.
- Run `tools/ui_snapshot_capture.gd`; if headless Windows skips screenshots because of the dummy renderer, run `tools/web_ui_snapshot_capture.ps1` against a served `Web Dev Capture` export and inspect the generated options, pause, and level-complete images.
- For Android, confirm the APK timestamp changed before trusting any APK string probe or packaging result.

## Current Preset Configuration

- `Android`, `Windows Desktop`, and `Web` still use `export_filter="all_resources"`.
- All three shipping presets now have expanded `exclude_filter` values that remove:
  - `tests/**`
  - `addons/gut/**`
  - `addons/ui_design_tool/**`
  - `addons/gui_auto_layout/**`
  - dev-only capture and snapshot scripts under `tools/`
  - editor-only helpers
- A dedicated `Web Dev Capture` preset now exists with `custom_features="dev_capture"` and export output at `export/web-dev/index.html`.

## Runtime Rules After The Split

- `tools/playtest_capture.gd` still exists in the repo, but it is not autoloaded in `project.godot`.
- `src/ui/web_capture_router.gd` remains autoloaded and therefore remains present in exports that include project autoloads.
- `WebCaptureRouter` now always applies the Web viewport fix on HTML5 builds, but it only routes capture flows when all of the following are true:
  - the build has the custom feature `dev_capture`
  - the URL includes `capture_ui=1`
  - the requested screen is one of the known capture routes
- Result: the shipping Web preset ignores `capture_ui=1`, while the `Web Dev Capture` preset still supports browser-driven snapshot routing.

## Runtime-Required Exceptions

These files are under tooling-style paths, but they are intentionally still shipped because gameplay or the platform shell depends on them:

- `src/ui/web_capture_router.gd`
- `tools/level_solver.gd`
- `tools/web_custom_shell.html`
- `addons/godot_ui_animations/UIAnimationHandler.tscn`

`tools/level_solver.gd` is loaded by gameplay code, `tools/web_custom_shell.html` is the configured Web shell, and `addons/godot_ui_animations` is required by the `UIAnimation` autoload.

## Pre-Fix Leakage

Before the preset cleanup in this session, direct payload probes showed all three platforms shipping some combination of:

- `tests/**`
- `addons/gut/**`
- `addons/ui_design_tool/**`
- `addons/gui_auto_layout/**`
- `tools/playtest_capture.gd`
- `tools/playtest_m2_runner.gd`
- `tools/playtest_runner.gd`
- `tools/shell_polish_capture.gd`
- `tools/shell_polish_playtest_capture.gd`
- `tools/shell_smoke_capture.gd`
- `tools/ui_snapshot_capture.gd`

The root cause was not autoload registration. It was `all_resources` plus narrow excludes.

## Post-Cleanup Packaging Status

| Platform        | Artifact status                                | Dev-only capture/test/editor tooling | Runtime-required exceptions              | Notes                                                                                                                                                                                                                      |
| --------------- | ---------------------------------------------- | ------------------------------------ | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Windows Desktop | Fresh rebuild completed on May 9               | Not present in `savepack` output     | Present                                  | Export finished with pre-existing project warnings, but no `Storing File:` matches remained for `tests/**`, `addons/gut/**`, `addons/ui_design_tool/**`, `addons/gui_auto_layout/**`, or the excluded `tools/*.gd` helpers |
| Web             | Fresh rebuild completed on May 9               | Not present in `savepack` output     | Present                                  | Same packaging result as Windows Desktop                                                                                                                                                                                   |
| Web Dev Capture | Fresh rebuild completed on May 9               | Same exclusions as shipping Web      | Present                                  | Adds only the `dev_capture` custom feature, not the excluded dev-only scripts                                                                                                                                              |
| Android         | No fresh post-fix APK produced in this session | Post-fix status unverified           | Stale APK still contains pre-fix leakage | `android/build/nekodash.apk` still has an April 3, 2026 timestamp and still exposes old leaked paths, so it cannot be treated as a post-fix result                                                                         |

## Capture-Related Files Still Ending Up In Shipped Builds

For the fresh May 9 shipping rebuilds that were actually produced in this session:

- `src/ui/web_capture_router.gd` still ships in Windows and Web because it is an autoloaded project script.

For the currently checked-in Android APK on disk:

- `assets/tests/**`
- `assets/tools/playtest_capture.gd`
- `assets/tools/playtest_runner.gd`
- other pre-fix tooling strings still appear in the stale APK payload

That Android APK is not a valid post-cleanup verification artifact.

## Browser Verification Of The New Web Split

Two direct browser probes were run against local servers:

- Shipping Web export with `capture_ui=1&screen=options&delay_ms=5000`
  - Result: remained on the main menu
  - Evidence screenshot: `screenshots/export_audit/web_shipping_options_probe.png`
- `Web Dev Capture` export with the same query string
  - Result: opened the options overlay as expected
  - Evidence screenshot: `screenshots/export_audit/web_dev_options_probe.png`

This confirms that the runtime capture behavior is now behind the dedicated `dev_capture` feature rather than being available to the normal Web export.

## Validation Notes

- Full GUT suite after the change: 691 / 691 passing.
- `tools/ui_snapshot_capture.gd` still hits the known headless dummy-renderer limitation on Windows and reports null-image skips.
- The documented fallback `tools/web_ui_snapshot_capture.ps1` was run against the served `Web Dev Capture` export.
- Fresh desktop screenshots were inspected for:
  - `options_desktop_web.png`
  - `pause_desktop_web.png`
  - `level_complete_desktop_web.png`

## Evidence Methodology

- For fresh Windows and Web exports, the exporter `savepack` log is the authoritative source for whether a file was packaged.
- Raw `rg -a` probes against `.pck` files can still surface excluded paths from metadata such as `project.binary` or script caches, so they are useful for spot checks but not authoritative on their own.
- For Android, the stale artifact timestamp is the decisive reason the current APK probe cannot be used as post-fix evidence.
