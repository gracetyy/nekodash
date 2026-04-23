# Scene Manager

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Infrastructure (enables all on-screen transitions)

## Overview

The Scene Manager is a Godot autoload singleton (`SceneManager`) that owns all
screen-level navigation in NekoDash. It maintains the current screen state, drives
`get_tree().change_scene_to_file()` transitions, and emits signals that downstream
systems (Music Manager, Input System) subscribe to for context-aware behaviour.
Every transition in the game — from Main Menu to World Map, from World Map to a
level, from a level to the Level Complete Screen — goes through `SceneManager`. No
scene transitions happen via direct `get_tree()` calls from other nodes.

At MVP, transitions are instant (no fade animation). A `transition_started` /
`transition_completed` signal pair provides the hook for a future fade or slide
animation without requiring changes to any caller.

## Player Fantasy

Invisible. The Scene Manager has no player-facing moment. Its failure modes are
the player's experience: a freeze between the Level Complete Screen and the World
Map, a level that loads with stale state still in memory, or the music track lagging
behind the current screen. Getting these right means nothing; getting them wrong is
jarring.

The only indirect player value: snappy, instant scene changes mean the game never
makes the player wait. Mobile puzzle games live and die on pick-up-and-put-down flow.
A scene transition that hesitates — even for a quarter-second — breaks that rhythm.

## Detailed Design

### Screens

NekoDash has exactly six named screens at MVP:

| Screen Enum Value | Scene File Path                       | Description                                               |
| ----------------- | ------------------------------------- | --------------------------------------------------------- |
| `MAIN_MENU`       | `res://scenes/ui/main_menu.tscn`      | Title screen; "Play", "Skins" buttons; equipped cat shown |
| `WORLD_MAP`       | `res://scenes/ui/world_map.tscn`      | Level select grid; shows all worlds and level lock state  |
| `GAMEPLAY`        | `res://scenes/gameplay/gameplay.tscn` | The playfield: grid, HUD, cat; loads a `LevelData`        |
| `LEVEL_COMPLETE`  | `res://scenes/ui/level_complete.tscn` | Post-level results: stars, move count, next/replay/map    |
| `SKIN_SELECT`     | `res://scenes/ui/skin_select.tscn`    | Skin browser and equip screen                             |
| `LOADING`         | `res://scenes/ui/loading.tscn`        | Optional placeholder shown during async loads (stretch)   |

`LOADING` is a stretch goal; at MVP all loads are synchronous and fast enough to
skip it. The enum value is reserved so callers can reference it without code change
when it is implemented.

### Core Rules

1. **Autoload singleton**: `SceneManager` is registered as a Godot autoload. No
   other node calls `get_tree().change_scene_to_file()` directly. All navigation
   goes through `SceneManager.go_to(screen, params)`.

2. **`go_to(screen: Screen, params: Dictionary = {}) -> void`**: The single public
   navigation method. `screen` is a value from the `Screen` enum. `params` is
   optional context passed to the incoming scene (e.g., `{ "level_data": LevelData }`
   for `GAMEPLAY`). Emits `transition_started(from_screen, to_screen)` before the
   swap and `transition_completed(to_screen)` after.

3. **`go_to_level(level_data: LevelData) -> void`**: Convenience wrapper for the
   most common transition. Equivalent to `go_to(Screen.GAMEPLAY, { "level_data": level_data })`.
   Preferred over calling `go_to()` directly from level-select UI.

4. **Parameter handoff**: After `change_scene_to_file()` resolves, `SceneManager`
   calls `_deliver_params(new_scene_root, params)` which looks for a
   `receive_scene_params(params: Dictionary)` method on the new scene root and calls
   it if found. This is the standard contract for passing context into a scene. The
   incoming scene is responsible for reading what it needs; SceneManager does not
   validate param contents.

5. **Current screen tracking**: `SceneManager` stores `_current_screen: Screen` and
   `_previous_screen: Screen`. `get_current_screen() -> Screen` and
   `get_previous_screen() -> Screen` are public read methods. Useful for "back"
   navigation without hardcoding the source.

6. **`go_back() -> void`**: Navigates to `_previous_screen` with no params. Used
   by "back" buttons that don't need to pass context. If `_previous_screen` is
   unset (first navigation), `go_back()` is a no-op with a warning log.

7. **Transition guard**: If `go_to()` is called while a transition is already in
   progress (`_transitioning: bool`), the call is dropped and a warning is logged.
   No queuing. This prevents double-tap or race-condition double transitions.

8. **No transition animation at MVP**: `transition_started` fires, scene swaps
   immediately, `transition_completed` fires. The signal pair is the future hook
   for a fade or slide. The `duration` parameter in `transition_started` is `0.0`
   at MVP; a future animation system reads it.

9. **World context signal**: When navigating to `GAMEPLAY`, `SceneManager` emits
   `world_changed(world_id: String)` after `transition_completed`. Music Manager
   subscribes to this to know when to switch to a new world's ambient track. The
   `world_id` is read from `params["level_data"].world_id` if present; empty string
   if not.

10. **No scene preloading at MVP**: Scenes are loaded synchronously via
    `change_scene_to_file()`. Post-jam: use `ResourceLoader.load_threaded_request()`
    for the GAMEPLAY scene (largest load time) combined with the `LOADING` screen.

### States and Transitions

| State             | Entry Condition                           | Exit Condition                           | Behavior                                             |
| ----------------- | ----------------------------------------- | ---------------------------------------- | ---------------------------------------------------- |
| **Idle**          | App start or `transition_completed` fires | `go_to()` called                         | Current scene is active; no transition in progress   |
| **Transitioning** | `go_to()` called while Idle               | Scene change completes, params delivered | `_transitioning = true`; `go_to()` calls are dropped |

### Allowed Transitions (MVP)

Any screen may transition to any other screen via `go_to()`. The following are the
expected navigation flows — enforced by convention in UI code, not by SceneManager:

| From             | To               | Trigger                                     |
| ---------------- | ---------------- | ------------------------------------------- |
| `MAIN_MENU`      | `WORLD_MAP`      | "Play" button                               |
| `MAIN_MENU`      | `SKIN_SELECT`    | "Skins" button                              |
| `WORLD_MAP`      | `GAMEPLAY`       | Tap a level button                          |
| `WORLD_MAP`      | `MAIN_MENU`      | "Back" button                               |
| `GAMEPLAY`       | `LEVEL_COMPLETE` | `level_completed` fires (Coverage Tracking) |
| `GAMEPLAY`       | `WORLD_MAP`      | "Quit to map" button in HUD                 |
| `LEVEL_COMPLETE` | `GAMEPLAY`       | "Retry" button (same `LevelData`)           |
| `LEVEL_COMPLETE` | `GAMEPLAY`       | "Next Level" button (next `LevelData`)      |
| `LEVEL_COMPLETE` | `WORLD_MAP`      | "Map" button                                |
| `SKIN_SELECT`    | `MAIN_MENU`      | "Back" / "Done" button                      |

SceneManager does not enforce this table — it is documentation for UI programmers.

### Interactions with Other Systems

| System                    | Direction                        | Interface                                                                                                                                                                                  |
| ------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Music Manager**         | Music Manager → SceneManager     | Subscribes to `world_changed(world_id)` and `transition_completed(screen)` to select ambient track.                                                                                        |
| **Input System**          | SceneManager → Input System      | Emits `transition_started` before scene swap; Input System may pause input acceptance during transition (avoids phantom swipes). Provisional — Input System may implement this on its own. |
| **Obstacle System**       | SceneManager → Obstacle System   | Calls `ObstacleSystem.reset()` before unloading the gameplay scene (or Obstacle System's `_exit_tree()` handles cleanup).                                                                  |
| **Coverage Tracking**     | Coverage Tracking → SceneManager | `level_completed` fires → UI layer calls `SceneManager.go_to(Screen.LEVEL_COMPLETE, params)`. SceneManager is not subscribed directly; the HUD or a level coordinator mediates.            |
| **Level Progression**     | Level Progression → SceneManager | Level Progression provides "next level" `LevelData` for the "Next Level" button in Level Complete Screen. SceneManager receives it as a param.                                             |
| **Main Menu**             | Main Menu → SceneManager         | Calls `go_to(Screen.WORLD_MAP)` and `go_to(Screen.SKIN_SELECT)`.                                                                                                                           |
| **World Map**             | World Map → SceneManager         | Calls `go_to_level(level_data)` on level tap.                                                                                                                                              |
| **Level Complete Screen** | Level Complete → SceneManager    | Calls `go_to_level(same_or_next)` for retry/next; `go_to(Screen.WORLD_MAP)` for map.                                                                                                       |
| **Skin Select Screen**    | Skin Select → SceneManager       | Calls `go_back()` on dismiss.                                                                                                                                                              |

## Signals

| Signal                                         | Payload                              | Description                                                         |
| ---------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------- |
| `transition_started(from: Screen, to: Screen)` | from screen, to screen               | Fired before scene swap begins. Duration is `0.0` at MVP.           |
| `transition_completed(to: Screen)`             | current screen after swap            | Fired after scene swap and param delivery complete.                 |
| `world_changed(world_id: String)`              | world ID from the incoming LevelData | Fired after `transition_completed` for `GAMEPLAY` transitions only. |

## Formulas

None. Scene Manager contains no mathematical logic.

## Edge Cases

| Scenario                                                       | Expected Behavior                                                                                                                     | Rationale                                                                    |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `go_to()` called while `_transitioning == true`                | Warning logged; call dropped. No double transition.                                                                                   | Button double-tap guard; mobile touch latency can cause this easily          |
| `go_back()` called with no previous screen (first navigation)  | Warning logged; no-op. Nothing happens.                                                                                               | Prevents crash on unexpected navigation ordering                             |
| `receive_scene_params()` not implemented on the incoming scene | `_deliver_params()` silently skips the call. No error.                                                                                | Not every scene needs params; MAIN_MENU and SKIN_SELECT never receive params |
| `go_to_level()` called with `level_data == null`               | Logs an error; navigation aborted; no scene change.                                                                                   | Null LevelData would crash the gameplay scene; catch early                   |
| App resumes from background (mobile)                           | Scene Manager does not handle OS resume/pause. The existing scene resumes as-is; Input System handles swipe state reset.              | OS lifecycle is Godot's domain; SceneManager manages game-level flow only    |
| `go_to(Screen.LOADING)` called at MVP                          | Navigates to the loading scene as any other screen; no special behaviour. At MVP the loading scene may be a placeholder blank screen. | LOADING is functional even if minimal at MVP                                 |

## Dependencies

| System              | Direction                    | Nature                                                                                            | Hard/Soft                                                                        |
| ------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **Godot SceneTree** | SceneManager → Godot         | Uses `get_tree().change_scene_to_file()`; no alternative path                                     | **Hard** — SceneManager wraps this API                                           |
| **Music Manager**   | Music Manager → SceneManager | Subscribes to `world_changed`; SceneManager emits the signal regardless of whether anyone listens | **Soft** — SceneManager functions without Music Manager                          |
| **Obstacle System** | SceneManager → Obstacle      | Calls `reset()` on level unload; Obstacle System could also self-cleanup via `_exit_tree()`       | **Soft** — depends on final scene architecture; `_exit_tree()` is the safer path |

## Tuning Knobs

No runtime tuning knobs at MVP. Future knobs:

| Parameter                         | Description                                                                        |
| --------------------------------- | ---------------------------------------------------------------------------------- |
| `transition_duration: float`      | Duration of fade/slide animation; `0.0` at MVP; non-zero activates animation layer |
| `transition_type: TransitionType` | Fade, slide-left, slide-right, etc. — enum owned by future animation layer         |

## Visual/Audio Requirements

| Event                  | Owner                                              | Description                                                                                                             | Priority   |
| ---------------------- | -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------- |
| Screen transition fade | SceneManager (hook via signals) + Technical Artist | Future: black fade out → in. `transition_started` fires at fade-out start; `transition_completed` fires at fade-in end. | Stretch    |
| Music track swap       | Music Manager                                      | Subscribes to `world_changed`; fades out old track, fades in new                                                        | MVP-Polish |
| Transition sound       | SFX Manager                                        | Optional whoosh or click on scene change; subscribes to `transition_started`                                            | Stretch    |

## UI Requirements

None. SceneManager is invisible infrastructure. Each individual screen scene owns
its own UI layout and navigation buttons, which call into SceneManager.

## Acceptance Criteria

| #    | Criterion                                                                                                                                              |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| SM-1 | `go_to(Screen.WORLD_MAP)` changes the active scene to `world_map.tscn` and emits `transition_started` then `transition_completed`.                     |
| SM-2 | `go_to_level(level_data)` changes the active scene to `gameplay.tscn` and calls `receive_scene_params({ "level_data": level_data })` on the root.      |
| SM-3 | `get_current_screen()` returns `Screen.GAMEPLAY` after a `go_to_level()` call completes.                                                               |
| SM-4 | `go_to()` called a second time while `_transitioning` is true drops the call and logs a warning; only one transition occurs.                           |
| SM-5 | `go_back()` navigates to the previous screen when one exists; is a no-op with a warning log when no previous screen is recorded.                       |
| SM-6 | `world_changed(world_id)` is emitted after `transition_completed` for a `GAMEPLAY` transition; not emitted for `WORLD_MAP` or `MAIN_MENU` transitions. |
| SM-7 | `go_to_level(null)` logs an error and does not change the active scene.                                                                                |
| SM-8 | A scene that does not implement `receive_scene_params()` loads without error.                                                                          |

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                                                                    | Priority | Owner                                  | Resolution                                      |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------------------- | ----------------------------------------------- |
| OQ-1 | Should the "level coordinator" (the node that listens to `level_completed` and calls `SceneManager.go_to(LEVEL_COMPLETE, params)`) live in the gameplay scene root, or should it be a separate autoload? Provisional: gameplay scene root owns a `LevelCoordinator` node — keeps level-flow logic scene-local, avoids yet another autoload. | Medium   | Resolve during Undo/Restart or HUD GDD | Provisional: scene-local coordinator            |
| OQ-2 | For the "Next Level" button in Level Complete Screen, who resolves the next `LevelData`? Level Progression (autoload) or a param passed in from the level coordinator? Provisional: Level Progression provides `get_next_level(current_level_id)` and Level Complete Screen calls it directly; no extra SceneManager param needed.          | Low      | Resolve during Level Progression GDD   | Provisional: Level Progression queried directly |
| OQ-3 | Does SceneManager need a `reload_current()` shortcut for restarting a level without going to the World Map? Undo/Restart will need to reset in-level state, not reload the scene. Provisional: no scene reload for restart — Undo/Restart handles in-place level reset; `reload_current()` is not needed at MVP.                            | Low      | Resolve during Undo/Restart GDD        | Provisional: no reload method                   |
