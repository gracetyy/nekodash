## LevelCatalogue — ordered collection of all LevelData resources.
## Implements: design/gdd/level-progression.md (Catalogue Loading section)
## Task: S2-03
##
## Authored by the level designer: all .tres LevelData files are added to
## the levels array in (world_id, level_index) order. Level Progression
## sorts at runtime as a validation step.
class_name LevelCatalogue
extends Resource


## Ordered array of all LevelData resources in the game.
@export var levels: Array[LevelData] = []
