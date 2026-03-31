# Skin Select Screen

> **Status**: Draft
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 22 of 22
> **Category**: UI
> **Priority**: MVP-Skins

---

## Overview

The Skin Select Screen lets the player browse all cat skins, see which are unlocked,
preview locked skins with their unlock hint, and equip an unlocked skin. It is the final
UI screen in the system. Equipping a skin writes to `SaveManager` immediately; the
equipped skin is reflected in the Main Menu and gameplay scene on the next load.

---

## Responsibilities

| Responsibility                          | Owned By                            |
| --------------------------------------- | ----------------------------------- |
| Display all skins (unlocked and locked) | Skin Select Screen ✅               |
| Show unlock hint text for locked skins  | Skin Select Screen ✅               |
| Allow player to equip an unlocked skin  | Skin Select Screen ✅               |
| Write equipped skin choice to save data | Skin Select Screen → SaveManager ✅ |
| Navigate back to Main Menu              | Skin Select Screen ✅               |
| Skin definitions and textures           | Cosmetic / Skin Database            |
| Unlock state                            | Save / Load System                  |

---

## Scene

| Property        | Value                                                            |
| --------------- | ---------------------------------------------------------------- |
| Scene path      | `res://scenes/ui/skin_select.tscn`                               |
| Screen enum     | `Screen.SKIN_SELECT`                                             |
| Receives params | No — `receive_scene_params` not implemented                      |
| Is autoload     | No                                                               |
| Music           | `_track_menu` (Music Manager handles via `transition_completed`) |

---

## Display Elements

| Element                | Source                                                         | Notes                                                 |
| ---------------------- | -------------------------------------------------------------- | ----------------------------------------------------- |
| **Skin grid**          | `CosmeticDatabase.get_all_skins()`                             | One card per skin; scrollable grid                    |
| **Skin preview**       | `CosmeticDatabase.get_preview_texture(skin_id)`                | Shown in each card and in the large preview area      |
| **Skin name**          | `SkinData.display_name`                                        | Label on each card                                    |
| **Equipped indicator** | `SaveManager.get_equipped_skin()`                              | Highlight/badge on currently equipped card            |
| **Lock icon**          | `not SaveManager.get_unlocked_skins().has(skin_id)`            | Overlay on locked cards                               |
| **Unlock hint**        | `SkinData.unlock_hint`                                         | Shown below locked skin cards; e.g. "3-star 5 levels" |
| **Large preview**      | Currently selected skin                                        | Right panel or overlay; updates on card tap           |
| **Equip button**       | Active when selected skin is unlocked and not already equipped | "Equip" → `SaveManager.set_equipped_skin()`           |
| **Back button**        | Static                                                         | Returns to Main Menu                                  |

---

## Layout

```
┌──────────────────────────────────────────────────┐
│  [← Back]          My Cats                       │  ← Header
├──────────────────┬───────────────────────────────┤
│  ┌────┐  ┌────┐  │                               │
│  │ 🐱 │  │ 🔒 │  │   [Large skin preview]        │
│  │★★★ │  │hint│  │                               │
│  └────┘  └────┘  │   Cozy Cat                    │  ← Selected skin name
│  ┌────┐  ┌────┐  │                               │
│  │ 🔒 │  │ 🔒 │  │   [ Equip ]                   │  ← CTA (disabled if locked)
│  │hint│  │hint│  │                               │
│  └────┘  └────┘  │                               │
└──────────────────┴───────────────────────────────┘
         Grid           Selection panel
```

On mobile portrait, collapse to a single-column scrollable list of cards; tapping a card
opens a full-screen preview overlay with the Equip button.

---

## Initialization Flow

```gdscript
func _ready() -> void:
    _equipped_skin_id = SaveManager.get_equipped_skin()
    _selected_skin_id = _equipped_skin_id  # Default selection = currently equipped
    _populate_grid()
    _refresh_selection_panel(_selected_skin_id)

func _populate_grid() -> void:
    var unlocked := SaveManager.get_unlocked_skins()
    for skin in CosmeticDatabase.get_all_skins():
        var card := _make_skin_card(skin, unlocked.has(skin.skin_id))
        _grid_container.add_child(card)

func _make_skin_card(skin: SkinData, is_unlocked: bool) -> Control:
    # Set preview texture, name label
    # If not unlocked: show lock overlay and skin.unlock_hint
    # If skin.skin_id == _equipped_skin_id: show equipped badge
    # Connect pressed → _on_skin_card_pressed(skin.skin_id)
    pass

func _on_skin_card_pressed(skin_id: String) -> void:
    _selected_skin_id = skin_id
    _refresh_selection_panel(skin_id)

func _refresh_selection_panel(skin_id: String) -> void:
    var skin := CosmeticDatabase.get_skin(skin_id)
    var is_unlocked := SaveManager.get_unlocked_skins().has(skin_id)
    _preview_texture.texture = skin.preview_texture
    _skin_name_label.text = skin.display_name
    _equip_btn.disabled = not is_unlocked or skin_id == _equipped_skin_id
```

---

## Equip Flow

```gdscript
func _on_equip_btn_pressed() -> void:
    SaveManager.set_equipped_skin(_selected_skin_id)
    _equipped_skin_id = _selected_skin_id
    _refresh_all_cards()  # Update equipped badge across grid
    _refresh_selection_panel(_selected_skin_id)  # Disable equip btn

func _refresh_all_cards() -> void:
    for card in _grid_container.get_children():
        card.set_equipped(card.skin_id == _equipped_skin_id)
```

---

## Navigation

| Action                                                     | Call                                   |
| ---------------------------------------------------------- | -------------------------------------- |
| Back button                                                | `SceneManager.go_to(Screen.MAIN_MENU)` |
| (No "Done" button needed — equip is immediate; Back exits) |                                        |

---

## Live Unlock Refresh

If the player somehow triggers `SaveManager.skin_unlocked` while on this screen (unlikely,
but the Level Complete Screen + World Map + Skin Select could theoretically be open in a
re-entry scenario), subscribe to `SaveManager.skin_unlocked` and refresh the grid. At MVP
this scenario cannot occur (Skin Select is only reached from Main Menu; you cannot play a
level from this screen) so live refresh is not required. Document as a post-jam item.

---

## Design Rules

1. **All skins always visible**: Locked skins are shown in the grid, greyed out with a
   lock overlay. Players see what they're working toward.

2. **No unlock action from this screen**: The Skin Select Screen shows lock hints but
   provides no "watch ad" or "purchase" button at MVP. Those are post-jam monetisation
   features.

3. **Equip is immediate and persistent**: `set_equipped_skin()` writes to disk immediately.
   No "Apply" / "Cancel" pattern. The player taps "Equip" and it sticks.

4. **Equipping current skin is a no-op visually**: The Equip button is disabled when the
   selected skin is already equipped. This prevents confusion.

5. **`unlock_hint` may be missing**: If `SkinData.unlock_hint` is empty, show nothing
   below the locked skin card — no empty label visible.

6. **No receive_scene_params**: This screen never needs initialisation params from its
   callers.

7. **Back uses `go_to` not `go_back`**: Since this screen is always navigated to from Main
   Menu (`MAIN_MENU → SKIN_SELECT`), the back destination is always Main Menu. Use
   `SceneManager.go_to(Screen.MAIN_MENU)` explicitly.

---

## Edge Cases

| Edge Case                                             | Behaviour                                                                              |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Only one skin in database                             | Grid shows one card; Equip button always disabled (it's the default, already equipped) |
| All skins unlocked                                    | No lock overlays; all cards are tappable                                               |
| `equipped_skin_id` in save does not exist in database | `CosmeticDatabase.get_skin()` falls back to default; screen loads normally             |
| `unlock_hint` is empty on a locked SkinData           | Lock icon shown, no hint text label rendered                                           |
| Player tabs "back" before any equip                   | Nothing changes; Main Menu shows previously equipped skin unchanged                    |

---

## Acceptance Criteria

| ID    | Criterion                                                                                         |
| ----- | ------------------------------------------------------------------------------------------------- |
| SS-1  | All skins from `CosmeticDatabase` are displayed in the grid                                       |
| SS-2  | Unlocked skins show their preview texture and name; no lock overlay                               |
| SS-3  | Locked skins show a lock overlay and `unlock_hint` text                                           |
| SS-4  | Currently equipped skin is visually indicated on its card                                         |
| SS-5  | Tapping an unlocked skin selects it and shows a large preview                                     |
| SS-6  | Tapping "Equip" writes the selection to `SaveManager` and marks the new skin as equipped          |
| SS-7  | Equip button is disabled when the selected skin is already equipped                               |
| SS-8  | Equip button is disabled when the selected skin is locked                                         |
| SS-9  | Back button returns to Main Menu                                                                  |
| SS-10 | After equipping a skin and returning to Main Menu, the Main Menu cat sprite reflects the new skin |

---

## Dependencies

| Depends On               | Interface Used                                                                                                     |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Cosmetic / Skin Database | `CosmeticDatabase.get_all_skins()`, `get_skin()`, `get_preview_texture()`; `SkinData.display_name`, `.unlock_hint` |
| Save / Load System       | `SaveManager.get_equipped_skin()`, `get_unlocked_skins()`, `set_equipped_skin()`                                   |
| Scene Manager            | `SceneManager.go_to(Screen.MAIN_MENU)`                                                                             |

---

## Open Questions

| ID   | Question                                                       | Priority | Resolution                                                                                         |
| ---- | -------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------- |
| OQ-1 | Post-jam: add "Watch Ad" / "Purchase" buttons on locked cards? | Low      | Yes, post-jam monetisation layer. Skin Select Screen will need refactoring at that point. Not MVP. |
| OQ-2 | Should equipped skin be saved per session or persist?          | —        | Persists (SaveManager writes to disk on equip). Already resolved.                                  |
