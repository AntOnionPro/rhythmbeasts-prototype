class_name BeatSnap
extends RefCounted
## Result of snapping an instant to the nearest subdivision of the beat grid.

## Index of the nearest subdivision step, counted in units of 1 / steps_per_beat beats.
var step: int = 0
var steps_per_beat: int = 1
## Position of the nearest step, in beats.
var beat: float = 0.0
## Position of the nearest step, in song seconds.
var time_sec: float = 0.0
## Signed distance from the queried instant to the step: negative = early, positive = late.
var offset_ms: float = 0.0
