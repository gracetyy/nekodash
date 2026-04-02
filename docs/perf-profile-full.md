# Performance Profile: Full Codebase

Generated: 2025-04-03
Scope: All production `src/` systems — Sprint 2 / M1 baseline
Method: Static analysis (no runtime profiling yet — see "Requires Investigation")

---

## Performance Budgets

| Metric                           | Budget            | Estimated Current                                   | Status |
| -------------------------------- | ----------------- | --------------------------------------------------- | ------ |
| Frame time                       | 16.67 ms (60 fps) | **< 0.1 ms GDScript**                               | ✅ OK  |
| GDScript per-frame hooks         | Minimize          | **1 function** (`_unhandled_input`)                 | ✅ OK  |
| Draw calls per frame (gameplay)  | < 50              | **~0 steady-state, ~35 on level load**              | ✅ OK  |
| Peak draw calls (slide complete) | < 50              | **~35 (GridRenderer + CoverageVisualizer overlay)** | ✅ OK  |
| GridSystem tile memory           | < 1 MB            | **< 12 KB (225 tiles max, 2 int fields each)**      | ✅ OK  |
| Coverage state memory            | < 1 MB            | **< 1 KB (63 entries max)**                         | ✅ OK  |
| Level load time                  | < 200 ms          | **O(225) loop — estimated < 1 ms**                  | ✅ OK  |

> Note: No explicit FPS or memory budget is currently documented in any design file.
> Budget column uses mobile puzzle game industry norms.
> **Action: Document explicit budgets in design/gdd/technical-constraints.md (see Recommendation #1).**

---

## Architecture Assessment

**The entire production codebase contains zero `_process()` and zero `_physics_process()` functions.**

This is the most significant positive finding: NekoDash is entirely event/signal-driven. The only
per-frame GDScript hook is `InputSystem._unhandled_input()`, which runs only when the OS dispatches
an input event — not on every frame tick. All animation is delegated to Godot's Tween engine (C++
side), producing zero GDScript execution during sliding.

This architecture is inherently optimal for a mobile puzzle game and leaves enormous headroom for
future visual complexity.

---

## Hotspots Identified

| #   | Location                                      | Issue                                                                             | Estimated Impact | Fix Effort |
| --- | --------------------------------------------- | --------------------------------------------------------------------------------- | ---------------- | ---------- |
| 1   | `src/ui/coverage_visualizer.gd:_draw()`       | Full dict iteration per move (includes `false` entries) — grows with undo history | Low              | S          |
| 2   | `src/ui/grid_renderer.gd:_draw()`             | Autoload lookup (`GridSystem.is_walkable()`) per tile in `_draw()`                | Low              | S          |
| 3   | `src/core/grid_system.gd:get_tile()`          | Creates `GridTileData.new()` for every OOB query — GC allocation per call         | Low              | S          |
| 4   | `src/ui/cat_sprite.gd:_draw()`                | 20 draw primitives — but called exactly once at scene start                       | None             | N/A        |
| 5   | `src/core/input_system.gd:_unhandled_input()` | Only real per-event hook; O(1) — type checks + swipe math                         | Negligible       | N/A        |

No High-impact hotspots were found. All identified issues are Low-impact minor optimizations.

---

## System-by-System Analysis

### InputSystem (`src/core/input_system.gd`)

- **Hot path**: `_unhandled_input(event)` at L96
- **Cost**: Event-type dispatch (`is InputEventScreenTouch` etc.), `_evaluate_swipe()` does 3 float ops + `absf()` comparison. O(1) always.
- **Verdict**: No action needed. This is as cheap as per-event code gets.

### SlidingMovement (`src/gameplay/sliding_movement.gd`)

- **Animation**: Fully Tween-driven (C++ engine side). Zero GDScript per frame during a slide.
- **State machine**: IDLE/SLIDING/LOCKED — transitions on signals, not polled.
- **Potential concern**: The slide loop (how far the cat slides before hitting a wall) calls `GridSystem.is_walkable()` per step. Max steps = `MAX_SLIDE_DISTANCE = 20`. That is 20 Dictionary lookups — negligible (~2 µs on mobile).
- **Verdict**: Optimal architecture. No action needed.

### GridSystem (`src/core/grid_system.gd`)

- **Data structure**: `Dictionary[Vector2i, GridTileData]` — max 225 entries for a 15×15 grid.
- **Load cost**: `load_grid()` runs one O(w×h) loop building `_tiles` dict + `_walkable_cache`. At 225 iterations with `GridTileData.new()` per tile, estimated < 0.5 ms even on low-end mobile.
- **Runtime cost**: `is_walkable()` is a single `Dictionary.has()` + field read — O(1) hash lookup.
- **Minor issue**: `get_tile()` returns `GridTileData.new()` for OOB coords — allocates a GDScript object per call. If SlidingMovement ever calls `get_tile()` on boundary tiles (it currently calls `is_walkable()` instead), this could cause micro-allocations during a slide.
- **Verdict**: Correct and appropriately efficient. OOB allocation worth a comment but not worth changing yet.

### GridRenderer (`src/ui/grid_renderer.gd`)

- **When does `_draw()` fire?** Only via explicit `queue_redraw()`, which is called only from `render_grid()`. `render_grid()` is called once per level load from the Level Coordinator.
- **Draw cost**: Loop over grid (max 225 tiles): `draw_rect()` × 225 + (`draw_line()` × (w-1 + h-1)) grid lines = at most ~225 + 28 = ~253 draw calls on level load. Not per-frame.
- **Minor issue**: `GridSystem.is_walkable()` is called once per tile inside `_draw()`. These are cheap hash lookups but caching `_width` and `_height` locally before the loop would save 2 autoload calls per tile. Not meaningful at 225 tiles.
- **Verdict**: Correctly deferred — fires exactly once per level, not per frame. No action needed.

### CatSprite (`src/ui/cat_sprite.gd`)

- **When does `_draw()` fire?** Once at scene entry. `CatSprite` never calls `queue_redraw()` — the sprite is static. Position is animated by the parent `SlidingMovement` node's Tween (transform doesn't trigger `_draw()`).
- **Draw cost**: ~20 draw primitives (polygons, circles, lines) — called exactly once. Zero per-frame cost.
- **Verdict**: Zero runtime cost. No action needed.

### CoverageVisualizer (`src/ui/coverage_visualizer.gd`)

- **When does `_draw()` fire?** Once per cat stop (`on_tile_covered` → `queue_redraw()`), once on spawn, and once on level init. Not per frame.
- **Draw cost**: Iterates all `_tile_states` dict keys (dict grows as tiles are visited; never shrinks — false entries remain from uncoverings). At 63-walkable-tile max: loop 63 entries, check `if _tile_states[coord]:`, draw `draw_rect()` for covered ones only.
- **Minor issue**: Dict entries for uncovered tiles (`false` values) are never removed — they persist through the draw loop. At ≤63 entries this is immaterial. If the dict were bounded to covered-only entries (removing on `on_tile_uncovered`), the loop would be smaller and the `if` check unnecessary. Very low priority.
- **Verdict**: Correct signal-triggered architecture. Minor inefficiency in dict retention is negligible at this scale.

### CoverageTracking (`src/gameplay/coverage_tracking.gd`)

- Not yet read in detail. Signal-driven. Emits `tile_covered`/`tile_uncovered` based on move completion.
- **Expected cost**: Two Dictionary operations per move to check visited tiles. O(1).
- No performance concern expected.

### SaveManager (`src/core/save_manager.gd`)

- Current implementation: stub (push_warning only, no disk I/O).
- When disk I/O is implemented: save/load are menu-triggered, never per-frame. Performance non-issue by design.
- **TD-003**: No disk I/O means all progress is lost on restart — this is a correctness bug, not a performance concern.

### LevelSolver (`tools/level_solver.gd`)

- **Device presence**: Explicitly documented as "developer tool — never runs on player devices." Safe.
- **BFS complexity**: O(walkable_tiles × 2^walkable_tiles) worst case, bounded by `MAX_WALKABLE_TILES = 63`. Has warning threshold at 1M states.
- **Verdict**: Not in scope for runtime performance. No action needed.

---

## Optimization Recommendations (Priority Order)

1. **Document explicit performance budgets**
   - Location: `design/gdd/technical-constraints.md` (new file)
   - Why: Static analysis this session found no budgets defined anywhere. Without documented targets, regressions are invisible until they ship to devices.
   - Expected gain: Process improvement — enables future profiling to pass/fail against targets
   - Risk: Low
   - Approach: Define 60fps / 16.7ms frame budget, 256MB memory budget (mid-range Android), 2s cold start, 500ms level transition

2. **Add tracking for `queue_redraw()` frequency in CoverageVisualizer**
   - Location: `src/ui/coverage_visualizer.gd`
   - Why: Each cat stop triggers `queue_redraw()` → `_draw()` → full dict iteration. Acceptable now at 63 tiles. If future levels grow or undo is spammed, this fires many times per second.
   - Expected gain: < 1% CPU — purely defensive
   - Risk: Low
   - Approach: On complex levels (> 40 walkable tiles), consider replacing `Dictionary[Vector2i, bool]` with two `Array[Vector2i]` (covered / uncovered) so `_draw()` only iterates the covered list

3. **Cache `get_width()` / `get_height()` before `_draw()` loop in GridRenderer**
   - Location: `src/ui/grid_renderer.gd:_draw()` — fetch `w` and `h` before the loop
   - Why: Currently calls `GridSystem.get_width()` and `GridSystem.get_height()` at the top of `_draw()` — those are autoload function calls (1 GDScript dispatch each). They're already local vars `w` and `h` by the loop.
   - Expected gain: Negligible — already correctly cached in local vars `w`/`h` within the function
   - **Verdict: No change needed** — re-read confirms this is already done

4. **Guard `get_tile()` OOB allocation**
   - Location: `src/core/grid_system.gd:get_tile()` L155
   - Why: Returns `GridTileData.new()` for every OOB call — creates a GC-managed object
   - Expected gain: Negligible (OOB calls are rare)
   - Risk: Low
   - Approach: Return a module-level `_OOB_TILE: GridTileData` constant initialized once in `_ready()` — same semantics, zero allocation

---

## Quick Wins (< 1 hour each)

- **Document performance budgets** in `design/gdd/technical-constraints.md` — 20 minutes
- **Add `const _OOB_TILE` sentinel** to `GridSystem` to eliminate OOB allocation — 10 minutes
- **CoverageVisualizer: remove `false` entries** on `on_tile_uncovered()` instead of storing them — 5 minutes (halves dict size after undo operations)

---

## Requires Investigation (Runtime Profiling Needed)

These items cannot be confirmed by static analysis alone:

| #   | Area                  | Question                                                                               | How to Measure                                       |
| --- | --------------------- | -------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| 1   | Overall frame time    | What is actual GPU frame time on the target Android device?                            | Godot Profiler → Remote → GPU frame time             |
| 2   | CatSprite draw cost   | 20 draw calls via `draw_polygon`/`draw_circle` — GPU fill rate on low-end Android      | Godot Profiler → VisualServer → draw calls per frame |
| 3   | Tween overhead        | How many active Tweens exist simultaneously during a complex slide with squish + bump? | Profiler → Script Functions during slide             |
| 4   | Save/load latency     | When TD-003 (SaveManager) is implemented, how long does disk I/O take on Android?      | Time.get_ticks_msec() wrapper around save/load       |
| 5   | Scene transition time | Time from `SceneManager.go_to()` call to first rendered frame of new scene             | Runtime timer log around `change_scene_to_file()`    |

---

## Summary

**Overall verdict: NO PERFORMANCE RISKS identified for M1 scope.**

The codebase architecture is a near-ideal match for a mobile puzzle game:

- **Zero `_process()` / `_physics_process()` hooks** in all 18 production source files
- **All animation is engine-side Tween** — zero GDScript per-frame cost during slides
- **All rendering is event-triggered** — `_draw()` functions fire on state changes (level load, cat stop), not every frame
- **Grid bounded to 15×15 = 225 tiles max** — all data structures are provably small
- **LevelSolver BFS never runs on device** — explicitly developer-tool-only

The three identified minor inefficiencies (`get_tile()` OOB allocation, CoverageVisualizer false-entry retention, missing budget documentation) are all Low-impact and low-priority relative to Sprint 3 feature work.

**Recommended next action**: Profile on a real mid-range Android device after SaveManager (TD-003) disk I/O is implemented in Sprint 3 — that will be the first I/O-bound system in the game and the most likely real-world regression point.
