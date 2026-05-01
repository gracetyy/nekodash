## TutorialData — resource defining tutorial triggers and assets.
## Implements: S2-10 (Hardcoded Path Refactor)
class_name TutorialData
extends Resource

## Levels that trigger the tutorial system.
@export var trigger_level_ids: Array[String] = ["w1_l1", "w1_l2", "w1_l3"]

## UI Scenes
@export var bubble_scene: PackedScene
@export var pill_button_scene: PackedScene

## Icons
@export var arrow_down: Texture2D
@export var arrow_up: Texture2D
@export var arrow_purple_right: Texture2D
