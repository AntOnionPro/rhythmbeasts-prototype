@tool
class_name Platform
extends AnimatableBody2D
## Stage platform drawn by code. Origin is the top-center of its surface.
## AnimatableBody2D so it can be moved later and carry fighters with it.

## Physics layers (1-based).
const SOLID_LAYER: int = 1
const ONE_WAY_LAYER: int = 2
const SOLID_COLOR: Color = Color(0.35, 0.35, 0.45)
const ONE_WAY_COLOR: Color = Color(0.55, 0.55, 0.7)

@export var size: Vector2 = Vector2(240.0, 16.0):
	set(value):
		size = value
		queue_redraw()
## Fighters can jump up through it and drop down through it.
@export var one_way: bool = true:
	set(value):
		one_way = value
		queue_redraw()

@onready var _collision: CollisionShape2D = %Collision


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var platform_shape: RectangleShape2D = RectangleShape2D.new()
	platform_shape.size = size
	_collision.shape = platform_shape
	_collision.position = Vector2(0.0, size.y / 2.0)
	_collision.one_way_collision = one_way
	collision_layer = 0
	set_collision_layer_value(ONE_WAY_LAYER if one_way else SOLID_LAYER, true)
	collision_mask = 0


func _draw() -> void:
	draw_rect(Rect2(-size.x / 2.0, 0.0, size.x, size.y), ONE_WAY_COLOR if one_way else SOLID_COLOR)
