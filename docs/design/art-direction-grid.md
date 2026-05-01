# NekoDash — Grid & World Art Direction

> **Status**: Approved
> **Created**: 2026-04-02
> **Author**: Grace + GitHub Copilot

---

## Purpose

This document defines the visual art direction for the **game grid** — the floor tiles, obstacles, and walls that create the game's world. It ensures a consistent, high-quality aesthetic across all rooms.

- **Wall variants by position**: World 1 runtime wall selection is role-based (`top`, `bottom`, `left`, `right`, and explicit corner tokens)

> **Critical Note**: The plain coloured tiles in the AI reference screenshots are **placeholder art only**. The actual game grid must look like a **top-down view of an interior room**. The cat is walking across a real floor. Walkable tiles are floor surfaces (wood, carpet, stone, etc.). Obstacles are furniture and household objects seen from above. The overall feel is a cosy, kawaii domestic space.

---

## Core Visual Concept: The Room

The game grid represents a **room interior viewed from directly overhead**.

- The **cat slides across the floor** — every walkable tile is a floor surface.
- The **obstacles are furniture** — the cat bumps into a bookshelf, sofa, box, etc.
- The room has **walls at its border** — the grid's outer edge reads as room walls.
- Each **world has a distinct room theme** — different rooms mean different floor materials and furniture sets.

The player should feel they are watching a cat zoom around a miniature room from above. This is the "cosy puzzle" emotional core. It elevates the game from abstract coloured tiles to a charming domestic diorama.

---

## 1. Floor Tiles (Walkable)

### Visual Requirements

- Floor tiles must read as a **real surface material** with texture and pattern.
- Tiles must be distinguishable as a grid unit while seamlessly tiling across the board.
- The **cat's trail** (visited tiles) shows a **paw-print impression** or subtle glow/warmth on the floor.
- Unvisited and visited tiles must be clearly different but both feel like floor.
- No plain flat colour or rectangle — even the baseline (World 1) must have visible grain.

### Trail State vs Unvisited State

| State     | Visual Description                                                              |
| --------- | ------------------------------------------------------------------------------- |
| Unvisited | Floor material at normal lighting / tone.                                       |
| Visited   | Floor material with a warm golden glow or visible paw impression overlay.       |
| Current   | Cat sits here; no special tile treatment (cat sprite handles position clarity). |

The trail overlay must not obscure the floor texture — it layers on top as a tint or additive glow, not a flat fill.

---

## 2. Obstacle Tiles (Blocking / Walls)

Obstacles are furniture and household objects that define the level's path.

### Art Rules

1. **Top-down perspective**: All objects are rendered from directly above.
2. **Volume & Depth**: Objects use subtle shadows or "isometric-lite" depth lines to suggest 3D volume.
3. **Solid Presence**: Obstacles must read as solid and impassable (physically chunky).
4. **Multi-cell support**: Furniture can span multiple cells (e.g. 1×2 sofa, 1×3 shelf) but art must be designed to align with the grid.
5. **Drop shadow**: All furniture objects cast a short drop shadow to the bottom-right (simulating top-left light).
6. **No floor outlines**: Obstacles should not have borders that match the floor grid; they should look like objects sitting _on_ the floor.

---

## 3. Grid Container & Room Walls

### Grid Frame (Unified Container)

The grid is presented as a **single unified container panel**, not a per-tile border treatment. It sits inside a rounded-rect frame with a purple-mauve border and subtle corner accent details.

### Wall Tiles (Room Wall Surface)

Blocking cells at the grid perimeter use **wall tile sprites** that represent the room's walls. These are background sprites applied to blocking cells that visually distinguish themselves from floor tiles (e.g. wallpaper vs wood).

---

## 4. World Themes

Each world represents a different room in the cat's home, with unique materials and palettes.

### World 1 — Dreamy Den ("The Bedroom") 🛏️

**Vibe**: Soft, cosy, personal.

- **Furniture**: Double bed, wardrobe, nightstand, bean bag.

### World 2 — Cream Caverns ("The Kitchen") 🍳

**Vibe**: Clean, bright, functional.

- **Furniture**: Refrigerator, stove, microwave, kitchen sink.

### World 3 — Pastel Plains ("The Living Room") 🛋️

**Vibe**: Bright, welcoming, warm.

- **Furniture**: Sofa, armchair, coffee table, TV stand, plant pots.

---

## 5. Cat Trail — Visual Specification

The cat's trail is the player's "drawing" that fills the room.

- **Overlay**: Sits on top of the floor, behind the cat. Uses additive/multiply blending.
- **Color**: Warm amber/gold tint (universal across all worlds).
- **Animation**: Bright glow when freshly placed, fading to a soft resting tint over ~0.3s.
- **Paw Print**: Subtle, translucent darker-amber paw silhouettes centered on visited tiles.

---

## 6. Rendering Guidelines

- **Tile Sizing**: Calculated at runtime to fill vertical space while maintaining square tiles and an 8px side margin.
- **Visual Weight**: Proportions are slightly exaggerated/chibi for readability.
- **Color Harmony**: Furniture colours are warm and desaturated, matching the world palette.

---

## 7. Do's and Don'ts

### Do ✅

- Reference **Animal Crossing** or **Stardew Valley** for furniture silhouettes and overhead room vibes.
- Use a **top-left light source** for consistent shadows.
- Exaggerate proportions for readability at small sizes.
- Let the floor texture provide implicit grid cues.

### Don't ❌

- Do not use **flat solid-colour tiles** (except as an accessibility fallback).
- Do not use **pure black** for outlines or shadows; use dark warm browns.
- Do not make obstacles feel **abstract or geometric**; they should be recognizable objects.
- Do not make the trail overlay fully opaque.

---

## 8. References

- **Design System**: `docs/design/design-system.md` (Colors and UI Components)
- **Asset Manifest**: `docs/design/asset-manifest.md` (Full list of implemented files)
- **Grid System**: `design/gdd/grid-system.md` (Data model and movement)
