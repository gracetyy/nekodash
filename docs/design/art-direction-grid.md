# NekoDash — Grid & World Art Direction

> **Status**: Approved
> **Created**: 2026-04-02
> **Author**: Grace + GitHub Copilot
> **Reference Images**: `design/reference/` (game-level-screen, world-map, level-selection)

---

## Purpose

This document defines the visual art direction for the **game grid** — the floor tiles,
obstacle/wall objects, and per-world theming that the player sees during gameplay.

> **Critical Note**: The plain coloured tiles in the AI reference screenshots are
> **placeholder art only**. The actual game grid must look like a **top-down view
> of an interior room**. The cat is walking across a real floor. Walkable tiles are
> floor surfaces (wood, carpet, stone, etc.). Obstacles are furniture and household
> objects seen from above. The overall feel is a cosy, kawaii domestic space.

---

## Core Visual Concept: The Room

The game grid represents a **room interior viewed from directly overhead**.

- The **cat slides across the floor** — every walkable tile is a floor surface
- The **obstacles are furniture** — the cat bumps into a bookshelf, sofa, box, etc.
- The room has **walls at its border** — the grid's outer edge reads as room walls
- Each **world has a distinct room theme** — different rooms mean different floor
  materials and furniture sets

The player should feel they are watching a cat zoom around a miniature room from above.
This is the "cosy puzzle" emotional core. It elevates the game from abstract coloured
tiles to a charming domestic diorama.

---

## 1. Floor Tiles (Walkable)

### Visual Requirements

- Floor tiles must read as a **real surface material** with texture and pattern
- Tiles must be distinguishable as a grid unit while seamlessly tiling across the board
- The **cat's trail** (visited tiles) shows a **paw-print impression** or subtle
  glow/warmth on the floor — like the cat has padded softly across that spot
- Unvisited and visited tiles must be clearly different but both feel like floor
- No plain flat colour or rectangle — even the baseline (World 1) must have visible grain

### Trail State vs Unvisited State

| State     | Visual Description                                                             |
| --------- | ------------------------------------------------------------------------------ |
| Unvisited | Floor material at normal lighting / tone                                       |
| Visited   | Floor material with a warm golden glow or visible paw impression overlay       |
| Current   | Cat sits here; no special tile treatment (cat sprite handles position clarity) |

The trail overlay must not obscure the floor texture — it layers on top as a tint or
additive glow, not a flat fill.

---

## 2. Obstacle Tiles (Blocking / Walls)

> **UPDATE (2026-04-15)**: The idea of using complex furniture and detailed room walls as level grid obstacles is deferred to post-jam. For the MVP, we will simply use three distinct colored tile PNGs (yellow, purple, mint) to represent obstacles/walls.

### MVP Design Rules (Simple Tiles)

1. **Obstacles are simple colored tiles**, specifically yellow, purple, and mint.

### Post-Jam Rules (Furniture)

1. **Obstacles are furniture and household objects**, not abstract walls or bricks
2. All objects are rendered as a **top-down (plan) view** — we see the top face
3. Objects must have a **visible volume suggestion** — a subtle shadow or isometric-lite
   depth line on one or two sides to prevent flatness (think Animal Crossing / Stardew
   top-down room style)
4. Each obstacle must clearly read as **solid and impassable** — physically chunky,
   not decorative
5. Obstacles can **span multiple cells** (e.g. a sofa = 1×2, a bookshelf = 1×3)
   but must define which cells they occupy in the level data as individual `BLOCKING`
   tiles — the art is a multi-tile sprite

### Obstacle → Furniture Mapping

These are the obstacle types planned across worlds. Each maps to a gameplay `ObstacleType`
enum value and a real-world furniture analogue. Art must ship for all MVP types.

#### MVP Obstacle Types (Static walls)

These all share `ObstacleType.STATIC_WALL` in code. Art differentiates them visually
by world theme and tile atlas cell ID:

| Obstacle Art ID      | Object              | Tile Size | Visual Description (top-down)                                       | World       | Draft Source              |
| -------------------- | ------------------- | --------- | ------------------------------------------------------------------- | ----------- | ------------------------- |
| `OBS_BOX`            | Cardboard box       | 1×1       | Square box top, brown kraft paper texture, paw-print sticker on top | W3          | `tileset-livingroom-ver1` |
| `OBS_STOOL`          | Round stool         | 1×1       | Circular seat cushion, wooden legs visible as dots                  | W3          | —                         |
| `OBS_PLANT_SM`       | Small plant pot     | 1×1       | Round terracotta pot top, green leafy crown                         | W3          | `tileset-livingroom-ver1` |
| `OBS_SHELF`          | Bookshelf           | 1×3       | Top-down strip: colourful pastel book spines                        | W3+post-jam | `tileset-livingroom-ver1` |
| `OBS_SOFA`           | Sofa / couch        | 1×2       | Lavender rounded back cushion + seat cushion visible                | W3          | `tileset-livingroom-ver1` |
| `OBS_ARMCHAIR`       | Armchair            | 1×1       | Lavender cushion seat, smaller than sofa                            | W3          | `tileset-livingroom-ver2` |
| `OBS_TABLE`          | Side table          | 1×1       | Square or round table top, small legs at corners/edge               | W3          | `tileset-livingroom-ver1` |
| `OBS_TABLE_RND`      | Round coffee table  | 1×1       | Circular top, minimal legs                                          | W3          | `tileset-livingroom-ver2` |
| `OBS_TV_STAND`       | TV on media unit    | 1×2       | TV screen top view on wood console unit                             | W3          | `tileset-livingroom-ver2` |
| `OBS_OTTOMAN`        | Circular ottoman    | 1×1       | Round padded seat, top-down circle                                  | W3          | `tileset-livingroom-ver2` |
| `OBS_FLOOR_CUSHION`  | Floor cushion       | 1×1       | Round/square cushion on floor, soft patterned fabric from top       | W3          | —                         |
| `OBS_CACTUS`         | Cactus              | 1×1       | Round ceramic pot, chunky green cactus from top                     | W3          | —                         |
| `OBS_SCRATCHER`      | Cat scratcher post  | 1×1       | Circular base from above, wrapped sisal column top                  | W3          | —                         |
| `OBS_WARDROBE`       | Wardrobe            | 1×3       | Two/three-door top, handles, walnut wood grain texture              | W1          | `tileset-bedroom`         |
| `OBS_BED`            | Double bed          | 2×2       | Pink/rose duvet, heart-print pillows visible from top               | W1          | `tileset-bedroom`         |
| `OBS_NIGHTSTAND`     | Nightstand + lamp   | 1×1       | Small square unit, round lamp base on top                           | W1          | `tileset-bedroom`         |
| `OBS_BEANBAG`        | Bean bag            | 1×1       | Peach/orange teardrop shape from top                                | W1          | `tileset-bedroom`         |
| `OBS_DRAWERS`        | Chest of drawers    | 1×2       | Rectangular unit, drawer handle lines visible                       | W1          | `tileset-bedroom`         |
| `OBS_MIRROR`         | Floor mirror        | 1×2       | Tall oval mirror, thin frame                                        | W1          | `tileset-bedroom`         |
| `OBS_LAUNDRY`        | Laundry basket      | 1×1       | Round wicker basket from top                                        | W1          | `tileset-bedroom`         |
| `OBS_CATBED`         | Round cat bed       | 1×1       | Small circle with padded rim                                        | W1          | `tileset-bedroom`         |
| `OBS_FRIDGE`         | Fridge              | 1×1       | Tall/prominent rectangle, handle line on door                       | W2          | `tileset-kitchen`         |
| `OBS_STOVE`          | Stove / cooktop     | 1×2       | 4 circular burner rings visible from top                            | W2          | `tileset-kitchen`         |
| `OBS_MICROWAVE`      | Microwave           | 1×1       | Small rectangle, door latch detail                                  | W2          | `tileset-kitchen`         |
| `OBS_WASHER`         | Washer / dishwasher | 1×1       | Square unit, round porthole window on door                          | W2          | `tileset-kitchen`         |
| `OBS_SINK`           | Kitchen sink        | 1×1       | Rectangular sink unit, circular drain visible                       | W2          | `tileset-kitchen`         |
| `OBS_BINS`           | Recycling bins      | 1×1 each  | Round mint-green bin tops, recycle symbol                           | W2          | `tileset-kitchen`         |
| `OBS_COFFEE`         | Coffee maker        | 1×1       | Compact rounded top view                                            | W2          | `tileset-kitchen`         |
| `OBS_COUNTER`        | Kitchen counter     | 1×3       | Long horizontal white/cream counter unit                            | W2          | `tileset-kitchen`         |
| `OBS_KITCHEN_ISLAND` | Kitchen island      | 1×2       | Freestanding counter island, two-tile wide, top-down                | W2          | —                         |
| `OBS_CAT_BOWL`       | Cat food bowl       | 1×1       | Round bowl with food, cute paw print on bowl exterior               | W2          | —                         |
| `OBS_COLUMN`         | Room support col    | 1×1       | Octagonal or round pillar top, stone/marble                         | All         | —                         |

#### Post-Jam Obstacle Types (Dynamic)

| Obstacle Art ID | Object         | Note                                       |
| --------------- | -------------- | ------------------------------------------ |
| `OBS_MOVING`    | Roomba / pet   | Animated sprite, moves on a path           |
| `OBS_TIMED`     | Automatic door | Opens/closes on timer                      |
| `OBS_TELE`      | Cat flap / rug | Teleporter — distinct swirl/shimmer effect |

### Obstacle Art Rules

- **Drop shadow**: All furniture objects cast a short drop shadow to the bottom-right
  (simulating a top-left light source) — 3–4px offset, 40% opacity black
- **No outlines on floor**: Obstacles should NOT share the same visual weight as floor
  tile boundaries — they must read as objects sitting ON the floor
- **Colour harmony**: Furniture colours are warm and desaturated, matching the world
  palette — no harsh black/grey metal objects in early worlds
- **Cute-scale distortion**: Proportions are slightly exaggerated/chibi — a sofa is
  chunkier, a bookshelf has cuter pastel book spines, etc.

---

## 3. Grid Container & Room Walls

### Grid Frame (Unified Container)

Draft art (`design/draft/tileset-floor-ver2 1.png`) confirms the grid is presented as a
**single unified container panel**, not a per-tile border treatment:

- The entire playfield of floor tiles sits inside a **rounded-rect frame** with a
  **purple-mauve border and subtle corner accent details**
- This frame is one panel element in the scene (a `Panel` or `NinePatchRect` node)
  behind/around the `TileMapLayer`, not individual border-row sprite tiles
- The interior of the frame is filled by the seamless floor tile layer
- Frame background colour: matches `grid-wall` token (purple-mauve) or world-specific border colour

### Wall Tiles (Room Wall Surface)

Blocking cells at the grid perimeter (and any interior walls) use **wall tile sprites**
that represent the room's walls — NOT just the frame above. Wall tiles are background
sprites applied to blocking cells:

- Each world has a dedicated wall tile set (4–8 variants) — see `design/draft/tileset-wall-ver1` through `ver4`
- Straight sections use the plain/repeated wall variant
- Corner cells use the L-shape corner variant
- Decorative placements (clock, picture, outlet) go where the player can see them
- Wall tiles must visually distinguish themselves from floor tiles: different surface
  material (painted plaster vs wood grain), different value/darkness

**Wall tile sets by world:**

| World            | Theme                        | Draft File              | Variants                                                                                 |
| ---------------- | ---------------------------- | ----------------------- | ---------------------------------------------------------------------------------------- |
| 1 — Bedroom      | Pastel pink kawaii wallpaper | `tileset-wall-ver4.png` | 8: plain pink, stars, hearts, corner, fairy lights, floating shelf, poster, outer corner |
| 2 — Kitchen      | White/mint subway tile       | `tileset-wall-ver3.png` | 8: plain, mint accent, grout, corner, knife rack, calendar, window, outer corner         |
| 3 — Living Room  | Brown wood log-cabin planks  | `tileset-wall-ver1.png` | 6: plain, corner, alt corner, shelf, clock, picture                                      |
| Post-jam — Study | Lavender paw-print wallpaper | `tileset-wall-ver2.png` | 8: plain, stripe, dense paw, corner, cat picture, switch, outlet, dark solid             |

---

## 4. World Themes

Each world is a **different room** in the cat's home. Each has a unique floor material,
furniture palette, and wall treatment. The player should feel they are exploring new
rooms as they progress.

---

### World 1 — Dreamy Den ("The Bedroom") 🛏️

**Room concept**: The cat's own bedroom — soft, cosy, personal. First world: larger grid,
higher obstacle density. Sets the warm kawaii tone for the whole game.

| Element               | Description                                                                                                                     |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Grid size range**   | 7×7 to 9×9                                                                                                                      |
| **Obstacle density**  | 0.18–0.25 (more furniture = more challenge per move)                                                                            |
| **Levels**            | 5–7 levels                                                                                                                      |
| **Floor tile**        | Soft pale pink carpet — subtle fabric weave texture, dusky rose colour                                                          |
| **Floor colour**      | Unvisited: `#FFE8EE` · Visited glow: `#FFD6E0`                                                                                  |
| **Trail tint**        | Warm golden-amber glow over the carpet texture                                                                                  |
| **Background colour** | `#FDE8EE`                                                                                                                       |
| **Accent colour**     | `#F5C842` (gold)                                                                                                                |
| **Wall border**       | Pastel pink kawaii wallpaper (`tileset-wall-ver4`) — 8 variants with fairy lights, floating shelf, poster                       |
| **Furniture set**     | Double bed (2×2), wardrobe (1×3), chest of drawers, nightstand with lamp, floor mirror, bean bag, laundry basket, round cat bed |
| **Furniture palette** | Warm rose/pink duvet, walnut brown wardrobe, peach soft furnishings                                                             |
| **Colour mood**       | Dusky rose, mauve, soft warm pink, cream                                                                                        |
| **Music mood**        | Dreamy, lullaby-adjacent, music box or gentle chime, soft synth                                                                 |

---

### World 2 — Cream Caverns ("The Kitchen") 🍳

**Room concept**: Clean, bright kitchen. Unlocked after completing all World 1 levels.
Medium grid, medium obstacle density. Introduces tighter spatial puzzles.

| Element               | Description                                                                                                  |
| --------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Grid size range**   | 6×6 to 8×8                                                                                                   |
| **Obstacle density**  | 0.15–0.20                                                                                                    |
| **Levels**            | 5–7 levels                                                                                                   |
| **Floor tile**        | White ceramic square tiles with thin grey grout lines, slight gloss on tile centres                          |
| **Floor colour**      | Unvisited: `#F8F8F8` · Grout: `#D8D8D8` · Visited glow: `#DCF3EA` (mint)                                     |
| **Trail tint**        | Mint-green glow over tile surface                                                                            |
| **Background colour** | `#EEF7F3`                                                                                                    |
| **Wall border**       | White/mint subway tile (`tileset-wall-ver3`) — knife rack, window, calendar props                            |
| **Furniture set**     | Refrigerator, stove/cooktop, microwave, kitchen counter, kitchen island, sink, recycling bins, cat food bowl |
| **Furniture palette** | Clean white, stainless silver accents, mint green bins, cream cabinetry                                      |
| **Colour mood**       | Clean white, sage, warm cream                                                                                |
| **Music mood**        | Slightly upbeat, light percussion, playful melody, marimba or whistle                                        |

---

### World 3 — Pastel Plains ("The Living Room") 🛋️

**Room concept**: Bright, welcoming living room. Unlocked after completing all World 2 levels.
Smaller grid, lower obstacle density. All levels solvable ≤8 moves at 3-star, no dead-end traps.

| Element               | Description                                                                                               |
| --------------------- | --------------------------------------------------------------------------------------------------------- |
| **Grid size range**   | 5×5 to 7×7                                                                                                |
| **Obstacle density**  | 0.10–0.15 (fewer obstacles, trickier placement)                                                           |
| **Levels**            | 5–7 levels. All solvable ≤8 moves at 3-star, no dead-end traps.                                           |
| **Floor tile**        | Warm oak hardwood planks — warm honey-beige, visible wood grain, horizontal plank lines                   |
| **Floor colour**      | Unvisited: `#F5E6C8` · Visited glow: `#F5C842`                                                            |
| **Trail tint**        | Warm amber glow over the plank texture                                                                    |
| **Background colour** | `#F5EDE0`                                                                                                 |
| **Accent colour**     | `#5C4A6B` (dark plum)                                                                                     |
| **Wall border**       | Brown wood log-cabin planks (`tileset-wall-ver1`) — shelf, clock, picture props                           |
| **Furniture set**     | Sofa, armchair, floor cushion, bookshelf, coffee table, TV stand, large plant, cactus, cat scratcher post |
| **Furniture palette** | Lavender cushions, oak wood tones, terracotta for plants, warm cream                                      |
| **Colour mood**       | Warm cream, honey, soft sage greenery                                                                     |
| **Music mood**        | Warm lo-fi acoustic, slow tempo, soft piano                                                               |

---

### Future Worlds (Post-Jam Concepts)

| Room            | Floor Concept                      | Dominant Colour     |
| --------------- | ---------------------------------- | ------------------- |
| Study / Library | Dark walnut herringbone planks     | Walnut, dusty lilac |
| Bathroom        | White hex tiles with blue grout    | White, sky blue     |
| The Greenhouse  | Stone/terracotta tiles, mossy gaps | Deep green, clay    |
| The Hallway     | Black & white checkerboard         | Monochrome          |
| The Attic       | Rough plank boards, dusty          | Sepia, aged oak     |

---

## 5. Cat Trail — Visual Specification

The cat's trail (visited tiles) is one of the most visually important elements in the
game — it is the player's "drawing" that fills the room.

### Trail Overlay Layer

- Sits **on top of** the floor texture layer, **behind** the cat sprite
- Uses additive or multiply blending to let the floor texture show through
- Colour: warm amber/gold tint — consistent across all worlds (the "cat warmth" reads
  as a universal language regardless of room theme)

### Trail Variants

| Context           | Effect                                                                |
| ----------------- | --------------------------------------------------------------------- |
| Freshly placed    | Bright warm glow (full opacity), fades slightly over ~0.3s to settled |
| Settled (resting) | Softer, slightly dimmer warm tint — still clearly visible             |
| On restart/undo   | Fades out over ~0.2s as tiles revert                                  |

### Paw Print Overlay (Optional Enhancement)

If performance allows, each visited tile may also render a **subtle paw print stamp**
centred on the tile — a translucent darker-amber paw silhouette. This makes the trail
read literally as the cat's path. Size: 60–70% of tile width. Opacity: 25–35%.

---

## 6. Tile Sizing & Grid Rendering

### Tile Dimensions

| Grid Size | Target Tile Px (portrait 390px wide) | Margin        |
| --------- | ------------------------------------ | ------------- |
| 5×5       | 60px × 60px                          | 8px each side |
| 7×7       | 48px × 48px                          | 8px each side |
| 9×9       | 36px × 36px                          | 8px each side |
| 11×11     | 28px × 28px                          | 8px each side |

Tile sizes are calculated at runtime to fill the available vertical space while
maintaining square tiles and the 8px horizontal margin constraint.

### Rendering Layers (bottom → top)

```
Layer 0: Floor / Background tiles (TileMapLayer — floor set)
Layer 1: Trail overlay (TileMapLayer — trail set OR shader overlay)
Layer 2: Obstacle / furniture sprites (TileMapLayer — obstacle set)
Layer 3: Cat sprite (CharacterBody2D or AnimatedSprite2D)
Layer 4: VFX particles (trail sparkle, bump dust, etc.)
Layer 5: HUD (CanvasLayer — always on top)
```

### Pixel Art vs Vector Art Decision

| Approach           | Pros                                          | Cons                                          |
| ------------------ | --------------------------------------------- | --------------------------------------------- |
| **Pixel art**      | Native to tile grids, sharp at fixed scales   | Needs multiple resolutions or careful scaling |
| **Vector SVG**     | Scales perfectly, file-size efficient         | Complex for detailed textures                 |
| **Painted raster** | Rich texture, matches cute illustration style | Larger files, needs power-of-2 atlases        |

**Recommendation**: Painted raster at 64×64px per tile base resolution, exported into
a Godot TileSet atlas. Scale to match viewport using integer scaling where possible.
Minimum export: 1× (64px) and 2× (128px) for high-DPI screens.

---

## 7. Tileset Atlas Layout

The `TileMapLayer` atlas should be organised as follows (to match `get_tile_art_id()`
in the Grid System API):

```
Row 0 : Floor tiles      — [unvisited_w1, unvisited_w2, unvisited_w3, ...]
Row 1 : Trail overlay    — [trail_w1, trail_w2, trail_w3, ...]
Row 2 : Wall border      — [border_w1, border_w2, border_w3, ...]
Row 3 : Obstacle 1×1     — [box, stool, plant, table, column, ...]
Row 4 : Obstacle 1×2     — [sofa_top, sofa_btm, wardrobe_top, wardrobe_btm, ...]
Row 5 : Obstacle 1×3     — [shelf_top, shelf_mid, shelf_btm, ...]
Row 6 : Paw print stamps — [paw_w1, paw_w2, paw_w3, ...]
```

The atlas cell ID referenced by `get_tile_art_id()` maps directly to column index
within the correct row. The `world_id` parameter selects the column offset.

---

## 8. Art Asset Checklist (MVP)

### Floor Tiles (per world × 3 worlds = 3 each)

- [ ] Floor — unvisited (World 1: pale pink carpet `#FFE8EE`) — not yet created
- [ ] Floor — visited/trail (World 1: carpet + golden glow `#FFD6E0` + paw stamp) — not yet created
- [ ] Floor — unvisited (World 2: white ceramic tile `#F8F8F8`) — not yet created
- [ ] Floor — visited/trail (World 2: ceramic + mint glow `#DCF3EA` + paw stamp) — not yet created
- [✅] Floor — unvisited (World 3: warm oak plank `#F5E6C8`) — `tileset-floor-ver1`
- [✅] Floor — visited/trail (World 3: plank + amber glow `#F5C842` + paw stamp) — `tileset-floor-ver1`
- [ ] Trail overlay (world-specific glow, tileable) — not yet created as standalone tile
- [✅] Paw stamp on trail tile — confirmed in `tileset-floor-ver1` (right tile has white paw stamp)

### Grid Container Frame

- [✅] Unified rounded-rect grid frame with purple-mauve border — confirmed in `tileset-floor-ver2`

### Wall Tile Sets (per world)

- [✅] Wall tile set — World 1 / Bedroom (pink kawaii) — `tileset-wall-ver4.png` (8 variants)
- [✅] Wall tile set — World 2 / Kitchen (white/mint subway) — `tileset-wall-ver3.png` (8 variants)
- [✅] Wall tile set — World 3 / Living Room (wood plank) — `tileset-wall-ver1.png` (6 variants)
- [✅] Wall tile set — Post-jam / Study (lavender paw) — `tileset-wall-ver2.png` (8 variants)

### Obstacles (MVP set — shared across worlds, palette-swapped per world)

**World 1 (Bedroom):**

- [✅] `OBS_BED` — double bed (2×2) — `tileset-bedroom`
- [✅] `OBS_NIGHTSTAND` — nightstand + lamp (1×1) — `tileset-bedroom`
- [✅] `OBS_BEANBAG` — bean bag (1×1) — `tileset-bedroom`
- [✅] `OBS_WARDROBE` — wardrobe (1×3) — `tileset-bedroom`
- [✅] `OBS_DRAWERS` — chest of drawers (1×2) — `tileset-bedroom`
- [✅] `OBS_MIRROR` — floor mirror (1×2) — `tileset-bedroom`
- [✅] `OBS_LAUNDRY` — laundry basket (1×1) — `tileset-bedroom`
- [✅] `OBS_CATBED` — round cat bed (1×1) — `tileset-bedroom`

**World 2 (Kitchen):**

- [✅] `OBS_FRIDGE` — fridge (1×1) — `tileset-kitchen`
- [✅] `OBS_STOVE` — stove/cooktop (1×2) — `tileset-kitchen`
- [✅] `OBS_MICROWAVE` — microwave (1×1) — `tileset-kitchen`
- [✅] `OBS_WASHER` — washer/dishwasher (1×1) — `tileset-kitchen`
- [✅] `OBS_SINK` — kitchen sink (1×1) — `tileset-kitchen`
- [✅] `OBS_BINS` — recycling bins (1×1) — `tileset-kitchen`
- [✅] `OBS_COFFEE` — coffee maker (1×1) — `tileset-kitchen`
- [✅] `OBS_COUNTER` — kitchen counter (1×3) — `tileset-kitchen`
- [ ] `OBS_KITCHEN_ISLAND` — kitchen island (1×2) — not yet created
- [ ] `OBS_CAT_BOWL` — cat food bowl (1×1) — not yet created

**World 3 (Living Room):**

- [✅] `OBS_BOX` — cardboard box (1×1) — `tileset-livingroom-ver1`
- [✅] `OBS_PLANT_SM` — small plant pot (1×1) — `tileset-livingroom-ver1`
- [✅] `OBS_SHELF` — bookshelf (1×3) — `tileset-livingroom-ver1`
- [✅] `OBS_SOFA` — sofa (1×2) — `tileset-livingroom-ver1`
- [✅] `OBS_ARMCHAIR` — armchair (1×1) — `tileset-livingroom-ver2`
- [✅] `OBS_TABLE` — side table (1×1) — `tileset-livingroom-ver1`
- [✅] `OBS_TABLE_RND` — round coffee table (1×1) — `tileset-livingroom-ver2`
- [✅] `OBS_TV_STAND` — TV on media unit (1×2) — `tileset-livingroom-ver2`
- [✅] `OBS_OTTOMAN` — circular ottoman (1×1) — `tileset-livingroom-ver2`
- [ ] `OBS_FLOOR_CUSHION` — floor cushion (1×1) — not yet created
- [ ] `OBS_CACTUS` — cactus (1×1) — not yet created
- [ ] `OBS_SCRATCHER` — cat scratcher post (1×1) — not yet created
- [ ] `OBS_STOOL` — round stool (1×1) — not yet created
- [ ] `OBS_COLUMN` — pillar (1×1) — not yet created

**Post-jam — Study/Library obstacle set not yet created.**

### Palette-Swap Variants

Each obstacle needs a colour variant per world (World 1: rose/pink bedroom tones, World 2: white/mint kitchen,
World 3: oak/cream living room). This can be achieved via:

- Separate atlas tiles per world, OR
- Godot `CanvasItemMaterial` modulate + palette shader (preferred for asset efficiency)

---

## 9. Do's and Don'ts

### Do ✅

- Reference Animal Crossing: New Horizons (room overhead view), Stardew Valley (furniture
  silhouettes), and A Short Hike (warm cosy palette) as visual tone references
- Keep furniture colours warm and desaturated — no neon, no harsh contrast
- Let the wood grain / tile grout add implicit grid lines — the player can read the grid
  without explicit lines drawn on it
- Exaggerate furniture proportions slightly for readability at small tile sizes

### Don't ❌

- Do not use flat solid-colour tiles (the AI reference images are placeholder art — do not
  ship the flat purple/green tiles)
- Do not make obstacles feel abstract or geometric — every obstacle should be identifiable
  as a real household object
- Do not use the same obstacle art for different `ObstacleType` values — player reads
  obstacle type visually
- Do not make the trail overlay fully opaque — the floor texture must show through
- Do not use pure black for any outline or shadow — use dark warm browns instead

---

## 10. References

- **AI Reference images**: `design/reference/game-level-screen.png` (structure only, not palette)
- **Tone references**: Animal Crossing room overhead, Stardew Valley indoor tiles, A Short Hike
- **Furniture scale reference**: Think "Fisher-Price chunky toy" proportions — oversized, rounded, durable-looking
- **Per-screen layout**: `docs/design/design-system.md` Section 6.4
- **Grid data model**: `design/gdd/grid-system.md`
- **Obstacle type enums**: `design/gdd/obstacle-system.md`
- **Draft assets (text descriptions)**: `docs/design/draft-assets.md`
