class_name AttackData
extends Resource
## One attack's timing, reach and impact. Offsets assume the attacker faces right,
## relative to the attacker's feet. Times in seconds, distances in pixels.

## Stable identifier other systems map from (e.g. SoundBank: attack id -> sample).
@export var id: StringName = &""
@export var damage: float = 5.0

@export_group("Timing")
@export var startup_sec: float = 0.05
@export var active_sec: float = 0.08
@export var recovery_sec: float = 0.15

@export_group("Hitbox")
@export var hitbox_size: Vector2 = Vector2(56.0, 32.0)
## Center of the hitbox.
@export var hitbox_offset: Vector2 = Vector2(44.0, -44.0)

@export_group("Impact")
## Base launch velocity: x forward, negative y up.
@export var knockback: Vector2 = Vector2(260.0, -180.0)
## Extra knockback per point of target damage (0.01 = +1% per point).
@export var knockback_growth: float = 0.01
## Attacker and target freeze this long on contact.
@export var hitstop_sec: float = 0.06
## Target cannot act this long after the hit.
@export var hitstun_sec: float = 0.2


## Launch velocity for a target that has accumulated target_damage, hit towards direction (+1/-1).
func get_knockback(target_damage: float, direction: float) -> Vector2:
	var growth: float = 1.0 + target_damage * knockback_growth
	return Vector2(knockback.x * direction, knockback.y) * growth
