# Save / Load System

> **Status**: Approved
> **Author**: Grace + GitHub Copilot
> **Last Updated**: 2026-03-31
> **Implements Pillar**: Infrastructure (supports all pillars indirectly)

## Overview

The Save / Load System persists and restores all player progress for NekoDash. It
owns a single save file on disk (`user://nekodash_save.json`) containing: per-level
completion state and best star rating, the currently equipped skin ID, and the set
of unlocked skin IDs. It exposes a clean API — `save()`, `load()`, `get_level_record()`,
`set_level_record()`, `get_equipped_skin()`, `set_equipped_skin()`,
`get_unlocked_skins()`, `unlock_skin()` — used by Level Progression, Star Rating
System, Skin Unlock / Milestone Tracker, and the Skin Select Screen. It is an
autoload singleton (`SaveManager`). Data is written to disk immediately on every
mutation — no deferred flush, no batching — so progress is never lost to a crash
or OS kill. On load, data is validated against a version field; if the file is
corrupt or missing, the system initialises a clean slate without crashing.

## Player Fantasy

The player completes a level, sees three gold stars, and closes the app. The next
day they open it and their stars are still there. That's it. This system has no
player-facing moment of its own — it is invisible infrastructure. Its only failure
mode is noticeable: data loss, or a returning player seeing all their progress wiped.
Getting that wrong is a trust-destroying event in a mobile game. Getting it right
is unremarkable and correct.

The design goal is **zero data loss on all normal exits plus graceful recovery on
corruption**. Mobile OSes kill apps without warning; the immediate-write model
(write on every change, not on exit) is the only safe approach.

## Detailed Design

### Core Rules

1. **Autoload singleton**: `SaveManager` is registered as a Godot autoload. All other
   systems access it via `SaveManager.method_name()`. It has no scene dependency and
   no node lifecycle.

2. **Single file, JSON format**: Data is stored at `user://nekodash_save.json` using
   Godot's `FileAccess` (not the deprecated `File`). JSON is human-readable for
   debugging and avoids binary format compatibility issues across Godot versions.

3. **Immediate write**: Every call to a setter (`set_level_record()`,
   `set_equipped_skin()`, `unlock_skin()`) calls `_write_to_disk()` before returning.
   No deferred flush. This protects against mobile app-kill data loss at the cost of
   negligible I/O (file is small — 15–20 levels × a few fields).

4. **Load on startup**: `SaveManager._ready()` calls `load()` automatically. If the
   file does not exist, `_init_default_save()` is called and the default state is
   written to disk. If the file exists but fails validation, the corrupt file is
   renamed to `nekodash_save.corrupt.json` (preserved for debugging) and a fresh
   default save is written. No crash, no silent data loss.

5. **Version field**: The save file includes `"version": 1`. If a loaded file has a
   mismatched or missing version, it is treated as corrupt (Rule 4). This provides a
   migration hook for future schema changes.

6. **In-memory cache**: After loading, all data is held in a `_data: Dictionary`
   in memory. Getters read from `_data`. Setters mutate `_data` then write to disk.
   Disk reads only happen at startup (or after corruption recovery).

7. **Level records**: Each level's record is stored under its level ID (string key).
   A record contains: `completed: bool`, `best_stars: int` (0–3), and optionally
   `best_moves: int` (the player's personal best move count; 0 if never completed).
   Star ratings are stored as the best achieved — never decremented.

8. **Best moves**: `best_moves` only updates when the new `final_move_count < stored
best_moves` (or `best_moves == 0` for a first completion). It never increases. A
   lower move count on a fresh attempt replaces the record. Stars follow the same
   best-only logic.

9. **Skin data**: `equipped_skin_id: String` holds the currently active skin.
   `unlocked_skin_ids: Array[String]` holds all skins the player has earned. The
   default skin (`"cat_default"`) is always present in `unlocked_skin_ids` and is
   the initial `equipped_skin_id`. Skins are never removed once unlocked.

10. **No active-level state**: The Save system does NOT persist mid-level state
    (current tile position, current move count, undo history). These are in-memory
    only. A killed app during a level returns the player to the level select screen
    with that level's previous best record intact. Mid-level progress is intentionally
    not persisted at MVP — levels are short enough that replaying from scratch is
    acceptable.

11. **Read-only check**: `is_level_completed(level_id: String) -> bool` and
    `get_best_stars(level_id: String) -> int` are convenience read methods used
    frequently by Level Progression and World Map to populate UI. These never write.

### Save File Schema

```json
{
  "version": 1,
  "levels": {
    "world1_level1": { "completed": true, "best_stars": 3, "best_moves": 8 },
    "world1_level2": { "completed": true, "best_stars": 2, "best_moves": 14 },
    "world1_level3": { "completed": false, "best_stars": 0, "best_moves": 0 }
  },
  "equipped_skin_id": "cat_cozy",
  "unlocked_skin_ids": ["cat_default", "cat_cozy"]
}
```

All level IDs are strings matching `LevelData.level_id` exactly. IDs that appear in
the save file but have no corresponding `LevelData` resource are silently ignored
(handles removed/renamed levels in post-jam updates).

### Public API

| Method                                                                                | Returns                               | Description                                                                                              |
| ------------------------------------------------------------------------------------- | ------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `load() -> void`                                                                      | —                                     | (called in `_ready`) Loads file, validates, initializes default if missing/corrupt.                      |
| `save() -> void`                                                                      | —                                     | Writes `_data` to disk immediately. Called automatically by all setters; rarely needed externally.       |
| `get_level_record(level_id: String) -> Dictionary`                                    | `{completed, best_stars, best_moves}` | Returns the record for the level; returns default values if unseen.                                      |
| `set_level_record(level_id: String, completed: bool, stars: int, moves: int) -> void` | —                                     | Updates the record if `stars > previous` or `moves < previous best`. Writes to disk.                     |
| `is_level_completed(level_id: String) -> bool`                                        | `bool`                                | Convenience read; returns `false` for unseen levels.                                                     |
| `get_best_stars(level_id: String) -> int`                                             | `int` (0–3)                           | Convenience read; returns `0` for unseen levels.                                                         |
| `get_best_moves(level_id: String) -> int`                                             | `int`                                 | Returns personal best move count; `0` if never completed.                                                |
| `get_equipped_skin() -> String`                                                       | `String`                              | Returns the current skin ID.                                                                             |
| `set_equipped_skin(skin_id: String) -> void`                                          | —                                     | Sets equipped skin if `skin_id` is in `unlocked_skin_ids`. Writes to disk. Logs warning if not unlocked. |
| `get_unlocked_skins() -> Array[String]`                                               | `Array`                               | Returns copy of unlocked skin ID list.                                                                   |
| `unlock_skin(skin_id: String) -> void`                                                | —                                     | Adds `skin_id` to `unlocked_skin_ids` if not already present. Writes to disk. Emits `skin_unlocked`.     |
| `reset_all_progress() -> void`                                                        | —                                     | **DEBUG ONLY** — clears all data, reinitialises to default, writes to disk. Disabled in release builds.  |

### Signals

| Signal                                   | Description                                                                  |
| ---------------------------------------- | ---------------------------------------------------------------------------- |
| `level_record_updated(level_id: String)` | Emitted after `set_level_record()` writes a new best.                        |
| `skin_unlocked(skin_id: String)`         | Emitted after `unlock_skin()` successfully adds a new skin.                  |
| `save_loaded`                            | Emitted after `load()` completes (success or default init).                  |
| `save_corrupted`                         | Emitted if the save file was corrupt; UI can show a "progress reset" notice. |

### States and Transitions

| State        | Entry Condition                             | Exit Condition                      | Behavior                                                         |
| ------------ | ------------------------------------------- | ----------------------------------- | ---------------------------------------------------------------- |
| **Unloaded** | Autoload registered, `_ready()` not yet run | `_ready()` completes                | All getters return default values; setters log warning, no-op    |
| **Loaded**   | `load()` completes successfully             | App exit / never exits normally     | All reads from `_data`; writes to `_data` + disk on every setter |
| **Corrupt**  | File exists but fails validation            | Corruption handled, default written | Transient state; exits immediately to Loaded with default data   |

### Interactions with Other Systems

| System                              | Direction                       | Interface                                                                                                                             |
| ----------------------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Level Progression**               | Level Progression → SaveManager | Calls `set_level_record()` after level complete; reads `is_level_completed()` + `get_best_stars()` to determine unlock state.         |
| **Star Rating System**              | Star Rating → SaveManager       | Provides `final_stars` and `final_moves` to Level Progression, which calls `set_level_record()`. Star Rating does NOT write directly. |
| **Skin Unlock / Milestone Tracker** | Milestone Tracker → SaveManager | Calls `unlock_skin()` when a milestone is hit; reads `get_best_stars()` and completion counts to evaluate unlock conditions.          |
| **Skin Select Screen**              | Skin Select → SaveManager       | Reads `get_unlocked_skins()` and `get_equipped_skin()` to populate UI; calls `set_equipped_skin()` on player selection.               |
| **Main Menu**                       | Main Menu → SaveManager         | Reads `get_equipped_skin()` to show the player's cat on the main menu; reads save state to decide "Continue" vs "New Game" prompt.    |
| **World Map / Level Select**        | World Map → SaveManager         | Reads `is_level_completed()` and `get_best_stars()` for every level to render lock/unlock state and star display.                     |
| **Scene Manager**                   | Scene Manager → (none direct)   | Scene Manager does not interact with SaveManager directly; Level Progression mediates the post-level save write.                      |

## Formulas

### Best Star Update Rule

```
if new_stars > stored_best_stars:
    stored_best_stars = new_stars
    stored_completed  = true
```

Stars only ever increase. A 1-star re-run never overwrites a 3-star record.

### Best Moves Update Rule

```
if stored_best_moves == 0 or new_moves < stored_best_moves:
    stored_best_moves = new_moves
```

Best moves only update on improvement (lower count) or first completion.

### File Size Estimate

```
~100 bytes/level × 20 levels = ~2 KB
+ skin data ~200 bytes
+ version/metadata ~50 bytes
≈ ~2.5 KB total
```

Negligible. Immediate-write I/O is safe at this scale.

## Edge Cases

| Scenario                                                                | Expected Behavior                                                                                        | Rationale                                                                   |
| ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| File does not exist (first launch)                                      | `_init_default_save()` creates default data; writes file; emits `save_loaded`                            | Normal first-run path                                                       |
| File exists but JSON is malformed (truncated write, corruption)         | Corrupt file renamed to `nekodash_save.corrupt.json`; default data initialized; `save_corrupted` emitted | Preserve the corrupt file for debugging; never crash                        |
| File exists, valid JSON, but `"version"` field is missing or wrong      | Treated as corrupt (same path as malformed JSON)                                                         | Version mismatch means unknown schema; safest to reset                      |
| `set_level_record()` called with lower stars than current best          | No update to stars; `level_record_updated` NOT emitted; moves still update if improved                   | Best-only semantics; never regress star count                               |
| `set_equipped_skin()` called with a skin not in `unlocked_skin_ids`     | Logs a warning; does not change `equipped_skin_id`; does not write to disk                               | Guard against programmer error; equipping a locked skin should never happen |
| `unlock_skin()` called with an already-unlocked skin ID                 | No-op; `skin_unlocked` NOT emitted; no disk write                                                        | Idempotent; callers need not check before calling                           |
| App killed by OS mid-write (power loss, force-quit)                     | File may be partially written → treated as corrupt on next launch (fallback path handles it)             | Atomic write via temp file is the mitigation (see note below)               |
| `get_level_record()` called for a level ID not yet in save data         | Returns `{ "completed": false, "best_stars": 0, "best_moves": 0 }` — default record                      | Unseen levels default gracefully; no crash, no null                         |
| Save file has an entry for a `level_id` not in any `LevelData` resource | Entry silently ignored; does not appear in any query                                                     | Handles levels removed between app versions                                 |
| `reset_all_progress()` called in a release build                        | Method is gated behind `OS.is_debug_build()`; no-op in release with warning log                          | Safety guard; must not be callable in shipped builds                        |

### Atomic Write Note

To guard against OS-kill mid-write corrupting the save file: write to
`user://nekodash_save.tmp` first, then rename it over `nekodash_save.json` using
`DirAccess.rename()`. Godot's `FileAccess` does not provide atomic rename natively
on all platforms, so this is best-effort; the corruption fallback (Rule 4) handles
the rare failure case without data loss beyond the current session.

## Dependencies

| System                  | Direction                       | Nature                                                                                                 | Hard/Soft                                                                                                       |
| ----------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| **Godot FileAccess**    | SaveManager → Godot             | Uses `FileAccess.open()` for read/write; `DirAccess.rename()` for atomic swap; `JSON.parse()` for read | **Hard** — no alternative I/O path                                                                              |
| **Level Progression**   | Level Progression → SaveManager | Calls `set_level_record()` after level complete; this is the primary write trigger                     | **Soft** for SaveManager itself — SaveManager functions without Level Progression, but records won't be written |
| **Skin unlock systems** | Milestone Tracker → SaveManager | Calls `unlock_skin()` to persist rewards                                                               | **Soft** — game functions without skins; progression persists independently                                     |

## Tuning Knobs

No runtime tuning knobs. The save schema is defined by the API and cannot be modified
without a version bump. All authoring-time parameters for what gets saved are
determined by the schema documented above.

| Future knob (post-jam)         | Description                                                                                         |
| ------------------------------ | --------------------------------------------------------------------------------------------------- |
| Cloud save sync (post-jam)     | `user://` save is the ground truth; cloud sync is additive, not a replacement                       |
| Multiple save slots (post-jam) | File path parameterised to `user://nekodash_save_{slot}.json`; API extended                         |
| Encryption (post-jam IAP)      | If IAP skins are introduced, consider encrypting `unlocked_skin_ids` to prevent trivial hex-editing |

## Visual/Audio Requirements

None. Save / Load is entirely invisible infrastructure with no in-game visuals or
audio of its own. The `save_corrupted` signal may optionally drive a transient UI
notice ("Your save data was reset") in the Main Menu — that is a Main Menu concern,
not SaveManager's.

## UI Requirements

None directly. SaveManager exposes data; World Map, Level Select, Skin Select Screen,
and Main Menu consume it for their own display needs. SaveManager does not own any
UI nodes.

## Acceptance Criteria

| #     | Criterion                                                                                                                                                        |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SL-1  | On first launch, `user://nekodash_save.json` does not exist → after startup, file is created with default data and `save_loaded` is emitted.                     |
| SL-2  | After `set_level_record("world1_level1", true, 3, 8)`, the file on disk contains `"completed": true, "best_stars": 3, "best_moves": 8`.                          |
| SL-3  | After SL-2, calling `set_level_record("world1_level1", true, 1, 12)` does not decrease `best_stars` (stays 3) but does not update `best_moves` either (stays 8). |
| SL-4  | After SL-2, calling `set_level_record("world1_level1", true, 3, 6)` updates `best_moves` to 6.                                                                   |
| SL-5  | A corrupt save file is renamed `nekodash_save.corrupt.json`; fresh default data is loaded; `save_corrupted` is emitted; app does not crash.                      |
| SL-6  | `get_level_record("unseen_level")` returns `{ completed: false, best_stars: 0, best_moves: 0 }` without error.                                                   |
| SL-7  | `unlock_skin("cat_cozy")` adds the skin once to `unlocked_skin_ids` and emits `skin_unlocked`; calling it again is a no-op with no signal.                       |
| SL-8  | `set_equipped_skin("cat_locked")` where `"cat_locked"` is not in `unlocked_skin_ids` logs a warning and does not change the equipped skin.                       |
| SL-9  | `reset_all_progress()` resets all data to default when called in a debug build; no-ops in a release build.                                                       |
| SL-10 | `"cat_default"` is always present in `unlocked_skin_ids` in every valid save state (default init, post-corrupt reset, and after any number of unlocks).          |

## Open Questions

| #    | Question                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | Priority          | Owner                                                                                                                                | Resolution                     |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------ |
| OQ-1 | Should `best_moves` be stored even for 0-star completions (player finishes the level but over the `star_1_moves` threshold)? Provisional: yes — any completion updates `best_moves` regardless of star count. A "completed" record is any state where `completed == true`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | Low               | Resolve during Level Progression GDD                                                                                                 | Provisional: yes, always store |
| OQ-2 | Atomic write via temp-file + rename: Godot's `DirAccess.rename()` is not guaranteed atomic on all mobile platforms. If the tmp-file approach proves unreliable on Android/iOS, fall back to writing directly and relying on the corruption-recovery path. Flag for real-device testing.                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Medium            | Resolve during devops / build verification                                                                                           | Open — test on device          |
| OQ-3 | Should `SaveManager` emit a `progress_loaded(summary)` signal with a high-level summary (total stars, levels completed) that Main Menu can display without iterating all records? Provisional: no at MVP — Main Menu can query directly; add if Main Menu GDD needs it.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Low               | Resolve during Main Menu GDD                                                                                                         | Provisional: no                |
| OQ-4 | **Post-jam: save file anti-cheat.** Currently `user://nekodash_save.json` is plain JSON; a player can edit it directly to grant stars, unlock all skins, or set move counts. Options: **(a) HMAC checksum** — append an HMAC-SHA256 of the serialised JSON using a key embedded at build time; reject loads where the checksum mismatches (easy to implement via Godot's `Crypto` class, meaningful deterrent without online infra). **(b) XOR/base64 obfuscation** — obscures casual inspection but provides no real security. **(c) Server-side save** — authoritative but requires online infra. For an offline mobile game, option (a) is the recommended minimum. Detected tampering should reset the save with a warning rather than hard-crashing. | Medium (Post-jam) | Design before post-jam release if leaderboards or competitive progression is added. Otherwise low priority for a single-player game. | Open                           |
