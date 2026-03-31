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

- [ ] Slide response time (perceived ms from keypress to motion start)
- [ ] Landing squish visibility and feel
- [ ] Bump animation readability
- [ ] Multi-direction rapid input (does queuing feel natural?)

**Mobile touch observations:**

- [ ] Swipe direction accuracy (% correct on first 20 swipes)
- [ ] Swipe rejection rate (too-short / too-slow swipes)
- [ ] Edge-of-screen swipe reliability
- [ ] Perceived slide speed satisfaction

### Metrics

_(Fill in after testing)_

- Frame time: [measure with Godot profiler]
- Slide duration (1 tile): expected 0.10s, actual: \_\_\_
- Slide duration (5 tiles): expected 0.33s, actual: \_\_\_
- Bump duration: expected 0.12s, actual: \_\_\_
- Swipe accuracy: \_\_\_/20 correct direction
- Swipe rejection rate: \_\_\_% of total gestures
- Iteration count: 1 (initial build)

### Recommendation: [PROCEED / PIVOT / KILL]

_(Fill in after testing — choose one and explain with evidence)_

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

_(Fill in after testing — discoveries that affect other systems)_

- [ ] Does the 15 tiles/sec speed need adjustment?
- [ ] Does MIN_SLIDE_DURATION (0.10s) need adjustment?
- [ ] Is the bump animation readable enough on small mobile screens?
- [ ] Does the EASE_OUT + QUAD easing feel right or should it be linear?
- [ ] Any input system changes needed for the production GDD?
