# Game Studio Agent Architecture

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.3
- **Language**: GDScript (primary), C++ via GDExtension (performance-critical)
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@.claude/docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md

## GDScript Development Skills

@.claude/skills/gdscript-patterns/SKILL.md

> Load this before writing any GDScript. Contains type inference rules, known Godot 4 quirks,
> collision layer bitmask table, and common runtime pitfalls.

## Scene Builder & Headless Workflow

@.claude/skills/godot-scene-builder/SKILL.md

> Load when building `.tscn` files programmatically, running headless validation,
> or capturing screenshots on Windows via `--write-movie`.

## Asset Generation (Gemini / Imagen 3)

@.claude/skills/asset-gen/SKILL.md

> Load when generating sprites, textures, backgrounds, or reference art.
> Uses Imagen 3 for text-to-image and Gemini Flash for image editing/variants.
> Includes background removal via `rembg`.

## Response Format

- Always end every response with a "## Suggested Next Steps" section containing actionable prompts/things the user can ask to continue progressing on their game.

# RULES ALWAYS TO FOLLOW

- Always run full test suite and auto capture test after each code change. Verify the screenshots by viewing all images. Only report task completion to the user after all tests have passed successfully. Ensure structural and behavioral integrity through rigorous validation before finality.
- Transparency is mandatory regarding incomplete data migration or pending content. Never claim a task is complete if there is content missing or data pending, even if the code architecture is finished. Playability and data completeness are as important as structural code integrity.
- On Windows, always use 'godot_console.exe' with the '--headless' flag for CLI tasks and automated testing. The standard 'godot.exe' detaches from the terminal and does not stream output/logs back to the console, making it unsuitable for remote agent diagnostics.
- All shell commands on this Windows machine are executed via PowerShell. When constructing commands (e.g. for Godot CLI), ensure syntax is PowerShell-compliant (e.g. using $env:VARIABLE instead of %VARIABLE%).
- CRITICAL: NEVER use destructive Git commands (like 'git checkout --orphan', 'git rm -rf .', or forcing branch switches) for local deployments. This wipes untracked and ignored files (like .claude/, .env, and local assets) from the disk. ALWAYS use GitHub Actions or isolated worktrees for deployment tasks to protect the user's workspace. Failure to do so causes catastrophic data loss.

# Godot Commands

- Godot binary: `godot`
- GUT tests: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gprefix=test_ -gexit 2>&1`
- If doesn't work then `& "C:\Users\Grace\AppData\Local\Godot_v4.3\godot.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gprefix=test_ -gexit 2>&1` (last resort)
- ALWAYS try `godot` before using `& "C:\Users\Grace\AppData\Local\Godot_v4.3\godot.exe"`
- Android exports that invoke the Gradle build must run on Java 17. Java 21 fails with `Invalid Java version 21. Version 17 is the required Java version for Godot gradle builds.`
- On this machine, set `$env:JAVA_HOME = 'C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot'` and prepend `$env:JAVA_HOME\bin` to `$env:Path` before running Android export or `android/build/gradlew.bat`.
- If a CLI Android rebuild needs the signed fallback path, run `android/build_signed_debug.ps1` from the repo root instead of calling `gradlew assembleDebug` directly.

# Automated Playtesting (MCP + Screenshots)

- `tools/playtest_capture.gd` exists as a dev capture helper, but it is not currently registered in `project.godot` as an autoload. Add it temporarily when a session needs gameplay-event screenshots or scripted captures, then remove it again.
- Screenshot output path (Windows): `C:\Users\Grace\AppData\Roaming\Godot\app_userdata\NekoDash\playtest_screenshots\`
- `src/ui/web_capture_router.gd` is the only always-registered capture-related autoload. It ships with current exports because it is in `project.godot`, applies the Web viewport fix on HTML5 builds, and only routes capture flows when the build has the custom feature `dev_capture` and the URL includes `capture_ui=1`.
- UI regression screenshot gate (required after UI edits): run `godot --path . --script tools/ui_snapshot_capture.gd 2>&1`, then inspect `user://playtest_screenshots/ui_verify/options_current.png`, `pause_current.png`, and `level_complete_current.png` before marking the task complete.
- On Windows headless runs, `tools/ui_snapshot_capture.gd` can fail to produce images with the dummy renderer. When that happens, use `tools/web_ui_snapshot_capture.ps1` against a served `Web Dev Capture` export and inspect those PNGs instead.
- Recommended playtest loop:
  1.  Launch scene with `mcp_godot_run_project` (`res://scenes/gameplay/gameplay.tscn`)
  2.  Read runtime logs via `mcp_godot_get_debug_output`
  3.  Open produced screenshots via `view_image`
  4.  Stop process via `mcp_godot_stop_project`
- For end-to-end scripted movement tests, use `tools/playtest_runner.gd` as temporary autoload `PlaytestRunner`.
- Remove any temporary playtest autoloads from `project.godot` after the run unless persistent auto-playtesting is intentionally desired.
- Current export audit: see `docs/export-capture-audit.md`. Fresh May 10 Windows/Web/Android rebuilds exclude the dev-only capture, test, and editor tooling; use `Web Dev Capture` when browser-driven capture routing is required. Android packaging is verified again, but it depends on running the export under Java 17.
