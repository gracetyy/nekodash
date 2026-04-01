# Level Coordinator

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-04-02
> **System #**: 23 of 23
> **Category**: Engine / Coordination
> **Priority**: MVP-Core

---

## Overview

The Level Coordinator is the root node of `res://scenes/gameplay/gameplay.tscn`. It
owns the initialization order of all per-level-session systems, enforces the critical
`slide_completed` signal connection order, snapshots the player's previous-best data at
level load time, and orchestrates the transition to the Level Complete Screen once
`level_record_saved` fires.

The Level Coordinator is **not** an autoload. It lives only for the duration of the
gameplay scene. When SceneManager loads `gameplay.tscn`, it calls
`receive_scene_params()` on the scene root (this node) with the `LevelData` resource
for the level to play.

---

## Player Fantasy

The Level Coordinator is invisible. The player never sees it, names it, or interacts
with it. Its player fantasy is the feeling that _everything just works_: the cat appears
at the right tile, the first swipe registers correctly, the move counter starts at zero,
and when the last tile lights up the results screen appears with the right star count.
Getting the Level Coordinator right means the player never experiences a broken state —
a level that starts with coverage already at 100%, a star rating that's off by a move,
or a Next Level button that leads somewhere wrong. It is foundation work.

---

## Responsibilities

| Responsibility                                           | Owned By             |
| -------------------------------------------------------- | -------------------- |
| Receiving `LevelData` from Scene Manager                 | Level Coordinator ✅ |
| Initializing all per-level systems in correct order      | Level Coordinator ✅ |
| Enforcing `slide_completed` connection order             | Level Coordinator ✅ |
| Snapshotting player's previous-best data at level load   | Level Coordinator ✅ |
| Subscribing to `level_record_saved` for transition logic | Level Coordinator ✅ |
| Building the Level Complete Screen params dict           | Level Coordinator ✅ |
| Triggering scene transition to Level Complete Screen     | Level Coordinator ✅ |
| Game logic (sliding, coverage, scoring)                  | Child systems        |
| Persisting records                                       | Save / Load System   |
| Scene loading and unloading                              | Scene Manager        |

---

## Detailed Design

### Scene Hierarchy

```
LevelCoordinator           ← root node (this document)
├── GridSystem
├── ObstacleSystem
├── SlidingMovement
│   └── CatSprite
├── CoverageTracking
├── CoverageVisualizer
├── MoveCounter
├── StarRatingSystem
├── LevelProgression
├── UndoRestart
└── HUD (CanvasLayer)
```

Autoloads called: `SaveManager`, `SceneManager`.

### Initialization Order

`receive_scene_params()` is called by SceneManager before `_ready()` fires. The node
stores `_current_level_data` immediately. Then `_ready()` proceeds:

```gdscript
func receive_scene_params(params: Dictionary) -> void:
    _current_level_data = params.get("level_data") as LevelData

func _ready() -> void:
    _snapshot_previous_bests()  # MUST happen first — before any save write
    _initialize_systems()
    _connect_signals()
```

**Step 1 — Snapshot previous bests**

```gdscript
func _snapshot_previous_bests() -> void:
    var id := _current_level_data.level_id
    _prev_best_moves = SaveManager.get_best_moves(id)       # 0 if never played
    _was_previously_completed = SaveManager.is_level_completed(id)
```

Snapshotting here is the **only** safe time: `level_record_saved` has not yet fired,
so SaveManager holds the player's previous-session data. Any read after the save write
would return the current attempt's data.

**Step 2 — Initialize child systems**

```gdscript
func _initialize_systems() -> void:
    var spawn_pos: Vector2i = _current_level_data.spawn_position

    _grid_system.initialize(_current_level_data)
    _obstacle_system.initialize(_current_level_data, _grid_system)
    _sliding_movement.initialize_level(spawn_pos)

    # Coverage tracking must know the full walkable set before slides begin
    _coverage_tracking.initialize(_current_level_data, _grid_system)
    _coverage_visualizer.initialize_level(
        _grid_system.get_grid_width(), _grid_system.get_grid_height()
    )

    _move_counter.initialize(_current_level_data)
    _star_rating_system.set_level_id(_current_level_data.level_id)
    _level_progression.set_current_level(_current_level_data)
    _undo_restart.initialize(_current_level_data, spawn_pos)
    _hud.initialize(_undo_restart, _move_counter, _coverage_tracking)
```

**Step 3 — Connect signals (order is critical)**

```gdscript
func _connect_signals() -> void:
    # slide_completed order: UndoRestart FIRST, MoveCounter SECOND, CoverageTracking THIRD
    # — see "Signal Connection Order" section for rationale
    _sliding_movement.slide_completed.connect(_undo_restart._on_slide_completed)
    _sliding_movement.slide_completed.connect(_move_counter._on_slide_completed)
    _sliding_movement.slide_completed.connect(_coverage_tracking._on_slide_completed)

    # spawn_position_set: CoverageTracking pre-covers starting tile
    _sliding_movement.spawn_position_set.connect(
        _coverage_tracking._on_spawn_position_set
    )
    _sliding_movement.spawn_position_set.connect(
        _coverage_visualizer._on_spawn_position_set
    )

    # Tile coverage → visual update
    _coverage_tracking.tile_covered.connect(_coverage_visualizer._on_tile_covered)
    _coverage_tracking.coverage_updated.connect(_hud._on_coverage_updated)

    # level_completed chain
    _coverage_tracking.level_completed.connect(_undo_restart._on_level_completed)
    _coverage_tracking.level_completed.connect(_hud._on_level_completed)
    _coverage_tracking.level_completed.connect(_star_rating_system._on_level_completed)

    # rating_computed → LevelProgression saves record
    _star_rating_system.rating_computed.connect(_level_progression._on_rating_computed)

    # level_record_saved → Level Coordinator triggers scene transition
    _level_progression.level_record_saved.connect(_on_level_record_saved)

    # Undo/Restart → HUD
    _undo_restart.undo_applied.connect(_hud._on_undo_applied)
    _undo_restart.level_restarted.connect(_hud._on_level_restarted)

    # Move counter → HUD + StarRatingSystem
    _move_counter.move_count_changed.connect(_hud._on_move_count_changed)
```

### Signal Connection Order

Three systems subscribe to `slide_completed`. The order matters:

| Connection # | System           | Why                                                                                                                                                                                                                                                            |
| ------------ | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1st**      | UndoRestart      | Must snapshot pre-mutation state (`cat_pos_before`, `coverage_before`, `move_count_before`) before MoveCounter or CoverageTracking mutate their values.                                                                                                        |
| **2nd**      | MoveCounter      | Must increment before CoverageTracking runs. On the final slide, CoverageTracking emits `level_completed` → StarRatingSystem reads `get_final_move_count()`. If MoveCounter hasn't incremented yet, the star rating is computed with an off-by-one move count. |
| **3rd**      | CoverageTracking | Runs last. By the time it processes the slide (and possibly emits `level_completed`), UndoRestart has a correct snapshot and MoveCounter has the correct count.                                                                                                |

> **Critical**: this order must never be changed. If a system needs to subscribe
> to `slide_completed` for a new reason, place it between MoveCounter and
> CoverageTracking (or after CoverageTracking) — never before UndoRestart.

### Level Complete Flow

`level_record_saved` fires synchronously at the end of the
`level_completed → rating_computed → level_record_saved` signal chain. By the
time `_on_level_record_saved` is called, SaveManager has already written the record
and all in-scene query APIs return current-attempt values.

```gdscript
const LEVEL_COMPLETE_OVERLAY_DELAY_SEC: float = 0.6

func _on_level_record_saved(level_id: int, stars: int, final_moves: int) -> void:
    var next_level := _level_progression.get_next_level(level_id)  # LevelData or null
    var params := {
        "level_data":               _current_level_data,
        "stars":                    stars,
        "final_moves":              final_moves,
        "prev_best_moves":          _prev_best_moves,
        "was_previously_completed": _was_previously_completed,
        "next_level_data":          next_level,
    }
    # Register transition synchronously so SceneManager is ready immediately:
    SceneManager.go_to(Screen.LEVEL_COMPLETE, params)
    # Brief beat — lets the player see tiles fully lit before overlay appears:
    await get_tree().create_timer(LEVEL_COMPLETE_OVERLAY_DELAY_SEC).timeout
    if _state != State.TRANSITIONING:
        return  # guard: restart during delay has re-entered PLAYING
    _show_level_complete_overlay(params)
```

All values are plain data types or resource objects — no node references. The gameplay
scene is about to be unloaded by SceneManager; passing a node reference into the next
scene's params would be unsafe.

**`_on_overlay_next` — advancing to the next level inline**

When the player taps Next on the inline overlay (before `level_complete.tscn` exists),
the coordinator re-initializes all systems for the next level without a scene reload.
Critically, `_snapshot_previous_bests()` **must** be called immediately after
`_current_level_data` is updated — the same reason it is called first in `_ready()`: the
save record for the new level must be read before any signal chain can overwrite it.

```gdscript
func _on_overlay_next(next_level: LevelData) -> void:
    if _overlay != null:
        _overlay.queue_free()
        _overlay = null
    _current_level_data = next_level
    _snapshot_previous_bests()   # MUST happen before _initialize_systems()
    _disconnect_signals()
    _initialize_systems()
    _connect_signals()
    _sliding_movement.initialize_level(_current_level_data.cat_start)
    _state = State.PLAYING
```

---

## Signals

The Level Coordinator itself emits no signals. It is a consumer and orchestrator. All
cross-system signalling is wired through `_connect_signals()`.

---

## States and Transitions

| State             | Entry Condition                                             | Exit Condition                  | Behavior                                                                                                                                                                    |
| ----------------- | ----------------------------------------------------------- | ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Loading**       | Scene instantiated; `receive_scene_params()` not yet called | `receive_scene_params()` called | `_current_level_data` not yet set; no child systems ready                                                                                                                   |
| **Initializing**  | `receive_scene_params()` called                             | `_ready()` completes            | Systems initialized; signals connected; snapshot taken                                                                                                                      |
| **Playing**       | `_ready()` complete                                         | `level_record_saved` fires      | All systems active; player can move, undo, and restart                                                                                                                      |
| **Transitioning** | `level_record_saved` fired                                  | Scene unloaded by SceneManager  | `SceneManager.go_to()` called; `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` timer running; overlay shown after delay. Restart during this window re-enters Playing and skips overlay. |

---

## Edge Cases

| Scenario                                                               | Expected Behavior                                                                                                              |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `receive_scene_params()` called without `level_data` key               | Log an error and load a default/placeholder `LevelData`; do not crash                                                          |
| `level_data.spawn_position` outside grid bounds                        | GridSystem and SlidingMovement will detect and log; Level Coordinator does not validate — it delegates to child systems        |
| `get_next_level()` returns `null` (last level)                         | Passed as `null` in params; Level Complete Screen hides Next Level button                                                      |
| `level_record_saved` fires while scene transition is already in flight | `SceneManager.go_to()` is idempotent; duplicate call is either ignored or queued (SceneManager's responsibility)               |
| Player restarts during the `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` window   | `_state` reverts to `Playing`; the `await` continuation checks `_state != TRANSITIONING` and returns immediately — no overlay. |
| Child node missing from scene tree                                     | `@onready` var will be `null`; first method call on it crashes with a clear null-reference error. Check scene structure first. |

---

## Acceptance Criteria

| #     | Criterion                                                                                                                                       |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| LC-1  | `receive_scene_params()` is called before `_ready()`; all child systems initialize with the correct `LevelData`.                                |
| LC-2  | `_prev_best_moves` reflects the player's previous-session best, not the current attempt's final move count.                                     |
| LC-3  | `slide_completed` connection order is UndoRestart → MoveCounter → CoverageTracking.                                                             |
| LC-4  | On the final slide, `StarRatingSystem` reads the incremented move count (not off-by-one).                                                       |
| LC-5  | `level_record_saved` triggers `SceneManager.go_to(Screen.LEVEL_COMPLETE, ...)` exactly once per level.                                          |
| LC-6  | All six keys are present in the params dict passed to Level Complete Screen.                                                                    |
| LC-7  | No node references are included in the params dict — only plain types and resources.                                                            |
| LC-8  | On `restart()`, all child systems return to their initial state without a scene reload.                                                         |
| LC-9  | The level-complete overlay appears no sooner than `LEVEL_COMPLETE_OVERLAY_SEC` after `level_record_saved` fires.                                |
| LC-10 | `_snapshot_previous_bests()` is called immediately after `_current_level_data` is changed in `_on_overlay_next`, before any system initializes. |

---

## Dependencies

| Depends On             | Interface Used                                                         | Hard/Soft |
| ---------------------- | ---------------------------------------------------------------------- | --------- |
| **LevelData**          | `level_id`, `spawn_position`, passed to all child systems              | Hard      |
| **Save / Load System** | `get_best_moves()`, `is_level_completed()` — read at level load only   | Hard      |
| **Scene Manager**      | `go_to(Screen.LEVEL_COMPLETE, params)` — triggers scene transition     | Hard      |
| **All child systems**  | `initialize()`, signal subscriptions — see Initialization Order above  | Hard      |
| **Level Progression**  | `set_current_level()`, `get_next_level()`, `level_record_saved` signal | Hard      |
| **Star Rating System** | `set_level_id()`, `rating_computed` signal                             | Hard      |

---

## Tuning Knobs

| Constant                           | Default | Effect                                                                                                        |
| ---------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------- |
| `LEVEL_COMPLETE_OVERLAY_DELAY_SEC` | `0.6`   | Seconds between full grid coverage and overlay appearance. Provides the satisfying pause before results show. |

All other initialization is structural (scene hierarchy and signal wiring). The
signal connection order is a correctness constraint, not a design variable.

---

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                 | Priority | Resolution                                                                                                                                |
| ---- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should the Level Coordinator also handle SFX and Music Manager calls on level load (e.g., start the level music track)? Or should MusicManager subscribe to `SceneManager.scene_changed`?                                                                                                | Medium   | Provisional: Level Coordinator calls `MusicManager.play_gameplay_track()` in `_ready()`. Simpler than a global scene-change subscription. |
| OQ-2 | The `level_record_saved` signal fires with `(level_id, stars, final_moves)` from LevelProgression. If LevelProgression's API changes, Level Coordinator must be updated. Should Level Coordinator instead call a `get_last_result()` method on LevelProgression after `level_completed`? | Low      | Provisional: keep signal args — avoids coupling to a new getter API.                                                                      |
