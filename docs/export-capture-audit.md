# Export Tooling Audit

**Date:** May 10, 2026

This audit now covers both capture-related tooling and the broader non-game files that were leaking into shipping exports. It reflects the current preset configuration in `export_presets.cfg`, fresh Windows/Web/Android verification performed on May 10, 2026, browser-based verification of the Web capture split, and the repo-side Android fallback wrapper `android/build_signed_debug.ps1` that is required when the direct Godot Android export stalls after refreshing `android/build/assets`.

## Pre-Ship Checklist

- Rebuild every shipping target that is part of the release: `Windows Desktop`, `Web`, and `Android` when Android is shipping.
- Review each fresh exporter log for `savepack: end` and verify there are no `Storing File:` entries for `tests/**`, `addons/gut/**`, `addons/ui_design_tool/**`, `addons/gui_auto_layout/**`, or the excluded dev-only `tools/*.gd` helpers.
- Serve the shipping Web export and confirm `capture_ui=1&screen=options` stays inert instead of routing away from the normal main-menu flow.
- Serve the `Web Dev Capture` export and confirm the same URL opens the requested capture screen, which verifies the `dev_capture` split still works.
- Run the full GUT suite.
- Run `tools/ui_snapshot_capture.gd`; if headless Windows skips screenshots because of the dummy renderer, run `tools/web_ui_snapshot_capture.ps1` against a served `Web Dev Capture` export and inspect the generated options, pause, and level-complete images.
- For Android, use `android/build_signed_debug.ps1` when the direct Godot export does not finish the Gradle package step. The wrapper sets Java 17, applies `perform_signing=true`, carries the Android preset metadata from `export_presets.cfg`, and copies the signed APK back to `android/build/nekodash.apk` and `android/build/NekoDash.apk`.
- For Android, confirm the APK timestamp changed, `apksigner verify --verbose --print-certs` succeeds, and the APK installs and launches on an emulator or device before trusting the result.

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

| Platform        | Artifact status                          | Dev-only capture/test/editor tooling          | Runtime-required exceptions | Notes                                                                                                                                                                                                                                                                                                                                                                                    |
| --------------- | ---------------------------------------- | --------------------------------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Windows Desktop | Fresh rebuild completed on May 10        | Not present in `savepack` output              | Present                     | Export finished with the same pre-existing project warnings, stayed alive during startup smoke, created a main window, and wrote a runtime log.                                                                                                                                                                                                                                          |
| Web             | Fresh rebuild completed on May 10        | Not present in `savepack` output              | Present                     | Shipping Web stayed on the normal main-menu flow when `capture_ui=1&screen=options` was tested with an isolated browser profile. An earlier non-isolated probe that opened Options was a stale browser-state false positive.                                                                                                                                                             |
| Web Dev Capture | Fresh rebuild completed on May 10        | Same exclusions as shipping Web               | Present                     | Desktop capture routes for Options, Pause, and Level Complete rendered correctly. Some mobile routes still only reached the Godot loading screen within the current capture budgets, so mobile dev-capture verification is only partial.                                                                                                                                                 |
| Android         | Fresh signed rebuild completed on May 10 | Not found in generated `android/build/assets` | Present                     | Direct Godot export still stalled after refreshing `android/build/assets`, but `android/build_signed_debug.ps1` rebuilt the generated Gradle project in a temp directory with Java 17, `perform_signing=true`, and the Android preset metadata. The resulting APK verifies with `apksigner`, installs on the local emulator, and launches as `io.itch.nekodash/com.godot.game.GodotApp`. |

## Capture-Related Files Still Ending Up In Shipped Builds

For the fresh May 10 shipping rebuilds that were verified in this session:

- `src/ui/web_capture_router.gd` still ships in Windows and Web because it is an autoloaded project script.
- No blocked dev-only capture, test, or editor files were found in the generated `android/build/assets` tree before the final signed Android package step.
- The Android runtime-required `tools/level_solver.gd` and `addons/godot_ui_animations/UIAnimationHandler.tscn` content still survives in exported/remapped form under `android/build/assets/tools/level_solver.gd.remap`, `android/build/assets/tools/level_solver.gdc`, and `android/build/assets/addons/godot_ui_animations/UIAnimationHandler.tscn.remap`.

## Browser Verification Of The New Web Split

Two direct browser probes were run against local servers:

- Shipping Web export with `capture_ui=1&screen=options&delay_ms=5000` using an isolated browser profile
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
- Mobile `Web Dev Capture` screenshots for `world_map_mobile_web.png`, `skin_select_mobile_web.png`, and `options_mobile_web.png` still showed the Godot loading screen within the current capture budgets and should be treated as a remaining verification gap.
- The original unsigned Android failure was caused by invoking `gradlew assembleDebug` without `-Pperform_signing=true`; `android/build/config.gradle` defaults signing off for non-Android-Studio builds unless that property is explicitly supplied.
- `android/build_signed_debug.ps1` now rebuilds from a temp copy of the generated Gradle project, applies Java 17 and the Android preset metadata, verifies the result with `apksigner`, and writes the signed APK back to `android/build/nekodash.apk` and `android/build/NekoDash.apk`.
- The final signed Android APK installed successfully on the local `Medium_Phone` emulator, and `dumpsys activity` reported `io.itch.nekodash/com.godot.game.GodotApp` as the top resumed activity.

## Evidence Methodology

- For fresh Windows and Web exports, the exporter `savepack` log is the authoritative source for whether a file was packaged.
- Raw `rg -a` probes against `.pck` files can still surface excluded paths from metadata such as `project.binary` or script caches, so they are useful for spot checks but not authoritative on their own.
- For Android, the generated `android/build/assets` tree is the authoritative pre-Gradle payload source when the direct Godot export stalls before final packaging.
- For Android CLI fallback builds, use `android/build_signed_debug.ps1` instead of a bare `gradlew assembleDebug`; otherwise Gradle will emit an unsigned APK and may also fall back to the default `com.godot.game` application id instead of the Android export preset metadata.
