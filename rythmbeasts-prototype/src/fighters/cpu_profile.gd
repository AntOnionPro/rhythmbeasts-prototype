class_name CpuProfile
extends Resource
## How a CPU opponent plays. Distances in pixels, times in seconds.

## Attacks thrown in order, by attack id. The default follows the drop combo.
@export var attack_pattern: Array[StringName] = [&"light", &"light", &"heavy", &"heavy"]
## The pattern restarts if this many beats pass without attacking.
@export var pattern_reset_beats: float = 2.0
## Attacks are pressed on this grid...
@export var attack_subdivision: Conductor.Subdivision = Conductor.Subdivision.EIGHTH
## ...off by a random error with this standard deviation.
@export var timing_error_ms: float = 25.0
## Chance to take each attack opportunity (each grid step in range).
@export_range(0.0, 1.0) var attack_chance: float = 0.7
## Max horizontal / vertical distance to the opponent to attack.
@export var attack_range: Vector2 = Vector2(80.0, 40.0)
## Chance to block when the opponent starts an attack nearby.
@export_range(0.0, 1.0) var block_chance: float = 0.3
@export var block_hold_sec: float = 0.35
## Minimum time between movement decisions (jumps, drops).
@export var reaction_sec: float = 0.2
## Height difference to the opponent that makes it jump up or drop down.
@export var vertical_threshold: float = 60.0
