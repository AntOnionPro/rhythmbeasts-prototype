class_name FighterConfig
extends Resource
## Tunable movement data for a fighter. Distances in pixels, times in seconds.

@export_group("Body")
@export var body_size: Vector2 = Vector2(48.0, 72.0)
@export var body_color: Color = Color(0.3, 0.7, 1.0)

@export_group("Run")
@export var max_run_speed: float = 420.0
@export var ground_acceleration: float = 3000.0
@export var ground_friction: float = 3500.0
@export var air_acceleration: float = 1800.0
@export var air_friction: float = 600.0

@export_group("Jump")
@export var jump_velocity: float = 820.0
@export var air_jump_velocity: float = 720.0
@export var air_jumps: int = 1
## Vertical speed is multiplied by this when jump is released while rising.
@export_range(0.0, 1.0) var jump_cut_multiplier: float = 0.45
## Grace time to jump after walking off a ledge.
@export var coyote_time_sec: float = 0.08
## A jump pressed this long before landing still triggers on landing.
@export var jump_buffer_sec: float = 0.1

@export_group("Fall")
@export var gravity: float = 2200.0
@export var max_fall_speed: float = 900.0
@export var fast_fall_speed: float = 1400.0
## How long one-way platforms are ignored after dropping through them.
@export var drop_through_sec: float = 0.2
