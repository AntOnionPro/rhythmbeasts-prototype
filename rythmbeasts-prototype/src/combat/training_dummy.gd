class_name TrainingDummy
extends CharacterBody2D
## Practice target: takes hits, flashes, gets knocked back and shows accumulated damage.
## Origin is at the feet. Resets to its start position if it falls off the stage.

const FLASH_SEC: float = 0.1
const DAMAGE_FONT_SIZE: int = 20
const DAMAGE_LABEL_GAP: float = 8.0
const DAMAGE_COLOR: Color = Color(1.0, 1.0, 1.0)

@export var body_size: Vector2 = Vector2(48.0, 72.0)
@export var body_color: Color = Color(0.85, 0.75, 0.4)
@export var flash_color: Color = Color(1.0, 1.0, 1.0)
@export var gravity: float = 2200.0
@export var max_fall_speed: float = 900.0
@export var ground_friction: float = 2500.0
@export var air_friction: float = 400.0
## Falling below this global y resets the dummy.
@export var reset_below_y: float = 900.0

var _damage: float = 0.0
var _hitstop_timer: float = 0.0
var _flash_timer: float = 0.0
var _start_position: Vector2

@onready var _collision: CollisionShape2D = %Collision
@onready var _hurtbox: Hurtbox = %Hurtbox


func _ready() -> void:
	collision_layer = 0
	set_collision_layer_value(Fighter.BODY_LAYER, true)
	collision_mask = 0
	set_collision_mask_value(Platform.SOLID_LAYER, true)
	set_collision_mask_value(Platform.ONE_WAY_LAYER, true)

	var body_shape: RectangleShape2D = RectangleShape2D.new()
	body_shape.size = body_size
	_collision.shape = body_shape
	_collision.position = Vector2(0.0, -body_size.y / 2.0)
	_hurtbox.setup(self, body_size)
	_hurtbox.hit_received.connect(_on_hit_received)
	_start_position = global_position


func _physics_process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			queue_redraw()
	if _hitstop_timer > 0.0:
		_hitstop_timer -= delta
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	var friction: float = ground_friction if is_on_floor() else air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	move_and_slide()

	if global_position.y > reset_below_y:
		_reset()


func _draw() -> void:
	var color: Color = flash_color if _flash_timer > 0.0 else body_color
	draw_rect(Rect2(-body_size.x / 2.0, -body_size.y, body_size.x, body_size.y), color)
	var label: String = "%d%%" % roundi(_damage)
	var font: Font = ThemeDB.fallback_font
	var label_width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, DAMAGE_FONT_SIZE).x
	draw_string(font, Vector2(-label_width / 2.0, -body_size.y - DAMAGE_LABEL_GAP), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, DAMAGE_FONT_SIZE, DAMAGE_COLOR)


func _reset() -> void:
	global_position = _start_position
	velocity = Vector2.ZERO
	_damage = 0.0
	queue_redraw()


func _on_hit_received(attack: AttackData, _attacker: Node2D, direction: float) -> void:
	_damage += attack.damage
	velocity = attack.get_knockback(_damage, direction)
	_hitstop_timer = attack.hitstop_sec
	_flash_timer = FLASH_SEC
	queue_redraw()
