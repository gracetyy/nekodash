# Music Manager

> **Status**: Approved
> **Created**: 2026-03-31
> **Last Updated**: 2026-03-31
> **System #**: 10 of 22
> **Category**: Audio
> **Priority**: MVP-Polish

---

## Overview

Music Manager is the sole owner of background music playback. It subscribes to Scene
Manager's `world_changed` and `transition_completed` signals to select the right ambient
track for each context, cross-fades between tracks using a two-player Tween approach, and
persists music volume and mute preference in `user://settings.cfg` alongside SFX Manager's
entries.

Music Manager is a Godot autoload singleton. Its only runtime dependency is SceneManager
(also an autoload), subscribed to via signal at `_ready()`.

---

## Player Fantasy

The music is the room the puzzle lives in. When the player taps into a new world, the warm
ambient track that fades in is not decoration — it's atmosphere. It signals that this set of
puzzles has its own identity. The Level Complete sting is the punctuation: a quick celebratory
hit that says "you did it" before the screen even finishes loading. Silence on the Main Menu
would feel empty; the wrong track on a hard world would feel wrong in a way the player
couldn't name. The Music Manager is invisible when working perfectly. The player just feels
like the game has soul.

---

## Responsibilities

| Responsibility                     | Owned By                                      |
| ---------------------------------- | --------------------------------------------- |
| Background music playback          | Music Manager ✅                              |
| Track selection per screen / world | Music Manager ✅                              |
| Cross-fade between tracks          | Music Manager ✅                              |
| Music bus volume and mute          | Music Manager ✅                              |
| Persist music settings             | Music Manager ✅                              |
| Sound effects                      | SFX Manager                                   |
| Scene transitions                  | Scene Manager                                 |
| Streaming large audio from server  | Out of scope — all tracks ship bundled at MVP |

---

## Design Rules

1. **Two `AudioStreamPlayer` nodes for cross-fading**: `_player_a` and `_player_b` are
   created at `_ready()`, both assigned to the `Music` bus. One is always "active"; the
   other is "incoming". On a track change, the incoming player starts the new track, a
   Tween fades out the active player and fades in the incoming player simultaneously, then
   the roles swap. This avoids a silent gap between tracks.

2. **Screen-to-track mapping**: Each screen has an associated track category:

   | Screen           | Track                                                                                             |
   | ---------------- | ------------------------------------------------------------------------------------------------- |
   | `MAIN_MENU`      | `_track_menu`                                                                                     |
   | `WORLD_MAP`      | `_track_menu` (reuse; same calm ambient feel)                                                     |
   | `GAMEPLAY`       | Per-world track (from `_world_tracks` dictionary, keyed by `world_id` string)                     |
   | `LEVEL_COMPLETE` | `_track_level_complete` (short sting; loops=false; after finish: silence or return to menu track) |
   | `SKIN_SELECT`    | `_track_menu`                                                                                     |
   | `LOADING`        | No music change (carry over from previous)                                                        |

3. **`world_changed` drives in-gameplay track changes**: When `SceneManager` emits
   `world_changed(world_id: String)`, Music Manager looks up the matching track in
   `_world_tracks`. If the same track is already playing, it does nothing (no restart).
   If a different track (or no track) is playing, it cross-fades.

4. **`transition_completed` drives non-gameplay track changes**: Music Manager subscribes
   to `transition_completed(screen)`. When `screen` is not `GAMEPLAY` and not `LOADING`,
   it selects the appropriate track from the mapping above and cross-fades.

5. **Same-track guard**: If the incoming track is already the currently playing track
   (same `AudioStream` reference), Music Manager aborts the cross-fade — no restart, no
   gap.

6. **Loop flag**: Gameplay tracks and menu tracks loop (`loop = true`). The Level Complete
   sting does **not** loop. After the sting finishes, Music Manager sets the active player
   to null and emits nothing — silence until the next transition.

7. **Null-track fallback**: Any screen or world with no configured track plays silence.
   `play_track(null)` stops the current track with a fade and leaves both players idle.

8. **Cross-fade duration**: Default `CROSS_FADE_DURATION = 1.0` seconds. Constant —
   not configurable at MVP. The Level Complete sting has no in-fade (starts immediately
   at full volume) because it is a celebratory hit that must land on time.

9. **Volume and mute stored in `user://settings.cfg`**: Music Manager reads and writes
   keys `music_volume_db` (default `0.0`) and `music_muted` (default `false`) in the
   `[audio]` section. It shares the file with SFX Manager but touches only its own keys.

10. **No mid-fade interruption stacking**: If a cross-fade Tween is in progress when a
    new track change is requested, the existing Tween is killed, both players are snapped
    to their final volumes (old player to -80 dB and stopped, new player to the desired
    volume), and the new cross-fade begins immediately. This prevents tween accumulation
    from repeated rapid transitions.

---

## Track Asset Structure

Music Manager holds `@export` properties for each track. These are wired in the Godot
editor or via the autoload scene:

```gdscript
@export var track_menu: AudioStream          # Main Menu, World Map, Skin Select
@export var track_level_complete: AudioStream  # Level Complete sting (no loop)
@export var world_tracks: Dictionary          # String(world_id) → AudioStream
                                              # e.g. { "1": preload("res://audio/music/world1.ogg"),
                                              #        "2": preload("res://audio/music/world2.ogg"),
                                              #        "3": preload("res://audio/music/world3.ogg") }
```

`world_tracks` uses `String` keys because `SceneManager.world_changed` passes `world_id`
as a `String` (converted from `LevelData.world_id: int` via `str()`). Music Manager does
not convert to int — it uses the String as-is for the dictionary lookup.

---

## Initialization

`_ready() -> void`

1. Load settings from `user://settings.cfg`; apply `music_volume_db` and `music_muted` to
   the `Music` bus via `AudioServer`.
2. Create `_player_a` and `_player_b` as `AudioStreamPlayer` children, both on the
   `Music` bus.
3. Connect to `SceneManager.world_changed` and `SceneManager.transition_completed`.
4. Set `_active_player = _player_a`, `_incoming_player = _player_b`.
5. Start `track_menu` immediately (app opens on Main Menu).

---

## Core Cross-Fade

`_play_track(stream: AudioStream) -> void` — private

```
if stream == _active_player.stream and _active_player.playing:
    return  # same track already playing — no-op

# Kill any in-progress Tween
if _fade_tween != null and _fade_tween.is_valid():
    _fade_tween.kill()
    _incoming_player.stop()
    _active_player.volume_db = _target_volume_db()

# Set up incoming player
_incoming_player.stream = stream
_incoming_player.volume_db = -80.0

if stream == null:
    # Fade out active only
    _fade_tween = create_tween()
    _fade_tween.tween_property(_active_player, "volume_db", -80.0, CROSS_FADE_DURATION)
    await _fade_tween.finished
    _active_player.stop()
    return

_incoming_player.play()

# Cross-fade
_fade_tween = create_tween().set_parallel(true)
_fade_tween.tween_property(_active_player, "volume_db", -80.0, CROSS_FADE_DURATION)
_fade_tween.tween_property(_incoming_player, "volume_db", _target_volume_db(), CROSS_FADE_DURATION)
await _fade_tween.finished

_active_player.stop()
# Swap roles
var tmp := _active_player
_active_player = _incoming_player
_incoming_player = tmp
```

`_target_volume_db() -> float`: returns `-80.0` if muted, else `_music_volume_db`.

---

## Public Interface

### Methods

| Method             | Signature                    | Description                                                  |
| ------------------ | ---------------------------- | ------------------------------------------------------------ |
| `set_music_volume` | `(volume_db: float) -> void` | Clamp to `[-60, 6]`; apply to Music bus; persist to settings |
| `set_music_muted`  | `(muted: bool) -> void`      | Mute/unmute Music bus; persist to settings                   |
| `get_music_volume` | `() -> float`                | Current music volume in dB                                   |
| `is_music_muted`   | `() -> bool`                 | Current music mute state                                     |

No `play_track()` public method — track selection is fully driven by Scene Manager signals.
External callers have no reason to override the ambient track at MVP.

### Signals

None emitted. Music Manager is a pure consumer of Scene Manager signals.

---

## Edge Cases

| Edge Case                                                         | Behaviour                                                                                                                                                       |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `world_changed` fires for a world with no entry in `world_tracks` | Play silence (fade out current track); `push_warning()`                                                                                                         |
| `transition_completed` fires with `LOADING`                       | No track change; carry over current track                                                                                                                       |
| Level Complete sting has no asset assigned                        | Silent; `push_warning()`                                                                                                                                        |
| Level Complete sting finishes (no loop)                           | Silence is intentional; the player is expected to navigate away within seconds. Menu track resumes on the next `transition_completed` signal (e.g., World Map). |
| Cross-fade Tween interrupted by rapid scene changes               | Kill tween, snap volumes, begin new fade                                                                                                                        |
| App loses focus (mobile background)                               | Godot's Audio Server handles OS mute automatically; no special handling needed at MVP                                                                           |
| All tracks `null` on startup                                      | Both players idle; silence; no crash                                                                                                                            |

---

## Acceptance Criteria

| ID   | Criterion                                                                                                                                  |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| MM-1 | Menu track begins playing when the app starts (Main Menu scene)                                                                            |
| MM-2 | Navigating to a Gameplay scene triggers `world_changed`; the corresponding world track cross-fades in within `CROSS_FADE_DURATION` seconds |
| MM-3 | Navigating to the same world twice in a row does not restart or re-fade the track                                                          |
| MM-4 | Navigating from Gameplay back to World Map cross-fades back to the menu track                                                              |
| MM-5 | Level Complete screen plays the complete sting exactly once, without looping                                                               |
| MM-6 | `set_music_muted(true)` silences audio immediately; track position is maintained                                                           |
| MM-7 | After app restart, music volume and mute state are restored from `user://settings.cfg`                                                     |
| MM-8 | Rapid screen transitions (faster than cross-fade duration) do not cause music glitches or piled-up Tweens                                  |
| MM-9 | `world_changed` with an unmapped world_id plays silence and logs a warning                                                                 |

---

## Dependencies

| Depends On    | Interface Used                                                                    |
| ------------- | --------------------------------------------------------------------------------- |
| Scene Manager | `world_changed(world_id: String)`, `transition_completed(screen: Screen)` signals |

---

## Open Questions

| ID   | Question                                                                                                                       | Priority | Resolution                                                                                                                            |
| ---- | ------------------------------------------------------------------------------------------------------------------------------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| OQ-1 | What should happen to music after the Level Complete sting finishes — silence, return to world track, or return to menu track? | Medium   | Provisional: silence after sting. The Level Complete Screen leads to World Map; music resumes on `transition_completed` to World Map. |
| OQ-2 | Should the Level Complete sting overlap the gameplay world track (duck/crossfade) or replace it?                               | Low      | Provisional: replace with crossfade — sting starts at full volume, world track fades out simultaneously.                              |
