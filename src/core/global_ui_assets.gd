## GlobalUIAssets — resource defining shared UI textures and icons.
## Implements: S3-01 (Hardcoded Path Refactor)
class_name GlobalUIAssets
extends Resource

## Common Icons
@export var icons: Dictionary = {}

## Title Textures
@export var title_landscape: Texture2D
@export var title_portrait: Texture2D

## UI Scenes
@export var bubble_scene: PackedScene
@export var pill_button_scene: PackedScene
@export var skin_card_scene: PackedScene

## Common UI Elements
@export var ribbon_white: StyleBox
@export var ribbon_purple: StyleBox
@export var ribbon_yellow: StyleBox
@export var ribbon_grey: StyleBox
