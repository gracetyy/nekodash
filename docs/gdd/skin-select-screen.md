# Skin Select Screen

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 23 of 23
> **Category**: UI
> **Priority**: MVP-Skins

---

## Overview

The Skin Select Screen currently acts as a placeholder gallery. It shows a small set of
skin cards, lets the player preview the selected cat, and keeps the Equip CTA disabled
until the full unlock/equip flow is wired to `CosmeticDatabase` and `SaveManager`. It
exists to keep the cosmetic entry point visible without pretending the feature is
complete.

---

## Player Fantasy

My cats. A small, deliberate gallery that previews the cosmetic system before it is fully
wired. The player can browse the cards, see the current selection reflected in the preview,
and understand where unlock hints and equip actions will eventually live. Right now the
screen is a safe staging area for the future trophy case.

---

## Responsibilities

| Responsibility                      | Owned By                 |
| ----------------------------------- | ------------------------ |
| Display placeholder skin cards      | Skin Select Screen ✅    |
| Preview the currently selected skin | Skin Select Screen ✅    |
| Keep Equip CTA disabled for now     | Skin Select Screen ✅    |
| Reserve space for unlock hint text  | Skin Select Screen ✅    |
| Navigate back to Main Menu          | Skin Select Screen ✅    |
| Skin definitions and textures       | Cosmetic / Skin Database |
| Unlock state                        | Save / Load System       |

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

| Element                | Source                            | Notes                                            |
| ---------------------- | --------------------------------- | ------------------------------------------------ |
| **Skin grid**          | Hard-coded placeholder skin cards | One card per skin; scrollable grid               |
| **Skin preview**       | Selected placeholder card         | Shown in each card and in the large preview area |
| **Skin name**          | Placeholder data                  | Label on each card                               |
| **Equipped indicator** | `SaveManager.get_equipped_skin()` | Highlight/badge on the currently equipped skin   |
| **Lock icon**          | Visual placeholder                | Overlay on cards that are not yet wired          |
| **Unlock hint**        | Placeholder text                  | Not yet driven by milestone data                 |
| **Large preview**      | Currently selected skin           | Right panel or overlay; updates on card tap      |
| **Equip button**       | Disabled                          | Present in layout, not active yet                |
| **Back button**        | Static                            | Returns to Main Menu                             |

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

## Tuning Knobs

None at MVP. No runtime-configurable parameters.

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
