## Prototype Report: Sliding Movement

### Hypothesis

The slide-until-wall-hit core verb feels satisfying on mobile touchscreen input at
the GDD's tuning parameters: 15 tiles/sec constant velocity, 0.10s minimum slide
duration, 6px bump offset, 40px minimum swipe distance. Specifically: the swipe →
slide → land loop is responsive, directionally accurate, and produces a pleasant
"weight" feel (not floaty, not jerky).

### Approach

Built a minimal 4-script prototype in `prototypes/sliding-movement/`:

- **proto_grid.gd**: Hardcoded 7×7 grid (border walls + 4 interior walls) with
  coverage overlay rendering. Enough topology for 1–5 tile slides in all4 directions.
- **proto_cat.gd**: Full slide resolution (`resolve_slide` loop), Tween animation
  with EASE_OUT + TRANS_QUAD easing, landing squish (TRANS_ELASTIC recover), bump
  animation (nudge + elastic return). All GDD tuning knob values hardcoded as constants.
- **proto_input.gd**: Touch swipe detection (distance threshold 40px, duration cap
  500ms, dominant-axis cardinal resolution) + keyboard WASD/arrows. Logs every
  accepted and rejected swipe with distance/duration metrics.
- **proto_hud.gd**: Minimal overlay showing move count, coverage, and active speed.

Total implementation: ~350 lines of GDScript across 4 files.
No production imports. No save system. No scene manager. Pure movement feel test.

### Result

_(Fill in after running the prototype on desktop and mobile device)_

**Desktop keyboard observations:**

- [x] Slide response time — immediate, no perceptible delay
- [x] Landing squish visibility and feel — correct
- [x] Bump animation readability — correct
- [x] Multi-direction rapid input — felt natural, no queuing issues

**Mobile touch observations:**

- [x] Slide feel validated on device — movement responsive and readable
- [x] Portrait orientation confirmed working
- [x] Screen fills correctly (canvas_items stretch, expand aspect)
- [x] Grid not too small — tile size readable at phone screen dimensions
- [ ] Swipe accuracy vs 20-swipe count — not formally measured
- [ ] Swipe rejection rate — not formally measured

### Metrics

_(Fill in after testing)_

- Frame time: solid 60fps, no hitches (visual inspection)
- Slide duration (1 tile): expected 0.10s, actual: matches (no deviation noticed)
- Slide duration (5 tiles): expected 0.33s, actual: matches (no deviation noticed)
- Bump duration: expected 0.12s, actual: matches (no deviation noticed)
- Swipe accuracy: not formally measured
- Swipe rejection rate: not formally measured
- **Slide speed desktop**: 15.0 t/s ✓ feels correct
- **Slide speed mobile**: 25.0 t/s ✓ feels correct (15.0 felt sluggish — grid is physically smaller on device)
- Iteration count: 2 (initial build + mobile speed + orientation fix)

### Recommendation: PROCEED

Desktop and mobile feel both validated. All GDD tuning values correct on desktop (15 t/s). Mobile requires 25 t/s due to the grid being physically smaller on screen — this is expected and resolved via platform detection (`DisplayServer.is_touchscreen_available()`). Portrait orientation and fullscreen stretch confirmed working. Easing (TRANS_QUAD) kept — no floatiness observed on device. Core verb hypothesis confirmed.

### If Proceeding

Production implementation changes needed:

- Architecture: Separate `SlidingMovement` scene node subscribing to `InputSystem`
  signal (not reading input directly)
- Decouple grid access: receive grid reference via `initialize()` call from Level
  Coordinator, not `get_parent().get_node()`
- Add `LOCKED` state driven by Scene Manager signal
- Coverage tracking is a separate system (not embedded in cat or grid)
- Replace hardcoded grid with `GridSystem.load_grid(level_data)`
- Add `set_grid_position_instant()` API for Undo/Restart integration
- Expose `is_accepting_input: bool` for Input System gating
- Add `spawn_position_set` signal for Coverage Tracking initialization
- Estimated production effort: S (1 session) — the core algorithm is validated;
  production work is structural wiring

### If Pivoting

_(Only write if testing reveals the core verb doesn't work)_

### If Killing

_(Only write if the concept fundamentally fails)_

### Lessons Learned

- [x] **Speed is platform-dependent**: 15 t/s correct for desktop; 25 t/s correct for mobile. Production `SlidingMovement` node must expose separate `@export` values for each platform, or use `DisplayServer.is_touchscreen_available()` to select at runtime.
- [x] **EASE_OUT + TRANS_QUAD felt fine on device** — no floatiness observed on mobile. Previous desktop concern was premature. Keep TRANS_QUAD.
- [x] **Portrait + stretch required in project.godot**: viewport 540×960, `stretch/mode=canvas_items`, `stretch/aspect=expand`, `orientation=1`. Must be set before any Android test build.
- [x] **Bug found**: restart (R key) did not reset the HUD move counter — `proto_hud.gd` does not listen for a reset event. Production move counter must subscribe to a `level_restarted` signal from the Level Coordinator.
- [ ] Swipe accuracy formal measurement still pending (20-swipe count)
- [ ] Bump animation readability on mobile — not formally evaluated; appeared readable
- [ ] Input system changes for production GDD: none identified; mobile accuracy formal count still pending
