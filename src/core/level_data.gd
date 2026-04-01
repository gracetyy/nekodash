## LevelData — on-disk resource defining a single NekoDash puzzle level.
## Implements: design/gdd/level-data-format.md
class_name LevelData
extends Resource

## Identity
@export var level_id: String ## e.g. "w1_l1" — unique across all levels
@export var world_id: int ## 1-based world number
@export var level_index: int ## 1-based position within the world
@export var display_name: String ## e.g. "First Steps"

## Grid Layout
@export var grid_width: int ## 3–MAX_GRID_SIZE (15)
@export var grid_height: int ## 3–MAX_GRID_SIZE (15)
@export var walkability_tiles: PackedInt32Array ## TileWalkability int values, row-major
@export var obstacle_tiles: PackedInt32Array ## ObstacleType int values, row-major
@export var cat_start: Vector2i ## Starting tile coord for the cat

## Pre-computed Solution
@export var minimum_moves: int ## BFS optimal; 0 = not yet solved

## Star Rating Thresholds
@export var star_3_moves: int ## ≤ this = 3 stars (should equal minimum_moves)
@export var star_2_moves: int ## ≤ this = 2 stars
@export var star_1_moves: int ## ≤ this = 1 star
