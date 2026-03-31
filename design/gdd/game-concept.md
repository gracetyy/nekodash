# Game Concept: NekoDash

_Created: 2026-03-30_
_Status: Draft_

---

## Elevator Pitch

> A kawaii mobile puzzle game where you swipe a cute cat across a top-down grid, gliding until it hits a wall, with the goal of covering every tile in the fewest moves possible. It's like Pokémon's ice cave puzzles, AND ALSO your entire score is always visible as a challenge to beat.

---

## Core Identity

| Aspect                | Detail                                                              |
| --------------------- | ------------------------------------------------------------------- |
| **Genre**             | Puzzle / Sliding mechanics                                          |
| **Platform**          | Mobile-first (iOS + Android); multiplatform via Godot export        |
| **Target Audience**   | Casual puzzle fans and completionist mobile players                 |
| **Player Count**      | Single-player                                                       |
| **Session Length**    | 5–30 minutes                                                        |
| **Monetization**      | F2P with optional cosmetic IAP and rewarded video ads (light touch) |
| **Estimated Scope**   | Small (jam: 3–6 weeks MVP; post-jam expansion optional)             |
| **Comparable Titles** | Pokémon ice-sliding puzzles, Bloxorz, Bonza Word Puzzle             |

---

## Core Fantasy

You are a perfectly focused little cat. Every swipe is precise, intentional, elegant. The floor lights up behind you as you glide across it — and when you lift your finger after the final tile goes gold, you feel the quiet satisfaction of a clean solution. You could have done it in 8 moves. You did it in 6. The cat blinks contentedly.

---

## Unique Hook

It's like an ice-sliding puzzle game, AND ALSO the minimum possible solution is always displayed — so every player, casual or perfectionist, always knows exactly how close to perfect they are.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic                                 | Priority | How We Deliver It                                                       |
| ----------------------------------------- | -------- | ----------------------------------------------------------------------- |
| **Challenge** (obstacle course, mastery)  | 1        | Minimum-move counter; increasingly complex level layouts                |
| **Sensation** (sensory pleasure)          | 2        | Satisfying slide momentum, tile-light VFX, soft audio feedback, haptics |
| **Submission** (relaxation, comfort zone) | 3        | No timers, no lives, no punishment; kawaii aesthetic keeps tone warm    |
| **Discovery** (exploration, secrets)      | 4        | New obstacle types introduced per world; hidden skin unlock conditions  |
| **Expression** (self-expression)          | 5        | Cat skin cosmetics; no gameplay impact                                  |
| **Fantasy** (make-believe)                | N/A      | —                                                                       |
| **Narrative** (drama, story arc)          | N/A      | No story required at jam scope                                          |
| **Fellowship** (social connection)        | N/A      | Single-player only                                                      |

### Key Dynamics (Emergent player behaviors)

- Players will replay levels after completion, chasing the minimum-move count
- Players will mentally "pre-plan" routes before swiping, naturally developing spatial reasoning skills
- Players will share satisfying solutions or perfect-score screenshots socially
- Players will try new skins on familiar levels as a way to re-engage with old content

### Core Mechanics (Systems we build)

1. **Sliding movement** — Swipe input propels the cat in a cardinal direction; cat glides until hitting a wall or obstacle; no partial stops on open tiles
2. **Coverage tracking** — Each tile the cat passes over is marked as covered; level completes when 100% of walkable tiles are covered
3. **Move counter + minimum solver** — Every move is counted; a BFS/Dijkstra algorithm calculates and displays the minimum moves for each level
4. **Obstacle system** — Static walls (MVP), plus moving walls, teleporters, and timed obstacles (post-jam)
5. **Skin system** — Cosmetic cat skins unlockable via gameplay milestones, rewarded ads, or optional IAP

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need                                      | How This Game Satisfies It                                                      | Strength   |
| ----------------------------------------- | ------------------------------------------------------------------------------- | ---------- |
| **Autonomy** (freedom, meaningful choice) | Player chooses when to retry, when to move on, and which skin to use            | Supporting |
| **Competence** (mastery, skill growth)    | Move counter and minimum display give constant, legible feedback on improvement | Core       |
| **Relatedness** (connection, belonging)   | Cat character creates warmth and personality; skin unlocks reinforce identity   | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — 3-star system, minimum move targets, skin collection
- [x] **Explorers** — New obstacle types per world, discovering optimal solutions
- [ ] **Socializers** — Not a focus; no multiplayer
- [ ] **Killers/Competitors** — No PvP or leaderboards at MVP scope

### Flow State Design

- **Onboarding curve**: First 3 levels are tutorial-by-design — open grids with 1-2 moves, no text needed. Player learns the mechanic by doing it.
- **Difficulty scaling**: Each world introduces exactly one new obstacle type. Complexity grows via grid size and obstacle combinations, not by changing the core verb.
- **Feedback clarity**: Tile color changes on coverage; move count updates live; completion triggers a satisfying visual + audio flourish. Minimum move count is always visible.
- **Recovery from failure**: No penalty for failure. "Undo" and "restart" are always available with no cost. Failure reads as "interesting puzzle to solve" not "you lost."

---

## Core Loop

### Moment-to-Moment (30 seconds)

Swipe → cat glides across the grid with momentum → lands with a soft thud sound and a small bounce animation → covered tiles light up in the cat's color → player scans new position and plans the next swipe. The action is intrinsically satisfying: smooth movement, clear visual feedback, tactile swipe gesture.

### Short-Term (5–15 minutes)

One level: player attempts a solution, sees their move count vs. minimum, decides whether to retry for a better score or accept and advance. Retry is instant. This is where "one more try" psychology lives.

### Session-Level (15–30 minutes)

A world of 8–10 levels with a consistent obstacle theme. Ends with a slightly harder capstone puzzle that rewards the skills learned in that world. Natural stopping point: world complete screen with overall star rating.

### Long-Term Progression

- Unlock new worlds (gated by completing previous world, not by star count)
- Earn cat skins through cumulative milestones (e.g., "3-star 5 levels", "total 100 levels completed")
- Optional: watch a rewarded ad to unlock a preview skin; purchase skin bundles via IAP

### Retention Hooks

- **Mastery**: "I did it in 7, the minimum is 5 — I know I can do better."
- **Curiosity**: "What obstacle does the next world introduce?"
- **Investment**: Skin collection grows over time; player has a "main" cat
- **Completion**: Star count per world creates a visible completion signal

---

## Game Pillars

### Pillar 1: Every Move Is a Choice

The player is always the puzzle-solver, never the victim of an unfair layout. Every level must be solvable, and the solution space must be predictable from the rules. No ambiguity, no randomness, no luck.

_Design test_: "Should we add a timer that forces faster decisions?" → No. Time pressure shifts the game from spatial reasoning to reflex, which contradicts this pillar.

### Pillar 2: Joyful at Every Moment

Visual and audio feedback must make even failed attempts feel warm and pleasant. The cat's animations, sounds, and expressions should never communicate frustration or judgment — only personality and delight.

_Design test_: "Should the cat look distressed or sad when the player fails?" → No. The cat blinks, tilts its head, maybe shrugs. The tone stays kawaii.

### Pillar 3: Complete Your Own Way

Every level has a casual completion path (cover the tiles, move on, see the world) and a perfectionist challenge (minimum moves, 3 stars). Neither player type is penalized or blocked. Stars are for pride, not for progress gates.

_Design test_: "Should we require 3 stars to unlock the next world?" → No. Progress is gated by level completion only. Stars are a personal achievement.

### Pillar 4: Respect the Player's Time

Sessions are short by design. Levels take 1–3 minutes. There are no mandatory ads, no energy systems, no wait timers. The game earns monetization through charm, not coercion.

_Design test_: "Should we add an energy system to extend playtime?" → No. Energy systems punish play frequency and poison the Submission aesthetic.

### Anti-Pillars (What This Game Is NOT)

- **NOT a reflex game**: No time pressure, no lives lost, no punishment for slow thinking. The puzzle is always patient.
- **NOT narrative-driven**: No story, dialogue, or cutscenes at MVP scope. The cat's personality is communicated entirely through animation and design.
- **NOT pay-to-win**: Skins are purely cosmetic. IAP never affects puzzle access, minimum move display, or any gameplay system.
- **NOT a grind**: Players are never asked to replay content they don't want to replay. No daily quests, no login bonuses at MVP.

---

## Inspiration and References

| Reference                   | What We Take From It                                           | What We Do Differently                                                         | Why It Matters                                                           |
| --------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| Pokémon ice-sliding puzzles | The core sliding-until-wall mechanic; spatial satisfaction     | Explicit minimum-move counter; coverage-based goal instead of "reach the exit" | Validates the core mechanic is fun and understood by a mass audience     |
| Monument Valley             | Calm aesthetic, satisfying sound design, puzzle-as-art feeling | Grid-based, no perspective illusions; more replayable per level                | Shows premium puzzle mobile games can feel luxurious without complex art |
| Bloxorz                     | Coverage/state-based puzzle design; spatial reasoning depth    | 2D top-down; character instead of abstract block; mobile-native controls       | Validates coverage mechanics as a puzzle foundation                      |

**Non-game inspirations**:

- Japanese kawaii character design (Sanrio, chiikawa) — for the cat's circular, oversized-head aesthetic
- ASMR/lofi music aesthetics — for the audio palette: soft, warm, minimal
- Flat 2D illustration (Procreate/dribble kawaii art) — for tileset and UI visual direction

---

## Target Player Profile

| Attribute                     | Detail                                                             |
| ----------------------------- | ------------------------------------------------------------------ |
| **Age range**                 | 14–35                                                              |
| **Gaming experience**         | Casual to mid-core; plays mobile games daily                       |
| **Time availability**         | 5–20 minute sessions; commute, waiting, winding down               |
| **Platform preference**       | Mobile (iOS or Android primary)                                    |
| **Current games they play**   | Monument Valley, Wordle, Alto's Odyssey, casual puzzle apps        |
| **What they're looking for**  | A calm, satisfying puzzle without social pressure or energy gates  |
| **What would turn them away** | Aggressive ads, energy systems, time pressure, ugly or generic art |

---

## Technical Considerations

| Consideration                | Assessment                                                                                                                                       |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Engine**                   | Godot 4 + GDScript — lightweight for 2D mobile, free, excellent export to iOS/Android, active community                                          |
| **Key Technical Challenges** | Minimum-move solver (BFS on grid state with coverage tracking); swipe gesture disambiguation on mobile; TileMapLayer-based level design pipeline |
| **Art Style**                | Flat 2D, pastel kawaii, thick outlines, top-down perspective                                                                                     |
| **Art Pipeline Complexity**  | Low-Medium — tilesets, character sprites with animation frames, UI elements; manageable solo with basic art background                           |
| **Audio Needs**              | Minimal — 1 looping ambient track per world, ~6 SFX (swipe, land, tile-cover, complete, star-earn, menu)                                         |
| **Networking**               | None                                                                                                                                             |
| **Content Volume (MVP)**     | 15–20 levels, 3 worlds, 2–3 unlockable skins                                                                                                     |
| **Content Volume (Full)**    | 50+ levels, 6+ worlds, 10+ skins, moving walls + teleporters + timed obstacles                                                                   |
| **Procedural Systems**       | None — all levels hand-authored                                                                                                                  |

---

## Risks and Open Questions

### Design Risks

- **Coverage mechanic may be less satisfying than "reach the exit"**: The "must cover ALL tiles" goal is harder to communicate and may frustrate players if a single tile is missed with no clear path back. Mitigation: clear tile highlighting, generous undo system.
- **Minimum-move solver complexity**: Some grid configurations may produce minimum solutions that are unintuitive or feel "cheap." Mitigation: human-review all generated minimums during level design.
- **Difficulty curve too steep or too shallow for jam timeline**: With only 15–20 levels, difficulty must scale precisely. Mitigation: playtest sessions are essential before submission.

### Technical Risks

- **BFS solver performance on complex grids**: Solving minimum moves on large grids with many obstacle states (especially moving walls) could be computationally expensive. Mitigation: pre-compute and store solutions at level-design time, not at runtime.
- **Swipe gesture conflicts with OS-level swipe navigation**: Mobile systems (especially iOS edge swipes) can intercept swipe input. Mitigation: test swipe zones early; use tap-and-drag rather than pure swipe if needed.
- **Godot mobile export pipeline**: First-time Godot user; iOS/Android export setup has known friction (certificates, signing). Mitigation: test export pipeline in week 1, not week 5.

### Market Risks

- **Crowded mobile puzzle market**: The App Store is saturated with sliding puzzles. Mitigation: kawaii aesthetic + minimum-solver transparency is a differentiator; a jam release is low-stakes.
- **Discoverability**: First game, no audience. Mitigation: jam submission naturally provides an audience; not a commercial risk at this scope.

### Scope Risks

- **Art production for solo dev**: Even low-poly 2D art takes time. A pastel kawaii style requires consistent character animation. Mitigation: limit MVP to 1 cat sprite with 3–4 animation states; use simple tilesets with thick outlines (forgiving of small inconsistencies).
- **Feature creep from the full-vision list**: Moving walls, teleporters, timed obstacles are post-jam. Mitigation: Pillar 4 (Respect Player's Time) applies to developer time too — cut anything that doesn't test the core loop.

### Open Questions

- **Q: Is the "cover all tiles" goal immediately intuitive without tutorial text?** → Answered by the first playtest session. Design the first 3 levels to teach by example.
- **Q: Does the minimum-move display motivate or discourage casual players?** → Test by reading player reactions during playtest. If it demotivates, add an option to hide it.
- **Q: What is the right grid size range?** → Start 4×4 for tutorial, target 6×8 for mid-game. Validate against playtest timing data.

---

## MVP Definition

**Core hypothesis**: Players find the swipe-and-cover loop intrinsically satisfying, and the minimum-move counter motivates meaningful replay.

**Required for MVP**:

1. Sliding movement system (swipe → glide → stop at wall)
2. Coverage tracking + level completion detection
3. Move counter + pre-computed minimum move display
4. 15–20 hand-authored levels across 3 worlds (static walls only)
5. 1 playable cat skin + 1–2 unlockable skins via gameplay milestones
6. Basic audio: 1 ambient loop + core SFX set
7. Mobile-native swipe controls + portrait layout

**Explicitly NOT in MVP** (defer to post-jam):

- Moving walls, teleporters, timed obstacles
- Rewarded video ads and IAP
- Skin shop UI
- Leaderboards or social features
- Additional worlds beyond 3

### Scope Tiers

| Tier                 | Content                    | Features                                    | Timeline    |
| -------------------- | -------------------------- | ------------------------------------------- | ----------- |
| **MVP (jam submit)** | 15–20 levels, 3 worlds     | Sliding + coverage + move counter + 2 skins | 3–5 weeks   |
| **Post-jam v1.1**    | +2 worlds, +obstacle types | Moving walls, teleporters                   | +3–4 weeks  |
| **Full Vision**      | 50+ levels, 6+ worlds      | All obstacles, rewarded ads, IAP skin shop  | +2–3 months |

---

## Next Steps

- [ ] Run `/setup-engine godot 4` to configure engine reference docs
- [ ] Run `/design-review design/gdd/game-concept.md` to validate completeness
- [ ] Run `/map-systems` to decompose into individual systems with dependencies and priorities
- [ ] Run `/design-system` to author per-system GDDs (sliding movement, coverage tracker, solver algorithm, level format, skin system)
- [ ] Run `/architecture-decision` for first key technical decisions (level data format, solver approach, swipe input handling)
- [ ] Run `/prototype sliding-movement` to validate the core verb is fun before building everything else
- [ ] Run `/sprint-plan new` to plan the first jam sprint
