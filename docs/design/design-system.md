# NekoDash — UI Design System

> **Status**: Approved
> **Created**: 2026-04-02
> **Author**: Grace + GitHub Copilot
> **Reference Images**: `design/reference/` (all screenshots)

---

## 1. Color Palette

All colors referenced throughout this document use these named tokens.

### Base

| Token           | Hex       | Usage                                              |
| --------------- | --------- | -------------------------------------------------- |
| `cream-bg`      | `#F6F1D8` | Global page/screen background                      |
| `cream-card`    | `#FAF7E7` | Modals, cards, popup panels (see `card/normal-bg`) |
| `cream-dark`    | `#CFC0B2` | Subtle section dividers inside cards               |
| `paw-watermark` | `#F1DFCA` | Paw-print watermark pattern on background          |
| `text`          | `#55324B` | Global text token (Dark Plum)                      |
| `icon`          | `#FDFDFB` | Global icon token (White)                          |

### Game Grid

| Token          | Hex       | Usage                                    |
| -------------- | --------- | ---------------------------------------- |
| `grid/wall`    | `#CEB6E4` | Default walkable wall/obstacle tile tint |
| `grid/floor`   | `#EFF9F1` | Default open floor tile tint             |
| `grid/visited` | `#FBD490` | Cat's visited/covered tile               |

### Cards

| Token                           | Hex       | Usage                                    |
| ------------------------------- | --------- | ---------------------------------------- |
| `card/normal-bg`                | `#FAF7E7` | Normal card/panel background             |
| `card/normal-bg-shadow`         | `#DDCBB7` | Drop shadow for normal card              |
| `card/normal-outline`           | `#5E4863` | Border/outline for normal card           |
| `card/normal-outline-shadow`    | `#BAB3B9` | Drop shadow for normal card outline      |
| `card/disabled-bg`              | `#BAB3B9` | Background for disabled/locked card      |
| `card/disabled-bg-shadow`       | `#9A8B94` | Drop shadow for disabled card            |
| `card/disabled-outline`         | `#7C777E` | Border/outline for disabled card         |
| `card/highlight-bg`             | `#F3C145` | Background for highlighted/selected card |
| `card/highlight-bg-shadow`      | `#D19646` | Drop shadow for highlighted card         |
| `card/highlight-outline`        | `#5E4863` | Border/outline for highlighted card      |
| `card/highlight-outline-shadow` | `#BCB3B7` | Drop shadow for highlighted card outline |

### Buttons — Action Mapping & States

Buttons use a **4-colour system** with explicit tokens for all states including hover and pressed shadows:

| Intent          | State                 | Token Name                         | Hex       |
| :-------------- | :-------------------- | :--------------------------------- | :-------- |
| **Primary**     | Normal                | `btn/primary-bg-normal`            | `#F3C145` |
|                 | Hover                 | `btn/primary-bg-hover`             | `#F8D36A` |
|                 | Pressed               | `btn/primary-bg-pressed`           | `#E4AE31` |
|                 | Shadow (normal)       | `btn/primary-bg-normal-shadow`     | `#D19646` |
|                 | Shadow (hover)        | `btn/primary-bg-hover-shadow`      | `#F3C145` |
|                 | Shadow (pressed)      | `btn/primary-bg-pressed-shadow`    | `#D19646` |
|                 | Text                  | `btn/primary-text-normal`          | `#55324B` |
|                 | Icon                  | `btn/primary-icon-normal`          | `#FDFDFB` |
| **Secondary**   | Normal                | `btn/secondary-bg-normal`          | `#A5D5BD` |
|                 | Hover                 | `btn/secondary-bg-hover`           | `#BCE4D0` |
|                 | Pressed               | `btn/secondary-bg-pressed`         | `#90C4A8` |
|                 | Shadow (normal)       | `btn/secondary-bg-normal-shadow`   | `#7FB499` |
|                 | Shadow (hover)        | `btn/secondary-bg-hover-shadow`    | `#A5D5BD` |
|                 | Shadow (pressed)      | `btn/secondary-bg-pressed-shadow`  | `#7FB499` |
|                 | Text                  | `btn/secondary-text-normal`        | `#55324B` |
|                 | Icon                  | `btn/secondary-icon-normal`        | `#FDFDFB` |
| **Tertiary**    | Normal                | `btn/tertiary-bg-normal`           | `#C0AFE2` |
|                 | Hover                 | `btn/tertiary-bg-hover`            | `#DAC6F5` |
|                 | Pressed               | `btn/tertiary-bg-pressed`          | `#A58BCA` |
|                 | Shadow (normal)       | `btn/tertiary-bg-normal-shadow`    | `#A083BD` |
|                 | Shadow (hover)        | `btn/tertiary-bg-hover-shadow`     | `#C0AFE2` |
|                 | Shadow (pressed)      | `btn/tertiary-bg-pressed-shadow`   | `#7F649A` |
|                 | Text                  | `btn/tertiary-text-normal`         | `#55324B` |
|                 | Icon                  | `btn/tertiary-icon-normal`         | `#FDFDFB` |
|                 | Icon Shadow (normal)  | `btn/tertiary-icon-normal-shadow`  | `#A083BD` |
|                 | Icon Shadow (hover)   | `btn/tertiary-icon-hover-shadow`   | `#C0AFE2` |
|                 | Icon Shadow (pressed) | `btn/tertiary-icon-pressed-shadow` | `#7F649A` |
| **Danger**      | Normal                | `btn/danger-bg-normal`             | `#614C6A` |
|                 | Hover                 | `btn/danger-bg-hover`              | `#7A6285` |
|                 | Pressed               | `btn/danger-bg-pressed`            | `#5E4863` |
|                 | Shadow (normal)       | `btn/danger-bg-normal-shadow`      | `#5E4863` |
|                 | Shadow (hover)        | `btn/danger-bg-hover-shadow`       | `#614C6A` |
|                 | Shadow (pressed)      | `btn/danger-bg-pressed-shadow`     | `#53405B` |
|                 | Text                  | `btn/danger-text-normal`           | `#FDFDFB` |
|                 | Icon                  | `btn/danger-icon-normal`           | `#FDFDFB` |
| **Disabled**    | Normal                | `btn/disabled-bg`                  | `#C6C5C9` |
|                 | Shadow                | `btn/disabled-bg-shadow`           | `#ACA2AC` |
|                 | Outline               | `btn/disabled-outline`             | `#9B8B98` |
|                 | Text                  | `btn/disabled-text`                | `#ACA2AC` |
|                 | Icon                  | `btn/disabled-icon`                | `#ACA2AC` |
| **Dropshadows** | Normal                | `btn/dropshadow`                   | `#BAB3B9` |
|                 | Pressed               | `btn/dropshadow-pressed`           | `#9A8B94` |

### HUD & Stars

| Token                          | Hex       | Usage                                     |
| ------------------------------ | --------- | ----------------------------------------- |
| `hud-pill-bg`                  | `#735D6B` | Move counter pill background              |
| `hud-pill-text`                | `#F8EBC2` | Move counter number                       |
| `items/star-filled`            | `#F2C456` | Base fill for earned stars                |
| `items/star-filled-highlight`  | `#FDFDFB` | Glint/highlight on filled stars           |
| `items/star-filled-shadow`     | `#EDB147` | Drop shadow/bottom bevel for filled stars |
| `items/star-filled-outline`    | `#55324B` | Dark Plum outline for filled stars        |
| `items/star-filled-dropshadow` | `#D19646` | Drop shadow for filled stars              |
| `items/star-empty`             | `#BAB3B9` | Base fill for unearned/missed stars       |
| `items/star-empty-outline`     | `#55324B` | Dark Plum outline for empty stars         |
| `items/star-empty-dropshadow`  | `#9A8B94` | Drop shadow for empty stars               |
| `items/star-hollow`            | `#C5BFC2` | Background socket/hollow slot for stars   |
| `items/star-hollow-shadow`     | `#A99BA2` | Inner shadow/bevel for the hollow socket  |
| `items/star-hollow-outline`    | `#55324B` | Dark Plum outline for hollow socket       |
| `items/star-hollow-dropshadow` | `#9A8B94` | Drop shadow for hollow socket             |

### Semantic

| Token            | Hex       | Usage                                          |
| ---------------- | --------- | ---------------------------------------------- |
| `badge-new-best` | `#F5A623` | "NEW BEST" orange pill badge on level complete |
| `lock-gold`      | `#E8A820` | Padlock icon colour on locked levels/skins     |

---

## 2. Typography

### Scale

| Role             | Size (mobile px) | Weight         | Example                            |
| ---------------- | ---------------- | -------------- | ---------------------------------- |
| Logo             | 48/56            | Black + stroke | "NekoDash" header                  |
| Screen Title     | 24/28            | ExtraBold      | WORLD SELECTION, SKINS             |
| Modal Heading    | 28/34            | Black          | LEVEL COMPLETE!, PAUSED, PERFECT!  |
| Button Label     | 32               | ExtraBold      | PLAY, RESUME, NEXT LEVEL           |
| HUD Number       | 20/22            | Black          | Move counter, min-move display     |
| Body / Sub-label | 13/15            | SemiBold       | "Can you do it in 6?", world names |
| Badge            | 11/12            | ExtraBold      | NEW BEST, Equipped                 |

---

## 3. Component Library

### 3.1 Pill Button (Dynamic Width)

The primary interactive text element across all screens.

- **Shape:** Fully rounded (border-radius = height / 2)
- **Visible face:** 56px high
- **Exported asset:** 60px high total (56px face + 4px baked bottom shadow)
- **Width:** Dynamic via `NinePatchRect` stretching.
- **Background:** Solid fill colour (per token above).
- **Shadow:** 4px bottom-only hard shadow/base, baked into export, colour matches button shadow token
- **Label:** Centered, `Button Label` type scale (32px). Text color depends on variant (`#55324B` for Primary/Secondary/Tertiary; `#FDFDFB` for Danger).
- **Icon:** Optional interior icon. 36x36px frame (containing 30x30px transparent vector), placed left or right of label with 8px gap using `HBoxContainer`.

**Construction model:**

- The pill button is treated as a **two-layer object**:
  1. top face (fill, outline, icon, text),
  2. bottom base/shadow layer.
- The shadow is part of the authored art asset, not added later as an engine effect.
- The exported PNG must include the full shadow area inside its bounds.

**States:**

- Default: full colour, full 4px bottom shadow visible.
- Hover / Focus: fill shifts to hover variant; shadow depth remains visually 4px.
- Pressed: top face physically shifts downward by exactly 2px; the owning button component scene or script should shift overlaid labels/icons down by 2px as part of the component implementation. Visible shadow depth reduces to 2px.
- Disabled: `btn-disabled` fill, `text-on-btn` label/icon where readability needs it, muted overall contrast, `btn-disabled-shadow` base.

**Interaction rule:**

- Hover changes **colour**, not elevation.
- Pressed changes **depth**, not hue family.

**Variants by intent:**

| Variant   | Fill            | Shadow token           | Used for                     |
| --------- | --------------- | ---------------------- | ---------------------------- |
| Primary   | `btn-primary`   | `btn-primary-shadow`   | PLAY, RESUME, NEXT LEVEL, OK |
| Secondary | `btn-secondary` | `btn-secondary-shadow` | RETRY, RESTART, NEXT ▶       |
| Tertiary  | `btn-tertiary`  | `btn-tertiary-shadow`  | QUIT, CLOSE, WORLD MAP       |
| Danger    | `btn-danger`    | `btn-danger-shadow`    | Destructive actions          |

### 3.2 Icon Button (Circular)

Used in the HUD and for screen navigation. Exported as fully baked PNGs including background, icon, border, and shadow.

- **Shape:** Circle, 48px diameter.
- **Format:** Rendered 48x48px PNG states (Normal, Hover, Pressed, Disabled).
- **Dimension Rule:** Exact 48x48px boundary. Shadows must be baked inside this boundary without increasing the canvas size (to avoid jitter).
- **Shadow Specs:** Hard bottom shadow (no blur). Normal state: 2px `RGB(70, 40, 110)`. Hover state: 3px `RGB(96, 56, 130)`.
- **Usage:** Plugged directly into Godot's `TextureButton` node.

| Variant         | Icon                        | Active State                           | Disabled State                            |
| --------------- | --------------------------- | -------------------------------------- | ----------------------------------------- |
| `undo-active`   | Counter-clockwise arrow     | Purple ring border, `text-dark` icon   | N/A                                       |
| `undo-disabled` | Counter-clockwise arrow     | N/A                                    | Grey border, `text-muted` icon, no shadow |
| `restart`       | Full-circle clockwise arrow | Purple ring border, `text-dark` icon   | N/A                                       |
| `back-chevron`  | Left-facing < chevron       | Default cream border, `text-dark` icon | N/A                                       |
| `settings-gear` | Cogwheel / gear             | Default cream border, `text-dark` icon | N/A                                       |
| `close-x`       | × cross                     | Default cream border, `text-dark` icon | N/A                                       |

The `undo-disabled` variant uses desaturated grey — use when no moves are available to undo.

### 3.3 Back Arrow Button

Top-left corner navigation on sub-screens (Level Select, Skins, World Map).

```
Shape     : Rounded square, ~40px
Background: cream-card or white
Icon      : Left-facing chevron/arrow, text-dark
```

### 3.4 Star Rating Strip

Horizontal row of 3 stars, used in HUD, level complete, and world aggregate displays.

```
Spacing   : 6px between stars
Filled    : star-filled fill + star-outline stroke
Empty     : star-empty fill + star-outline stroke (lighter)
Container : pill-shaped background in HUD (cream-card, light border)
```

| Size Tier      | Star Size           | Context                                                                    |
| -------------- | ------------------- | -------------------------------------------------------------------------- |
| Large          | 48–72px             | Level complete celebration (animated burst-in)                             |
| Medium         | 24–32px             | HUD strip and world-map level card rows                                    |
| Small          | ~16px               | Compact aggregate indicators and micro badges                              |
| Aggregate pill | 3-star compact pill | World card — 3 small inline stars in one cream pill (`ui-stars.png` Row 3) |

The **aggregate pill** (confirmed in `design/draft/ui-stars 1.png` Row 3) is used on World Map cards to show total star count at a glance. It is a single cream pill sprite containing 3 small inline star icons.

Level tiles now use the medium star assets to improve readability on mobile and desktop.

### 3.5 Panels & Modals

The primary container for all popups, menus, and end-of-level screens.

- **Shape:** Rounded rectangle (24px Corner Radius)
- **Background:** `card/normal-bg`
- **Border:** 10px Outside Stroke using `card/normal-outline`
- **Inner Bevel:** 10px Bottom Inner Shadow using `card/normal-bg-shadow`
- **Drop Shadow:** 10px Right & Bottom Drop Shadow using `card/normal-outline`
- **Implementation:** Exported as a 128x128px `NinePatchRect` base. Godot margins: 44px Top/Left, 54px Bottom/Right.

### 3.5.2 Ribbon Banner (Level Complete)

- **Asset Height:** 80px (updated from legacy 64–70px variants)
- **Use:** Level-complete title banner and other modal callout ribbons
- **Text Rule:** Ribbon title text is bold display type with no outline stroke
- **Alignment Rule:** Center title text vertically inside the ribbon and anchor the "NEW BEST" badge at top-right overlap.

### 3.5.1 Tooltip Bubbles

Floating speech bubbles used for tutorials or contextual hints.

- **Shape:** Rounded rectangle (10px Radius) with downward-pointing triangle tail (2px Radius on tip).
- **Scale:** 50% scale of the primary Modal Panel style.
- **Background:** `card/normal-bg`
- **Border:** 5px Outside Stroke using `card/normal-outline`
- **Inner Bevel:** 5px Bottom Inner Shadow using `card/normal-bg-shadow`
- **Drop Shadow:** 3px Right & Bottom Drop Shadow using `card/normal-outline`
- **Implementation:** Exported as a 59x73px `NinePatchRect` base. Godot margins must exactly protect the tail: 15px Left/Top, 18px Right, 26px Bottom. Anchor the tail to the left in Figma and use a larger Left Margin in Godot (e.g., 35px) to prevent horizontal tail stretching.

### 3.6 World Map / Level Cards

Cards representing individual levels on the World Map screen.

- **Shape:** Rounded square (16px Corner Radius)
- **States & Tokens:**
  - **Unlocked:** `card/normal-bg` fill, `card/normal-outline` stroke, `card/normal-bg-shadow` inner bevel, `card/normal-outline-shadow` drop shadow.
  - **3-Star Highlight:** `card/highlight-bg` fill, `card/highlight-outline` stroke, `card/highlight-bg-shadow` inner bevel, `card/highlight-outline-shadow` drop shadow.
  - **Locked:** `card/disabled-bg` fill, `card/disabled-outline` stroke, `card/disabled-bg-shadow` inner bevel.
- **Dimensions:** 10px Stroke, 10px Bottom Inner Shadow, 8px Bottom-Only Drop Shadow.
- **Implementation:** Exported as a 72x90px `NinePatchRect` base. Godot margins: 26px Left/Top/Right, 44px Bottom.

### 3.7 World Card (World Map)

```
Height      : ~120px
Border-radius: 16px
Background  : world-specific tint (see Art Direction doc for world colors)
Border      : 2px solid (slightly darker world tint)
Layout      : title + star row on the left, mini grid preview thumbnail on right
Lock state  : padlock overlay, greyed tint, disabled
Spacing     : 12px gap between cards
```

### 3.8 Skin Card (Skin Select)

> **UPDATE (2026-04-15)**: The skins and shop functionality are deferred to post-jam. Sections 3.8 and 6.9 remain for future reference.

Draft assets (`design/draft/ui-skins 1.png`) confirm a **portrait card format** (taller than wide).
Each card shows: cat silhouette in card body + name label at bottom + optional state badge.

```
Shape       : Rounded rectangle, portrait orientation (~80–100px wide, ~120px tall)
Cat area    : Upper ~70% of card — cat silhouette centred
Label area  : Lower ~30% — skin name, `text-dark`, Body scale
```

**Three States:**

| State    | Border                                                 | Cat                                     | Label Row                                                | Badge                                                                  |
| -------- | ------------------------------------------------------ | --------------------------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------- |
| Unlocked | cream-card (no special border)                         | Full colour silhouette                  | Name only                                                | None                                                                   |
| Equipped | Gold/amber border matching 3-star level card treatment | Full colour silhouette                  | Name                                                     | **"EQUIPPED" pill** at bottom (teal, `btn-secondary` fill, white text) |
| Locked   | Full grey/desaturated card                             | Grey silhouette + padlock icon centered | Unlock condition (`text-muted`, 11px, e.g. "3★ World 1") | None                                                                   |

The equipped state reuses the gold border treatment from 3-star level cards for visual consistency.
Locked cards show the complete unlock requirement as text, not just a padlock — do not hide the condition.

### 3.9 Wall Tile (Grid Blocking Cells)

Wall tiles are the **background surface** applied to blocking/obstacle-adjacent grid cells
at the room border. They are a distinct component from furniture obstacles.

> **Source**: Confirmed by `design/draft/tileset-wall-ver1` through `ver4`.
> Wall tiles are NOT just a border stroke — they are full background tile sprites
> applied to the cells that form the room's walls.

```
Size        : 64×64px (matching floor tile base resolution)
Per world   : Each world has its own wall tile set (4–8 sprite variants)
Variants    : Straight, corner (L-shape), decorative (with prop details)
Function    : Fills blocking cells that represent room walls (not furniture obstacles)
```

**Wall Tile Sets by World:**

| World             | Theme                        | File                    | Detail level                                                          |
| ----------------- | ---------------------------- | ----------------------- | --------------------------------------------------------------------- |
| 1 — Living Room   | Wooden log-cabin planks      | `tileset-wall-ver1.png` | 6 variants including shelf, clock, framed picture                     |
| 2 — Study/Library | Lavender paw-print wallpaper | `tileset-wall-ver2.png` | 8 variants including light switch, power outlet, framed cat art       |
| 3 — Kitchen       | White/mint subway tile       | `tileset-wall-ver3.png` | 8 variants including knife rack, calendar, kitchen window with plants |
| 4 — Bedroom       | Pastel pink kawaii wallpaper | `tileset-wall-ver4.png` | 8 variants including fairy lights, floating shelf, poster             |

Decorative wall tile variants (with props) should be placed at grid corners and edges
where they are most visible to the player. Plain variants fill bulk of wall run.

---

### 3.10 Slider (Pause Screen)

```
Track       : 6px height, rounded, grid-floor tint
Fill        : btn-primary tint
Thumb       : 24px circle, btn-primary fill, white center dot
Label       : "Music" / "SFX" in Body scale, left-aligned above track
```

Behavior rules:

- Slider fill persists after focus loss and non-slider clicks.
- Muted channels set slider to non-interactive state (no hover/click/focus).
- Muted sliders use disabled assets (`slider_track_disabled`, `slider_fill_disabled`) and disabled knob treatment.
- Checkbox controls use larger icon sizing for readability; disabled checkboxes use `checkbox_disabled`.

### 3.11 HUD Move Counter Pill

```
Shape       : Cat shaped
Background  : hud-pill-bg
Layout      : cat icon (20px) top-left + number below in HUD Number scale
Sub-label   : "Moves" in 11px below number
Color       : All text hud-pill-text
```

---

## 4. Layout & Spacing

### Screen Margins

```
Horizontal edge padding : 16px
Top safe area padding   : 12px (plus OS status bar)
Bottom safe area padding: 16px (plus OS home indicator)
```

### Vertical Rhythm

```
Stack spacing between major sections : 16px
Button stack gap                     : 10–12px
Card internal padding                : 20–24px
```

### Aspect Ratio Target

Portrait 9:16 (390×844 points). All layout specs assume this ratio.
Wider screens: add horizontal letterbox or scale up card width proportionally.

---

## 5. Global Background

Every screen uses a consistent background

Base fill

- cream-bg F6F1D8 (or the per-world background token e.g. w1-bg, w2-bg, w3-bg)

Pattern

- Repeating subtle tile made from a small paw-print watermark pattern
- Pattern tile is a square PNG (128×128px) designed to tile seamlessly
- Applied as a tiling image fill in Figma (Fill type = Image, Mode = Tile) so it repeats automatically to fill any frame size
- No stretching or scaling per screen; the same tile is reused and repeated on all screen sizes

Animation

- None, static background

Usage

- The background is the same visual treatment across all non-gameplay UI screens (main menu, world map, skin select, level complete)
- Gameplay screens may show the same tiling pattern in the margin area around the grid, or a world-specific room illustration, but the pattern is always implemented as a tiling image rather than a single large painted texture

---

## 6. Screen-by-Screen Layout Specs

### 6.1 Main Menu

```
Layout (top → bottom):
  [logo]              centered, 40px top margin
  [cat sprite]        centered, 32px below logo, ~180px tall
  [PLAY button]       full-width, 32px below cat
  [SKINS button]      full-width, 10px below PLAY
  [SETTINGS button]   full-width, 10px below SKINS

Logo:       Custom NekoDash lettering (see art direction); Japanese sub-label below
Cat sprite: Currently equipped skin, idle animation (bob/blink)
Buttons:    Primary / Tertiary / Secondary colour order per reference
```

### 6.2 World Selection (World Map)

```
Layout:
  [back button]       top-left
  [WORLD SELECTION]   centered title
  [coin counter]      top-right (icon + number pill)
  [world card list]   scrollable vertically, 12px gap
  [cat mascot]        bottom-right corner, decorative

World cards: see Component 3.7
Coin counter: paw/star icon + number in cream-card pill
```

### 6.3 Level Select

```
Layout:
  [back button]       top-left
  [world name]        centered title ("WORLD 1 – PASTEL PLAINS")
  [mini grid preview] top-right (thumbnail of world's tile style)
  [level grid]        3-column grid, scrollable, 8px gap between tiles
  [cat mascot]        bottom-right decorative

Level tiles: see Component 3.6
Scroll: vertical, no visible scrollbar
```

### 6.4 Gameplay Screen

```
Layout:
  [HUD bar]           full-width, 60px tall
    ├─ [move counter] left
    ├─ [star strip]   center
    └─ [undo/restart] right
  [game grid]         fills remaining vertical space, centered horizontally
                      with 8px horizontal margin each side

HUD bar background: transparent (shows cream-bg)
Grid: see Art Direction doc for visual treatment
Grid margins: 8px from screen edge, grid is vertically centered in remaining space
```

### 6.5 Tutorial (first level only)

```
Same layout as Gameplay, plus:
  [speech bubble]     attached to cat, white rounded-rect with text-dark copy
  [arrow animation]   chevron trail showing swipe direction (3 fading chevrons → bold arrow)

Speech bubble: "Swipe to slide!", 15px body text, small triangle pointer toward cat
Arrow: teal/mint color, animated fade-in sequence, disappears after first swipe
```

### 6.6 Pause Screen

```
Triggered by: pause button (not shown in reference — TBD: tap top-area or dedicated button)
Overlay layout:
  [scrim]             full screen rgba overlay
  [cat peek sprite]   cat_default_peek.png (440×350), centered, with 42px of bottom overlap into the modal top edge
  [modal panel]       centered, ~300px wide
    ├─ "PAUSED" heading
    ├─ Music slider
    ├─ SFX slider
    ├─ Display toggles: Reduce Motion / Large Text / Simple UI / Fullscreen
    ├─ Input hint picker
    ├─ [RESUME button]   Primary
    ├─ [RESTART button]  Secondary
    └─ [QUIT button]     Tertiary
```

Options overlay uses the same `cat_default_peek.png` placement rule: keep the
cat texture centered and overlap the texture bottom by 42px into the modal top edge.
`Simple UI` swaps gameplay back to the mint/yellow/purple placeholder tiles instead of
the authored room-art board.

### 6.7 Level Complete — 1-2 Stars

```
Overlay layout:
  [scrim]
  [modal panel]
    ├─ "LEVEL COMPLETE!" heading
    ├─ [star strip]     1–2 stars filled
    ├─ cat sprite       smaller, curious/thinking expression
    ├─ "Moves: X"       HUD Number scale, text-gold
    ├─ "Min: Y"         HUD Number scale, text-dark
    ├─ "Can you do it in Y?" subtext, italic, text-muted
    ├─ [NEXT ▶ button]  Secondary
    ├─ [RETRY button]   Primary
    └─ [< UNDO LAST]    Tertiary (undo the final move to try to improve)

"UNDO LAST" button allows player to back up one move and try to reach 3 stars.
```

### 6.8 Level Complete — 3 Stars (Perfect)

**Preferred variant: Ver2 (more polished)**

```
Overlay layout:
  [full-screen confetti / sparkle burst]
  [modal panel]
    ├─ "LEVEL COMPLETE!" heading
    ├─ world/level identifier "W1-03" subtext
    ├─ [3 large stars]  enlarged, animated burst-in
    ├─ cat sprite       happy/hearts expression
    ├─ "X moves · Y min · [NEW BEST]"  row
    ├─ [Next Level button]   Primary (full-width)
    ├─ [Retry button]        Secondary (full-width)
    └─ [World Map button]    Tertiary (full-width)

Star burst animation: stars scale from 0 → 1.2 → 1.0 with bounce easing, staggered 80ms delay each.
"NEW BEST" badge: **orange pill** (320×90px per `ui-misc.png` spec), orange/amber fill (`#F5A623` or similar),
white text — appears only on new personal best. This is a sprite component from `ui-stars.png` Row 2,
not a plain text label. The `badge-new-best` color token should be updated to orange (currently set to
teal — teal is used for EQUIPPED badge instead).
```

### 6.9 Skin Selection

> **UPDATE (2026-04-15)**: Skin and shop functions are deferred to post-jam. This section remains for future reference.

```
Layout:
  [back button]        top-left
  [SKINS title]        centered
  [coin counter]       top-right
  [skin card grid]     scrollable, 2-col or 3-col grid of portrait skin cards (§3.8)
  [OK / EQUIP button]  bottom full-width, Primary (activates selected skin)

Skin cards: see Component §3.8 (portrait card format — silhouette + name + state badge)
Tapping an unlocked card selects it; the EQUIP button then applies it.
Locked cards display unlock condition label — tapping shows a "locked" feedback but no action.
```

---

## 7. Motion & Animation Guidelines

| Element             | Animation                            | Duration | Easing          |
| ------------------- | ------------------------------------ | -------- | --------------- |
| Cat slide           | Linear (no easing) — physics feel    | per-tile | `LINEAR`        |
| Cat stop (bump)     | 3-frame squish/stretch bounce        | 120ms    | `EASE_OUT`      |
| Tile trail light-up | Fade from grid-floor to grid-trail   | 80ms     | `EASE_IN_OUT`   |
| Star fill (HUD)     | Scale 0.8→1.0 pop                    | 100ms    | `EASE_OUT_BACK` |
| Modal appear        | Scale from 0.85→1.0, fade in         | 180ms    | `EASE_OUT_BACK` |
| Modal dismiss       | Scale 1.0→0.95, fade out             | 120ms    | `EASE_IN`       |
| 3-star burst        | Stars scale 0→1.2→1.0, staggered     | 300ms ea | `EASE_OUT_BACK` |
| Confetti burst      | Particle explosion outward           | 800ms    | `EASE_OUT`      |
| Cat idle (menu)     | Gentle vertical bob + blink          | 2s loop  | `EASE_IN_OUT`   |
| Screen transition   | Slide or fade (TBD by scene manager) | 200ms    | `EASE_IN_OUT`   |

---

## 8. Iconography

| Icon           | Context                                   | Style                                              | Draft Source                       |
| -------------- | ----------------------------------------- | -------------------------------------------------- | ---------------------------------- |
| Undo arrow     | HUD (active)                              | Counter-clockwise curved arrow, purple ring border | `ui-button-3 1.png`                |
| Undo arrow     | HUD (disabled)                            | Same shape, grey/desaturated, no ring              | `ui-button-3 1.png`                |
| Restart arrow  | HUD                                       | Clockwise full-circle arrow                        | `ui-button-3 1.png`                |
| Back chevron   | Screen nav (top-left)                     | Left-facing < chevron, cream border                | `ui-button-3 1.png`                |
| Settings gear  | Pause / options                           | Cogwheel, cream border                             | `ui-button-3 1.png`                |
| Close ×        | Modal dismiss                             | × cross, cream border                              | `ui-button-3 1.png`                |
| Padlock        | Locked levels / skins                     | Rounded, chunky, brown/warm fill (not gold)        | `ui-misc 1.png`                    |
| Star           | All rating contexts                       | 5-point, rounded tips, warm gold                   | `ui-stars 1.png`                   |
| Paw coin       | Currency counter (World Map, Skin Select) | Gold circular coin with paw pad design, ~32px      | `ui-misc 1.png`                    |
| "NEW BEST"     | Level complete (3-star)                   | Orange/amber pill, white ALL CAPS text, 320×90px   | `ui-misc 1.png` / `ui-stars 1.png` |
| Cat silhouette | Locked skin placeholder                   | Simple sitting cat outline, grey                   | `ui-skins 1.png`                   |
| Globe / earth  | "World Map" button icon                   | Simple globe with minimal lines                    | —                                  |

All icons: flat, no gradients, stroke weight 2–3px, matches rounded aesthetic.

---

## 9. Accessibility Considerations

- Minimum button tap target: 44×44px (iOS HIG / Android material)
- Star-only ratings must be accompanied by numeric text (e.g. "2/3") for screen readers
- All interactive elements must have `focus_mode` set in Godot for controller/keyboard nav
- Locked content: icon + text label (not icon only) for unlock conditions
- Color contrast: all text on buttons must meet WCAG AA (4.5:1 ratio minimum)
- Cat idle animation: no flashing, frequency < 3Hz (safe for photosensitivity)

---

## 10. What This Document Does NOT Cover

- Grid tile visual art direction → `docs/design/art-direction-grid.md`
- Audio cue timings → `design/gdd/sfx-manager.md` / `music-manager.md`
- Localization string specs → future `design/gdd/localization.md`
- Platform-specific store assets (screenshots, icons) → future `design/gdd/store-assets.md`
