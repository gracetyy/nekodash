# NekoDash — Asset Manifest

> **Updated**: 2026-04-03
> **Source of truth**: `design/draft/`, `docs/design/design-system.md`, `docs/design/art-direction-grid.md`
> **Cross-reference**: `docs/design/draft-assets.md` (text descriptions of all draft PNGs)

**Status legend**

- ✅ Draft art exists in `design/draft/` — ready to slice/export into `assets/`
- ⚑ Generic placeholder exists in `assets/` — needs replacing with game-specific art
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
│   │   ├── stars/                   ← 3 size tiers, filled/empty
│   │   ├── hud/                     ← move counter pill background
│   │   ├── panels/                  ← modal/popup shapes (nine-patch)
│   │   ├── world_map/               ← level card state sprites
│   │   ├── skin_select/             ← skin card state sprites
│   │   └── badges/                  ← badge components (new best, equipped, progress)
│   ├── backgrounds/                 ← full-screen room backgrounds
│   └── grid/                        ← grid container frame (nine-patch)
├── audio/
│   ├── sfx/
│   └── music/
└── fonts/
```

---

## 1. Cat Sprites — `assets/art/cats/`

All cat art is **64×64px** per frame. Top-down slightly isometric view.
Style: kawaii, soft edges, dark clean outline, pink blush, warm colour fill.
Source draft: `design/draft/sprite-cat.png` (single idle pose, white cat — use as base for all states).

| File                          | Description                                                                                  | Style Guide                                                                             | Size (px) | Software  | Format | Status |
| ----------------------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | --------- | --------- | ------ | ------ |
| `cat_default_idle.png`        | Default white cat, sitting/idle pose. Used on main menu, inside modals, skin select preview. | White fur, dark outline 2–3px, pink blush circles, large round eyes, relaxed tail curl. | 64×64     | Procreate | PNG    | ✅     |
| `cat_default_slide_up.png`    | Sliding upward — ears flat back, body elongated slightly.                                    | Same colour; body stretched ~10% vertically, limbs tucked.                              | 64×64     | Procreate | PNG    | ❌     |
| `cat_default_slide_down.png`  | Sliding downward.                                                                            | Same as slide_up, mirrored vertically.                                                  | 64×64     | Procreate | PNG    | ❌     |
| `cat_default_slide_left.png`  | Sliding left — body lean left, eyes squinting with speed.                                    | Horizontal stretch ~10%.                                                                | 64×64     | Procreate | PNG    | ❌     |
| `cat_default_slide_right.png` | Sliding right.                                                                               | Mirror of slide_left.                                                                   | 64×64     | Procreate | PNG    | ❌     |
| `cat_default_bump.png`        | Hitting a wall — squished flat ("pancake"), star burst expression.                           | Body squashed to ~60% height, 130% width, sweat drop optional.                          | 64×64     | Procreate | PNG    | ❌     |
| `cat_default_happy.png`       | 3-star level complete — eyes closed, happy smile, small hearts floating.                     | Same base; eyes as curved lines (UwU), 2–3 small heart particles around head.           | 64×64     | Procreate | PNG    | ❌     |

> **Additional skins**: Future skins (e.g. calico, black cat, sakura) reuse the same 7 frames with different colour fills. Add folder per skin: `cat_calico_idle.png`, etc.

> **Implementation note — Skeleton2D**: For smooth idle bob and direction-lean slide states, use `Skeleton2D` with a 2–3 bone rig (body, head, tail). Swap to a dedicated `AnimatedSprite2D` layer for extreme expression frames (bump pancake, happy UwU) that are too distorted for bone offsets. The two approaches are not mutually exclusive.

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
| `wall_plain.png`          | Solid soft pink wallpaper, plain.                       | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver4`, tile 1) |
| `wall_stars.png`          | Pastel pink with scattered small star motifs.           | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver4`, tile 2) |
| `wall_hearts.png`         | Pastel pink with scattered small heart motifs.          | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver4`, tile 3) |
| `wall_corner_outer.png`   | Outer convex bedroom corner.                            | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver4`, tile 4) |
| `wall_corner_inner.png`   | Inner concave bedroom corner.                           | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver4`, tile 8) |
| `wall_fairy_lights.png`   | Pink wall with string of warm fairy light dots.         | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver4`, tile 5) |
| `wall_floating_shelf.png` | Wall with floating shelf, small plant, and photo frame. | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver4`, tile 6) |
| `wall_poster.png`         | Wall with framed cat art poster.                        | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver4`, tile 7) |

### 3.2 World 2 — Kitchen `walls/w2_kitchen/`

Style: White/mint subway tile, clean grout lines, functional prop details.
Palette: `#F0F0EC` (tile white), `#C8CABE` (grout), `#A8D8C0` (mint accent).

| File                    | Description                                                      | Size (px) | Software  | Format | Status                                      |
| ----------------------- | ---------------------------------------------------------------- | --------- | --------- | ------ | ------------------------------------------- |
| `wall_plain.png`        | White subway tile wall, horizontal tile rows with grout lines.   | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver3`, tile 1)      |
| `wall_mint_accent.png`  | Mint green accent tile row crossing the wall.                    | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver3`, tile 2)      |
| `wall_corner_outer.png` | Outer L-shape kitchen corner.                                    | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver3`, tile 4 or 8) |
| `wall_corner_inner.png` | Inner concave kitchen corner.                                    | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver3`, tile 3)      |
| `wall_knife_rack.png`   | Wall with magnetic knife rack and knives.                        | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver3`, tile 5)      |
| `wall_calendar.png`     | Wall with small kitchen calendar or chalkboard.                  | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver3`, tile 6)      |
| `wall_window.png`       | Kitchen window looking out — green plants on windowsill visible. | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver3`, tile 7)      |

### 3.3 World 3 — Living Room `walls/w3_livingroom/`

Style: Brown horizontal wood plank panelling, warm log-cabin feel.
Palette: `#8B6030` (dark wood), `#A07040` (mid), `#C89860` (light). Warm shadows.

| File                    | Description                                                          | Size (px) | Software  | Format | Status                                 |
| ----------------------- | -------------------------------------------------------------------- | --------- | --------- | ------ | -------------------------------------- |
| `wall_plain.png`        | Straight wall run — horizontal brown wood planks tiling seamlessly.  | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver1`, tile 1) |
| `wall_corner_outer.png` | Convex L-shape corner — planks meet at 90°, corner column detail.    | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver1`, tile 2) |
| `wall_corner_inner.png` | Concave room corner — inside corner where two walls meet.            | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver1`, tile 3) |
| `wall_clock.png`        | Wall with round analogue clock and hanging details. Decorative prop. | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver1`, tile 5) |
| `wall_painting.png`     | Wall with small framed picture/painting. Decorative prop.            | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver1`, tile 6) |
| `wall_shelf.png`        | Wall with small floating shelf and tiny items on it.                 | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver1`, tile 4) |

### 3.4 Post-Jam — Study / Library `walls/post_jam_study/`

> **Note**: Study/Library world is post-jam only. Wall tiles exist in draft but are not required for MVP.

Style: Lavender/lilac wallpaper with scattered cream paw-print pattern.
Palette: `#D0C0E8` (lavender), `#F8F0E8` (cream paw ground), `#4A3870` (dark purple accent).

| File                    | Description                                                              | Size (px) | Software  | Format | Status                                 |
| ----------------------- | ------------------------------------------------------------------------ | --------- | --------- | ------ | -------------------------------------- |
| `wall_plain.png`        | Cream background with sparse scattered paw print pattern, lavender tint. | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver2`, tile 1) |
| `wall_stripe.png`       | Vertical lavender stripe variant of the paw wallpaper.                   | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver2`, tile 2) |
| `wall_paw_dense.png`    | Denser paw-print field — more paws, tighter pattern.                     | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver2`, tile 3) |
| `wall_corner_outer.png` | L-shape outer corner for lavender wallpaper.                             | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver2`, tile 4) |
| `wall_corner_inner.png` | Inner concave corner, dark purple solid tile for accent.                 | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver2`, tile 8) |
| `wall_cat_picture.png`  | Wall with framed cat portrait picture.                                   | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver2`, tile 5) |
| `wall_light_switch.png` | Wall with light switch plate.                                            | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver2`, tile 6) |
| `wall_outlet.png`       | Wall with electrical outlet.                                             | 64×64     | Procreate | PNG    | ✅ draft (`tileset-wall-ver2`, tile 7) |

---

## 4. Furniture / Obstacles — `assets/art/tiles/furniture/`

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
| `bed.png`              | 2×2       | Double bed from above — rose/pink duvet, heart-print pillow pair, walnut headboard top edge. | 128×128   | Procreate | PNG    | ✅ draft |
| `nightstand.png`       | 1×1       | Small square nightstand with lamp base on top.                                               | 64×64     | Procreate | PNG    | ✅ draft |
| `beanbag.png`          | 1×1       | Peach/orange teardrop bean bag from above.                                                   | 64×64     | Procreate | PNG    | ✅ draft |
| `wardrobe.png`         | 1×3       | 3-door walnut brown wardrobe from above — door panel lines and handles.                      | 64×192    | Procreate | PNG    | ✅ draft |
| `chest_of_drawers.png` | 1×2       | Rectangular drawers unit, drawer handle lines visible.                                       | 64×128    | Procreate | PNG    | ✅ draft |
| `floor_mirror.png`     | 1×2       | Tall oval mirror — thin frame, reflective surface (subtle highlight).                        | 64×128    | Procreate | PNG    | ✅ draft |
| `laundry_basket.png`   | 1×1       | Round wicker laundry basket from above — oval weave texture, open top.                       | 64×64     | Procreate | PNG    | ✅ draft |
| `cat_bed.png`          | 1×1       | Small round cat bed — padded rim circle, soft cushion centre.                                | 64×64     | Procreate | PNG    | ✅ draft |

### 4.2 World 2 — Kitchen `furniture/w2_kitchen/`

Palette: clean white, stainless silver accents, mint green bins, cream cabinetry.

| File                  | Tile Size | Description                                                              | Size (px) | Software  | Format | Status   |
| --------------------- | --------- | ------------------------------------------------------------------------ | --------- | --------- | ------ | -------- |
| `fridge.png`          | 1×1       | Tall fridge — prominent white rectangle, handle line on right side.      | 64×64     | Procreate | PNG    | ✅ draft |
| `stove.png`           | 1×2       | Cooktop with 4 clearly visible circular burner rings, cream body.        | 128×64    | Procreate | PNG    | ✅ draft |
| `microwave.png`       | 1×1       | Small rectangular microwave, door latch detail on right.                 | 64×64     | Procreate | PNG    | ✅ draft |
| `washer.png`          | 1×1       | Washer or dishwasher, square unit with round porthole window centred.    | 64×64     | Procreate | PNG    | ✅ draft |
| `sink.png`            | 1×1       | Kitchen sink unit — rectangular basin, circular drain visible.           | 64×64     | Procreate | PNG    | ✅ draft |
| `recycling_bin.png`   | 1×1       | Single mint-green round recycling bin from above, recycle symbol on top. | 64×64     | Procreate | PNG    | ✅ draft |
| `coffee_maker.png`    | 1×1       | Compact coffee maker from above — round carafe top.                      | 64×64     | Procreate | PNG    | ✅ draft |
| `kitchen_counter.png` | 1×3       | Long horizontal wall counter — white/cream, horizontal door panel.       | 64×192    | Procreate | PNG    | ✅ draft |
| `kitchen_island.png`  | 1×2       | Freestanding kitchen island — two-tile wide, top-down, cream top.        | 128×64    | Procreate | PNG    | ❌       |
| `cat_food_bowl.png`   | 1×1       | Round bowl with cat food, cute paw print on bowl exterior.               | 64×64     | Procreate | PNG    | ❌       |

### 4.3 World 3 — Living Room `furniture/w3_livingroom/`

Palette: lavender cushions, cream/oak wood tones, terracotta for plants.

| File                     | Tile Size | Description                                                                        | Size (px) | Software  | Format | Status   |
| ------------------------ | --------- | ---------------------------------------------------------------------------------- | --------- | --------- | ------ | -------- |
| `sofa.png`               | 1×2       | Lavender sofa with rounded back cushion and seat visible from above. Chunky, soft. | 128×64    | Procreate | PNG    | ✅ draft |
| `armchair.png`           | 1×1       | Smaller lavender armchair, same style as sofa.                                     | 64×64     | Procreate | PNG    | ✅ draft |
| `bookshelf.png`          | 1×3       | Tall bookshelf viewed from top — colourful pastel book spines in a row.            | 64×192    | Procreate | PNG    | ✅ draft |
| `plant_pot.png`          | 1×1       | Round terracotta pot with green leafy crown visible from top.                      | 64×64     | Procreate | PNG    | ✅ draft |
| `cardboard_box.png`      | 1×1       | Brown cardboard box top with tape cross and paw-print sticker.                     | 64×64     | Procreate | PNG    | ✅ draft |
| `side_table.png`         | 1×1       | Cream square side table, four small leg dots at corners.                           | 64×64     | Procreate | PNG    | ✅ draft |
| `coffee_table_round.png` | 1×1       | Circular coffee table top, minimal.                                                | 64×64     | Procreate | PNG    | ✅ draft |
| `tv_stand.png`           | 1×2       | TV screen (dark rectangle with slight glare) on wood media console.                | 128×64    | Procreate | PNG    | ✅ draft |
| `ottoman.png`            | 1×1       | Round tufted ottoman, top view, lavender or cream.                                 | 64×64     | Procreate | PNG    | ✅ draft |
| `floor_cushion.png`      | 1×1       | Round/square floor cushion, soft patterned fabric from top.                        | 64×64     | Procreate | PNG    | ❌       |
| `cactus.png`             | 1×1       | Chunky green cactus in round ceramic pot, top view.                                | 64×64     | Procreate | PNG    | ❌       |
| `cat_scratcher.png`      | 1×1       | Cat scratcher post — circular base from above, sisal rope column top.              | 64×64     | Procreate | PNG    | ❌       |

### 4.4 Post-Jam — Study / Library `furniture/post_jam_study/`

> **Note**: Study/Library world is post-jam only. The full obstacle set (bookshelf_large, armchair, side_lamp, stacked_books) is not required for MVP. Add after jam release.

---

## 5. Grid Container Frame — `assets/art/grid/`

The entire grid sits inside a single **nine-patch rounded-rect frame** (confirmed by `tileset-floor-ver2`).

| File             | Description                                                                                                                                                                     | Style Guide                                                                            | Size (px) | Nine-Patch Regions  | Software           | Format | Status                                       |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | --------- | ------------------- | ------------------ | ------ | -------------------------------------------- |
| `grid_frame.png` | Rounded-rect container panel for the gameplay grid. Purple-mauve border, cream-light interior, subtle corner accent details. Used as `NinePatchRect` behind the `TileMapLayer`. | Border `#8B6A9A` (4–6px), corner radius ~24px, inner fill fully transparent (alpha 0). | 128×128   | 24px from each edge | Figma or Procreate | PNG    | ✅ draft (extract from `tileset-floor-ver2`) |

---

## 6. UI — Buttons `assets/art/ui/buttons/`

All pill buttons are **nine-patch** so they scale horizontally.
Height: **56px** fixed. Design at 220×56px; nine-patch horizontal stretch region is the 1–2px centre strip.
Style: Fully rounded pill, solid colour fill, 4px bottom-only drop shadow (darken –20%).
Colours per `docs/design/design-system.md §1`.

| File                          | Label / Intent                             | Fill Colour      | Size (px) | Software | Format | Status                               |
| ----------------------------- | ------------------------------------------ | ---------------- | --------- | -------- | ------ | ------------------------------------ |
| `btn_play.png`                | PLAY — primary action                      | `#EFB034` gold   | 220×56    | Figma    | PNG    | ✅ draft (`ui-button-2`)             |
| `btn_play_pressed.png`        | PLAY pressed state — slightly darker fill  | `#D49A20`        | 220×56    | Figma    | PNG    | ✅ draft (variant in `ui-button-2`)  |
| `btn_next_level.png`          | NEXT LEVEL →                               | `#EFB034` gold   | 220×56    | Figma    | PNG    | ✅ draft (`ui-button-2`)             |
| `btn_next_level_disabled.png` | NEXT LEVEL (disabled/grey)                 | `#C8C0B4`        | 220×56    | Figma    | PNG    | ✅ draft (`ui-button-2`, grey state) |
| `btn_skins.png`               | SKINS                                      | `#C4A5E8` purple | 220×56    | Figma    | PNG    | ✅ draft (`ui-button-2`)             |
| `btn_retry.png`               | RETRY (with restart icon)                  | `#C4A5E8` purple | 220×56    | Figma    | PNG    | ✅ draft (`ui-button-1`)             |
| `btn_world_map.png`           | WORLD MAP (with home icon)                 | `#C4A5E8` purple | 220×56    | Figma    | PNG    | ✅ draft (`ui-button-1`)             |
| `btn_equip.png`               | EQUIP (with checkmark icon)                | `#EFB034` gold   | 220×56    | Figma    | PNG    | ✅ draft (`ui-button-1`)             |
| `btn_equipped.png`            | EQUIPPED ✓ (teal, confirms equipped state) | `#5ECBA8` teal   | 220×56    | Figma    | PNG    | ✅ draft (`ui-button-1`)             |

---

## 7. UI — Icon Buttons `assets/art/ui/icons/`

Circular icon buttons: **48×48px** circle, cream/white fill, subtle border ring, 2px shadow.
Active: purple border ring. Disabled: grey border, desaturated icon.
Standalone icons (padlock, paw coin) have transparent backgrounds.

| File                     | Icon                                   | Active / Standalone             | Size (px) | Software | Format | Status                                         |
| ------------------------ | -------------------------------------- | ------------------------------- | --------- | -------- | ------ | ---------------------------------------------- |
| `icon_undo_active.png`   | Counter-clockwise arrow                | Purple ring border              | 48×48     | Figma    | PNG    | ⚑ generic `Undo.png` exists — needs restyling  |
| `icon_undo_disabled.png` | Counter-clockwise arrow                | Grey border, desaturated        | 48×48     | Figma    | PNG    | ❌                                             |
| `icon_restart.png`       | Full-circle clockwise arrow            | Purple ring border              | 48×48     | Figma    | PNG    | ⚑ generic `Rotate_Right.png` — needs restyling |
| `icon_back.png`          | Left-facing < chevron                  | Default cream border            | 48×48     | Figma    | PNG    | ⚑ generic `Left_Arrow1.png` — needs restyling  |
| `icon_settings.png`      | Cogwheel gear                          | Default cream border            | 48×48     | Figma    | PNG    | ⚑ generic `Settings1.png` — needs restyling    |
| `icon_close.png`         | × cross                                | Default cream border            | 48×48     | Figma    | PNG    | ❌                                             |
| `icon_lock.png`          | Padlock — standalone, transparent bg   | Brown/warm fill, chunky rounded | 44×44     | Figma    | PNG    | ❌ game-specific needed                        |
| `icon_paw_coin.png`      | Gold circular coin with paw pad design | Gold fill, transparent bg       | 44×44     | Figma    | PNG    | ❌ (`ui-misc` has draft)                       |

---

## 8. UI — Stars `assets/art/ui/stars/`

Three size tiers. All stars: 5-point, rounded tips, warm gold fill.
Colours: filled = `#F5C030`, empty = `#D4C490`, outline stroke = `#C8A820`.

| File                     | Description                                                 | Size (px) | Software | Format | Status                                       |
| ------------------------ | ----------------------------------------------------------- | --------- | -------- | ------ | -------------------------------------------- |
| `star_large_filled.png`  | Large gold celebration star. Used on 3-star level complete. | 72×72     | Figma    | PNG    | ⚑ `star_gold.png` exists — may be wrong size |
| `star_large_empty.png`   | Large empty/outline star.                                   | 72×72     | Figma    | PNG    | ⚑ `star_grey.png` — may be wrong size        |
| `star_medium_filled.png` | Medium gold star — HUD strip, level card.                   | 32×32     | Figma    | PNG    | ❌                                           |
| `star_medium_empty.png`  | Medium empty star.                                          | 32×32     | Figma    | PNG    | ❌                                           |
| `star_small_filled.png`  | Small gold star — level tile card below number.             | 18×18     | Figma    | PNG    | ❌                                           |
| `star_small_empty.png`   | Small empty star.                                           | 18×18     | Figma    | PNG    | ❌                                           |

---

## 9. UI — HUD `assets/art/ui/hud/`

| File                    | Description                                                                                                                     | Style Guide                                                                                    | Size (px) | Software | Format | Status                                                           |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | --------- | -------- | ------ | ---------------------------------------------------------------- |
| `move_counter_pill.png` | Background pill for the move counter. Dark navy fill (`#2A2436`), rounded-rect. Used as `NinePatchRect` — stretch horizontally. | Dark navy, border radius = height/2, no border stroke needed. Nine-patch: 24px from each edge. | 120×52    | Figma    | PNG    | ⚑ `move-counter-bg.png` exists — verify colour matches `#2A2436` |

---

## 10. UI — Panels / Popups `assets/art/ui/panels/`

Panels are **nine-patch** — exported with transparent interior so content flows freely inside.

| File                       | Description                                                                                              | Style Guide                                                                                      | Size (px) | Nine-Patch Regions                        | Software | Format | Status                               |
| -------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | --------- | ----------------------------------------- | -------- | ------ | ------------------------------------ |
| `panel_modal_large.png`    | Primary modal panel (PAUSED, LEVEL COMPLETE, etc.). Cream fill, dark purple border, soft drop shadow.    | Fill `#FAF3E0`, border `#6B3C80` 2–3px, corner radius 24px, shadow `0 8px 32px rgba(0,0,0,0.2)`. | 320×420   | 32px each edge                            | Figma    | PNG    | ✅ draft (`ui-popup`, large panel)   |
| `panel_modal_medium.png`   | Shorter modal (e.g. 1–2 star level complete, simpler messages).                                          | Same as large.                                                                                   | 320×280   | 32px each edge                            | Figma    | PNG    | ✅ draft (`ui-popup`, medium panel)  |
| `panel_tooltip_bubble.png` | Small speech bubble with downward-pointing triangle pointer. Used for tutorial overlays attached to cat. | Same cream/purple fill. Triangle pointer centred at bottom.                                      | 200×80    | 20px top/sides, 32px bottom (for pointer) | Figma    | PNG    | ✅ draft (`ui-popup`, speech bubble) |

---

## 11. UI — World Map / Level Cards `assets/art/ui/world_map/`

Level cards are **fixed-size rounded squares**, not nine-patch — content is drawn by code over the card shape.

| File                      | Description                                                               | Style Guide                                                    | Size (px) | Software | Format | Status                                                |
| ------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------- | --------- | -------- | ------ | ----------------------------------------------------- |
| `level_card_unlocked.png` | Card background — unplayed/unlocked state. Cream fill, no special border. | Fill `#FAF3E0`, corner radius 16px, subtle dropshadow.         | 90×90     | Figma    | PNG    | ✅ draft (`ui-level-cards`, State 1)                  |
| `level_card_3star.png`    | Card background — 3-star completed. Gold/amber border treatment.          | Same fill, gold border `#E8A820` 3px.                          | 90×90     | Figma    | PNG    | ✅ draft (`ui-level-cards`, State 2)                  |
| `level_card_partial.png`  | Card background — partially completed (1–2 stars). Same as unlocked.      | Identical to `level_card_unlocked.png` — may reuse same asset. | 90×90     | Figma    | PNG    | ✅ draft (`ui-level-cards`, State 3, same as State 1) |
| `level_card_locked.png`   | Card background — locked. Full grey desaturated.                          | Fill `#C8C0B4`, corner radius 16px.                            | 90×90     | Figma    | PNG    | ✅ draft (`ui-level-cards`, State 4)                  |

---

## 12. UI — Skin Cards `assets/art/ui/skin_select/`

Portrait-format cards (taller than wide). See `docs/design/design-system.md §3.8`.

| File                     | Description                                                             | Style Guide                                                                                        | Size (px) | Software | Format | Status                         |
| ------------------------ | ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | --------- | -------- | ------ | ------------------------------ |
| `skin_card_unlocked.png` | Unlocked skin card background. Cream, no border. Cat area + label area. | Fill `#FAF3E0`, corner radius 16px. Upper 70% = cat zone; lower 30% = label zone (subtle divider). | 96×128    | Figma    | PNG    | ✅ draft (`ui-skins`, State 1) |
| `skin_card_equipped.png` | Equipped state — gold border card.                                      | Same fill, gold border `#E8A820` 3px.                                                              | 96×128    | Figma    | PNG    | ✅ draft (`ui-skins`, State 2) |
| `skin_card_locked.png`   | Locked state — full grey.                                               | Fill `#C8C0B4`, corner radius 16px.                                                                | 96×128    | Figma    | PNG    | ✅ draft (`ui-skins`, State 3) |

---

## 13. UI — Badges `assets/art/ui/badges/`

| File                      | Description                                                                                      | Style Guide                                                                       | Size (px) | Software | Format | Status                                      |
| ------------------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- | --------- | -------- | ------ | ------------------------------------------- |
| `badge_new_best.png`      | "NEW BEST!" orange pill badge — appears on 3-star level complete when personal best is beaten.   | Fill `#F5A623` orange, white ALL CAPS text "NEW BEST!", pill shape, rounded ends. | 320×90    | Figma    | PNG    | ✅ draft (`ui-misc`, `ui-stars` Row 2)      |
| `badge_equipped.png`      | "EQUIPPED ✓" teal pill — shown at bottom of equipped skin card.                                  | Fill `#5ECBA8` teal, white text "EQUIPPED", rounded pill.                         | 160×44    | Figma    | PNG    | ✅ draft (`ui-skins`, State 2)              |
| `badge_star_progress.png` | World progress pill — star icon + "12/15" number + horizontal fill bar. Used on World Map cards. | Cream fill, star icon left, number centre, progress bar right.                    | 280×48    | Figma    | PNG    | ✅ draft (`ui-misc`, 560×96px = 280×48 @2×) |

---

## 14. Backgrounds — `assets/art/backgrounds/`

Full portrait backgrounds at **390×844px @1× / 780×1688px @2×** (Retina export).
Painted from slightly elevated isometric-ish perspective or decorative illustration style.
These appear behind gameplay grids or as level-select screen art.

| File                   | Description                                                                                                                                    | Style Guide                                                                       | Size (px) | Software  | Format | Status                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | --------- | --------- | ------ | ------------------------------------------- |
| `bg_main_menu.png`     | Warm cream background for main menu — subtle paw print watermark pattern tiled over `#F5EDCC` base. No room-specific art needed; pattern only. | Paw watermark `#ECD9B0` at ~15% opacity, repeating ~80×80px tile.                 | 390×844   | Figma     | PNG    | ❌                                          |
| `bg_w1_bedroom.png`    | World 1 Bedroom — kawaii bedroom illustration. Used behind level select and as level decorative backdrop.                                      | Dusky rose carpet, fairy lights, pastel pink walls visible.                       | 390×844   | Procreate | PNG    | ✅ draft (`bg-bedroom.png` — unverified)    |
| `bg_w2_kitchen.png`    | World 2 Kitchen — clean white/mint kitchen room background.                                                                                    | White tiles, mint accent, warm light from window.                                 | 390×844   | Procreate | PNG    | ✅ draft (`bg-kitchen.png` — unverified)    |
| `bg_w3_livingroom.png` | World 3 Living Room — cosy room illustration. Used behind level select and as level decorative backdrop.                                       | Warm honey/cream palette; wood floor visible; furniture silhouettes around edges. | 390×844   | Procreate | PNG    | ✅ draft (`bg-livingroom.png` — unverified) |

---

## 15. Audio SFX — `assets/audio/sfx/`

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

## 16. Audio Music — `assets/audio/music/`

All BGM: OGG Vorbis, stereo, 44.1kHz, loopable (loop point metadata set in Godot).
Style: lo-fi cosy — piano, soft percussion, warm synth pads. Calm, non-intrusive.

| File                    | Used on          | Description                                                              | Duration     | Software               | Format | Status |
| ----------------------- | ---------------- | ------------------------------------------------------------------------ | ------------ | ---------------------- | ------ | ------ |
| `bgm_main_menu.ogg`     | Main menu screen | Gentle, inviting, introduces the game's warm tone. Slow tempo (~75 BPM). | 2–3 min loop | GarageBand / MuseScore | OGG    | ❌     |
| `bgm_w1_bedroom.ogg`    | World 1 gameplay | Dreamy, lullaby-adjacent, music box or gentle chime. Soft synth.         | 2 min loop   | GarageBand             | OGG    | ❌     |
| `bgm_w2_kitchen.ogg`    | World 2 gameplay | Slightly upbeat, light percussion, playful melody, marimba or whistle.   | 2 min loop   | GarageBand             | OGG    | ❌     |
| `bgm_w3_livingroom.ogg` | World 3 gameplay | Warm lo-fi acoustic, slow tempo, soft piano.                             | 2 min loop   | GarageBand             | OGG    | ❌     |

---

## 17. Fonts — `assets/fonts/`

| File                   | Role                                                                      | Source                | Format | Status |
| ---------------------- | ------------------------------------------------------------------------- | --------------------- | ------ | ------ |
| `Fredoka-Regular.ttf`  | Body copy, sub-labels, HUD numbers — rounded friendly feel                | Google Fonts: Fredoka | TTF    | ❌     |
| `Fredoka-SemiBold.ttf` | Button labels, badges, modal headings (fallback if ExtraBold unavailable) | Google Fonts: Fredoka | TTF    | ❌     |
| `Nunito-ExtraBold.ttf` | Screen titles, logo lettering — chunky weight                             | Google Fonts: Nunito  | TTF    | ❌     |
| `Nunito-Black.ttf`     | Modal headings ("LEVEL COMPLETE!"), emphasis                              | Google Fonts: Nunito  | TTF    | ❌     |

> **Download**: Both fonts are free on [Google Fonts](https://fonts.google.com).
> Import into Godot as `DynamicFont` resources, set antialiasing ON, hinting = auto.

---

## Summary

| Category     | Total Files | ✅ Draft Exists | ⚑ Placeholder | ❌ Missing                                  |
| ------------ | ----------- | --------------- | ------------- | ------------------------------------------- |
| Cat sprites  | 7           | 1 (idle only)   | 0             | 6                                           |
| Floor tiles  | 6           | 2 (World 3)     | 0             | 4 (Worlds 1 and 2)                          |
| Wall tiles   | 27          | 23              | 0             | 4 (Study inner corner, post-jam not MVP)    |
| Furniture    | 31          | 23              | 0             | 8 (kitchen island, cat bowl, LR new, Study) |
| Grid frame   | 1           | 1               | 0             | 0                                           |
| Buttons      | 9           | 9               | 0             | 0                                           |
| Icon buttons | 8           | 0               | 5 (generic)   | 3                                           |
| Stars        | 6           | 0               | 2 (size TBC)  | 4                                           |
| HUD          | 1           | 0               | 1             | 0                                           |
| Panels       | 3           | 3               | 0             | 0                                           |
| Level cards  | 4           | 4               | 0             | 0                                           |
| Skin cards   | 3           | 3               | 0             | 0                                           |
| Badges       | 3           | 3               | 0             | 0                                           |
| Backgrounds  | 5           | 3 (unverified)  | 0             | 2                                           |
| SFX          | 7           | 0               | 0             | 7                                           |
| Music        | 5           | 0               | 0             | 5                                           |
| Fonts        | 4           | 0               | 0             | 4                                           |
| **TOTAL**    | **132**     | **78**          | **8**         | **47**                                      |
