## GlobalAudioSettings — resource defining background music for non-gameplay screens.
## Implements: S4-15 (Audio Path Refactor)
class_name GlobalAudioSettings
extends Resource

## Maps SceneManager.Screen (int) to AudioStream for automatic playback.
@export var screen_tracks: Dictionary = {}

## Track to play if no other track matches.
@export var fallback_track: AudioStream
