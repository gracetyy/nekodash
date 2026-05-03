# NekoDash — Asset Manifest

> **Updated**: 2026-05-03
> **Source of truth**: Actual file system (`assets/`), `docs/design/design-system.md`, `docs/design/art-direction-grid.md`

**Status legend**

- ✅ Already in `assets/`
- ⚑ Generic placeholder exists in — needs replacing with game-specific art
- ⏸️ Not to be created / used in this stage
- ❌ Not yet created

---

## Directory Tree

```
res://assets/
├── art/
│   ├── app_icon/                    ← project icons in various sizes
│   ├── backgrounds/                 ← full-screen and tiling backgrounds
│   ├── cats/                        ← character sprites per skin × animation state
│   ├── tiles/
│   │   └── home/                    ← gameplay tiles per room
│   └── ui/
│       ├── badges/                  ← state badges (new best, etc)
│       ├── buttons/                 ← interactive button states
│       ├── headers/                 ← title logos and ribbons
│       ├── hud/                     ← gameplay interface elements
│       ├── icons/                   ← button icons and symbols
│       ├── panels/                  ← modal and bubble shapes
│       ├── settings/                ← sliders and checkboxes
│       ├── stars/                   ← rating stars in 3 sizes
│       └── world_map/               ← level and world card assets
├── audio/
│   ├── bgm/                         ← background music tracks
│   └── sfx/
│       ├── gameplay/                ← gameplay event sounds
│       └── ui/                      ← interface interaction sounds
└── fonts/                           ← Fredoka and Nunito font files
```

---

## 1. Cat Sprites — `assets/art/cats/`

All UI sprites are exported at **320×320px** (and **640×640px** for `@2x`).
`cat_default_peek.png` is used for modal accents.

| File                             | Description                                   | Size (px) | Status |
| -------------------------------- | --------------------------------------------- | --------- | ------ |
| `cat_default_idle.png`           | Default cat idle.                             | 320×320   | ✅     |
| `cat_default_idle_tail_up.png`   | Idle variant with tail raised.                | 320×320   | ✅     |
| `cat_default_idle_tail_down.png` | Idle variant with tail lowered.               | 320×320   | ✅     |
| `cat_default_blink.png`          | Blink expression variant.                     | 320×320   | ✅     |
| `cat_default_curious.png`        | Curious expression (0–2 star level complete). | 320×320   | ✅     |
| `cat_default_smile.png`          | Smile expression (perfect outcome).           | 320×320   | ✅     |
| `cat_default_excited.png`        | Excited expression (3-star outcome).          | 320×320   | ✅     |
| `cat_default_relax.png`          | Relaxed expression variant.                   | 320×320   | ✅     |
| `cat_default_peek.png`           | Decorative peek sprite for modal tops.        | 440×350   | ✅     |
| `cat_tabby_idle.png`             | Tabby skin idle sprite.                       | 320×320   | ✅     |

### Part-Based Gameplay Cat — `assets/art/cats/parts/`

> **Assembly order for gameplay rig**: tail (bottom), body, legs, head, face (top).

| File Pattern             | Description     | Size (px) | Status              |
| ------------------------ | --------------- | --------- | ------------------- |
| `cat_<skin_id>_tail.png` | Tail part.      | 320/640   | ✅ (default, tabby) |
| `cat_<skin_id>_body.png` | Torso part.     | 320/640   | ✅ (default, tabby) |
| `cat_<skin_id>_legs.png` | Leg/paw part.   | 320/640   | ✅ (default, tabby) |
| `cat_<skin_id>_head.png` | Head part.      | 320/640   | ✅ (default, tabby) |
| `cat_face_idle.png`      | Neutral face.   | 320/640   | ✅                  |
| `cat_face_blink.png`     | Blink face.     | 320/640   | ✅                  |
| `cat_face_excited.png`   | Excited face.   | 320/640   | ✅                  |
| `cat_face_relax.png`     | Relaxed face.   | 320/640   | ✅                  |
| `cat_face_smile.png`     | Smile face.     | 320/640   | ✅                  |
| `cat_face_surprised.png` | Surprised face. | 320/640   | ✅                  |
| `cat_face_painful.png`   | Painful face.   | 320/640   | ✅                  |

---

## 2. Floor Tiles — `assets/art/tiles/home/`

Each room folder contains `normal.png` (unvisited), `visited.png` (visited, plain), and `visited_paw.png` (visited with paw print).

| Room            | File Path                     | Size (px) | Status |
| --------------- | ----------------------------- | --------- | ------ |
| **Bedroom**     | `bedroom/1x1_floor_tile/`     | 64×64     | ✅     |
| **Kitchen**     | `kitchen/1x1_floor_tile/`     | 64×64     | ✅     |
| **Living Room** | `living_room/1x1_floor_tile/` | 64×64     | ✅     |
| **HKU**         | `hku/1x1_floor_tile/`         | 64×64     | ✅     |

---

## 3. Wall Tiles — `assets/art/tiles/`

Each room uses a standard 9-slice-like set of wall tiles.

| Room            | Base Directory                    | Status |
| --------------- | --------------------------------- | ------ |
| **Bedroom**     | `home/bedroom/1x1_wall_tile/`     | ✅     |
| **Kitchen**     | `home/kitchen/1x1_wall_tile/`     | ✅     |
| **Living Room** | `home/living_room/1x1_wall_tile/` | ✅     |
| **HKU**         | `hku/1x1_wall_tile/`              | ✅     |

### 3.1 Standard Wall File Set

Applicable to all rooms listed above:

| File                      | Description                    | Size (px) | Status |
| ------------------------- | ------------------------------ | --------- | ------ |
| `top.png`                 | Top edge wall tile.            | 64×64     | ✅     |
| `bottom.png`              | Bottom edge wall tile.         | 64×64     | ✅     |
| `left.png`                | Left edge wall tile.           | 64×64     | ✅     |
| `right.png`               | Right edge wall tile.          | 64×64     | ✅     |
| `top_left_corner.png`     | Top-left corner wall tile.     | 64×64     | ✅     |
| `top_right_corner.png`    | Top-right corner wall tile.    | 64×64     | ✅     |
| `bottom_left_corner.png`  | Bottom-left corner wall tile.  | 64×64     | ✅     |
| `bottom_right_corner.png` | Bottom-right corner wall tile. | 64×64     | ✅     |

### 3.2 Special Tiles — `assets/art/tiles/**/1x1_special_tile/`

| Asset Path                                   | Description                      | Size (px) | Status |
| -------------------------------------------- | -------------------------------- | --------- | ------ |
| `home/kitchen/1x1_special_tile/kill.png`     | KILL tile (hazard).              | 64×64     | ✅     |
| `home/living_room/1x1_special_tile/stop.png` | STOP tile (forced stop).         | 64×64     | ✅     |
| `hku/1x1_special_tile/one_way_up.png`        | One-way tile (entry from south). | 64×64     | ✅     |
| `hku/1x1_special_tile/one_way_down.png`      | One-way tile (entry from north). | 64×64     | ✅     |
| `hku/1x1_special_tile/one_way_left.png`      | One-way tile (entry from east).  | 64×64     | ✅     |
| `hku/1x1_special_tile/one_way_right.png`     | One-way tile (entry from west).  | 64×64     | ✅     |

---

## 4. Simple UI Grid Fallback — `assets/art/tiles/grids/`

| File              | Description         | Size (px) | Status |
| ----------------- | ------------------- | --------- | ------ |
| `grid_yellow.png` | Simple yellow tile. | 64×64     | ✅     |
| `grid_purple.png` | Simple purple tile. | 64×64     | ✅     |
| `grid_mint.png`   | Simple mint tile.   | 64×64     | ✅     |

---

## 5. Furniture / Obstacles — `assets/art/tiles/`

Obstacles are nodes that block movement. Base directory: `assets/art/tiles/{world}/{room}/{size}_obstacle_tile/`

### 5.0 Common Obstacles (`home/common/`)

| Asset Path                                                 | Description          | Status |
| ---------------------------------------------------------- | -------------------- | ------ |
| `1x1_obstacle_tile/cardboard_box_v1.png`                   | Small delivery box.  | ✅     |
| `1x1_obstacle_tile/cardboard_box_v2.png`                   | Open delivery box.   | ✅     |
| `1x1_obstacle_tile/cat_food_plate_v1.png`                  | Red food bowl.       | ✅     |
| `1x1_obstacle_tile/cat_food_plate_v2.png`                  | Blue food bowl.      | ✅     |
| `1x1_obstacle_tile/plant_v1.png`                           | Potted cactus.       | ✅     |
| `1x1_obstacle_tile/plant_v2.png`                           | Potted leafy plant.  | ✅     |
| `1x1_obstacle_tile/table_v2.png`                           | Square wooden table. | ✅     |
| `1x3_obstacle_tile_side_facing/shelf_with_book_on_top.png` | Tall vertical shelf. | ✅     |
| `2x1_obstacle_tile/shelf_v2.png`                           | Wide wall shelf.     | ✅     |

### 5.1 World 1 — Bedroom (`home/bedroom/`)

| Asset Path                            | Description              | Status |
| ------------------------------------- | ------------------------ | ------ |
| `1x1_obstacle_tile/nightstand_v1.png` | Small square nightstand. | ✅     |
| `1x1_obstacle_tile/shelf.png`         | Floating wall shelf.     | ✅     |
| `1x2_obstacle_tile/single_bed.png`    | Standard single bed.     | ✅     |
| `2x3_obstacle_tile/double_bed.png`    | Large double bed.        | ✅     |

### 5.2 World 2 — Kitchen (`home/kitchen/`)

| Asset Path                                 | Description                    | Status |
| ------------------------------------------ | ------------------------------ | ------ |
| `1x1_obstacle_tile/rubbish_bin.png`        | Green recycling bin.           | ✅     |
| `1x1_obstacle_tile/shelf.png`              | Kitchen wall shelf.            | ✅     |
| `1x1_obstacle_tile/sink.png`               | Kitchen sink unit.             | ✅     |
| `1x1_obstacle_tile/stove.png`              | Cooktop with burner rings.     | ✅     |
| `1x2_obstacle_tile_side_facing/fridge.png` | Tall side-facing refrigerator. | ✅     |
| `1x2_obstacle_tile_side_facing/shelf.png`  | Tall side-facing storage.      | ✅     |

### 5.3 World 3 — Living Room (`home/living_room/`)

| Asset Path                               | Description                | Status |
| ---------------------------------------- | -------------------------- | ------ |
| `1x1_obstacle_tile/ottoman.png`          | Round tufted ottoman.      | ✅     |
| `1x1_obstacle_tile/shelf.png`            | Living room wall shelf.    | ✅     |
| `1x1_obstacle_tile/sofa_big.png`         | Large single armchair.     | ✅     |
| `1x1_obstacle_tile/sofa_small.png`       | Single-seat small sofa.    | ✅     |
| `1x2_obstacle_tile/shelf.png`            | Wide living room shelf.    | ✅     |
| `1x2_obstacle_tile/sofa.png`             | Two-seat standard sofa.    | ✅     |
| `1x2_obstacle_tile_side_facing/sofa.png` | Side-facing standard sofa. | ✅     |

### 5.4 Special World — HKU (`hku/`)

| Asset Path                                        | Description                 | Status |
| ------------------------------------------------- | --------------------------- | ------ |
| `1x1_obstacle_tile/3d_printer.png`                | Innovation wing equipment.  | ✅     |
| `1x1_obstacle_tile/basketball_cart.png`           | Sports equipment.           | ✅     |
| `1x1_obstacle_tile/bus_stop.png`                  | University bus stop.        | ✅     |
| `1x1_obstacle_tile/cat_box.png`                   | Campus cat house.           | ✅     |
| `1x1_obstacle_tile/club_booth.png`                | Student society booth.      | ✅     |
| `1x1_obstacle_tile/gate.png`                      | Library entry gate.         | ✅     |
| `1x1_obstacle_tile/lift.png`                      | Elevator.                   | ✅     |
| `1x1_obstacle_tile/lily_pond.png`                 | Landmark Lily Pond.         | ✅     |
| `1x1_obstacle_tile/main_building.png`             | Miniature Main Building.    | ✅     |
| `1x1_obstacle_tile/piano.png`                     | CYM piano.                  | ✅     |
| `1x1_obstacle_tile/stone.png`                     | Decorative campus stone.    | ✅     |
| `1x1_obstacle_tile/stone_water.png`               | Sun Yat-sen garden feature. | ✅     |
| `1x1_obstacle_tile/teddy_bear.png`                | Graduation mascot.          | ✅     |
| `1x1_obstacle_tile/vending_machine.png`           | Campus refreshment.         | ✅     |
| `1x2_obstacle_tile/bus.png`                       | HKU Shuttle Bus.            | ✅     |
| `1x2_obstacle_tile/escalator.png`                 | MTR exit escalator.         | ✅     |
| `1x2_obstacle_tile/main_building_clock_tower.png` | Clock Tower landmark.       | ✅     |
| `2x1_obstacle_tile/fence.png`                     | Main Building fence.        | ✅     |

---

## 6. Decoration (Backdrops & Props) — `assets/art/tiles/`

Backdrops do not block movement. Base directory: `assets/art/tiles/{world}/{room}/{size}_backdrop/` (or `_tabletop_item/`)

### 6.0 Common Decorations (`home/common/`)

| Asset Path                           | Description               | Status |
| ------------------------------------ | ------------------------- | ------ |
| `0.5x0.5_tabletop_item/book.png`     | Small book.               | ✅     |
| `0.5x0.5_tabletop_item/coffee.png`   | Cup of coffee.            | ✅     |
| `0.5x0.5_tabletop_item/lamp.png`     | Desk lamp.                | ✅     |
| `0.5x0.5_tabletop_item/notebook.png` | Open notebook.            | ✅     |
| `0.5x0.5_tabletop_item/pen.png`      | Single pen.               | ✅     |
| `0.5x0.5_tabletop_item/plant.png`    | Small desk plant.         | ✅     |
| `1x1_backdrop/cactus.png`            | Floor cactus.             | ✅     |
| `1x1_backdrop/calendar.png`          | Wall calendar.            | ✅     |
| `1x1_backdrop/cardboard_box.png`     | Decorative cardboard box. | ✅     |
| `1x1_backdrop/cat_bed.png`           | Soft cat bed.             | ✅     |
| `1x1_backdrop/cat_toy.png`           | Small cat toy.            | ✅     |
| `1x1_backdrop/clock.png`             | Wall clock.               | ✅     |
| `1x1_backdrop/decor.png`             | Generic decoration.       | ✅     |
| `1x1_backdrop/electric_socket.png`   | Wall power socket.        | ✅     |
| `1x1_backdrop/light_switch.png`      | Wall light switch.        | ✅     |
| `1x1_backdrop/photo_v1.png`          | Framed photo (portrait).  | ✅     |
| `1x1_backdrop/photo_v2.png`          | Framed photo (landscape). | ✅     |
| `1x1_backdrop/rubbish_bin.png`       | Small rubbish bin.        | ✅     |
| `1x1_backdrop/windows.png`           | Window backdrop.          | ✅     |
| `1x2_backdrop/plant.png`             | Tall decorative plant.    | ✅     |

### 6.1 World 1 — Bedroom (`home/bedroom/`)

| Asset Path                        | Description              | Status |
| --------------------------------- | ------------------------ | ------ |
| `1x1_backdrop/bookshelf_v1.png`   | Small bookshelf.         | ✅     |
| `1x1_backdrop/bookshelf_v2.png`   | Small bookshelf variant. | ✅     |
| `1x1_backdrop/cat_sofa.png`       | Small sofa for cats.     | ✅     |
| `1x1_backdrop/clothes_basket.png` | Laundry basket.          | ✅     |
| `1x1_backdrop/drawing.png`        | Wall drawing.            | ✅     |
| `1x1_backdrop/luggage.png`        | Travel luggage.          | ✅     |
| `1x1_backdrop/wardrobe.png`       | Bedroom wardrobe.        | ✅     |
| `1x2_backdrop/bookshelf.png`      | Tall bookshelf.          | ✅     |
| `1x2_backdrop/mirror.png`         | Standing mirror.         | ✅     |
| `1x2_backdrop/wardrobe.png`       | Large bedroom wardrobe.  | ✅     |

### 6.2 World 2 — Kitchen (`home/kitchen/`)

| Asset Path                             | Description         | Status |
| -------------------------------------- | ------------------- | ------ |
| `1x1_backdrop/knife.png`               | Kitchen knife.      | ✅     |
| `1x1_backdrop/floor_mat.png`           | Kitchen floor mat.  | ❌     |
| `1x1_tabletop_item/microwave_oven.png` | Microwave oven.     | ✅     |
| `1x1_tabletop_item/toaster.png`        | Small toaster.      | ❌     |
| `1x2_backdrop/fridge.png`              | Large refrigerator. | ✅     |

### 6.3 World 3 — Living Room (`home/living_room/`)

| Asset Path                       | Description               | Status |
| -------------------------------- | ------------------------- | ------ |
| `1x1_backdrop/shoe_shelf.png`    | Entryway shoe shelf.      | ✅     |
| `1x1_backdrop/TV.png`            | Flat screen TV.           | ✅     |
| `1x1_backdrop/rug.png`           | Circular living room rug. | ❌     |
| `2x1_tabletop_item/TV.png`       | TV on media stand.        | ✅     |
| `2x1_tabletop_item/tv_stand.png` | Media console.            | ❌     |

### 6.4 Special World — HKU (`hku/`)

| Asset Path                      | Description            | Status |
| ------------------------------- | ---------------------- | ------ |
| `1x1_backdrop/bench.png`        | Campus seating.        | ✅     |
| `1x1_backdrop/notice_board.png` | Democracy Wall / Info. | ✅     |
| `1x2_backdrop/palm_tree.png`    | Iconic palm trees.     | ✅     |

---

## 7. UI — Pill Buttons `assets/art/ui/buttons/pill_bases/`

| File              | Intent            | Size (px) | Status |
| ----------------- | ----------------- | --------- | ------ |
| `primary_*.png`   | Primary (Gold)    | 220×60    | ✅     |
| `secondary_*.png` | Secondary (Mint)  | 220×60    | ✅     |
| `tertiary_*.png`  | Tertiary (Purple) | 220×60    | ✅     |
| `danger_*.png`    | Danger (Plum)     | 220×60    | ✅     |
| `disabled.png`    | Disabled (Grey)   | 220×60    | ✅     |

---

## 7A. Circular UI Buttons (`res://assets/art/ui/buttons/circular/`)

All circular buttons are present with `normal`, `hover`, `pressed`, and `disabled` states.

| Base Filename Prefix           | Icon / Intent                | Status |
| ------------------------------ | ---------------------------- | ------ |
| `btn_circle_achievement`       | Trophy icon.                 | ✅     |
| `btn_circle_ad`                | Play button with 'Ad' label. | ✅     |
| `btn_circle_arrow_*`           | Directional arrows.          | ✅     |
| `btn_circle_back`              | U-turn arrow.                | ✅     |
| `btn_circle_bg`                | Scenery icon.                | ✅     |
| `btn_circle_calendar`          | Calendar icon.               | ✅     |
| `btn_circle_cat`               | Cat head icon.               | ✅     |
| `btn_circle_close`             | X cross.                     | ✅     |
| `btn_circle_confirm`           | Checkmark.                   | ✅     |
| `btn_circle_dark_mode`         | Moon/Sun icon.               | ✅     |
| `btn_circle_double_arrow_*`    | Fast forward/rewind.         | ✅     |
| `btn_circle_exclaimation_mark` | Warning icon.                | ✅     |
| `btn_circle_exit`              | Door with arrow.             | ✅     |
| `btn_circle_fullscreen`        | Fullscreen arrows.           | ✅     |
| `btn_circle_gift`              | Present box.                 | ✅     |
| `btn_circle_home`              | House icon.                  | ✅     |
| `btn_circle_info`              | 'i' icon.                    | ✅     |
| `btn_circle_map`               | Map icon.                    | ✅     |
| `btn_circle_pause`             | Two vertical bars.           | ✅     |
| `btn_circle_paw`               | Paw print icon.              | ✅     |
| `btn_circle_question_mark`     | Help icon.                   | ✅     |
| `btn_circle_replay`            | Full circle arrow.           | ✅     |
| `btn_circle_settings_ver*`     | Cogwheel variants.           | ✅     |
| `btn_circle_shop`              | Shopping cart icon.          | ✅     |
| `btn_circle_sound_*`           | Speaker states.              | ✅     |
| `btn_circle_undo`              | Counter-clockwise arrow.     | ✅     |

---

## 7B. Interior Icons (`res://assets/art/ui/icons/pill_interiors/`)

| File                     | Icon                 | Status |
| ------------------------ | -------------------- | ------ |
| `icon_pill_retry.png`    | White retry arrow.   | ✅     |
| `icon_pill_home.png`     | White home icon.     | ✅     |
| `icon_pill_tick.png`     | White checkmark.     | ✅     |
| `icon_pill_play.png`     | White play triangle. | ✅     |
| `icon_pill_cat.png`      | White cat icon.      | ✅     |
| `icon_pill_info.png`     | White info icon.     | ✅     |
| `icon_pill_close.png`    | White cross sign.    | ✅     |
| `icon_pill_arrow_*`      | White arrows.        | ✅     |
| `icon_pill_settings.png` | White settings icon. | ✅     |

---

## 8. App Icons — `assets/art/app_icon/`

| File          | Description                    | Size (px) | Status |
| ------------- | ------------------------------ | --------- | ------ |
| `icon16.png`  | Favicon / micro icon.          | 16×16     | ✅     |
| `icon32.png`  | Small taskbar icon.            | 32×32     | ✅     |
| `icon48.png`  | Standard desktop icon.         | 48×48     | ✅     |
| `icon64.png`  | Large desktop icon.            | 64×64     | ✅     |
| `icon128.png` | Retina desktop / Mobile icon.  | 128×128   | ✅     |
| `icon256.png` | Store listing / High-res icon. | 256×256   | ✅     |

---

## 9. UI — Stars `assets/art/ui/stars/`

| File                     | Description                           | Size (px) | Status |
| ------------------------ | ------------------------------------- | --------- | ------ |
| `star_large_filled.png`  | Large gold celebration star.          | 72×72     | ✅     |
| `star_large_empty.png`   | Large empty star.                     | 72×72     | ✅     |
| `star_large_half.png`    | Large half-filled star.               | 72×72     | ✅     |
| `star_large_hollow.png`  | Large hollow socket star.             | 72×72     | ✅     |
| `star_medium_filled.png` | Medium gold star — HUD and world-map. | 32×32     | ✅     |
| `star_medium_empty.png`  | Medium empty star.                    | 32×32     | ✅     |
| `star_medium_half.png`   | Medium half-filled star.              | 32×32     | ✅     |
| `star_medium_hollow.png` | Medium hollow socket star.            | 32×32     | ✅     |
| `star_small_filled.png`  | Small gold star.                      | 18×18     | ✅     |
| `star_small_empty.png`   | Small empty star.                     | 18×18     | ✅     |
| `star_small_half.png`    | Small half-filled star.               | 18×18     | ✅     |
| `star_small_hollow.png`  | Small hollow socket star.             | 18×18     | ✅     |

---

## 9b. UI — Settings `assets/art/ui/settings/`

| File                        | Description                     | Size (px) | Status |
| --------------------------- | ------------------------------- | --------- | ------ |
| `slider_track.png`          | Slider groove/track background. | 116×56    | ✅     |
| `slider_fill.png`           | Filled progress bar layer.      | 116×56    | ✅     |
| `slider_track_disabled.png` | Disabled slider track.          | 116×56    | ✅     |
| `slider_fill_disabled.png`  | Disabled slider fill.           | 116×56    | ✅     |
| `checkbox_checked.png`      | Checked checkbox.               | 80×84     | ✅     |
| `checkbox_empty.png`        | Unchecked checkbox.             | 80×84     | ✅     |
| `checkbox_disabled.png`     | Disabled checkbox state.        | 80×84     | ✅     |

---

## 10. UI — HUD `assets/art/ui/hud/`

| File                  | Description                               | Size (px) | Status |
| --------------------- | ----------------------------------------- | --------- | ------ |
| `move-counter-bg.png` | Background pill for the move counter.     | 120×93    | ✅     |
| `star_pill.png`       | Cream pill background for HUD star strip. | 116×56    | ✅     |

---

## 11. UI — Panels / Popups `assets/art/ui/panels/`

| File                          | Description                               | Size (px) | Status |
| ----------------------------- | ----------------------------------------- | --------- | ------ |
| `panel_modal_normal.png`      | Universal modal base.                     | 128×128   | ✅     |
| `panel_modal_with_shadow.png` | Modal base with larger baked drop shadow. | 128×128   | ✅     |
| `panel_tooltip_bubble.png`    | Small speech bubble.                      | 59×73     | ✅     |

---

## 12. UI — World Map / Level Cards `assets/art/ui/world_map/`

| File                      | Description                      | Size (px) | Status |
| ------------------------- | -------------------------------- | --------- | ------ |
| `level_card_unlocked.png` | Unplayed/unlocked state.         | 72×90     | ✅     |
| `level_card_3star.png`    | 3-star completed state.          | 72×90     | ✅     |
| `level_card_locked.png`   | Locked state.                    | 72×90     | ✅     |
| `icon_lock.png`           | Lock icon shown on locked cards. | 64×64     | ✅     |

---

## 13. UI — Skin Cards `assets/art/ui/skin_select/` ⏸️

| File                     | Description                    | Status   |
| ------------------------ | ------------------------------ | -------- |
| `skin_card_unlocked.png` | Unlocked skin card background. | ⏸️ draft |
| `skin_card_equipped.png` | Equipped state.                | ⏸️ draft |
| `skin_card_locked.png`   | Locked state.                  | ⏸️ draft |

---

## 14. UI — Badges `assets/art/ui/badges/`

| File                      | Description                                     | Size (px) | Status |
| ------------------------- | ----------------------------------------------- | --------- | ------ |
| `badge_new_best.png`      | "NEW BEST!" orange pill badge.                  | 184×56    | ✅     |
| `badge_equipped.png`      | "EQUIPPED" teal pill.                           | 160×44    | ❌     |
| `badge_star_progress.png` | World progress pill (star icon + number + bar). | 280×48    | ❌     |

---

## 15. UI — Headers `assets/art/ui/headers/`

| File                           | Description                               | Size (px) | Status |
| ------------------------------ | ----------------------------------------- | --------- | ------ |
| `nekodash_title_landscape.png` | Wide-layout title art.                    | 720×176   | ✅     |
| `nekodash_title_portrait.png`  | Narrow-layout title art.                  | 720×539   | ✅     |
| `ribbon_purple.png`            | Primary decorative ribbon banner.         | 320×80    | ✅     |
| `ribbon_white.png`             | White variant ribbon for shell headers.   | 320×80    | ✅     |
| `ribbon_yellow.png`            | Yellow variant ribbon for callouts.       | 320×80    | ✅     |
| `ribbon_grey.png`              | Grey variant ribbon for subdued callouts. | 320×80    | ✅     |

---

## 16. Backgrounds — `assets/art/backgrounds/`

| File                | Description                               | Size (px) | Status |
| ------------------- | ----------------------------------------- | --------- | ------ |
| `paw_tile_128.png`  | Paw-print tile texture (small repeat).    | 128×128   | ✅     |
| `paw_tile_256.png`  | Paw-print tile texture (standard repeat). | 256×256   | ✅     |
| `bg_w1_bedroom.png` | World 1 Bedroom room background.          | 390×844   | ❌     |
| `bg_w2_kitchen.png` | World 2 Kitchen room background.          | 390×844   | ❌     |
| `bg_w3_living.png`  | World 3 Living Room background.           | 390×844   | ❌     |

---

## 17. Audio SFX — `assets/audio/sfx/`

### 17.1 Gameplay SFX — `gameplay/`

| File                 | Trigger             | Description        | Status |
| -------------------- | ------------------- | ------------------ | ------ |
| `slide_move.wav`     | Cat starts sliding. | Soft whoosh.       | ✅     |
| `wall_bump.wav`      | Cat hits a wall.    | Soft "boing".      | ✅     |
| `star_1.wav`         | First star earned.  | Bell ping.         | ✅     |
| `star_2.wav`         | Second star earned. | Higher bell ping.  | ✅     |
| `star_3.wav`         | Third star earned.  | Highest bell ping. | ✅     |
| `level_complete.wav` | Level complete.     | Cheerful jingle.   | ✅     |
| `no_star.wav`        | Complete (0 stars). | Subdued jingle.    | ✅     |

### 17.2 UI SFX — `ui/`

| File               | Trigger               | Description    | Status |
| ------------------ | --------------------- | -------------- | ------ |
| `button_tap.wav`   | Main button tap.      | Tactile click. | ✅     |
| `soft_tap.ogg`     | Secondary button tap. | Muted tap.     | ✅     |
| `toggle.ogg`       | Settings toggle.      | Switch sound.  | ✅     |
| `locked_level.wav` | Locked level tap.     | "Denied" thud. | ✅     |

---

## 18. Audio Music — `assets/audio/bgm/`

| File              | Used on             | Status |
| ----------------- | ------------------- | ------ |
| `opening.wav`     | Opening screen.     | ✅     |
| `bedroom.ogg`     | World 1 gameplay.   | ✅     |
| `kitchen.ogg`     | World 2 gameplay.   | ✅     |
| `living_room.ogg` | World 3 gameplay.   | ✅     |
| `skin_select.ogg` | Skin select screen. | ✅     |
| `hku.ogg`         | HKU special world.  | ✅     |

---

## 19. Fonts — `assets/fonts/`

| File                            | Format | Status |
| ------------------------------- | ------ | ------ |
| `Fredoka-Variable.ttf`          | TTF    | ✅     |
| `Fredoka-Body-SemiBold.tres`    | TRES   | ✅     |
| `Fredoka-Display-SemiBold.tres` | TRES   | ✅     |
| `Nunito-Variable.ttf`           | TTF    | ✅     |

---

## 20. UI Technical Resources

| File                                                | Status |
| --------------------------------------------------- | ------ |
| `assets/themes/global_ui_theme.tres`                | ✅     |
| `assets/shaders/ui/canvas_ui_overlay_blur.gdshader` | ✅     |
| `scenes/ui/level_complete_overlay.tscn`             | ✅     |
| `src/ui/level_complete_overlay.gd`                  | ✅     |
| `src/ui/paw_background.gd`                          | ✅     |
