## WorldData — resource defining a single world's metadata and its levels.
## Implements: S1-01 (Resource Refactor)
class_name WorldData
extends Resource

## Identity
@export var world_id: int
@export var world_name: String

## Audio
@export var bgm_track: AudioStream

## Levels belonging to this world.
@export var levels: Array[LevelData] = []
