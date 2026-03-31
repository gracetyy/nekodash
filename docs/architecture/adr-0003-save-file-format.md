# ADR-0003: Save File Format

## Status

Accepted

## Date

2026-03-31

## Context

### Problem Statement

NekoDash must persist player progress across sessions on mobile devices. Godot exposes multiple persistence options (JSON via `FileAccess`, `ConfigFile`, binary via `FileAccess`, `PackedByteArray`, Godot Resource `.tres`). A deliberate choice of format must be recorded to prevent inconsistent format usage as the codebase grows, and to document the corruption-recovery and migration strategy.

### Constraints

- Mobile OSes (Android, iOS) can kill the app at any time without calling `_exit_tree()` — data must be written immediately on every change, not on exit.
- Save data is small at MVP scope (~15–20 levels × a few fields, 2–3 skin IDs) — performance is not a driving concern.
- Future schema changes (post-jam content additions, post-jam anti-cheat) must be possible without wiping existing player saves.
- No server infrastructure — all persistence is local device storage only.
- Godot 4.3 `user://` directory is the correct cross-platform persistent storage path.

### Requirements

- Must be human-readable for development debugging (inspecting saves in a text editor).
- Must survive an app kill mid-write without corrupting the entire save (or detect and recover from corruption).
- Must include a version field to support future schema migrations.
- Must not persist mid-level transient state (current tile position, undo history) — levels are short enough that replaying from scratch is acceptable.

## Decision

**Save data is stored as JSON at `user://nekodash_save.json`, written via Godot's `FileAccess` API. Every setter call writes the entire file immediately. On load, the file is validated against a version field and a structural schema check; if validation fails, the corrupt file is renamed and a fresh default save is created.**

### File Path and Format

```
user://nekodash_save.json
```

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

- **Top-level keys**: `version` (int), `levels` (Dictionary), `equipped_skin_id` (String), `unlocked_skin_ids` (Array[String]).
- **Level keys**: String matching `LevelData.level_id` exactly (e.g., `"world1_level3"`).
- **Level values**: `completed` bool, `best_stars` int 0–3, `best_moves` int (0 = never completed).

### Write Strategy: Immediate Write on Every Setter

Every call to `set_level_record()`, `set_equipped_skin()`, or `unlock_skin()` serialises the full in-memory `_data` Dictionary and overwrites the file before returning. No buffering, no deferred flush.

```gdscript
func set_level_record(level_id: String, completed: bool, stars: int, moves: int) -> void:
    # ... mutate _data ...
    _write_to_disk()  # synchronous, before return
```

The file is small enough (~1–4 KB at full progression) that the full-rewrite cost is negligible on all target platforms.

### Corruption Recovery Strategy

On `_ready()`, `SaveManager` calls `_load_from_disk()`:

1. If the file does not exist → `_init_default_save()` and write.
2. If the file exists:
   a. Parse JSON. If parse fails → **corrupt**: rename to `nekodash_save.corrupt.json`, `_init_default_save()`, emit `save_corrupted`.
   b. If parsed but `version` field is missing or mismatched → **corrupt**: same recovery path.
   c. If parsed and version matches → validate required keys. Missing top-level keys → `_init_default_save()`.
   d. Valid → load into `_data`, emit `save_loaded`.

Renaming the corrupt file (not deleting it) preserves it for debugging while allowing the game to proceed cleanly.

### Version Field and Migration Hook

The `"version"` field is an integer starting at `1`. When schema changes are required in future updates:

1. Increment the version in code.
2. Write a migration function `_migrate_v1_to_v2(data: Dictionary) -> Dictionary` that transforms old schema to new.
3. In `_load_from_disk()`, after successful parse, invoke migrations in sequence before using `_data`.

At MVP only `version: 1` exists. No migration code is needed yet.

### In-Memory Cache

All runtime reads are from `_data: Dictionary` — no disk reads after initial load. This means:

- Getters are O(1) Dictionary lookups.
- The file is always a consistent snapshot of `_data` (written fully on each change).
- Two sources of truth (memory and disk) are kept in sync by the immediate-write discipline.

### What Is NOT Persisted

- Current tile position, move count, undo history, coverage state during an active level.
- Audio settings — those live in `user://settings.cfg` (owned by `SFXManager` and `MusicManager`).
- Any gameplay-transient state.

### Key Interfaces

```gdscript
# Path constant
const SAVE_PATH: String = "user://nekodash_save.json"
const CORRUPT_SAVE_PATH: String = "user://nekodash_save.corrupt.json"
const SAVE_VERSION: int = 1

# Signals
signal save_loaded
signal save_corrupted
signal level_record_updated(level_id: String)
signal skin_unlocked(skin_id: String)

# Core write methods (all call _write_to_disk() internally)
func set_level_record(level_id: String, completed: bool, stars: int, moves: int) -> void
func set_equipped_skin(skin_id: String) -> void
func unlock_skin(skin_id: String) -> void
```

## Alternatives Considered

### Alternative 1: Godot `ConfigFile` (`.cfg` format)

- **Description**: Use `ConfigFile` with `[sections]` for levels, skins, and settings. Same cross-platform `user://` path.
- **Pros**: Built-in Godot API; handles type-safe reads (`get_value(section, key, default)`); no manual JSON parsing.
- **Cons**: INI-style format is awkward for nested structures (level records require key-per-field: `world1_level1_completed=true`, `world1_level1_best_stars=3`, etc.). No native schema version field convention. Mixing game progress and audio settings in one file would conflate concerns.
- **Rejection Reason**: JSON with explicit version field is cleaner for arbitrarily nested data than INI-style key flattening. `ConfigFile` is better suited for settings (flat key-value pairs), which is exactly where it is used (`user://settings.cfg`).

### Alternative 2: Godot `Resource` (`.tres` / `.res`)

- **Description**: Define a `SaveData` resource class, populate it, and save it with `ResourceSaver.save()`.
- **Pros**: Deeply integrated with Godot's type system; strongly typed; works with editor inspection.
- **Cons**: `.tres` text format includes Godot-internal GDScript class type hints — not human-readable without the engine. Binary `.res` is faster but not debuggable. `ResourceSaver` is designed for asset pipeline, not save files; its behaviour on partial write (power cut mid-save) is undocumented. Schema migration requires engine-version-specific handling. `PackedByteArray` storage noted in project guidelines as having backwards-compatibility impact.
- **Rejection Reason**: JSON is more portable, more debuggable, and has a well-understood corruption model. Resource format is not designed for runtime save data.

### Alternative 3: Binary format (`PackedByteArray` via `FileAccess`)

- **Description**: Serialise `_data` to `PackedByteArray` and write raw bytes.
- **Pros**: Smallest file size; slightly faster write.
- **Cons**: Not human-readable; debugging requires a custom deserialiser. Schema migration is byte-offset arithmetic. Project guidelines explicitly flag `PackedByteArray` storage as having backwards-compatibility impact.
- **Rejection Reason**: File size and write speed are not constraints at MVP scale. Human readability for development debugging outweighs the marginal performance gains.

### Alternative 4: Deferred Write (Write on Scene Exit / App Pause)

- **Description**: Batch all mutations in memory and write only when the app is backgrounded or a level ends.
- **Pros**: Fewer file I/O operations.
- **Cons**: Mobile OS can kill the app during a level without calling any exit hook. Any level-completion write that hasn't flushed yet is silently lost. Player completes a level, OS kills app, player reopens — level is not recorded. Trust-destroying on mobile.
- **Rejection Reason**: Immediate write on every setter is the only safe model for mobile game saves.

## Consequences

### Positive

- Progress is never lost to an OS-kill between the completion event and a flush.
- Save files can be inspected with any text editor during development.
- Corruption is recoverable without crashing the game.
- Version field provides a defined migration path for all future schema changes.
- Settings and save data are cleanly separated into different files.

### Negative

- Full-file rewrite on every setter — wasteful if the file ever grows large (post-jam: many worlds, many skins). Acceptable at MVP scale.
- No post-jam anti-cheat yet — JSON is trivially editable by the player (OQ-4 in save-load-system.md). HMAC-based integrity check is deferred to post-jam.
- File path is fixed at `user://nekodash_save.json` — testing requires either mocking `FileAccess` or using a different user data directory.

### Risks

- **Risk**: Full-file rewrite mid-write (power loss) could produce a truncated file. **Mitigation**: Write to a `.tmp` file first, then `FileAccess.rename()` atomically. _Note: atomic rename is lower priority for MVP given jam scope; the corrupt-file recovery path handles truncation._
- **Risk**: Post-jam HMAC implementation changes the schema, requiring a `version: 2` migration. **Mitigation**: Version field and migration function pattern described above is specifically designed for this.
- **Risk**: A future GDD adds a new persisted field without updating the schema version. **Mitigation**: Any new field added to `_data` that is not in the `version: 1` schema must bump the version integer and add a migration.

## Performance Implications

- **CPU**: JSON serialisation and file write on each setter: negligible (< 1 ms) for a ~4 KB file.
- **Memory**: Entire save data held in `_data: Dictionary` in RAM permanently (autoload). At MVP scale this is < 10 KB. Negligible.
- **Load Time**: Single file parse in `SaveManager._ready()` before the first scene loads. Adds ~1–3 ms. Negligible.
- **Network**: Not applicable — local storage only.

## Migration Plan

This ADR records the intended architecture for a new project. Implementation steps:

1. Implement `SaveManager` autoload with `SAVE_PATH`, `SAVE_VERSION = 1`, `_data: Dictionary`.
2. `_ready()` calls `_load_from_disk()` following the corruption-recovery steps above.
3. All setters mutate `_data` then call `_write_to_disk()`.
4. When post-jam features require new fields (HMAC, undo penalty, procedural levels), increment `SAVE_VERSION` and add `_migrate_v{N}_to_v{N+1}()`.

## Validation Criteria

- Killing the app immediately after level completion does not lose the completion record on next launch.
- Manually corrupting `nekodash_save.json` (truncate or inject invalid JSON) results in the game launching cleanly with a fresh default save. The corrupt file is renamed, not deleted.
- The save file for a completed 15-level game is < 10 KB.
- Audio settings (`user://settings.cfg`) and save data (`user://nekodash_save.json`) are in separate files — modifying one has no effect on the other.

## Related Decisions

- [ADR-0001: Autoload Architecture](adr-0001-autoload-architecture.md) — `SaveManager` is autoload #1; this ADR specifies what it persists and how.
- [ADR-0002: Signal-Driven Decoupling](adr-0002-signal-driven-decoupling.md) — `SaveManager` emits `level_record_updated` and `skin_unlocked`; this ADR defines those signals.
- [design/gdd/save-load-system.md](../../design/gdd/save-load-system.md)
- [design/gdd/skin-unlock-milestone-tracker.md](../../design/gdd/skin-unlock-milestone-tracker.md)
- [design/gdd/cosmetic-skin-database.md](../../design/gdd/cosmetic-skin-database.md)
