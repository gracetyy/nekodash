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
@export var star_earned: AudioStream

## Played when any HUD button is tapped (undo, restart, exit).
@export var button_tap: AudioStream
