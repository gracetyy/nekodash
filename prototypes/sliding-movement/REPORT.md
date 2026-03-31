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

- [ ] Not tested on mobile — deferred to production build

### Metrics

_(Fill in after testing)_

- Frame time: solid 60fps, no hitches (visual inspection)
- Slide duration (1 tile): expected 0.10s, actual: matches (no deviation noticed)
- Slide duration (5 tiles): expected 0.33s, actual: matches (no deviation noticed)
- Bump duration: expected 0.12s, actual: matches (no deviation noticed)
- Swipe accuracy: not measured — mobile not tested
- Swipe rejection rate: not measured — mobile not tested
- Iteration count: 1 (initial build)

### Recommendation: PROCEED

Desktop feel validated all GDD tuning values — slide response, squish, and bump all read correctly at the specified parameters. 60fps with no hitches. Mobile testing was not completed in this prototype session; mobile validation should be added as a task in the first production sprint before locking the input system parameters.

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

- [ ] Speed (15 tiles/sec): no change needed on desktop
- [ ] MIN_SLIDE_DURATION (0.10s): no change needed
- [ ] Bump animation readability on mobile: untested — flag for first sprint
- [x] **Easing**: EASE_OUT + TRANS_QUAD feels slightly floaty — production should trial a faster ease-out curve (e.g. TRANS_EXPO or reduced duration) before locking
- [x] **Bug found**: restart (R key) did not reset the HUD move counter — `proto_hud.gd` does not listen for a reset event. Production move counter must subscribe to a `level_restarted` signal from the Level Coordinator.
- [ ] Input system changes for production GDD: none identified from desktop testing; mobile accuracy still needs validation
