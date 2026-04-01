# Gameplay Scene Prototype

## Hypothesis

The four M1 production systems (GridSystem, SlidingMovement, CoverageTracking,
MoveCounter) can be wired together in a single scene to play a level end-to-end
in the editor — loading grid data, sliding the cat, tracking coverage, counting
moves, and detecting level completion.

## How to Run

1. In Godot editor, set `Project → Project Settings → Application → Run → Main Scene` to
   `res://prototypes/gameplay-scene/GameplayPrototype.tscn`
2. Press F5 (Play)
3. Use WASD or arrow keys to slide the cat
4. Press R to restart, 1/2/3 to switch between w1_l1, w1_l2, w1_l3

## Controls

- **WASD / Arrow Keys**: Slide the cat
- **R**: Restart current level
- **1**: Load w1_l1 (First Steps, 4×3)
- **2**: Load w1_l2 (Turn the Corner, 4×4) — default
- **3**: Load w1_l3 (Central Wall, 5×5)

## Status

Concluded — PROCEED recommended

## Findings

Full signal chain verified working end-to-end. See REPORT.md for details.
Key finding: `level_completed` fires before MoveCounter increments for the same slide —
Level Coordinator should freeze the counter on completion.
