# SFX Manager

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 5 of 22
> **Category**: Audio
> **Priority**: MVP-Polish

---

## Overview

The SFX Manager is a stateless audio playback service. It owns a fixed pool of
`AudioStreamPlayer` nodes, exposes a single-call API for playing sound effects, and
manages the SFX and UI audio buses. Callers pass an `AudioStream` reference; SFX Manager
routes it to the next available pool slot. It never decides _what_ sound to play — that
decision belongs to the system making the call. It only decides _how_ to play it (bus
routing, pooling, volume, mute state).

SFX Manager is a Godot autoload singleton. It has no gameplay, UI, or progression
dependencies.

---

## Player Fantasy

Every sound effect is invisible infrastructure. The player never thinks "the SFX Manager
handled that" — they just feel the soft thud when the cat lands, the crisp click when tiles
light up, the satisfying chime when coverage hits 100%. The SFX Manager's player fantasy is
zero: it should be imperceptible. Its failure mode is a hollow, silent slide — the kind that
makes a puzzle feel cheap, like something is broken. Good SFX infrastructure is what keeps
that silence from ever happening.

---

## Responsibilities

| Responsibility                              | Owned By                                              |
| ------------------------------------------- | ----------------------------------------------------- |
| Maintain AudioStreamPlayer pool             | SFX Manager ✅                                        |
| Route streams to the SFX or UI bus          | SFX Manager ✅                                        |
| Persist SFX volume / mute state             | SFX Manager ✅                                        |
| Decide what stream to play for a game event | Calling system                                        |
| Store AudioStream assets                    | Calling system (via `@export`) or SfxLibrary resource |
| Music playback                              | Music Manager                                         |

---

## Design Rules

1. **Pool, never instantiate at runtime**: All `AudioStreamPlayer` nodes are created once
   in `_ready()`. No new nodes are created during gameplay. If all pool slots are busy, the
   oldest playing sound is interrupted (slot 0 is always the first victim).

2. **Two buses — SFX and UI**: Gameplay sounds (sliding, tile coverage, level complete) go
   to the `SFX` bus. Interface sounds (button presses, screen transitions) go to the `UI`
   bus. Both buses route to Master. This allows independent volume control for each
   category.

3. **Callers pass `AudioStream` resources directly**: There is no string-key event registry
   in SFX Manager. Callers hold `@export var` properties pointing to `.ogg` / `.wav`
   streams and pass them in. A separate `SfxLibrary` resource pattern may be used by
   callers to organise their assets, but SFX Manager has no knowledge of it.

4. **Pitch randomisation is opt-in**: `play()` accepts an optional `pitch_scale` parameter
   defaulting to `1.0`. Callers that want subtle variation pass a value in `[0.9, 1.1]`.
   SFX Manager does not apply hidden randomisation.

5. **Volume is stored in SFX Manager, not in SaveManager**: SFX volume preference is held
   in memory and written to Godot's built-in `ConfigFile` at `user://settings.cfg` — a
   separate, lightweight settings file kept distinct from the game save. This avoids
   coupling audio settings to the play-data save schema.

6. **Persistence on change**: Volume and mute state are written to disk immediately on each
   setter call. Values are loaded in `_ready()` before any other autoload reads them.

7. **Graceful null guard**: If a caller passes `null` as the stream, `play()` logs a
   warning and returns without playing. This prevents crashes during asset loading gaps in
   development.

---

## Audio Bus Layout

| Bus Name | Parent | Used For                                  |
| -------- | ------ | ----------------------------------------- |
| `Master` | —      | Final output, system volume               |
| `SFX`    | Master | Gameplay sounds                           |
| `UI`     | Master | Button taps, screen transitions           |
| `Music`  | Master | Background music (owned by Music Manager) |

Bus layout is authored in Godot's Audio Bus editor and shipped as the default
`res://default_bus_layout.tres`. SFX Manager reads bus indices by name at runtime using
`AudioServer.get_bus_index(&"SFX")` and `AudioServer.get_bus_index(&"UI")`.

---

## Pool Configuration

| Parameter       | Value            | Rationale                                                                                   |
| --------------- | ---------------- | ------------------------------------------------------------------------------------------- |
| SFX pool size   | 8 slots          | NekoDash maximum concurrent sounds: slide + tile cover × tiles (burst) + level complete ≤ 8 |
| UI pool size    | 4 slots          | UI sounds rarely overlap                                                                    |
| Overflow policy | Interrupt oldest | Prevents silent failures; oldest slot is always index 0 in iteration                        |

---

## Initialization

`_ready() -> void`

1. Load settings from `user://settings.cfg`; if absent, use defaults
   (`sfx_volume_db = 0.0`, `sfx_muted = false`, `ui_volume_db = 0.0`, `ui_muted = false`)
2. Create 8 `AudioStreamPlayer` nodes, assign bus `"SFX"`, add as children
3. Create 4 `AudioStreamPlayer` nodes, assign bus `"UI"`, add as children
4. Apply loaded volume and mute state to both buses via `AudioServer`

---

## Core Playback

### `play(stream: AudioStream, pitch_scale: float = 1.0) -> void`

Routes to the **SFX** bus pool.

```
if stream == null:
    push_warning("SFX Manager: play() called with null stream")
    return

for player in _sfx_pool:
    if not player.playing:
        player.stream = stream
        player.pitch_scale = pitch_scale
        player.play()
        return

# All slots busy — interrupt oldest (index 0)
_sfx_pool[0].stream = stream
_sfx_pool[0].pitch_scale = pitch_scale
_sfx_pool[0].play()
```

### `play_ui(stream: AudioStream) -> void`

Same logic, but iterates `_ui_pool`. No pitch randomisation parameter — UI sounds always
play at `pitch_scale = 1.0`.

---

## Public Interface

### Methods

| Method           | Signature                                                 | Description                                              |
| ---------------- | --------------------------------------------------------- | -------------------------------------------------------- |
| `play`           | `(stream: AudioStream, pitch_scale: float = 1.0) -> void` | Play a sound effect on the SFX bus                       |
| `play_ui`        | `(stream: AudioStream) -> void`                           | Play a UI sound on the UI bus                            |
| `set_sfx_volume` | `(volume_db: float) -> void`                              | Set SFX bus volume; clamp to [-60, 6]; write to settings |
| `set_ui_volume`  | `(volume_db: float) -> void`                              | Set UI bus volume; clamp to [-60, 6]; write to settings  |
| `set_sfx_muted`  | `(muted: bool) -> void`                                   | Mute/unmute SFX bus; write to settings                   |
| `set_ui_muted`   | `(muted: bool) -> void`                                   | Mute/unmute UI bus; write to settings                    |
| `get_sfx_volume` | `() -> float`                                             | Current SFX bus volume in dB                             |
| `get_ui_volume`  | `() -> float`                                             | Current UI bus volume in dB                              |
| `is_sfx_muted`   | `() -> bool`                                              | Current SFX mute state                                   |
| `is_ui_muted`    | `() -> bool`                                              | Current UI mute state                                    |

### Settings Persistence

Written to `user://settings.cfg` using Godot's `ConfigFile`:

```
[audio]
sfx_volume_db = 0.0
sfx_muted = false
ui_volume_db = 0.0
ui_muted = false
```

Music Manager writes its own entries to the same file under `[audio]` (keys:
`music_volume_db`, `music_muted`). Both managers read and write only their own keys;
neither overwrites the other's entries.

---

## Sound Events Reference

This table documents which game events should play SFX, as a guide for callers. Actual
stream assets are defined by the sound designer and wired up by the calling systems.

| Event                  | Suggested Bus | Calling System                               | Notes                                     |
| ---------------------- | ------------- | -------------------------------------------- | ----------------------------------------- |
| Cat slide starts       | SFX           | Sliding Movement                             | On `slide_started`                        |
| Cat lands / slide ends | SFX           | Sliding Movement                             | On `slide_completed`; pitch-vary slightly |
| Tile covered           | SFX           | Coverage Tracking                            | On `tile_covered`; short tick sound       |
| Level completed        | SFX           | Coverage Tracking (or Level Complete Screen) | On `level_completed`; fanfare             |
| 3-star rating          | SFX           | Level Complete Screen                        | On `rating_computed` with stars = 3       |
| Slide blocked          | SFX           | Sliding Movement                             | On `slide_blocked`; short thud            |
| Undo applied           | SFX           | Undo/Restart                                 | On `undo_applied`                         |
| Level restarted        | SFX           | Undo/Restart                                 | On `level_restarted`                      |
| Button press           | UI            | UI nodes                                     | All menu/HUD button taps                  |
| Screen transition      | UI            | Scene Manager                                | Optional; may skip at MVP                 |

---

## Edge Cases

| Edge Case                             | Behaviour                                                                                     |
| ------------------------------------- | --------------------------------------------------------------------------------------------- |
| `stream == null`                      | `push_warning()` and return; no crash                                                         |
| All pool slots busy                   | Interrupt oldest-playing slot (index 0)                                                       |
| Settings file missing on first launch | Use defaults; file created on first write                                                     |
| Settings file corrupted               | Fallback to defaults; overwrite on next write                                                 |
| `volume_db` out of range              | Clamped to `[-60.0, 6.0]` silently                                                            |
| Bus name not found in layout          | `push_error()` during `_ready()`; pool nodes created with no bus assignment (plays on Master) |

---

## Acceptance Criteria

| ID   | Criterion                                                                                |
| ---- | ---------------------------------------------------------------------------------------- |
| SX-1 | `play(stream)` plays the stream on the SFX bus within the same frame                     |
| SX-2 | `play_ui(stream)` plays on the UI bus, audibly distinct from SFX mix                     |
| SX-3 | Calling `play()` with 8 sounds already playing does not crash; oldest is interrupted     |
| SX-4 | `set_sfx_muted(true)` silences all SFX bus output; `play()` still returns without error  |
| SX-5 | `set_sfx_volume(-12.0)` sets the SFX bus to -12 dB and persists to `user://settings.cfg` |
| SX-6 | After app restart, volume and mute settings are restored from `user://settings.cfg`      |
| SX-7 | `play(null)` logs a warning and does not crash                                           |
| SX-8 | SFX Manager does not reference SaveManager, SceneManager, or any gameplay system         |

---

## Dependencies

None. SFX Manager is a standalone autoload.

---

## Open Questions

| ID   | Question                                                                                                         | Priority | Resolution                                                                                                                                                                   |
| ---- | ---------------------------------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | Should `play()` return the `AudioStreamPlayer` that was chosen, to allow callers to stop it early?               | Low      | Provisional: no — NekoDash has no use case for early stop at MVP. Revisit if a "stop slide sfx" need emerges.                                                                |
| OQ-2 | Settings file shared with Music Manager: should both managers touch `user://settings.cfg`, or should one own it? | Low      | Provisional: both write to the same file, each only their own keys. Only one `ConfigFile` instance per manager (no concurrent write contention in single-threaded GDScript). |
