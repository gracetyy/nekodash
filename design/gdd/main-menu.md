# Main Menu

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 21 of 22
> **Category**: UI
> **Priority**: MVP-Polish

---

## Overview

The Main Menu is the title screen and entry point to all other game areas. It shows the
game title, the player's currently equipped cat, and two navigation buttons: Play and
Skins. It reads from `SaveManager` only — no game systems are active on this screen.

Music Manager automatically plays the menu track when `transition_completed(MAIN_MENU)`
fires — Main Menu does not control audio.

---

## Player Fantasy

The entry point. A cute cat waits for you — your cat, whichever skin you last equipped.
The game title is present but doesn't shout. Two buttons. The menu is unhurried and
confident: it knows you're there, it knows what to show you. For a returning player,
seeing their equipped cat on the title screen is a small moment of "this is mine" before
the puzzle session begins. The Main Menu doesn't try to convince you to play; it just
opens the door and the cat sits by it.

---

## Responsibilities

| Responsibility                        | Owned By                                               |
| ------------------------------------- | ------------------------------------------------------ |
| Display game title                    | Main Menu ✅                                           |
| Display currently equipped cat sprite | Main Menu ✅ (reads `SaveManager.get_equipped_skin()`) |
| "Play" button → World Map             | Main Menu ✅                                           |
| "Skins" button → Skin Select          | Main Menu ✅                                           |
| Menu music                            | Music Manager (reacts to `transition_completed`)       |
| Persisting skin selection             | Save / Load System                                     |
| Skin texture resolution               | Cosmetic / Skin Database                               |

---

## Scene

| Property        | Value                                                        |
| --------------- | ------------------------------------------------------------ |
| Scene path      | `res://scenes/ui/main_menu.tscn`                             |
| Screen enum     | `Screen.MAIN_MENU`                                           |
| Receives params | No — `receive_scene_params` not implemented                  |
| Is autoload     | No                                                           |
| Initial scene   | Yes — this is `project.godot`'s `application/run/main_scene` |

---

## Display Elements

| Element          | Source                                                           | Notes                                                                          |
| ---------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Game title**   | Static text "NekoDash"                                           | Styled to match art direction                                                  |
| **Cat sprite**   | `SaveManager.get_equipped_skin()` → texture via Cosmetic/Skin DB | Shows the player's equipped cat; placeholder sprite until Cosmetic DB is built |
| **Play button**  | Static                                                           | Navigates to World Map                                                         |
| **Skins button** | Static                                                           | Navigates to Skin Select                                                       |

---

## Cat Sprite Display

Main Menu reads the equipped skin ID and resolves a texture to display:

```gdscript
func _ready() -> void:
    var skin_id := SaveManager.get_equipped_skin()
    var texture := _resolve_skin_texture(skin_id)
    _cat_sprite.texture = texture

func _resolve_skin_texture(skin_id: String) -> Texture2D:
    # Delegates to CosmeticDatabase (autoload or resource) once designed.
    # At MVP placeholder: return a fixed default texture.
    return preload("res://assets/art/cats/cat_default.png")
```

> **Dependency note**: The exact `_resolve_skin_texture()` implementation is deferred until
> the Cosmetic / Skin Database GDD is written (#20 in design order). At MVP the Main Menu
> may show a fixed placeholder cat sprite for all skin IDs.

---

## Navigation

| Button    | Call                                     | Notes                                                             |
| --------- | ---------------------------------------- | ----------------------------------------------------------------- |
| **Play**  | `SceneManager.go_to(Screen.WORLD_MAP)`   | Always goes to World Map; no "Continue vs New Game" choice at MVP |
| **Skins** | `SceneManager.go_to(Screen.SKIN_SELECT)` | Opens skin selector                                               |

There is no Back/Quit button. On mobile, the OS handles app exit via the device back
gesture or home button. A "Quit" button would only be relevant on desktop and is post-jam
scope.

---

## Layout

```
┌────────────────────────────────┐
│                                │
│         NekoDash               │  ← Title (top-center)
│                                │
│         [Cat Sprite]           │  ← Equipped cat art (center)
│                                │
│         [ Play ]               │  ← Primary CTA
│         [ Skins ]              │  ← Secondary CTA
│                                │
└────────────────────────────────┘
```

Vertical center layout. "Play" is the primary call-to-action (larger or bolder). "Skins"
is secondary, below Play.

---

## First-Launch State

On first launch (no save file yet), `SaveManager` returns the default skin ID
(`"cat_default"`). The cat sprite shows the default cat. No special first-launch flow or
tutorial is shown at MVP.

---

## Design Rules

1. **Pure navigation**: Main Menu holds no game state. It reads one value from SaveManager
   (`get_equipped_skin()`) and delegates everything else to SceneManager. Do not add game
   logic or state mutation here.

2. **No receive_scene_params**: Scene Manager confirms that MAIN_MENU never receives scene
   params. The scene does not implement `receive_scene_params()`.

3. **Cat sprite is cosmetic-only**: The Main Menu only previews the cat. It does not affect
   gameplay or progression.

4. **No settings UI at MVP**: Volume controls and other settings are post-jam. The Main
   Menu does not host a settings overlay.

5. **Music is automatic**: Main Menu must not start or stop music. Music Manager responds
   to `transition_completed(MAIN_MENU)` automatically.

6. **"Play" always opens World Map**: There is no "Continue" shortcut or last-played-level
   tracking at MVP. Post-jam: add a "Continue" button that calls
   `SceneManager.go_to_level(last_played_level_data)`.

---

## Edge Cases

| Edge Case                                     | Behaviour                                                                 |
| --------------------------------------------- | ------------------------------------------------------------------------- |
| No save file (first launch)                   | Default cat sprite shown; Play goes to World Map; everything looks normal |
| Skin ID in save file has no texture asset     | Show placeholder/default cat texture; do not crash                        |
| Player returns from World Map via Back button | Main Menu reloads via `_ready()`; cat sprite refreshed from SaveManager   |
| Player returns from Skin Select               | Main Menu reloads; new equipped skin is reflected in cat sprite           |

---

## Acceptance Criteria

| ID   | Criterion                                                                        |
| ---- | -------------------------------------------------------------------------------- |
| MM-1 | Main Menu is the application entry scene                                         |
| MM-2 | Game title "NekoDash" is displayed                                               |
| MM-3 | Cat sprite reflects `SaveManager.get_equipped_skin()` on load                    |
| MM-4 | "Play" button navigates to World Map                                             |
| MM-5 | "Skins" button navigates to Skin Select                                          |
| MM-6 | Returning from World Map or Skin Select re-shows Main Menu with fresh cat sprite |
| MM-7 | No crash on first launch (default skin shown)                                    |

---

## Tuning Knobs

None at MVP. No runtime-configurable parameters.

---

## Dependencies

| Depends On               | Interface Used                                                         |
| ------------------------ | ---------------------------------------------------------------------- |
| Save / Load System       | `SaveManager.get_equipped_skin()`                                      |
| Scene Manager            | `go_to(Screen.WORLD_MAP)`, `go_to(Screen.SKIN_SELECT)`                 |
| Cosmetic / Skin Database | `_resolve_skin_texture(skin_id)` — interface TBD; placeholder at MVP   |
| Music Manager            | Passive — no direct call; Music Manager reacts to SceneManager signals |

---

## Open Questions

| ID   | Question                                                                     | Priority | Resolution                                                        |
| ---- | ---------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------- |
| OQ-1 | Post-jam: add "Continue" button that reopens the last played level directly? | Low      | Yes, post-jam. Store `last_played_level_id: String` in save file. |
| OQ-2 | Should the cat sprite animate (idle animation) on the Main Menu?             | Low      | Post-jam. At MVP static sprite.                                   |
