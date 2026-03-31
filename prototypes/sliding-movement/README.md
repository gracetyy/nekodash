# Prototype: Sliding Movement

## Hypothesis

The slide-until-wall-hit core verb feels satisfying on mobile touchscreen input at
the GDD's tuning parameters (15 tiles/sec, 0.10s min duration, 40px min swipe distance).

## How to Run

1. Open the Godot project
2. Open `prototypes/sliding-movement/SlidingPrototype.tscn`
3. Set it as main scene (Project → Project Settings → Run → Main Scene) or press F6 to run current scene
4. Test with:
   - **Desktop**: WASD or arrow keys
   - **Mobile**: Swipe in cardinal directions (export to device or use remote debug)

## Status

**In Progress** — Prototype built, awaiting mobile device testing.

## What to Evaluate

- Does the slide feel snappy or sluggish?
- Does the bump animation clearly communicate "blocked"?
- Does swipe direction detection feel accurate?
- Is the landing squish noticeable and satisfying?
- Do long slides (5+ tiles) feel proportionally different from short slides (1-2 tiles)?

## Findings

_(Update after testing)_
