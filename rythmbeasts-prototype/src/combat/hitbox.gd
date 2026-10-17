class_name Hitbox
extends Area2D
## Attack area. Active only during an attack's active phase; hits each hurtbox once
## per activation and never its owner's hurtbox. Drawn while active for tuning.

signal hurtbox_entered(hurtbox: Hurtbox)

const DEBUG_COLOR: Color = Color(1.0, 0.2, 0.2, 0.5)

var _shape_node: CollisionShape2D
var _shape: RectangleShape2D
var _ignored_hurtbox: Hurtbox
var _already_hit: Array[Hurtbox] = []
var _active: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(Hurtbox.LAYER, true)
	monitorable = false
	monitoring = false
	_shape = RectangleShape2D.new()
	_shape_node = CollisionShape2D.new()
	_shape_node.shape = _shape
	add_child(_shape_node)
	area_entered.connect(_on_area_entered)


func _draw() -> void:
	if _active:
		draw_rect(Rect2(_shape_node.position - _shape.size / 2.0, _shape.size), DEBUG_COLOR)


func activate(attack: AttackData, facing: float, ignored_hurtbox: Hurtbox) -> void:
	_shape.size = attack.hitbox_size
	_shape_node.position = Vector2(attack.hitbox_offset.x * facing, attack.hitbox_offset.y)
	_ignored_hurtbox = ignored_hurtbox
	_already_hit.clear()
	_active = true
	# Deferred: may be called from inside physics callbacks.
	set_deferred("monitoring", true)
	queue_redraw()


func deactivate() -> void:
	_active = false
	set_deferred("monitoring", false)
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	var hurtbox: Hurtbox = area as Hurtbox
	if not _active or hurtbox == null or hurtbox == _ignored_hurtbox or _already_hit.has(hurtbox):
		return
	_already_hit.append(hurtbox)
	hurtbox_entered.emit(hurtbox)
