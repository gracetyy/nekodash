# NekoDash — UI Design System

> **Status**: Approved
> **Created**: 2026-04-02
> **Author**: Grace + GitHub Copilot
> **Reference Images**: `design/reference/` (all screenshots)

---

## Purpose

This document is the single source of truth for every visual UI decision in NekoDash.
It defines the color palette, typography, component library, spacing grammar, and
per-screen layout specifications derived from the AI reference screenshots. Any UI
work — implementation or new asset creation — must conform to these specs.

The **Grid / World Art Direction** (floor tiles, obstacle furniture, room theming) is
a separate document: `docs/design/art-direction-grid.md`.

---

## 1. Color Palette

All colors referenced throughout this document use these named tokens.

### Base

| Token           | Hex       | Usage                                     |
| --------------- | --------- | ----------------------------------------- |
| `cream-bg`      | `#F6F1D8` | Global page/screen background             |
| `cream-card`    | `#FFF8F0` | Modals, cards, popup panels               |
| `cream-dark`    | `#CFC0B2` | Subtle section dividers inside cards      |
| `paw-watermark` | `#F1DFCA` | Paw-print watermark pattern on background |

### Game Grid (floor/wall colors are overridden per world — see Art Direction doc)

| Token        | Hex       | Usage                                    |
| ------------ | --------- | ---------------------------------------- |
| `grid-wall`  | `#CEB6E4` | Default walkable wall/obstacle tile tint |
| `grid-floor` | `#EEF9F1` | Default open floor tile tint             |
| `grid-trail` | `#FBD490` | Cat's visited/covered tile               |

### Buttons — Action Mapping

Buttons use a **3-colour system** where colour signals intent, not just decoration:

| Token           | Hex           | Usage                                                  |
| --------------- | ------------- | ------------------------------------------------------ |
| `btn-primary`   | `#F3C145`     | Primary positive action (Play, Resume, Next Level, OK) |
| `btn-secondary` | `#A5D5BD`     | Secondary progression action (Retry, Restart, Next)    |
| `btn-tertiary`  | `#C0AFE2`     | Tertiary / neutral action (Quit, Close, World Map)     |
| `btn-disabled`  | `#C6C5C9`     | Locked / unavailable state                             |
| `btn-shadow`    | (darken -20%) | Bottom-edge drop shadow for all pill buttons           |

### Text

| Token          | Hex       | Usage                                                |
| -------------- | --------- | ---------------------------------------------------- |
| `text-dark`    | `#53314B` | Body copy, labels, stat numbers                      |
| `text-heading` | `#5C4A6B` | Modal headings ("PAUSED", "LEVEL COMPLETE!")         |
| `text-gold`    | `#C87A00` | Highlighted numbers, "PERFECT!", move-count callouts |
| `text-on-btn`  | `#FFFFFF` | All button labels                                    |
| `text-muted`   | `#8A7060` | Sub-labels, unlock condition text on locked tiles    |

### HUD

| Token           | Hex       | Usage                        |
| --------------- | --------- | ---------------------------- |
| `hud-pill-bg`   | `#735D6B` | Move counter pill background |
| `hud-pill-text` | `#F8EBC2` | Move counter number          |
| `star-filled`   | `#F5C842` | Earned star                  |
| `star-empty`    | `#C8C4D0` | Unearned star slot           |
| `star-outline`  | `#C8A820` | Star border/stroke           |

### Semantic

| Token            | Hex       | Usage                                                                                   |
| ---------------- | --------- | --------------------------------------------------------------------------------------- |
| `badge-new-best` | `#F5A623` | "NEW BEST" orange pill badge on level complete (was teal — corrected from draft assets) |
| `lock-gold`      | `#E8A820` | Padlock icon colour on locked levels/skins                                              |

---

## 2. Typography

NekoDash uses a single rounded sans-serif family throughout. The exact font is TBD
by the Art Director, but it must be: rounded, approachable, not geometric/cold.
**Candidate**: Nunito ExtraBold / Black, or Fredoka One.

### Scale

| Role             | Size (mobile px) | Weight         | Example                                 |
| ---------------- | ---------------- | -------------- | --------------------------------------- |
| Logo             | 48–56            | Black + stroke | "NekoDash" header                       |
| Screen Title     | 24–28            | ExtraBold      | "WORLD SELECTION", "SKINS"              |
| Modal Heading    | 28–34            | Black          | "LEVEL COMPLETE!", "PAUSED", "PERFECT!" |
| Button Label     | 18–20            | ExtraBold      | "PLAY", "RESUME", "NEXT LEVEL"          |
| HUD Number       | 20–22            | Black          | Move counter, min-move display          |
| Body / Sub-label | 13–15            | SemiBold       | "Can you do it in 6?", world names      |
| Badge            | 11–12            | ExtraBold      | "NEW BEST", "Equipped"                  |

### Text Treatment Rules

- All button labels: **ALL CAPS**
- Modal headings: **ALL CAPS**
- Navigation titles (World Selection, Skins): **Title Case**
- Body copy: Sentence case
- Logo: custom lettering — follow reference exactly
- Japanese subtitle on logo ("ネコダッシュ"): match reference scale (~16px, below main logo)

---

## 3. Component Library

### 3.1 Pill Button

The primary interactive element across all screens.

```
Shape     : Fully rounded (border-radius = height / 2)
Height    : 52–56px (mobile)
Width     : Full-width within card (with 20px margin each side) or fixed 180–220px
Background: solid fill (colour per token above)
Shadow    : 4px bottom-only drop shadow, colour = btn-shadow token
Label     : centered, text-on-btn, Button Label type scale
Icon      : optional, left or right of label with 8px gap
```

**States:**

- Default: full colour
- Pressed: -8% brightness, shadow reduces to 2px
- Disabled: `btn-disabled` fill, `text-muted` label, no shadow

**Variants by intent:**

| Variant   | Fill            | Used for                     |
| --------- | --------------- | ---------------------------- |
| Primary   | `btn-primary`   | PLAY, RESUME, NEXT LEVEL, OK |
| Secondary | `btn-secondary` | RETRY, RESTART, NEXT ▶       |
| Tertiary  | `btn-tertiary`  | QUIT, CLOSE, WORLD MAP       |

### 3.2 Icon Button (Circular)

Used in the HUD and for screen navigation. Six confirmed variants (from `design/draft/ui-button-3 1.png`):

```
Shape     : Circle, 44–48px diameter
Background: white or cream-card with subtle border ring
Icon      : 24–28px, centered
Shadow    : 2px drop shadow, soft
Label     : 11px text below circle (context-dependent)
```

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
| Medium         | 24px                | HUD strip (3 stars inline, pill container)                                 |
| Small          | ~16px               | Level tile card (below level number in `§3.6`)                             |
| Aggregate pill | 3-star compact pill | World card — 3 small inline stars in one cream pill (`ui-stars.png` Row 3) |

The **aggregate pill** (confirmed in `design/draft/ui-stars 1.png` Row 3) is used on World Map cards to show total star count at a glance. It is a single cream pill sprite containing 3 small inline star icons.

### 3.5 Modal / Popup Panel

Used for PAUSED, LEVEL COMPLETE, and similar overlays.

```
Background  : cream-card
Border-radius: 20–24px
Padding     : 24px horizontal, 28px vertical
Shadow      : 0 8px 32px rgba(0,0,0,0.2)
Max-width   : 320px (mobile), centered
Overlay     : semi-transparent dark scrim behind panel (rgba 0,0,0,0.35)
Cat mascot  : peeks over the top edge of the panel (peeking/sitting sprite)
Sparkles    : decorative ✦ sparkle sprites at panel corners / background
```

### 3.6 Level Tile (Level Select grid)

```
Shape       : Rounded square, ~90px
Background  : cream-card (unlocked), btn-disabled (locked)
Number      : Screen Title scale, text-dark (unlocked) / text-muted (locked)
Stars       : 3-star strip below number, small (18px stars)
Lock icon   : lock-gold padlock replaces number when locked
Active level: highlighted with btn-tertiary border (current / "in progress" level)
```

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

### 3.11 HUD Move Counter Pill

```
Shape       : Rounded rectangle, ~80×52px
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

Every screen uses a consistent background:

```
Base fill   : cream-bg (#F6F1D8)
Pattern     : Repeating subtle tile grid lines (very low opacity, ~8%)
              + scattered paw print watermarks (paw-watermark, opacity ~15%)
Pattern tile: ~40×40px grid, matches the visual grid-square motif
Animation   : None (static background)
```

The background is the same across all screens including gameplay — it shows through
around the game grid area.

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
  [cat peek sprite]   sits above modal top edge, centered
  [modal panel]       centered, ~300px wide
    ├─ "PAUSED" heading
    ├─ Music slider
    ├─ SFX slider
    ├─ [RESUME button]   Primary
    ├─ [RESTART button]  Secondary
    └─ [QUIT button]     Tertiary
```

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
