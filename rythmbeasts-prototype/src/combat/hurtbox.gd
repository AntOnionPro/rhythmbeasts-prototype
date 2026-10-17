class_name Hurtbox
extends Area2D
## Area that can be hit. Its body decides how to react through hit_received.

signal hit_received(attack: AttackData, attacker: Node2D, direction: float)

## Physics layer (1-based) hurtboxes live on.
const LAYER: int = 5

## The body this hurtbox belongs to; reported as the target of hits.
var body: Node2D
## Set by the body while blocking: hits are blocked instead of received.
var is_blocking: bool = false

var _shape_node: CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	set_collision_layer_value(LAYER, true)
	collision_mask = 0
	monitoring = false
	monitorable = true
	_shape_node = CollisionShape2D.new()
	add_child(_shape_node)


## size covers the body standing on its feet at the origin.
func setup(owner_body: Node2D, size: Vector2) -> void:
	body = owner_body
	var hurt_shape: RectangleShape2D = RectangleShape2D.new()
	hurt_shape.size = size
	_shape_node.shape = hurt_shape
	_shape_node.position = Vector2(0.0, -size.y / 2.0)


## Returns true if the hit landed, false if it was blocked.
func receive_hit(attack: AttackData, attacker: Node2D, direction: float) -> bool:
	if is_blocking:
		return false
	hit_received.emit(attack, attacker, direction)
	return true
