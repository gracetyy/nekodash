# Input System

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Pillar 1 — Every Move Is a Choice

## Overview

The Input System translates raw touchscreen gestures into discrete cardinal-direction commands that the Sliding Movement system can act on. It is the single point of contact between the player's finger and the game's logic. On mobile, this means recognizing a swipe or tap-and-drag gesture, determining the intended direction (up, down, left, right), and emitting a `direction_input` signal — suppressing the gesture if it doesn't meet confidence thresholds, and guarding against OS-level edge-swipe interception on iOS and Android. The Input System does not execute movement or modify game state; it only detects intent and signals it. All movement logic lives in Sliding Movement.

## Player Fantasy

Input is where the player's intention becomes the cat's action. The fantasy is **precision without friction**: the player swipes, the cat moves exactly where they intended, every time. A misread gesture — cat goes the wrong direction — breaks the puzzle logic and feels like a betrayal of the player's skill. The Input System must be invisible: it should feel like the player is directly controlling the cat with their fingertip, not issuing commands through a translation layer. This serves **Pillar 1 — Every Move Is a Choice** at the most fundamental level: if the input system misfires, the "choice" is corrupted before the puzzle even sees it. Good input design means the player never says "it didn't do what I meant" — and can instead take full ownership of both their clever solutions and their mistakes.

## Detailed Design

### Core Rules

1. The Input System supports two input modes, active simultaneously:
   - **Mobile (touch)**: `InputEventScreenDrag` — detects swipe gestures by tracking drag velocity and displacement. A gesture is valid if: drag distance ≥ `MIN_SWIPE_DISTANCE_PX`, drag duration ≤ `MAX_SWIPE_DURATION_MS`. Direction is resolved by whichever axis has greater absolute displacement (horizontal or vertical).
   - **Desktop (keyboard)**: `InputEventKey` — WASD and arrow keys map directly to cardinal directions. A keypress is valid if: key released after at least `MIN_KEY_HOLD_MS`, preventing accidental key bounces. Configurable via Godot's `InputMap`.
2. A valid gesture or keypress emits a `direction_input(direction: Vector2i)` signal with exactly one of: `Vector2i(0,-1)` (up), `Vector2i(0,1)` (down), `Vector2i(-1,0)` (left), `Vector2i(1,0)` (right).
3. Input is **blocked** when the cat is in the `SLIDING` state. The Sliding Movement system exposes an `is_accepting_input: bool` flag that the Input System respects. No gesture or keypress is processed until sliding completes and `is_accepting_input` returns to `true`.
4. Input is **blocked** when the game is not in the `PLAYING` state (i.e., during level load, level-complete screen, pause, or any UI screen).
5. Swipe direction is determined by the dominant axis of the gesture vector. If `abs(delta.x) > abs(delta.y)`, the direction is left/right; otherwise up/down. Diagonal gestures always resolve to a single cardinal direction.
6. The Input System does **not** modify grid state, cat position, or move count. It emits signals only.
7. **OS edge-swipe mitigation** (mobile): Use Godot's `DisplayServer.window_set_flag()` or project settings to disable system gestures in the gameplay viewport. This is applied at startup, not per-frame.

### States and Transitions

| State         | Entry Condition                                            | Exit Condition                                     | Behavior                                                              |
| ------------- | ---------------------------------------------------------- | -------------------------------------------------- | --------------------------------------------------------------------- |
| **Accepting** | Level loaded; `is_accepting_input == true`                 | Sliding Movement sets `is_accepting_input = false` | Processes gestures/keypresses; emits `direction_input` on valid input |
| **Blocked**   | `is_accepting_input == false` OR game not in PLAYING state | Condition clears                                   | All gestures and keypresses are silently discarded                    |

### Interactions with Other Systems

| System               | Direction             | Interface                                                                                                                                                                        |
| -------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sliding Movement** | Bidirectional         | Input System emits `direction_input(direction: Vector2i)`; Sliding Movement connects to this signal and sets `is_accepting_input` to control blocking                            |
| **Scene Manager**    | Scene Manager → Input | Scene Manager notifies the Input System of state transitions (PLAYING, UI, LOCKED) via a signal or direct method call; Input System only emits `direction_input` in PLAYING mode |

## Formulas

### Swipe Direction Resolution

```
dominant_axis = "horizontal" if abs(delta.x) > abs(delta.y) else "vertical"

if dominant_axis == "horizontal":
    direction = Vector2i(sign(delta.x), 0)
else:
    direction = Vector2i(0, sign(delta.y))
```

| Variable  | Type  | Source                            | Description                                                                                       |
| --------- | ----- | --------------------------------- | ------------------------------------------------------------------------------------------------- |
| `delta.x` | float | `InputEventScreenDrag.relative.x` | Horizontal drag displacement since gesture start                                                  |
| `delta.y` | float | `InputEventScreenDrag.relative.y` | Vertical drag displacement; **+y = down** (matches Godot screen space and Grid System convention) |
| `sign(v)` | int   | GDScript built-in                 | Returns -1, 0, or 1                                                                               |

### Swipe Validity Check

```
is_valid_swipe = (drag_distance >= MIN_SWIPE_DISTANCE_PX)
                 AND (drag_duration_ms <= MAX_SWIPE_DURATION_MS)

drag_distance = sqrt(delta.x² + delta.y²)
drag_duration_ms = (current_time_ms - gesture_start_time_ms)
```

| Variable           | Type           | Threshold                 | Notes                                                     |
| ------------------ | -------------- | ------------------------- | --------------------------------------------------------- |
| `drag_distance`    | float (pixels) | ≥ `MIN_SWIPE_DISTANCE_PX` | Filters tap noise and accidental micro-drags              |
| `drag_duration_ms` | int (ms)       | ≤ `MAX_SWIPE_DURATION_MS` | Filters slow drag-and-hold that reads as a scroll gesture |

_Note_: The `DIRECTION_DOMINANCE_RATIO` mentioned in Core Rules is implicitly enforced by the dominant-axis formula — whichever axis has greater absolute displacement wins. No explicit ratio check is needed.

## Edge Cases

| Scenario                                                  | Expected Behavior                                                                 | Rationale                                                                        |
| --------------------------------------------------------- | --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Player taps without dragging                              | No `direction_input` emitted (drag distance < `MIN_SWIPE_DISTANCE_PX`)            | Taps are for UI, not movement; prevents accidental moves                         |
| Perfectly diagonal swipe (`abs(delta.x) == abs(delta.y)`) | Default to vertical (up/down)                                                     | Degenerate case; consistent tie-breaking rule                                    |
| Swipe starts on a UI element                              | UI element consumes the touch event; no `direction_input` emitted                 | Godot's input propagation handles this if UI is in a higher-priority CanvasLayer |
| Swipe starts outside the game viewport                    | No `direction_input` emitted                                                      | Viewport-scoped event handling; OS edge gestures never reach the game            |
| Input received while in `Blocked` state                   | Silently discarded; no queuing                                                    | Prevents ghost moves after slide completion                                      |
| Two simultaneous touches (multi-touch)                    | Only the first touch is tracked; subsequent touches ignored while first is active | One finger = one move; prevents conflicting directions                           |
| Keyboard key held continuously (key repeat)               | Each key-repeat event fires a move if `is_accepting_input` is true                | Intentional for desktop testing speed                                            |
| Rapid swipe during level-complete animation               | Discarded (game not in PLAYING state)                                             | Prevents accidental advance to next level during completion flourish             |
| `delta.x == 0` and `delta.y == 0`                         | No direction emitted; treat as zero-length gesture                                | Guard against divide-by-zero in direction formula                                |

## Dependencies

| System               | Direction                          | Nature                                                                                                | Hard/Soft                                                                               |
| -------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **Sliding Movement** | Input → Sliding Movement           | Emits `direction_input(direction: Vector2i)` signal consumed by Sliding Movement                      | **Hard** — Input System exists to serve Sliding Movement; useless without a consumer    |
| **Scene Manager**    | Scene Manager → Input              | Notifies Input System of game state changes (PLAYING/UI/LOCKED) to enable or disable input processing | **Hard** — without state awareness, input fires during menus and level-complete screens |
| **Grid System**      | Input → Grid (indirect, read-only) | Reads `DEFAULT_TILE_SIZE_PX` from Grid System constants to calibrate tap zone sizes                   | **Soft** — touch zone sizing is an enhancement; movement still works without it         |

## Tuning Knobs

| Parameter               | Current Value | Safe Range | Effect of Increase                                      | Effect of Decrease                                                 |
| ----------------------- | ------------- | ---------- | ------------------------------------------------------- | ------------------------------------------------------------------ |
| `MIN_SWIPE_DISTANCE_PX` | 40            | 20–100     | Fewer accidental moves; requires more intentional swipe | More responsive; more accidental moves from micro-drags            |
| `MAX_SWIPE_DURATION_MS` | 400           | 200–800    | Accepts slower, more deliberate swipes                  | Only fast flicks register; may frustrate slower players            |
| `MIN_KEY_HOLD_MS`       | 25            | 0–100      | Fewer key-repeat rapid-fires between desktop moves      | 0 = key-bounce risk (same key fires twice from one physical press) |

_All three constants are exposed as `@export` variables on the InputSystem node so they can be tuned in the Godot editor without code changes._

## Visual/Audio Requirements

The Input System itself produces no visuals or audio — feedback is owned by downstream systems.

- **Swipe trail** (stretch goal): A faint arc drawn from drag start to current finger position during an in-progress swipe. Fades on release. Rendered by Input System or delegated to a VFX layer. _Not required for MVP._
- **Invalid swipe feedback**: If a gesture is discarded (too short, too slow, or `Blocked`), Input System emits nothing. Sliding Movement owns any "blocked" bump feedback.
- **No audio**: Input System emits no sounds. All movement audio is owned by Sliding Movement.

## UI Requirements

The Input System has no persistent UI. It is invisible during normal play.

- **Input hint overlay** (first launch): A one-time "swipe to move" prompt is shown on level 1. This prompt is owned by the UI/Onboarding system, not Input System. Input System continues processing normally; any valid `direction_input` signal dismisses the hint (handled by the UI system via signal subscription).
- **No on-screen buttons**: NekoDash is swipe-only on mobile. There are no virtual D-pads or directional buttons.

## Acceptance Criteria

| #    | Criterion                                                                                                                                                                               |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| H-1  | A swipe with `drag_distance >= MIN_SWIPE_DISTANCE_PX` and `drag_duration_ms <= MAX_SWIPE_DURATION_MS` fires exactly one `direction_input` signal with the correct `Vector2i` direction. |
| H-2  | A tap (`drag_distance < MIN_SWIPE_DISTANCE_PX`) fires no signal.                                                                                                                        |
| H-3  | A slow drag (`drag_duration_ms > MAX_SWIPE_DURATION_MS`) fires no signal.                                                                                                               |
| H-4  | A diagonal swipe where `abs(delta.y) >= abs(delta.x)` resolves to the vertical direction, not horizontal.                                                                               |
| H-5  | Input while in `Blocked` state fires no signal — the cat does not move.                                                                                                                 |
| H-6  | WASD keys (`W`, `A`, `S`, `D`) each fire exactly one `direction_input` with the matching cardinal `Vector2i`.                                                                           |
| H-7  | Arrow keys fire the same signals as their WASD equivalents.                                                                                                                             |
| H-8  | A key held down fires a new signal each time the OS key-repeat event fires, not only on first press.                                                                                    |
| H-9  | Multi-touch: a second finger touchdown while a first swipe is in progress is ignored; the first swipe resolves normally.                                                                |
| H-10 | A swipe starting at a screen edge does not trigger the OS system gesture (verified on physical device; mitigated via `DisplayServer` edge-swipe settings).                              |
| H-11 | Input event processing completes in ≤ 1 ms per frame (measured in Godot profiler on target device).                                                                                     |

## Open Questions

| #    | Question                                                                                                                     | Priority | Owner                                          |
| ---- | ---------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------------------------------------- |
| OQ-1 | Should a cancelled mid-swipe (finger reverses direction before release) use the final delta or the peak delta for direction? | Medium   | Resolve during Sliding Movement implementation |
| OQ-2 | Does the swipe trail VFX belong to Input System or a dedicated VFX layer?                                                    | Low      | Resolve during first art sprint                |
| OQ-3 | On desktop, should holding a key while in `Blocked` state queue one move to fire immediately on unblock?                     | Medium   | Resolve during Sliding Movement GDD            |
