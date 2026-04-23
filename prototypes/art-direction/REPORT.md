## Prototype Report: Art Direction

### Hypothesis

The new draft UI assets (kawaii-style headers, star icons, cat-head HUD background,
starburst overlays) create a cohesive visual identity when assembled into the four
primary game screens (Main Menu, Gameplay HUD, Level Complete, World Map).

### Approach

Built a standalone 4-screen prototype at `prototypes/art-direction/` using only the
draft art assets currently in `assets/art/ui/`. Each screen tests a different asset
combination:

- **Main Menu**: Pink bow header for title, purple/cyan flat headers for buttons,
  placeholder cat sprite
- **Gameplay HUD**: Notebook-cream header for level name, cat-head move counter bg,
  cyan/purple/cream button headers
- **Level Complete**: Pink bow header, gold/grey stars, starburst overlay effect,
  cat-head move display, colored button stack
- **World Map**: Purple bow header, notebook-style tab selectors, level grid with
  inline star ratings, locked level visual

Total build time: ~30 minutes. No production code imported. Arrow keys cycle screens.

### Result

1. **Headers work well as button/banner backgrounds.** The 5 header styles
   (bow, flat, asymmetric, asymmetric2, notebook) provide enough visual variety for
   distinct UI elements without clashing. The 10-color palette gives strong
   differentiation between action types (purple = primary, cyan = secondary,
   cream = neutral/back).

2. **Cat-head HUD background is strong.** The move counter inside the cat-head
   silhouette is immediately recognizable and on-brand. Its muted purple tone reads
   well against both the dark gameplay grid and the light UI backgrounds.

3. **Star icons are polished.** Gold/grey stars with thick brown outlines match the
   kawaii header art perfectly — same outline weight, same warm color temperature.
   They read clearly at both 20px (world map) and 96px (level complete).

4. **Starburst overlays add celebration energy.** The pink starburst at 30% opacity
   behind the Level Complete screen creates a joyful celebratory feel without
   overwhelming the content. Could animate rotation for extra polish.

5. **Color consistency concern**: The flat headers (header*\*.png) and bow headers
   (headerBow*\*.png) have slightly different outline thicknesses. This is visible
   when placed adjacent (e.g., HUD bottom buttons). Needs art review.

6. **Font integration gap**: No custom font was loaded — all labels use the default
   Godot font. The draft assets clearly expect a rounded/soft typeface to match
   their kawaii style. The current placeholder font feels sterile against the
   warm, illustrated UI elements.

7. **Missing tile/floor assets**: The `assets/art/tiles/` directories are empty.
   The gameplay grid currently uses a plain ColorRect. The contrast between polished
   UI frames and a flat-colored grid is jarring.

### Metrics

- Frame time: Not measured (headless confirmed clean load, visual run showed no hitches on Intel Iris Xe)
- Feel assessment: Header-based buttons feel inviting and toylike — appropriate for the kawaii target. The cat-head HUD element is the standout piece; it immediately communicates "this is a cat game" without text. Font mismatch reduces cohesion from ~8/10 to ~6/10.
- Asset coverage: 5 of 7 UI asset categories used (headers, stars, HUD, overlays, icons referenced). Items/coins not applicable to current screens. Tiles missing entirely.
- Iteration count: 1 (first implementation loaded cleanly)

### Recommendation: PROCEED

The draft UI assets establish a clear, appealing kawaii identity that works across all
four primary game screens. The header variants provide enough visual vocabulary for
buttons, banners, and tabs. The cat-head HUD piece and star icons are production-ready
in quality. Two blockers need resolution before full integration:

1. **Font selection is required** — a rounded, soft typeface (e.g., Quicksand,
   Nunito, or a custom kawaii font) is essential to match the illustrated asset style.
2. **Tile/floor art is needed** — the gameplay screen has no draft tile assets yet,
   creating a visual disconnect between HUD polish and grid plainness.

Neither blocker invalidates the art direction itself.

### If Proceeding

- **Font**: Select and integrate a rounded/kawaii-appropriate font. Test at sizes
  12, 16, 22, 28, 42 across all screens.
- **Tile art**: Commission or generate floor/wall tile sprites that match the thick-
  outline, flat-color style of the UI assets.
- **Component scenes**: Move shared button styling and other reusable UI treatment into dedicated component scenes instead of duplicating inline `theme_override_*` values.
- **Color system**: Formalize the header color assignments (purple = primary action,
  cyan = secondary, cream = neutral, pink = celebration/title).
- **Button interactivity**: Replace TextureRect button mockups with actual Button
  nodes using the header textures as StyleBox backgrounds for proper hover/press states.
- **Overlay animation**: Add slow rotation to starburst overlays on celebration
  screens.
- Estimated production effort: 2-3 days for font + theme + button system; tiles are
  a separate art pipeline task.

### Lessons Learned

1. The header assets are versatile — they work as banners, buttons, tabs, and info
   bars. This reduces the number of unique UI frame types needed.
2. The cat-head HUD shape should be used as a design motif beyond just the move
   counter (e.g., dialogue boxes, notification badges).
3. A 3-color action system (primary/secondary/neutral) mapped to specific header
   colors provides consistent UX language across all screens.
4. Draft asset integration should always include a font pairing test — typography
   accounts for ~40% of visual cohesion and is easy to overlook when assets are
   illustration-focused.
