# Playtest Report

## Session Info

- **Date**: 2026-04-01
- **Build**: Local main build (gameplay.tscn focused)
- **Duration**: Single focused feedback session
- **Tester**: Player draft synthesis
- **Platform**: PC
- **Input Method**: Keyboard (WASD/Arrow)
- **Session Type**: Targeted test

## Test Focus

Gameplay readability and feel for `gameplay.tscn`, with emphasis on controls, completion transition, scoring pressure, and HUD clarity.

## First Impressions (First 5 minutes)

- **Understood the goal?** Partially
- **Understood the controls?** Partially
- **Emotional response**: Engaged
- **Notes**: Core puzzle loop is understandable, but onboarding and feedback timing need improvement.

## Gameplay Flow

### What worked well

- Wireframe baseline is playable and communicates the core loop.
- Current visual direction is acceptable for a prototype/wireframe stage.

### Pain points

- Undo button appears disabled after first move and clicking gives no response. **Severity: High**
- Completion transitions to stars screen too immediately after full coverage; lacks satisfying pause/animation bridge. **Severity: High**
- Move counter number lacks explicit label/context, reducing readability. **Severity: Medium**
- Coverage counter may be redundant for players because tile colors already communicate progress. **Severity: Medium**
- Current UI and animation quality feel early-stage and need significant polish for production. **Severity: Low (for current stage), High (for final quality target)**

### Confusion points

- Controls and objective are not taught in-scene; new players may not know swipe vs keyboard mappings or completion objective.

### Moments of delight

- Puzzle concept is still clear and promising despite rough presentation.

## Bugs Encountered

| #   | Description                                                           | Severity | Reproducible |
| --- | --------------------------------------------------------------------- | -------- | ------------ |
| 1   | Undo remains disabled after first move and button click has no effect | High     | Yes          |
| 2   | Level complete jumps to results too quickly without transition beat   | High     | Yes          |
| 3   | Move counter lacks text label clarifying what the number means        | Medium   | Yes          |

## Feature-Specific Feedback

### Undo Interaction

- **Understood purpose?** Yes
- **Found engaging?** No
- **Suggestions**: Enable Undo immediately after first valid slide and provide clear enabled-state visuals.
- **Design intent cross-check**: **Conflict** with HUD acceptance criteria (HU-7: Undo should enable after first slide).

### Completion Transition

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**: Add short completion beat (for example 0.3-0.8s pause, tile pulse, or cat reaction) before showing results.
- **Design intent cross-check**: **Conflict** with Level Complete fantasy describing a completion punctuation/beat before results.

### Star Rating Pressure

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**: Relax 3-star threshold tolerance slightly on selected levels so small inefficiencies can still earn 3 stars.
- **Design intent cross-check**: **Partial conflict/risk**. Game concept supports both casual and perfectionist play. If thresholds feel too strict, this can undermine Pillar 3 (Complete Your Own Way). Threshold tuning should be handled in level data balance, not hardcoded logic.

### Move Counter Clarity

- **Understood purpose?** Partially
- **Found engaging?** Partially
- **Suggestions**: Add explicit label such as "Moves" or "Moves / Target" near the numeric display.
- **Design intent cross-check**: **Conflict** with Move Counter/HUD intent of clearly communicating progress toward minimum moves.

### Coverage Counter Visibility

- **Understood purpose?** Yes
- **Found engaging?** Neutral
- **Suggestions**: Consider hiding detailed coverage count from player-facing HUD and retaining it in debug output (or optional advanced HUD mode).
- **Design intent cross-check**: **Potential conflict**. Current Coverage and HUD design explicitly present live coverage counts to aid planning. This needs a product decision before change.

### Visual Polish (UI, Animation, Cat)

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**: Keep current assets as wireframe baseline; schedule a dedicated polish pass for motion, readability hierarchy, and character appeal.
- **Design intent cross-check**: **Aligned** with current stage; polish expected post-wireframe.

### Tutorial / Onboarding

- **Understood purpose?** Partially
- **Found engaging?** N/A
- **Suggestions**: Add early step-by-step tutorial hints covering controls and objective (mobile swipe + desktop WASD/arrow).
- **Design intent cross-check**: **Open decision**. Supports onboarding quality but should be scoped against MVP constraints.

## Quantitative Data (if available)

- **Deaths**: N/A
- **Time per area**: N/A
- **Items used**: N/A
- **Features discovered vs missed**:
  - Discovered: core movement, level completion, results screen
  - Missed/unclear: clear control teaching, explicit move-counter meaning

## Overall Assessment

- **Would play again?** Maybe
- **Difficulty**: Just Right mechanically, but feedback clarity needs improvement
- **Pacing**: Slightly too abrupt at completion transition
- **Session length preference**: Good

## Top 3 Priorities from this session

1. Fix Undo button state/behavior so Undo is usable after first move.
2. Add a short completion transition beat before results screen.
3. Improve HUD clarity (labeled move counter) and decide whether coverage count remains player-facing.
