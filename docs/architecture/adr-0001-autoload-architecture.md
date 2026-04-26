# ADR-0001: Autoload Architecture

## Status

Accepted

## Date

2025-01-01

## Context

### Problem Statement

NekoDash has 23 systems. Some must survive scene transitions and be globally accessible (e.g., save data, scene navigation); others are transient per-level nodes that must reset cleanly between sessions. Without a recorded rule deciding which systems are autoloads and which are scene-instanced nodes, future contributors will encounter inconsistent architecture and fragile lifetime assumptions.

### Constraints

- Godot 4.3 autoloads are singletons attached to the root node before any scene loads.
- Autoloads cannot be freed mid-session without breaking all references to them.
- Jam timeline: no time for a full dependency-injection framework.
- Mobile-first: 60 FPS target, ≤256 MB memory — autoloads persist in memory permanently.

### Requirements

- Must be accessible from any scene without finding nodes in the tree.
- Must not hold per-level mutable state that needs resetting between levels.
- Must be safe to access before the gameplay scene is loaded.
- Governing rule must be simple enough to apply consistently for any future system additions.

## Decision

**Six systems are registered as Godot autoloads.** All other systems are scene-instanced nodes.

### Governing Rule

A system becomes an autoload if and only if it satisfies **all three** of:

1. **Cross-scene lifetime** — must survive scene transitions and remain valid between level loads.
2. **Multi-context access** — accessed from ≥2 unrelated scene contexts (e.g., both gameplay and UI scenes).
3. **No per-level mutable state** — does not own state that must reset when a new level begins.

Any system failing any criterion is a scene node, instantiated fresh per scene.

### Autoload Roster

| Order | Autoload           | File                            | Rationale                                                                                                                   |
| ----- | ------------------ | ------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1     | `SaveManager`      | `src/core/save_manager.gd`      | Persistent save data; read/written from gameplay, UI, and menu scenes.                                                      |
| 2     | `SceneManager`     | `src/core/scene_manager.gd`     | Controls all scene transitions; must exist before any scene is loaded. Depends on `SaveManager` for skin state.             |
| 3     | `SFXManager`       | `src/core/sfx_manager.gd`       | Pooled AudioStreamPlayer nodes must persist across scenes; pool would be destroyed on scene change if scene-instanced.      |
| 4     | `MusicManager`     | `src/core/music_manager.gd`     | Crossfade requires two AudioStreamPlayer nodes alive across transitions; scene-destruct would cut audio.                    |
| 5     | `CosmeticDatabase` | `src/core/cosmetic_database.gd` | Static read-only skin registry; accessed from gameplay, menus, and UI. No mutable state.                                    |
| 6     | `MilestoneTracker` | `src/core/milestone_tracker.gd` | Subscribes to `SaveManager.level_record_updated`; must survive level→UI transitions to catch signals fired during teardown. |

**Autoload load order matters**: `SaveManager` loads first (no deps); `SceneManager` second (reads `SaveManager`); audio managers third/fourth (no cross-deps); `CosmeticDatabase` fifth (reads `SkinDatabase` resource, no autoload deps); `MilestoneTracker` sixth (connects to `SaveManager` signal in `_ready()`).

### Systems That Are NOT Autoloads

| System             | Why Not an Autoload                                                                                                                              |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `LevelProgression` | Owns per-level mutable state (`current_level`, star tracking ref). Must reset cleanly when a new level loads. Instantiated by Level Coordinator. |
| `HUD`              | UI layer scoped to the gameplay scene. Destroyed and rebuilt each level for clean state.                                                         |
| `StarRatingSystem` | Stateless calculator node; no cross-scene lifetime needed. Instantiated in gameplay scene.                                                       |
| `UndoRestart`      | Owns undo history stack — per-level mutable state. Must reset on restart.                                                                        |
| `MoveCounter`      | Owns `move_count` int — per-level mutable counter. Must reset on restart.                                                                        |
| `CoverageTracking` | Owns covered-tile set — per-level mutable state. Must reset per level.                                                                           |

### Architecture Diagram

```
Root (Godot SceneTree)
├── SaveManager          [autoload #1]
├── SceneManager         [autoload #2]
├── SFXManager           [autoload #3]
├── MusicManager         [autoload #4]
├── CosmeticDatabase     [autoload #5]
├── MilestoneTracker     [autoload #6]
└── CurrentScene         [swapped by SceneManager]
    └── ... (gameplay nodes, UI nodes, menus — all transient)
```

### Key Interfaces

```gdscript
# Access pattern for autoloads (from any script):
SaveManager.get_level_record(level_id)
SceneManager.go_to(SceneManager.Screen.WORLD_MAP)
SFXManager.play(stream, pitch)
MusicManager  # signal-driven; no direct calls from gameplay
CosmeticDatabase.get_skin(skin_id)
MilestoneTracker  # internal; no direct calls from other systems
```

## Alternatives Considered

### Alternative 1: Full Dependency Injection (No Autoloads)

- **Description**: Every system is instantiated in a root composition node and passed to dependents as constructor arguments or via `initialize()` calls.
- **Pros**: No global state; fully testable; no hidden dependencies.
- **Cons**: Requires significant boilerplate for a 22-system jam game; `initialize()` chains become error-prone; incompatible with Godot's scene-instancing workflow for UI scenes.
- **Rejection Reason**: Jam timeline constraint. Adds 200–400 lines of wiring code with no gameplay value.

### Alternative 2: SaveManager-Only Autoload

- **Description**: Only `SaveManager` is an autoload; audio managers and `SceneManager` are passed by reference or retrieved via group.
- **Pros**: Minimises global singletons.
- **Cons**: Audio pool nodes would be destroyed on every scene change, causing audio cuts on transitions; `SceneManager` would need to find itself via group lookups, which is fragile.
- **Rejection Reason**: Audio crossfades and scene transitions require node persistence across scene changes — only autoloads provide this in Godot.

### Alternative 3: Everything as an Autoload

- **Description**: All 23 systems registered as autoloads.
- **Pros**: Trivially accessible from anywhere.
- **Cons**: `LevelProgression`, `MoveCounter`, `UndoRestart`, `CoverageTracking` all own per-level mutable state. As autoloads they would require explicit manual `reset()` calls before every level — a fragile discipline guarantee. Any missed reset = corrupted state in the next level. Defeats the purpose of Godot's scene lifecycle.
- **Rejection Reason**: Scene-lifecycle reset is safer and more idiomatic than manual reset discipline for per-level state.

## Consequences

### Positive

- State lifetime is explicit: autoloads = permanent, scene nodes = reset on scene change.
- No boilerplate injection wiring for the 6 cross-cutting systems.
- Audio and scene transitions work correctly without extra persistence logic.
- Future contributors have a clear rule for classifying any new system.

### Negative

- Six global singletons exist — any code can call any autoload without expressing the dependency explicitly.
- Unit testing autoload-dependent code in isolation requires mocking singletons.
- Load order must be maintained manually in Project Settings.

### Risks

- **Risk**: A future system is incorrectly made an autoload, leaking per-level state. **Mitigation**: Apply the three-criterion rule above. If any criterion fails, the system is a scene node.
- **Risk**: `MilestoneTracker` missing a `level_record_updated` signal if `SaveManager` registers it after `MilestoneTracker._ready()`. **Mitigation**: Load order guarantees `SaveManager` loads first; `MilestoneTracker` connects in `_ready()` which runs after all autoloads are instantiated.
- **Risk**: Circular autoload dependencies. **Mitigation**: Only `SceneManager` and `MilestoneTracker` reference `SaveManager`; no other inter-autoload dependencies exist. Load order enforces this.

## Performance Implications

- **CPU**: Negligible — 6 autoload singletons have no per-frame processing.
- **Memory**: ~constant overhead for 6 nodes + `SkinDatabase` resource loaded by `CosmeticDatabase`. Well within 256 MB budget.
- **Load Time**: All 6 autoloads load before the first scene; adds ~1–5 ms cold start (estimated). Acceptable.
- **Network**: Not applicable.

## Migration Plan

This ADR records the intended architecture for a new project. No migration required. At implementation time:

1. Register all 6 autoloads in `project.godot` under `[autoload]` in load order.
2. Verify `SaveManager` initialises cleanly before all others.
3. Confirm `project.godot` autoload section matches the roster table above before any gameplay code is written.

## Validation Criteria

- All 6 autoloads are present and load without errors when the project opens.
- `LevelProgression` is **not** in the autoload list in `project.godot`.
- A new level can be loaded immediately after completing another without any state bleed from the prior level's `MoveCounter`, `CoverageTracking`, or `UndoRestart`.
- Audio crossfade plays correctly across a scene transition initiated by `SceneManager`.

## Related Decisions

- [ADR-0002: Signal-Driven Decoupling](adr-0002-signal-driven-decoupling.md) _(pending)_
- [ADR-0003: Save File Format](adr-0003-save-file-format.md) _(pending)_
- [design/gdd/save-load-system.md](../../design/gdd/save-load-system.md)
- [design/gdd/scene-manager.md](../../design/gdd/scene-manager.md)
- [design/gdd/level-progression.md](../../design/gdd/level-progression.md)
- [design/gdd/sfx-manager.md](../../design/gdd/sfx-manager.md)
- [design/gdd/music-manager.md](../../design/gdd/music-manager.md)
- [design/gdd/cosmetic-skin-database.md](../../design/gdd/cosmetic-skin-database.md)
- [design/gdd/skin-unlock-milestone-tracker.md](../../design/gdd/skin-unlock-milestone-tracker.md)
