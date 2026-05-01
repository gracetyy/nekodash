## SceneRegistry — resource defining all screen and overlay scene paths.
## Implements: S1-05 (Scene Path Refactor)
class_name SceneRegistry
extends Resource

## Maps SceneManager.Screen (int) to scene file paths.
@export var screen_paths: Dictionary = {}

## Maps SceneManager.Overlay (int) to scene file paths.
@export var overlay_paths: Dictionary = {}
