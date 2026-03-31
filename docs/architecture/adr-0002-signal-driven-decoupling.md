# ADR-0002: Signal-Driven Decoupling

## Status

Accepted

## Date

2026-03-31

## Context

### Problem Statement

NekoDash has 22 systems that communicate at runtime. Without a governing rule for _how_ systems communicate, the codebase drifts toward two failure modes: (a) tight coupling via direct node references that break when a system moves or is absent, and (b) over-signalling that turns every value change into a broadcast the whole tree must ignore. A recorded policy is needed so every cross-system communication path uses a consistent, intentional mechanism.

### Constraints

- Godot 4.3 signal system is first-class: typed signals, direct connect/disconnect, no runtime reflection required.
- Gameplay scene nodes (`LevelProgression`, `HUD`, `MoveCounter`, etc.) are instantiated fresh each level — their paths in the tree are not stable across sessions.
- Autoloads have stable global identifiers; scene nodes do not.
- Jam timeline: no time for a mediator/event-bus abstraction layer.

### Requirements

- Must prevent scene-node-to-scene-node tight coupling through paths or `$Node` chains.
- Must allow downstream observers (HUD, Level Complete Screen) to receive events without the emitting system knowing they exist.
- Must be consistent enough that contributors can predict where to look for a given event.
- Must not add boilerplate for simple, single-caller relationships (parent → child `initialize()` calls are fine).

## Decision

**All cross-system runtime communication uses Godot signals. Direct `$NodePath` references and `get_node()` calls are permitted only for parent→child hierarchical relationships (i.e., a node initialising or configuring its own children). Peer-to-peer and child-to-parent communication always uses signals.**

### The Two-Rule Policy

**Rule 1 — Downstream observation uses signals.**
When system B needs to react to an event emitted by system A, B connects to A's signal. A emits; A does not call B directly. A does not import B's type. This is the primary decoupling mechanism.

**Rule 2 — Initialization flows downward via `initialize()` calls.**
When a parent coordinator spawns child nodes, the coordinator may call `initialize(args)` on its direct children to inject dependencies at scene-load time. This is intentional tight coupling in one direction (top-down) and is acceptable. Children never call `initialize()` on their parents.

### Canonical Signal Flow (Gameplay Scene)

```
Input System
  └─[direction_input(dir)]──────────────────► Sliding Movement
                                                └─[slide_completed(from,to,dir,tiles)]──► Coverage Tracking
                                                │                                         └─[coverage_updated(n,t)]──► HUD
                                                │                                         └─[level_completed]──────────► Star Rating System
                                                │                                                                         └─[rating_computed(id,stars,moves)]──► Level Progression
                                                │                                                                                                                 └─[level_record_saved(id,stars,moves)]──► Level Complete Screen
                                                │                                                                                                                 └ SaveManager.set_level_record()
                                                └─[slide_completed]──────────────────────► Move Counter
                                                └─[slide_completed]──────────────────────► Undo/Restart (snapshot)
```

**Key observation**: `CoverageTracking` never calls `StarRatingSystem` directly. `StarRatingSystem` never calls `LevelProgression` directly. Each system only emits facts; downstream consumers connect at scene-load time.

### Autoload Signal Contracts (Cross-Scene Signals)

Signals that must survive scene transitions live on autoloads:

| Signal                                         | Owner          | Subscribers                        |
| ---------------------------------------------- | -------------- | ---------------------------------- |
| `level_record_updated(level_id, stars, moves)` | `SaveManager`  | `MilestoneTracker`                 |
| `skin_unlocked(skin_id)`                       | `SaveManager`  | _(future: unlock notification UI)_ |
| `transition_started`                           | `SceneManager` | `MusicManager`, `SFXManager`       |
| `transition_completed(screen)`                 | `SceneManager` | `MusicManager`                     |
| `world_changed(world_id)`                      | `SceneManager` | `MusicManager`                     |

These signals are connected in each subscriber's `_ready()` and are never disconnected (autoloads live forever).

### Scene-Local Signal Contracts (Per-Level Signals)

Signals between gameplay scene nodes are connected by the **Level Coordinator** at scene load, not in the editor. The Level Coordinator calls `initialize()` on each system and connects signals after all nodes are ready.

| Signal                               | Emitter            | Connected To                                          |
| ------------------------------------ | ------------------ | ----------------------------------------------------- |
| `direction_input(dir)`               | `InputSystem`      | `SlidingMovement`                                     |
| `spawn_position_set(pos)`            | `SlidingMovement`  | `CoverageTracking`                                    |
| `slide_completed(from,to,dir,tiles)` | `SlidingMovement`  | `CoverageTracking`, `MoveCounter`, `UndoRestart`      |
| `slide_blocked(pos,dir)`             | `SlidingMovement`  | `SFXManager` (bump SFX)                               |
| `coverage_updated(n,t)`              | `CoverageTracking` | `HUD`                                                 |
| `tile_covered(coord)`                | `CoverageTracking` | Visual tile layer                                     |
| `level_completed`                    | `CoverageTracking` | `StarRatingSystem`                                    |
| `rating_computed(id,stars,moves)`    | `StarRatingSystem` | `LevelProgression`                                    |
| `level_record_saved(id,stars,moves)` | `LevelProgression` | `LevelCompleteScreen`                                 |
| `move_count_changed(current,min)`    | `MoveCounter`      | `HUD`                                                 |
| `undo_applied(history_len)`          | `UndoRestart`      | `HUD`                                                 |
| `level_restarted`                    | `UndoRestart`      | `SlidingMovement` (reset), `CoverageTracking` (reset) |

### What Is Explicitly Forbidden

- `$"../SiblingNode"` references between peer gameplay systems.
- `get_node("/root/GameplayScene/SomeSystem")` absolute paths.
- Any system importing another peer system's class via `preload` and holding a typed reference to it long-term.
- Connecting signals in the Godot editor for dynamic nodes (gameplay scene nodes are dynamic — connect in code only).

### What Is Permitted

- `@onready var hud: HUD = $HUD` inside a parent coordinator that owns `HUD` as a direct child.
- Autoload access from any script: `SaveManager.get_level_record(id)` — autoloads are global by design (see ADR-0001).
- Passing node references as signal arguments when a downstream system needs a read-only handle (e.g., Level Complete Screen receives `level_progression` ref via `receive_scene_params()`).

## Alternatives Considered

### Alternative 1: Global EventBus Autoload

- **Description**: A single `EventBus` autoload holds all signals for the entire game. Every system connects to and emits from `EventBus`.
- **Pros**: Eliminates all node-reference passing; easy to add new observers.
- **Cons**: Single namespace for all events in the game — all 22+ signals in one file. Debugging which system emitted a specific event requires tracing through `EventBus`. Type safety is reduced. Godot's native signal debugger shows `EventBus` as the emitter, losing origin context.
- **Rejection Reason**: Godot's typed signals on emitting nodes already provide decoupling with better origin traceability and compile-time type checking. `EventBus` adds overhead without clear benefit at this scale.

### Alternative 2: Direct Node References via Dependency Injection

- **Description**: Level Coordinator holds typed references to all gameplay systems and passes them directly to systems that need to call methods on peers.
- **Pros**: Explicit, traceable dependencies; easier to step-debug.
- **Cons**: Creates tightly coupled method-call chains between peers. `StarRatingSystem` would need a reference to `LevelProgression` to call `record_completion()` — the order of operations becomes the caller's problem, not a natural signal ordering. Refactoring any system's API breaks all its callers.
- **Rejection Reason**: Signal-based observation keeps each system's API its own responsibility. Downstream systems react; they don't get called.

### Alternative 3: Signals in Editor for All Connections

- **Description**: Connect all signals in the Godot editor's inspector panel.
- **Pros**: Visible in editor UI; no connection code to write.
- **Cons**: Gameplay scene nodes are instanced dynamically — editor signal connections are stored in `.tscn` files and break when scene structure changes. Any refactor of the scene tree silently severs connections with no compile-time warning.
- **Rejection Reason**: Code-based connections at scene-load time (`Level Coordinator._ready()`) are explicit, version-controlled, and refactor-safe.

## Consequences

### Positive

- Each system's public contract is its signal list — clean, documented, findable.
- Systems can be replaced or mocked independently for testing (mock emits the same signals; downstream is unaffected).
- No system knows which other systems are observing it — adding a new observer (e.g., an analytics listener) requires zero changes to the emitting system.
- Signal origin is always the emitting node, making Godot's built-in signal profiler useful.

### Negative

- Signal connection code in `Level Coordinator._ready()` grows with each new system — it becomes the canonical "wiring manifest" for the gameplay scene.
- Debugging an unexpected event requires tracing which system connected to which signal at scene load.
- Latent signal connections (connected but never emitted) are not caught by the type system.

### Risks

- **Risk**: A signal is connected but the emitting node is freed before it disconnects, causing "Connection to freed object" errors. **Mitigation**: Use `CONNECT_ONE_SHOT` for single-fire signals (e.g., `level_completed`); disconnect signals in `_exit_tree()` for long-lived connections.
- **Risk**: Signal argument types drift — emitter changes signature but compiler only warns on direct callers, not signal receivers. **Mitigation**: Use Godot 4 typed signals (`signal rating_computed(level_id: String, stars: int, final_moves: int)`) throughout; GDScript will warn on mismatched lambda parameter types.
- **Risk**: Level Coordinator wiring becomes stale when new signals are added mid-development. **Mitigation**: Every new signal added to a gameplay node must be registered in the Level Coordinator wiring block and in this ADR's signal table above.

## Performance Implications

- **CPU**: Signal emit is a Godot-native operation — negligible overhead per call. No tick-rate concern; all gameplay signals fire on discrete events (swipes, tile crossings), not every frame.
- **Memory**: Each `connect()` call allocates a small Callable; total connections across all gameplay systems is ~20. Negligible.
- **Load Time**: Wiring occurs in `_ready()`; all connections resolve in a single pass. No measurable impact.
- **Network**: Not applicable.

## Migration Plan

This ADR records the intended architecture for a new project. No migration required. At implementation time:

1. Define all signals with full typed signatures on their owning nodes.
2. The Level Coordinator script wires all scene-local signals in `_ready()` after calling `initialize()` on each system.
3. Autoload subscribers (`MusicManager`, `MilestoneTracker`) connect to autoload signals in their own `_ready()`.
4. No `.tscn` file should contain signal connections between gameplay systems — audit `Level.tscn` node signals panel to confirm it is empty.

## Validation Criteria

- No gameplay system script contains `get_node()`, `$NodePath`, or `preload` for a _peer_ system's script file.
- All gameplay signal connections can be found by grepping the Level Coordinator script.
- The Godot signal profiler shows signal origins matching the emitting node names (not `EventBus` or `GameplayScene`).
- A new observer can be added for any gameplay signal by adding a single `connect()` call in Level Coordinator — no changes to the emitting system required.

## Related Decisions

- [ADR-0001: Autoload Architecture](adr-0001-autoload-architecture.md) — establishes which systems are global; this ADR governs how they communicate.
- [ADR-0003: Save File Format](adr-0003-save-file-format.md) _(pending)_
- [design/gdd/sliding-movement.md](../../design/gdd/sliding-movement.md)
- [design/gdd/coverage-tracking.md](../../design/gdd/coverage-tracking.md)
- [design/gdd/star-rating-system.md](../../design/gdd/star-rating-system.md)
- [design/gdd/level-progression.md](../../design/gdd/level-progression.md)
- [design/gdd/scene-manager.md](../../design/gdd/scene-manager.md)
- [design/gdd/music-manager.md](../../design/gdd/music-manager.md)
