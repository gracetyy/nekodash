## SfxLibrary — centralised AudioStream references for all SFX events.
## Task: S4-24
##
## Resource holding @export AudioStream slots for the four wired SFX events.
## Values are null at scaffold stage (awaiting real audio files).
## Load via: var lib: SfxLibrary = load("res://data/sfx_library.tres")
class_name SfxLibrary
extends Resource


# —————————————————————————————————————————————
# Gameplay SFX
# —————————————————————————————————————————————

## Played when the cat begins a slide move.
@export var slide_move: AudioStream

## Played when all tiles are covered and the level is complete.
@export var level_complete: AudioStream


# —————————————————————————————————————————————
# UI SFX
# —————————————————————————————————————————————

## Played when a star is awarded on the Level Complete screen.
@export var star_earned: AudioStream # Deprecated, use star_1/2/3

@export var star_1: AudioStream
@export var star_2: AudioStream
@export var star_3: AudioStream
@export var no_star: AudioStream

## Played when any HUD button is tapped (undo, restart, exit).
@export var button_tap: AudioStream

## Played when a circular button is tapped.
@export var soft_tap: AudioStream

## Played when a locked level is tapped.
@export var locked: AudioStream
