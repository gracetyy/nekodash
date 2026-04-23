# NekoDash — Asset Manifest

> **Updated**: 2026-04-17
> **Source of truth**: `design/draft/`, `docs/design/design-system.md`, `docs/design/art-direction-grid.md`
> **Cross-reference**: `docs/design/draft-assets.md` (text descriptions of all draft PNGs)

**Status legend**

- ✅ Already in `assets/`
- ⚑ Generic placeholder exists in `assets/` or `design/drafts/` — needs replacing with game-specific art
- ⏸️ Not to be created / used in this stage
- ❌ Not yet created

---

## Directory Tree

```
res://assets/
├── art/
│   ├── cats/                        ← character sprites per skin × animation state
│   ├── tiles/
│   │   ├── floor/                   ← floor tile states per world (3 worlds)
│   │   ├── walls/                   ← wall tile variants per world (w1_bedroom, w2_kitchen, w3_livingroom, post_jam_study)
│   │   └── furniture/               ← obstacle sprites per world (w1_bedroom, w2_kitchen, w3_livingroom, post_jam_study)
│   ├── ui/
│   │   ├── buttons/                 ← pill buttons, all variants
│   │   ├── icons/                   ← circular icon buttons + standalone icons
│   │   ├── headers/                 ← main title logos and text graphics
│   │   ├── stars/                   ← 3 size tiers, filled/empty
│   │   ├── hud/                     ← move counter pill background
│   │   ├── panels/                  ← modal/popup shapes (nine-patch)
│   │   ├── world_map/               ← level card state sprites
│   │   ├── skin_select/             ← skin card state sprites
│   │   └── badges/                  ← badge components (new best, equipped, progress)
│   │   └── settings/                ← volume sliders + checkboxes
│   ├── backgrounds/                 ← full-screen room backgrounds
│   └── grid/                        ← grid container frame (nine-patch)
├── audio/
│   ├── sfx/
│   └── music/
└── fonts/
```

---

## 1. Cat Sprites — `assets/art/cats/`

All shipped cat UI sprites are exported at **320×320px** for base assets and
**640×640px** for `@2x` assets. `cat_default_peek.png` is a decorative modal
accent exported at **440×350px**, with a **42px** transparent bottom alignment
gutter so the cat head can sit flush against modal/card top edges.
Style: kawaii, soft edges, dark clean outline, pink blush, warm colour fill.
Source draft: `design/draft/sprite-cat.png` (single idle pose, white cat — use as base for all states).

| File                         | Description                                                            | Style Guide                                                                             | Size (px) | Software  | Format | Status |
| ---------------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | --------- | --------- | ------ | ------ |
| `cat_default_idle.png`       | Default cat idle used in menus/UI.                                     | White fur, dark outline 2–3px, pink blush circles, large round eyes, relaxed tail curl. | 320×320   | Procreate | PNG    | ✅     |
| `cat_default_idle@2x.png`    | Retina idle variant for larger displays.                               | Same artwork as idle; higher-resolution export.                                         | 640×640   | Procreate | PNG    | ✅     |
| `cat_default_blink.png`      | Blink expression variant for subtle idle alternation.                  | Same base silhouette; eyes closed briefly.                                              | 320×320   | Procreate | PNG    | ✅     |
| `cat_default_blink@2x.png`   | Retina blink variant.                                                  | Same as blink, doubled resolution.                                                      | 640×640   | Procreate | PNG    | ✅     |
| `cat_default_curious.png`    | Curious expression used for 0–2 star level-complete outcomes.          | Tilted/curious expression, still readable at small scale.                               | 320×320   | Procreate | PNG    | ✅     |
| `cat_default_curious@2x.png` | Retina curious variant.                                                | Same as curious, doubled resolution.                                                    | 640×640   | Procreate | PNG    | ✅     |
| `cat_default_smile.png`      | Smile expression used for perfect level-complete outcomes.             | Warm satisfied smile; readable at small modal size.                                     | 320×320   | Procreate | PNG    | ✅     |
| `cat_default_smile@2x.png`   | Retina smile variant.                                                  | Same as smile, doubled resolution.                                                      | 640×640   | Procreate | PNG    | ✅     |
| `cat_default_excited.png`    | Excited expression fallback for non-perfect 3-star outcomes.           | Energetic happy expression for strong (but not perfect) outcomes.                       | 320×320   | Procreate | PNG    | ✅     |
| `cat_default_excited@2x.png` | Retina excited variant.                                                | Same as excited, doubled resolution.                                                    | 640×640   | Procreate | PNG    | ✅     |
| `cat_default_relax.png`      | Relaxed expression variant for non-critical decorative placements.     | Softer, calmer expression while keeping silhouette consistency.                         | 320×320   | Procreate | PNG    | ✅     |
| `cat_default_relax@2x.png`   | Retina relaxed variant.                                                | Same as relax, doubled resolution.                                                      | 640×640   | Procreate | PNG    | ✅     |
| `cat_default_peek.png`       | Decorative cat peek sprite for top-edge modal accents (pause/options). | Place with **42px** bottom overlap against modal top edge to align cat head to card.    | 440×350   | Procreate | PNG    | ✅     |

> **Additional skins**: Future skins (e.g. calico, black cat, sakura) reuse the same 7 frames with different colour fills. Add folder per skin: `cat_calico_idle.png`, etc.

### Part-Based Gameplay Cat — `assets/art/cats/parts/`

Gameplay now assembles the in-level cat from layered part sprites. Every part is exported on the same **320×320px** canvas (and **640×640px** for `@2x`) so parts align at shared origin without per-layer cropping offsets.

| File Pattern             | Description                                                                           | Size (px) | Format | Status             |
| ------------------------ | ------------------------------------------------------------------------------------- | --------- | ------ | ------------------ |
| `cat_<skin_id>_tail.png` | Bottom-most gameplay layer. Tail rotates around a shape-matched pivot for idle swing. | 320/640   | PNG    | ✅ (`cat_default`) |
| `cat_<skin_id>_body.png` | Base torso layer above tail.                                                          | 320/640   | PNG    | ✅ (`cat_default`) |
| `cat_<skin_id>_legs.png` | Leg/paw layer above body.                                                             | 320/640   | PNG    | ✅ (`cat_default`) |
| `cat_<skin_id>_head.png` | Head layer above legs. Rotates slightly for left/right slide direction feedback.      | 320/640   | PNG    | ✅ (`cat_default`) |
| `cat_face_idle.png`      | Top-most neutral face layer.                                                          | 320/640   | PNG    | ✅                 |
| `cat_face_blink.png`     | Blink face variant.                                                                   | 320/640   | PNG    | ✅                 |
| `cat_face_excited.png`   | Excited face variant.                                                                 | 320/640   | PNG    | ✅                 |
| `cat_face_relax.png`     | Relaxed face variant.                                                                 | 320/640   | PNG    | ✅                 |
| `cat_face_smile.png`     | Smile face variant.                                                                   | 320/640   | PNG    | ✅                 |

> **Gameplay assembly order (bottom → top)**: tail, body, legs, head, face.

> **Implementation note — Godot**: Assemble gameplay cat visuals using child `Sprite2D` nodes on one parent cat node. Animate parent slide squish/stretch on the movement node, and animate child offsets/rotation (tail swing + head tilt) on part pivots.

---

## 2. Floor Tiles — `assets/art/tiles/floor/`

Each tile is **64×64px**, painted raster. The tile must look like a real floor material.
One unvisited state + one visited/trail state per world.
Draft source: `design/draft/tileset-floor-ver1 1.png` (World 1 confirmed).

| File                     | Description                                                                                                                                                        | Style Guide                                                                    | Size (px) | Software  | Format | Status                                      |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ | --------- | --------- | ------ | ------------------------------------------- |
| `floor_w1_unvisited.png` | World 1 Bedroom — soft pale pink carpet, subtle fabric weave texture. Rounded-square silhouette with dark purple-mauve border.                                     | Carpet pink `#FFE8EE`, weave `#F0D0DA`, border `#5C4A6B`.                      | 64×64     | Procreate | PNG    | ❌                                          |
| `floor_w1_visited.png`   | World 1 Bedroom trail state — carpet with warm golden-amber glow overlay + centred paw print stamp.                                                                | Amber tint `#FFD6E0` overlay; paw stamp white, opacity 70%, 40×40px centred.   | 64×64     | Procreate | PNG    | ❌                                          |
| `floor_w2_unvisited.png` | World 2 Kitchen — white ceramic square tiles with thin grey grout lines. Slight gloss highlight on tile centre.                                                    | Tile `#F8F8F8`, grout `#D8D8D8`, highlight `#FFFFFF` at centre.                | 64×64     | Procreate | PNG    | ❌                                          |
| `floor_w2_visited.png`   | World 2 Kitchen trail — ceramic tile with mint-green glow overlay + paw stamp.                                                                                     | Mint tint `#DCF3EA` blend over base; paw stamp white.                          | 64×64     | Procreate | PNG    | ❌                                          |
| `floor_w3_unvisited.png` | World 3 Living Room — light honey-beige oak hardwood plank. 3 horizontal grain lines, subtle edge shadow. Rounded-square silhouette with dark purple-mauve border. | Warm plank `#F5E6C8`, grain lines `#E0CDA8`, border `#5C4A6B`.                 | 64×64     | Procreate | PNG    | ✅ draft (`tileset-floor-ver1`, left tile)  |
| `floor_w3_visited.png`   | World 3 Living Room trail state — same plank texture with warm golden-amber glow overlay + centred white paw print stamp.                                          | Amber tint `#F5C842` over base; paw stamp white, opacity 70%, 40×40px centred. | 64×64     | Procreate | PNG    | ✅ draft (`tileset-floor-ver1`, right tile) |

---

## 3. Wall Tiles — `assets/art/tiles/walls/`

Each wall tile is **64×64px**. Wall tiles fill blocking cells at the room border.
Each world has its own subfolder. Tiles must clearly differ from floor tiles in surface material.
Draft sources: `tileset-wall-ver1` through `ver4`.

### 3.1 World 1 — Bedroom `walls/w1_bedroom/`

Style: Pastel soft pink kawaii wallpaper with scattered star/heart motifs.
Palette: `#F8C8D8` (pink), `#F0E8F0` (light ground), `#E0A0C0` (deeper pink).

| File                      | Description                                             | Size (px) | Software  | Format | Status                                 |
| ------------------------- | ------------------------------------------------------- | --------- | --------- | ------ | -------------------------------------- |
| `wall_plain.png`          | Solid soft pink wallpaper, plain.                       | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver4`, tile 1) |
| `wall_stars.png`          | Pastel pink with scattered small star motifs.           | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver4`, tile 2) |
| `wall_hearts.png`         | Pastel pink with scattered small heart motifs.          | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver4`, tile 3) |
| `wall_corner_outer.png`   | Outer convex bedroom corner.                            | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver4`, tile 4) |
| `wall_corner_inner.png`   | Inner concave bedroom corner.                           | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver4`, tile 8) |
| `wall_fairy_lights.png`   | Pink wall with string of warm fairy light dots.         | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver4`, tile 5) |
| `wall_floating_shelf.png` | Wall with floating shelf, small plant, and photo frame. | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver4`, tile 6) |
| `wall_poster.png`         | Wall with framed cat art poster.                        | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver4`, tile 7) |

### 3.2 World 2 — Kitchen `walls/w2_kitchen/`

Style: White/mint subway tile, clean grout lines, functional prop details.
Palette: `#F0F0EC` (tile white), `#C8CABE` (grout), `#A8D8C0` (mint accent).

| File                    | Description                                                      | Size (px) | Software  | Format | Status                                      |
| ----------------------- | ---------------------------------------------------------------- | --------- | --------- | ------ | ------------------------------------------- |
| `wall_plain.png`        | White subway tile wall, horizontal tile rows with grout lines.   | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver3`, tile 1)      |
| `wall_mint_accent.png`  | Mint green accent tile row crossing the wall.                    | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver3`, tile 2)      |
| `wall_corner_outer.png` | Outer L-shape kitchen corner.                                    | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver3`, tile 4 or 8) |
| `wall_corner_inner.png` | Inner concave kitchen corner.                                    | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver3`, tile 3)      |
| `wall_knife_rack.png`   | Wall with magnetic knife rack and knives.                        | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver3`, tile 5)      |
| `wall_calendar.png`     | Wall with small kitchen calendar or chalkboard.                  | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver3`, tile 6)      |
| `wall_window.png`       | Kitchen window looking out — green plants on windowsill visible. | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver3`, tile 7)      |

### 3.3 World 3 — Living Room `walls/w3_livingroom/`

Style: Brown horizontal wood plank panelling, warm log-cabin feel.
Palette: `#8B6030` (dark wood), `#A07040` (mid), `#C89860` (light). Warm shadows.

| File                    | Description                                                          | Size (px) | Software  | Format | Status                                 |
| ----------------------- | -------------------------------------------------------------------- | --------- | --------- | ------ | -------------------------------------- |
| `wall_plain.png`        | Straight wall run — horizontal brown wood planks tiling seamlessly.  | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver1`, tile 1) |
| `wall_corner_outer.png` | Convex L-shape corner — planks meet at 90°, corner column detail.    | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver1`, tile 2) |
| `wall_corner_inner.png` | Concave room corner — inside corner where two walls meet.            | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver1`, tile 3) |
| `wall_clock.png`        | Wall with round analogue clock and hanging details. Decorative prop. | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver1`, tile 5) |
| `wall_painting.png`     | Wall with small framed picture/painting. Decorative prop.            | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver1`, tile 6) |
| `wall_shelf.png`        | Wall with small floating shelf and tiny items on it.                 | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver1`, tile 4) |

### 3.4 Post-Jam — Study / Library `walls/post_jam_study/`

> **Note**: Study/Library world is post-jam only. Wall tiles exist in draft but are not required for MVP.

Style: Lavender/lilac wallpaper with scattered cream paw-print pattern.
Palette: `#D0C0E8` (lavender), `#F8F0E8` (cream paw ground), `#4A3870` (dark purple accent).

| File                    | Description                                                              | Size (px) | Software  | Format | Status                                 |
| ----------------------- | ------------------------------------------------------------------------ | --------- | --------- | ------ | -------------------------------------- |
| `wall_plain.png`        | Cream background with sparse scattered paw print pattern, lavender tint. | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver2`, tile 1) |
| `wall_stripe.png`       | Vertical lavender stripe variant of the paw wallpaper.                   | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver2`, tile 2) |
| `wall_paw_dense.png`    | Denser paw-print field — more paws, tighter pattern.                     | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver2`, tile 3) |
| `wall_corner_outer.png` | L-shape outer corner for lavender wallpaper.                             | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver2`, tile 4) |
| `wall_corner_inner.png` | Inner concave corner, dark purple solid tile for accent.                 | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver2`, tile 8) |
| `wall_cat_picture.png`  | Wall with framed cat portrait picture.                                   | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver2`, tile 5) |
| `wall_light_switch.png` | Wall with light switch plate.                                            | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver2`, tile 6) |
| `wall_outlet.png`       | Wall with electrical outlet.                                             | 64×64     | Procreate | PNG    | ⏸️ draft (`tileset-wall-ver2`, tile 7) |

---

## 4. MVP Tile Obstacles — `assets/art/tiles/grids/`

> **UPDATE (2026-04-15)**: The idea of using furniture as level grid walls and floors is deferred to post-jam. MVP uses three simple tile PNGs.

| File              | Tile Size | Description                | Size (px) | Software  | Format | Status |
| ----------------- | --------- | -------------------------- | --------- | --------- | ------ | ------ |
| `grid_yellow.png` | 1×1       | Simple yellow colored tile | 64×64     | Procreate | PNG    | ✅     |
| `grid_purple.png` | 1×1       | Simple purple colored tile | 64×64     | Procreate | PNG    | ✅     |
| `grid_mint.png`   | 1×1       | Simple mint colored tile   | 64×64     | Procreate | PNG    | ✅     |

---

## 5. Post-Jam Furniture / Obstacles — `assets/art/tiles/furniture/` ⏸️

All furniture uses **64px per grid cell** as the base unit.

- 1×1 tile: 64×64px
- 1×2 horizontal: 128×64px
- 1×2 vertical: 64×128px
- 1×3 vertical: 64×192px
- 2×2: 128×128px

Style: top-down view, chibi/chunky proportions, soft drop shadow bottom-right (3–4px, 40% black).
No pure-black outlines — use dark warm colour matching furniture.

### 4.1 World 1 — Bedroom `furniture/w1_bedroom/`

Palette: warm rose/pink duvet, walnut brown wardrobe, peach soft furnishings.

| File                   | Tile Size | Description                                                                                  | Size (px) | Software  | Format | Status   |
| ---------------------- | --------- | -------------------------------------------------------------------------------------------- | --------- | --------- | ------ | -------- |
| `bed.png`              | 2×2       | Double bed from above — rose/pink duvet, heart-print pillow pair, walnut headboard top edge. | 128×128   | Procreate | PNG    | ⏸️ draft |
| `nightstand.png`       | 1×1       | Small square nightstand with lamp base on top.                                               | 64×64     | Procreate | PNG    | ⏸️ draft |
| `beanbag.png`          | 1×1       | Peach/orange teardrop bean bag from above.                                                   | 64×64     | Procreate | PNG    | ⏸️ draft |
| `wardrobe.png`         | 1×3       | 3-door walnut brown wardrobe from above — door panel lines and handles.                      | 64×192    | Procreate | PNG    | ⏸️ draft |
| `chest_of_drawers.png` | 1×2       | Rectangular drawers unit, drawer handle lines visible.                                       | 64×128    | Procreate | PNG    | ⏸️ draft |
| `floor_mirror.png`     | 1×2       | Tall oval mirror — thin frame, reflective surface (subtle highlight).                        | 64×128    | Procreate | PNG    | ⏸️ draft |
| `laundry_basket.png`   | 1×1       | Round wicker laundry basket from above — oval weave texture, open top.                       | 64×64     | Procreate | PNG    | ⏸️ draft |
| `cat_bed.png`          | 1×1       | Small round cat bed — padded rim circle, soft cushion centre.                                | 64×64     | Procreate | PNG    | ⏸️ draft |

### 4.2 World 2 — Kitchen `furniture/w2_kitchen/`

Palette: clean white, stainless silver accents, mint green bins, cream cabinetry.

| File                  | Tile Size | Description                                                              | Size (px) | Software  | Format | Status   |
| --------------------- | --------- | ------------------------------------------------------------------------ | --------- | --------- | ------ | -------- |
| `fridge.png`          | 1×1       | Tall fridge — prominent white rectangle, handle line on right side.      | 64×64     | Procreate | PNG    | ⏸️ draft |
| `stove.png`           | 1×2       | Cooktop with 4 clearly visible circular burner rings, cream body.        | 128×64    | Procreate | PNG    | ⏸️ draft |
| `microwave.png`       | 1×1       | Small rectangular microwave, door latch detail on right.                 | 64×64     | Procreate | PNG    | ⏸️ draft |
| `washer.png`          | 1×1       | Washer or dishwasher, square unit with round porthole window centred.    | 64×64     | Procreate | PNG    | ⏸️ draft |
| `sink.png`            | 1×1       | Kitchen sink unit — rectangular basin, circular drain visible.           | 64×64     | Procreate | PNG    | ⏸️ draft |
| `recycling_bin.png`   | 1×1       | Single mint-green round recycling bin from above, recycle symbol on top. | 64×64     | Procreate | PNG    | ⏸️ draft |
| `coffee_maker.png`    | 1×1       | Compact coffee maker from above — round carafe top.                      | 64×64     | Procreate | PNG    | ⏸️ draft |
| `kitchen_counter.png` | 1×3       | Long horizontal wall counter — white/cream, horizontal door panel.       | 64×192    | Procreate | PNG    | ⏸️ draft |
| `kitchen_island.png`  | 1×2       | Freestanding kitchen island — two-tile wide, top-down, cream top.        | 128×64    | Procreate | PNG    | ⏸️       |
| `cat_food_bowl.png`   | 1×1       | Round bowl with cat food, cute paw print on bowl exterior.               | 64×64     | Procreate | PNG    | ⏸️       |

### 4.3 World 3 — Living Room `furniture/w3_livingroom/`

Palette: lavender cushions, cream/oak wood tones, terracotta for plants.

| File                     | Tile Size | Description                                                                        | Size (px) | Software  | Format | Status   |
| ------------------------ | --------- | ---------------------------------------------------------------------------------- | --------- | --------- | ------ | -------- |
| `sofa.png`               | 1×2       | Lavender sofa with rounded back cushion and seat visible from above. Chunky, soft. | 128×64    | Procreate | PNG    | ⏸️ draft |
| `armchair.png`           | 1×1       | Smaller lavender armchair, same style as sofa.                                     | 64×64     | Procreate | PNG    | ⏸️ draft |
| `bookshelf.png`          | 1×3       | Tall bookshelf viewed from top — colourful pastel book spines in a row.            | 64×192    | Procreate | PNG    | ⏸️ draft |
| `plant_pot.png`          | 1×1       | Round terracotta pot with green leafy crown visible from top.                      | 64×64     | Procreate | PNG    | ⏸️ draft |
| `cardboard_box.png`      | 1×1       | Brown cardboard box top with tape cross and paw-print sticker.                     | 64×64     | Procreate | PNG    | ⏸️ draft |
| `side_table.png`         | 1×1       | Cream square side table, four small leg dots at corners.                           | 64×64     | Procreate | PNG    | ⏸️ draft |
| `coffee_table_round.png` | 1×1       | Circular coffee table top, minimal.                                                | 64×64     | Procreate | PNG    | ⏸️ draft |
| `tv_stand.png`           | 1×2       | TV screen (dark rectangle with slight glare) on wood media console.                | 128×64    | Procreate | PNG    | ⏸️ draft |
| `ottoman.png`            | 1×1       | Round tufted ottoman, top view, lavender or cream.                                 | 64×64     | Procreate | PNG    | ⏸️ draft |
| `floor_cushion.png`      | 1×1       | Round/square floor cushion, soft patterned fabric from top.                        | 64×64     | Procreate | PNG    | ⏸️       |
| `cactus.png`             | 1×1       | Chunky green cactus in round ceramic pot, top view.                                | 64×64     | Procreate | PNG    | ⏸️       |
| `cat_scratcher.png`      | 1×1       | Cat scratcher post — circular base from above, sisal rope column top.              | 64×64     | Procreate | PNG    | ⏸️       |

### 4.4 Post-Jam — Study / Library `furniture/post_jam_study/`

> **Note**: Study/Library world is post-jam only. The full obstacle set (bookshelf_large, armchair, side_lamp, stacked_books) is not required for MVP. Add after jam release.

---

## 6. Grid Container Frame — `assets/art/grid/`

The entire grid sits inside a single **nine-patch rounded-rect frame** (confirmed by `tileset-floor-ver2`).

| File             | Description                                                                                                                                                                     | Style Guide                                                                            | Size (px) | Nine-Patch Regions  | Software           | Format | Status                                       |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | --------- | ------------------- | ------------------ | ------ | -------------------------------------------- |
| `grid_frame.png` | Rounded-rect container panel for the gameplay grid. Purple-mauve border, cream-light interior, subtle corner accent details. Used as `NinePatchRect` behind the `TileMapLayer`. | Border `#8B6A9A` (4–6px), corner radius ~24px, inner fill fully transparent (alpha 0). | 128×128   | 24px from each edge | Figma or Procreate | PNG    | ⏸️ draft (extract from `tileset-floor-ver2`) |

---

## 7. UI — Pill Buttons `assets/art/ui/buttons/pill_bases/`

Wide pill buttons are exported as **background-only raster assets** for Godot `NinePatchRect` use.
Text is rendered in-engine using Fredoka. Icons may be rendered separately in-engine for icon+label buttons,
or baked depending on the specific asset workflow, but the **background/base asset** always includes the
bottom shadow inside the export bounds.

### Pill Button Export Spec

```text
Visible face height : 56px
Bottom shadow/base  : 4px
Exported asset size : 220×60px at 1x
2x export           : 440×120px
Corner shape        : Fully rounded pill
Shadow style        : Bottom-only, hard/chunky, no blur-heavy web shadow
Nine-patch use      : Horizontal stretch only
Pressed offset      : The pressed state graphic is physically shifted down by 2px. The owning button component scene or script should shift overlaid labels/icons down by 2px as part of the component implementation when the button is in the pressed state.
```

### Nine-Patch Margins

At **1x (220×60)**:

- Left fixed cap: 56px
- Right fixed cap: 56px
- Stretchable center strip: 108px total center region, with the original logic preserving the middle band for horizontal scaling
- Vertical scaling: not intended; keep height fixed

At **2x (440×120)**:

- Left fixed cap: 112px
- Right fixed cap: 112px

| File                         | Intent            | State                 | Size (px)     | Format | Status |
| ---------------------------- | ----------------- | --------------------- | ------------- | ------ | ------ |
| `pill_primary_normal.png`    | Primary (Gold)    | Normal (4px shadow)   | 220×56 (+@2x) | PNG    | ✅     |
| `pill_primary_hover.png`     | Primary (Gold)    | Hover                 | 220×56 (+@2x) | PNG    | ✅     |
| `pill_primary_pressed.png`   | Primary (Gold)    | Pressed (0px shadow)  | 220×56 (+@2x) | PNG    | ✅     |
| `pill_secondary_normal.png`  | Secondary (Mint)  | Normal (4px shadow)   | 220×56 (+@2x) | PNG    | ✅     |
| `pill_secondary_hover.png`   | Secondary (Mint)  | Hover                 | 220×56 (+@2x) | PNG    | ✅     |
| `pill_secondary_pressed.png` | Secondary (Mint)  | Pressed (0px shadow)  | 220×56 (+@2x) | PNG    | ✅     |
| `pill_tertiary_normal.png`   | Tertiary (Purple) | Normal (4px shadow)   | 220×56 (+@2x) | PNG    | ✅     |
| `pill_tertiary_hover.png`    | Tertiary (Purple) | Hover                 | 220×56 (+@2x) | PNG    | ✅     |
| `pill_tertiary_pressed.png`  | Tertiary (Purple) | Pressed (0px shadow)  | 220×56 (+@2x) | PNG    | ✅     |
| `pill_danger_normal.png`     | Danger (Plum)     | Normal (4px shadow)   | 220×56 (+@2x) | PNG    | ✅     |
| `pill_danger_hover.png`      | Danger (Plum)     | Hover                 | 220×56 (+@2x) | PNG    | ✅     |
| `pill_danger_pressed.png`    | Danger (Plum)     | Pressed (0px shadow)  | 220×56 (+@2x) | PNG    | ✅     |
| `pill_disabled.png`          | Disabled (Grey)   | Disabled (0px shadow) | 220×56 (+@2x) | PNG    | ✅     |

---

### 7. UI Buttons & Icons

To prevent asset misuse in Godot, UI icons are split into two distinct directories based on their target node (`TextureButton` vs `TextureRect`).

#### 7A. Circular UI Buttons (`res://assets/art/ui/buttons/circular/`)

Fully baked 48x48px PNGs (and 96x96px `@2x` Retina versions) containing the background, icon, 3px plum stroke, and shadow. Designed for `TextureButton` nodes. Naming convention: `btn_circle_[name]_[state].png`.

_Status: All 26 button types (104 state files + 104 Retina @2x files) have been fully designed, batch-exported, and are ✅ Complete._

| Base Filename Prefix            | Icon / Intent                                | Format      | Status |
| ------------------------------- | -------------------------------------------- | ----------- | ------ |
| `btn_circle_achievement`        | Trophy / Medal icon for achievements         | PNG (+ @2x) | ✅     |
| `btn_circle_ad`                 | Play button with 'Ad' label for rewarded ads | PNG (+ @2x) | ✅     |
| `btn_circle_arrow_down`         | Downward directional arrow                   | PNG (+ @2x) | ✅     |
| `btn_circle_arrow_left`         | Left directional arrow / Back                | PNG (+ @2x) | ✅     |
| `btn_circle_arrow_right`        | Right directional arrow / Forward            | PNG (+ @2x) | ✅     |
| `btn_circle_arrow_up`           | Upward directional arrow                     | PNG (+ @2x) | ✅     |
| `btn_circle_back`               | U-turn arrow / Return to previous            | PNG (+ @2x) | ✅     |
| `btn_circle_bg`                 | Scenery/landscape icon for background select | PNG (+ @2x) | ✅     |
| `btn_circle_calendar`           | Calendar icon for daily rewards              | PNG (+ @2x) | ✅     |
| `btn_circle_cat`                | Cat head icon for skin select                | PNG (+ @2x) | ✅     |
| `btn_circle_close`              | X cross for closing modals                   | PNG (+ @2x) | ✅     |
| `btn_circle_confirm`            | Checkmark for confirming actions             | PNG (+ @2x) | ✅     |
| `btn_circle_dark_mode`          | Moon/Sun icon for theme toggle               | PNG (+ @2x) | ✅     |
| `btn_circle_double_arrow_left`  | Fast rewind / Skip back                      | PNG (+ @2x) | ✅     |
| `btn_circle_double_arrow_right` | Fast forward / Skip ahead                    | PNG (+ @2x) | ✅     |
| `btn_circle_exclaimation_mark`  | Warning / Important notice                   | PNG (+ @2x) | ✅     |
| `btn_circle_exit`               | Door with arrow / Quit game                  | PNG (+ @2x) | ✅     |
| `btn_circle_fullscreen`         | Expand arrows for fullscreen mode            | PNG (+ @2x) | ✅     |
| `btn_circle_gift`               | Present box for rewards                      | PNG (+ @2x) | ✅     |
| `btn_circle_home`               | House icon to return to Main Menu            | PNG (+ @2x) | ✅     |
| `btn_circle_info`               | 'i' icon for credits / how to play           | PNG (+ @2x) | ✅     |
| `btn_circle_map`                | Folded map icon for World Select             | PNG (+ @2x) | ✅     |
| `btn_circle_pause`              | Two vertical bars to pause gameplay          | PNG (+ @2x) | ✅     |
| `btn_circle_paw`                | Paw print icon (generic/misc)                | PNG (+ @2x) | ✅     |
| `btn_circle_question_mark`      | Help / Hint icon                             | PNG (+ @2x) | ✅     |
| `btn_circle_replay`             | Full circle arrow for level restart          | PNG (+ @2x) | ✅     |
| `btn_circle_settings_ver1`      | Cogwheel gear (Variant 1)                    | PNG (+ @2x) | ✅     |
| `btn_circle_settings_ver2`      | Cogwheel gear (Variant 2)                    | PNG (+ @2x) | ✅     |
| `btn_circle_shop`               | Shopping cart / Store icon                   | PNG (+ @2x) | ✅     |
| `btn_circle_sound_off`          | Speaker with X (Muted)                       | PNG (+ @2x) | ✅     |
| `btn_circle_sound_on`           | Speaker with sound waves (Unmuted)           | PNG (+ @2x) | ✅     |
| `btn_circle_undo`               | Counter-clockwise arrow to undo move         | PNG (+ @2x) | ✅     |

> **Note on States**: Every prefix listed above includes four exact files in the repository: `_normal.png`, `_hover.png`, `_pressed.png`, and `_disabled.png` (plus their respective `@2x.png` variants).

#### 7B. Pill Button Interior Icons (`res://assets/art/ui/icons/pill_interiors/`)

Transparent vector icons centered inside a 36x36px frame (30x30px artwork with 3px padding).
Each icon also ships as a 72x72px `@2x` variant.
Designed for `TextureRect` nodes inside dynamically sizing pill buttons.
Naming convention: `icon_pill_[name].png` + `icon_pill_[name]@2x.png`.

| File                        | Icon                   | Usage                    | Size (px) | Software | Format | Status |
| --------------------------- | ---------------------- | ------------------------ | --------- | -------- | ------ | ------ |
| `icon_pill_retry.png`       | White retry arrow      | Inside Secondary Pill    | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_home.png`        | White home icon        | Inside Tertiary Pill     | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_tick.png`        | White checkmark        | Inside Primary Pill      | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_play.png`        | White play triangle    | Main Menu Play pill      | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_cat.png`         | White cat icon         | Main Menu Skins pill     | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_info.png`        | White info icon        | Main Menu Credits pill   | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_close.png`       | White cross sign       | Modal close / cancel CTA | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_arrow_left.png`  | White left arrow sign  | Back / previous CTA      | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_arrow_right.png` | White right arrow sign | Next / continue CTA      | 36x36     | Figma    | PNG    | ✅     |
| `icon_pill_settings.png`    | White settings sign    | Main Menu Settings pill  | 36x36     | Figma    | PNG    | ✅     |

---

## 9. UI — Stars `assets/art/ui/stars/`

Three size tiers. All stars: 5-point, rounded tips, warm gold fill.

| File                     | Description                                                 | Size (px) | Software | Format | Status |
| ------------------------ | ----------------------------------------------------------- | --------- | -------- | ------ | ------ |
| `star_large_filled.png`  | Large gold celebration star. Used on 3-star level complete. | 72×72     | Figma    | PNG    | ✅     |
| `star_large_empty.png`   | Large empty/outline star.                                   | 72×72     | Figma    | PNG    | ✅     |
| `star_medium_filled.png` | Medium gold star — HUD strip and world-map level card rows. | 32×32     | Figma    | PNG    | ✅     |
| `star_medium_empty.png`  | Medium empty star.                                          | 32×32     | Figma    | PNG    | ✅     |
| `star_small_filled.png`  | Small gold star — compact aggregate/star-pill indicators.   | 18×18     | Figma    | PNG    | ✅     |
| `star_small_empty.png`   | Small empty star.                                           | 18×18     | Figma    | PNG    | ✅     |

Implementation note: hollow variants (`star_*_hollow.png`) remain in the repo for compatibility,
but active level-card UI now uses empty stars for unearned slots.

---

## 9b. UI — Settings `assets/art/ui/settings/`

All settings assets are used inside the Pause Screen modal (§6.6).
Checkboxes are fixed-size. Slider track and fill are nine-patch (horizontal stretch only).

### Volume Slider

Slider track and fill share the same outer frame size (116×56px). The fill graphic occupies
only the inner 108×44px area, centred — leaving a 4px margin top/bottom and 4px left/right
so the rounded fill cap sits cleanly inside the track.

> **Implementation Note (The Knob):** Slider knobs do **not** require new assets. They reuse the existing 9-slice pill buttons (e.g., `pill_primary_normal.png`) from `assets/art/ui/buttons/pill_bases/`. This allows the knob to dynamically size to fit a label (e.g., "🔊 80%") while automatically inheriting the existing normal, hover, pressed (2px downward shift), and disabled states.

| File                        | Description                                                                                      | Style Guide                                                                             | Size (px) | Nine-Patch Regions                    | Software | Format | Status |
| --------------------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- | --------- | ------------------------------------- | -------- | ------ | ------ |
| `slider_track.png`          | Slider groove/track background. Rounded pill, neutral tint. Nine-patch — stretches horizontally. | Mint/neutral fill, rounded ends, dark plum `#5C4A6B` outline. Outer frame 116×56px.     | 116×56    | 28px left/right edges, 0px top/bottom | Figma    | PNG    | ✅     |
| `slider_fill.png`           | Filled progress bar layer. Sits inside track, shorter on both ends. Nine-patch horizontal.       | `btn-primary` tint fill, rounded ends. Content area 108×44px centred in 116×56px frame. | 116×56    | 28px left/right edges, 0px top/bottom | Figma    | PNG    | ✅     |
| `slider_track_disabled.png` | Disabled slider track, muted contrast variant of track.                                          | Desaturated neutral track for muted/non-interactive channels.                           | 116×56    | 28px left/right edges, 0px top/bottom | Figma    | PNG    | ✅     |
| `slider_fill_disabled.png`  | Disabled slider fill, muted contrast variant of fill.                                            | Desaturated fill shown when channel is muted/locked.                                    | 116×56    | 28px left/right edges, 0px top/bottom | Figma    | PNG    | ✅     |

### Checkboxes

| File                    | Description                                               | Style Guide                                                                              | Size (px) | Nine-Patch Regions | Software | Format | Status |
| ----------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------- | --------- | ------------------ | -------- | ------ | ------ |
| `checkbox_empty.png`    | Unchecked checkbox. Rounded square, empty interior.       | Cream/neutral fill, dark plum `#5C4A6B` outline, rounded corners matching global radius. | 80×84     | N/A — fixed asset  | Figma    | PNG    | ✅     |
| `checkbox_checked.png`  | Checked checkbox. Same shape with checkmark drawn inside. | Same border + fill as empty; checkmark in `btn-primary` or dark plum, bold stroke 3px.   | 80×84     | N/A — fixed asset  | Figma    | PNG    | ✅     |
| `checkbox_disabled.png` | Disabled checkbox state.                                  | Desaturated checkbox used when toggle is unavailable/locked.                             | 80×84     | N/A — fixed asset  | Figma    | PNG    | ✅     |

---

## 10. UI — HUD `assets/art/ui/hud/`

| File                  | Description                                 | Style Guide                         | Size (px) | Software | Format | Status |
| --------------------- | ------------------------------------------- | ----------------------------------- | --------- | -------- | ------ | ------ |
| `move-counter-bg.png` | Background pill for the move counter.       | Cat shaped                          | 120×93    | Figma    | PNG    | ✅     |
| `star_pill.png`       | Authored cream pill background for gameplay | HUD star strip, 108×44 visible face | 116×56    | Figma    | PNG    | ✅     |

#### Nine-Patch Margins for `star_pill.png`

At 1x 116×56:

- Left fixed cap: 26px
- Right fixed cap: 26px
- Top fixed region: 6px
- Bottom fixed region: 10px

---

## 11. UI — Panels / Popups `assets/art/ui/panels/`

Panels are **nine-patch** — exported with a transparent interior so content flows freely inside.

| File                       | Description                                          | Style Guide                                                                                                                                                                                                                   | Size (px) | Nine-Patch Regions (Godot) | Software | Format | Status                     |
| -------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------------------------- | -------- | ------ | -------------------------- |
| `panel_modal_normal.png`   | Universal modal base (PAUSED, LEVEL COMPLETE).       | Fill `card/normal-bg`, 10px stroke `card/normal-outline`, 10px bottom inner shadow `card/normal-bg-shadow`, 10px bottom-right drop shadow `card/normal-outline`. Corner radius 24px.                                          | 128×128   | L: 44, T: 44, R: 54, B: 54 | Figma    | PNG    | ✅ Consolidated to 9-patch |
| `panel_tooltip_bubble.png` | Small speech bubble with downward-pointing triangle. | 50% scale of normal style: Fill `card/normal-bg`, 5px stroke `card/normal-outline`, 5px bottom inner shadow `card/normal-bg-shadow`, 3px bottom-right drop shadow `card/normal-outline`. Corner radius 10px, tail radius 2px. | 59×73     | L: 15, T: 15, R: 18, B: 26 | Figma    | PNG    | ✅ Scaled tactile style    |

---

## 12. UI — World Map / Level Cards `assets/art/ui/world_map/`

Level cards are **nine-patch rounded squares** to allow for dynamic scaling.
Style: 10px outside stroke, 10px bottom inner shadow, 8px bottom-only drop shadow.

| File                      | Description                      | Style Guide                                                                                                                                                                           | Size (px) | Nine-Patch Regions (Godot) | Software | Format | Status                  |
| ------------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------------------------- | -------- | ------ | ----------------------- |
| `level_card_unlocked.png` | Unplayed/unlocked state.         | Fill `card/normal-bg`, 10px stroke `card/normal-outline`, 10px inner shadow `card/normal-bg-shadow`, 8px bottom drop shadow `card/normal-outline-shadow`. Corner radius 16px.         | 72×90     | L: 26, T: 26, R: 26, B: 44 | Figma    | PNG    | ✅ Converted to 9-patch |
| `level_card_3star.png`    | 3-star completed state.          | Fill `card/highlight-bg`, 10px stroke `card/highlight-outline`, 10px inner shadow `card/highlight-bg-shadow`, 8px bottom drop shadow `card/highlight-outline-shadow`.                 | 72×90     | L: 26, T: 26, R: 26, B: 44 | Figma    | PNG    | ✅ Converted to 9-patch |
| `level_card_locked.png`   | Locked state.                    | Fill `card/disabled-bg`, 10px stroke `card/disabled-outline`, 10px inner shadow `card/disabled-bg-shadow`, 8px bottom drop shadow `card/disabled-outline` (or disabled shadow token). | 72×90     | L: 26, T: 26, R: 26, B: 44 | Figma    | PNG    | ✅ Converted to 9-patch |
| `icon_lock.png`           | Lock icon shown on locked cards. | Dark plum outline, readable at small card sizes.                                                                                                                                      | 64×64     | N/A — fixed icon           | Figma    | PNG    | ✅                      |

---

## 13. UI — Skin Cards `assets/art/ui/skin_select/` ⏸️

| File                     | Description                    | Style Guide                                                                |
| ------------------------ | ------------------------------ | -------------------------------------------------------------------------- |
| `skin_card_unlocked.png` | Unlocked skin card background. | Fill `card/normal-bg` (`#FAF7E7`), corner radius 16px. Upper 70% cat zone. |
| `skin_card_equipped.png` | Equipped state.                | Fill `card/highlight-bg` (`#F3C145`), corner radius 16px.                  |
| `skin_card_locked.png`   | Locked state.                  | Fill `card/disabled-bg` (`#BAB3B9`), border `card/disabled-outline`.       |

---

## 14. UI — Badges `assets/art/ui/badges/`

| File                      | Description                                                                                      | Style Guide                                                                    | Size (px) | Software | Format | Status                                      |
| ------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ | --------- | -------- | ------ | ------------------------------------------- |
| `badge_new_best.png`      | "NEW BEST!" orange pill badge — appears on level complete when personal best is beaten.          | Fill yellow orange, white ALL CAPS text "NEW BEST!", pill shape, rounded ends. | 184×56    | Figma    | PNG    | ✅                                          |
| `badge_equipped.png`      | "EQUIPPED ✓" teal pill — shown at bottom of equipped skin card.                                  | Fill `#5ECBA8` teal, white text "EQUIPPED", rounded pill.                      | 160×44    | Figma    | PNG    | ✅ draft (`ui-skins`, State 2)              |
| `badge_star_progress.png` | World progress pill — star icon + "12/15" number + horizontal fill bar. Used on World Map cards. | Cream fill, star icon left, number centre, progress bar right.                 | 280×48    | Figma    | PNG    | ✅ draft (`ui-misc`, 560×96px = 280×48 @2×) |

---

## 15. UI — Headers `assets/art/ui/headers/`

| File                           | Description                                                              | Size (px) | Software | Format | Status |
| ------------------------------ | ------------------------------------------------------------------------ | --------- | -------- | ------ | ------ |
| `nekodash_title.png`           | Legacy single-layout title graphic/logo (deprecated, no longer in repo). | Unknown   | Figma    | PNG    | ⏸️     |
| `nekodash_title_landscape.png` | Wide-layout title art for desktop/tablet and wider displays.             | Unknown   | Figma    | PNG    | ✅     |
| `nekodash_title_portrait.png`  | Narrow-layout title art for phone-width or portrait/narrow displays.     | Unknown   | Figma    | PNG    | ✅     |
| `ribbon_purple.png`            | Primary decorative ribbon banner for level-complete title placement.     | 320×80    | Figma    | PNG    | ✅     |
| `ribbon_white.png`             | White variant ribbon for shell headers (e.g. world map title strip).     | 320×80    | Figma    | PNG    | ✅     |
| `ribbon_yellow.png`            | Yellow variant ribbon for highlight callouts.                            | 320×80    | Figma    | PNG    | ✅     |
| `ribbon_grey.png`              | Grey variant ribbon for subdued/disabled callouts.                       | 320×80    | Figma    | PNG    | ✅     |

Implementation note: Main menu swaps between `nekodash_title_portrait.png` and `nekodash_title_landscape.png` at runtime based on viewport width. `ShellTheme.TITLE_TEXTURE` and opening shell fallback now point to the landscape file.

---

## 16. Backgrounds — `assets/art/backgrounds/`

Full portrait backgrounds at **390×844px @1× / 780×1688px @2×** (Retina export).
Painted from slightly elevated isometric-ish perspective or decorative illustration style.
These appear behind gameplay grids or as level-select screen art.

| File                   | Description                                                                                                                                    | Style Guide                                                                       | Size (px) | Software  | Format | Status                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | --------- | --------- | ------ | ------------------------------------------- |
| `paw_tile_128.png`     | Paw-print tile texture for cream patterned shell backgrounds (small repeat).                                                                   | Warm paw motif, subtle contrast for non-distracting UI backdrop use.              | 128×128   | Figma     | PNG    | ✅                                          |
| `paw_tile_256.png`     | Paw-print tile texture used by `PawBackground` script for shell screens (preferred repeat size).                                               | Warm paw motif, subtle contrast for non-distracting UI backdrop use.              | 256×256   | Figma     | PNG    | ✅                                          |
| `bg_main_menu.png`     | Warm cream background for main menu — subtle paw print watermark pattern tiled over `#F5EDCC` base. No room-specific art needed; pattern only. | Paw watermark `#ECD9B0` at ~15% opacity, repeating ~80×80px tile.                 | 390×844   | Figma     | PNG    | ❌                                          |
| `bg_w1_bedroom.png`    | World 1 Bedroom — kawaii bedroom illustration. Used behind level select and as level decorative backdrop.                                      | Dusky rose carpet, fairy lights, pastel pink walls visible.                       | 390×844   | Procreate | PNG    | ⏸️ draft (`bg-bedroom.png` — unverified)    |
| `bg_w2_kitchen.png`    | World 2 Kitchen — clean white/mint kitchen room background.                                                                                    | White tiles, mint accent, warm light from window.                                 | 390×844   | Procreate | PNG    | ⏸️ draft (`bg-kitchen.png` — unverified)    |
| `bg_w3_livingroom.png` | World 3 Living Room — cosy room illustration. Used behind level select and as level decorative backdrop.                                       | Warm honey/cream palette; wood floor visible; furniture silhouettes around edges. | 390×844   | Procreate | PNG    | ⏸️ draft (`bg-livingroom.png` — unverified) |

---

## 17. Audio SFX — `assets/audio/sfx/`

All SFX: OGG Vorbis, mono, 44.1kHz, < 2s duration, normalised to –3dBFS peak.
Style: soft, muted, cosy — no harsh or abrasive tones. Think plush/toy sounds.

| File                 | Trigger                   | Description                                    | Duration   | Software          | Format | Status |
| -------------------- | ------------------------- | ---------------------------------------------- | ---------- | ----------------- | ------ | ------ |
| `cat_slide.ogg`      | Cat starts sliding        | Soft whoosh, quick, light pitch rise.          | ~0.3s      | sfxr / Audacity   | OGG    | ❌     |
| `cat_bump.ogg`       | Cat hits a wall           | Soft "boing" or padded thud — cute, not harsh. | ~0.2s      | sfxr / Audacity   | OGG    | ❌     |
| `tile_trail.ogg`     | Each tile becomes visited | Very quiet soft "pad" or warm chime tick.      | ~0.1s      | sfxr / Audacity   | OGG    | ❌     |
| `level_complete.ogg` | Level complete trigger    | Ascending jingle, warm and cheerful.           | ~1.0s      | GarageBand / sfxr | OGG    | ❌     |
| `star_earn.ogg`      | Each star fills in        | Single bright bell ping, 3 pitches staggered.  | ~0.3s each | sfxr / Audacity   | OGG    | ❌     |
| `undo.ogg`           | Undo move used            | Soft reverse whoosh or rewind click.           | ~0.2s      | sfxr / Audacity   | OGG    | ❌     |
| `restart.ogg`        | Level restart             | Soft descending reset sound.                   | ~0.3s      | sfxr / Audacity   | OGG    | ❌     |

---

## 18. Audio Music — `assets/audio/music/`

All BGM: OGG Vorbis, stereo, 44.1kHz, loopable (loop point metadata set in Godot).
Style: lo-fi cosy — piano, soft percussion, warm synth pads. Calm, non-intrusive.

| File                    | Used on          | Description                                                              | Duration     | Software               | Format | Status |
| ----------------------- | ---------------- | ------------------------------------------------------------------------ | ------------ | ---------------------- | ------ | ------ |
| `bgm_main_menu.ogg`     | Main menu screen | Gentle, inviting, introduces the game's warm tone. Slow tempo (~75 BPM). | 2–3 min loop | GarageBand / MuseScore | OGG    | ❌     |
| `bgm_w1_bedroom.ogg`    | World 1 gameplay | Dreamy, lullaby-adjacent, music box or gentle chime. Soft synth.         | 2 min loop   | GarageBand             | OGG    | ❌     |
| `bgm_w2_kitchen.ogg`    | World 2 gameplay | Slightly upbeat, light percussion, playful melody, marimba or whistle.   | 2 min loop   | GarageBand             | OGG    | ❌     |
| `bgm_w3_livingroom.ogg` | World 3 gameplay | Warm lo-fi acoustic, slow tempo, soft piano.                             | 2 min loop   | GarageBand             | OGG    | ❌     |

---

## 19. Fonts — `assets/fonts/`

| File                         | Role                                                                    | Source                | Format | Status |
| ---------------------------- | ----------------------------------------------------------------------- | --------------------- | ------ | ------ |
| `Fredoka-Variable.ttf`       | Base variable font source for shell typography.                         | Google Fonts: Fredoka | TTF    | ✅     |
| `Fredoka-Body-SemiBold.tres` | Body text font resource used by shell labels and controls.              | Project resource      | TRES   | ✅     |
| `Fredoka-Display-Bold.tres`  | Display font resource used for headings and CTA emphasis.               | Project resource      | TRES   | ✅     |
| `Nunito-Variable.ttf`        | Intended fallback/secondary variable font for additional UI typography. | Google Fonts: Nunito  | TTF    | ✅     |

> **Download**: Fredoka and Nunito are free on [Google Fonts](https://fonts.google.com).
> Godot resources for active shell typography are currently `Fredoka-Body-SemiBold.tres` and `Fredoka-Display-Bold.tres`.

---

## 20. UI Technical Resources

| File                                                | Description                                                                 | Status |
| --------------------------------------------------- | --------------------------------------------------------------------------- | ------ |
| `assets/themes/global_ui_theme.tres`                | Global theme resource with default shell font assignment.                   | ✅     |
| `assets/shaders/ui/canvas_ui_overlay_blur.gdshader` | CanvasItem shader for modal blur + dim backdrop behind overlays.            | ✅     |
| `scenes/ui/level_complete_overlay.tscn`             | Overlay wrapper scene for level complete flow above gameplay.               | ✅     |
| `src/ui/level_complete_overlay.gd`                  | Controller script for level-complete overlay navigation and focus behavior. | ✅     |
| `src/ui/paw_background.gd`                          | Repeating paw-pattern background renderer used across shell screens.        | ✅     |
