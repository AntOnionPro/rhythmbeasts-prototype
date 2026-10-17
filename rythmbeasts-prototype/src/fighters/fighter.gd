class_name Fighter
extends CharacterBody2D
## Platform-fighter body: run, jump, air jumps, fast fall, drop-through platforms,
## light/heavy attacks and block. Origin is at the feet. Drawn by code.
## Intentions come from its Controller child: human input or CPU.

signal damage_changed(damage: float)

## Physics layer (1-based) fighters live on. Fighters do not collide with each other.
const BODY_LAYER: int = 3
const EYE_SIZE: Vector2 = Vector2(8.0, 8.0)
const EYE_INSET: Vector2 = Vector2(6.0, 14.0)
const EYE_COLOR: Color = Color(1.0, 1.0, 1.0)
const SHIELD_COLOR: Color = Color(0.5, 0.9, 1.0, 0.8)
const SHIELD_WIDTH: float = 4.0
## Nudge down so the body leaves the platform surface when dropping through.
const DROP_THROUGH_NUDGE: float = 1.0

@export var config: FighterConfig
## Input Map actions a human controller reads: <action_prefix>left, <action_prefix>jump, ...
@export var action_prefix: String = "p1_"

var _facing: float = 1.0
var _air_jumps_left: int = 0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _drop_through_timer: float = 0.0
var _is_fast_falling: bool = false
var _is_blocking: bool = false
var _damage: float = 0.0
var _hitstop_timer: float = 0.0
var _hitstun_timer: float = 0.0

@onready var _controller: FighterController = %Controller
@onready var _collision: CollisionShape2D = %Collision
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _hitbox: Hitbox = %Hitbox
@onready var _attack: FighterAttack = %Attack


func _ready() -> void:
	collision_layer = 0
	set_collision_layer_value(BODY_LAYER, true)
	collision_mask = 0
	set_collision_mask_value(Platform.SOLID_LAYER, true)
	set_collision_mask_value(Platform.ONE_WAY_LAYER, true)

	var body_shape: RectangleShape2D = RectangleShape2D.new()
	body_shape.size = config.body_size
	_collision.shape = body_shape
	_collision.position = Vector2(0.0, -config.body_size.y / 2.0)
	_air_jumps_left = config.air_jumps

	_controller.setup(self)
	_hurtbox.setup(self, config.body_size)
	_hurtbox.hit_received.connect(_on_hit_received)
	_attack.setup(self, _hitbox, _hurtbox)
	_attack.hit_connected.connect(_on_attack_hit_connected)


func _physics_process(delta: float) -> void:
	# Hitstop freezes the body in place, keeping its velocity for afterwards.
	if _hitstop_timer > 0.0:
		_hitstop_timer -= delta
		return
	_controller.update(delta)
	_update_timers(delta)
	_attack.update(delta)
	_handle_actions()
	_apply_horizontal(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_down()
	move_and_slide()
	if is_on_floor():
		_on_grounded()


func _draw() -> void:
	var size: Vector2 = config.body_size
	draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y), config.body_color)
	var eye_x: float = size.x / 2.0 - EYE_INSET.x - EYE_SIZE.x if _facing > 0.0 else -size.x / 2.0 + EYE_INSET.x
	draw_rect(Rect2(Vector2(eye_x, -size.y + EYE_INSET.y), EYE_SIZE), EYE_COLOR)
	if _is_blocking:
		draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y), SHIELD_COLOR, false, SHIELD_WIDTH)


## Places the fighter at position (feet), facing +1 (right) or -1 (left),
## with movement and combat state reset.
func respawn_at(spawn_position: Vector2, facing: float = 1.0) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_facing = facing
	_air_jumps_left = config.air_jumps
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_is_fast_falling = false
	_damage = 0.0
	_hitstop_timer = 0.0
	_hitstun_timer = 0.0
	_attack.cancel()
	_set_blocking(false)
	_set_drop_through(false)
	queue_redraw()
	damage_changed.emit(_damage)


func get_damage() -> float:
	return _damage


## Disabled controls read as neutral input; the body still falls and gets knocked back.
func set_controls_enabled(enabled: bool) -> void:
	_controller.enabled = enabled


## Tells the controller who to fight and where the main ground is (used by the CPU).
func set_opponent(opponent: Fighter, ground_rect: Rect2) -> void:
	_controller.set_context(opponent, ground_rect)


## +1 facing right, -1 facing left.
func get_facing() -> float:
	return _facing


func is_attacking() -> bool:
	return _attack.is_busy()


func get_air_jumps_left() -> int:
	return _air_jumps_left


func is_on_one_way_platform() -> bool:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var platform: Platform = collision.get_collider() as Platform
		if platform != null and platform.one_way and collision.get_normal().y < 0.0:
			return true
	return false


func _update_timers(delta: float) -> void:
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	_hitstun_timer = maxf(_hitstun_timer - delta, 0.0)
	if _drop_through_timer > 0.0:
		_drop_through_timer -= delta
		if _drop_through_timer <= 0.0:
			_set_drop_through(false)


func _handle_actions() -> void:
	var can_act: bool = _hitstun_timer <= 0.0 and not _attack.is_busy()
	_set_blocking(can_act and is_on_floor() and _controller.is_block_held())
	if not can_act or _is_blocking:
		return
	if _controller.is_light_just_pressed():
		_attack.start(_attack.light_attack, _facing)
	elif _controller.is_heavy_just_pressed():
		_attack.start(_attack.heavy_attack, _facing)


## Ground attacks, blocking and hitstun take away movement control; air attacks keep it.
func _has_movement_control() -> bool:
	return _hitstun_timer <= 0.0 and not _is_blocking and not (_attack.is_busy() and is_on_floor())


func _apply_horizontal(delta: float) -> void:
	var axis: float = _controller.get_move_axis() if _has_movement_control() else 0.0
	var grounded: bool = is_on_floor()
	var rate: float
	if not is_zero_approx(axis):
		rate = config.ground_acceleration if grounded else config.air_acceleration
		if signf(axis) != _facing and not _attack.is_busy():
			_facing = signf(axis)
			queue_redraw()
	else:
		rate = config.ground_friction if grounded else config.air_friction
	velocity.x = move_toward(velocity.x, axis * config.max_run_speed, rate * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var fall_limit: float = config.fast_fall_speed if _is_fast_falling else config.max_fall_speed
	velocity.y = minf(velocity.y + config.gravity * delta, fall_limit)


func _handle_jump() -> void:
	if not _has_movement_control():
		return
	if _controller.is_jump_just_pressed():
		_jump_buffer_timer = config.jump_buffer_sec

	if _jump_buffer_timer > 0.0:
		if is_on_floor() or _coyote_timer > 0.0:
			velocity.y = -config.jump_velocity
			_consume_jump()
		elif _air_jumps_left > 0:
			velocity.y = -config.air_jump_velocity
			_air_jumps_left -= 1
			_consume_jump()

	if _controller.is_jump_just_released() and velocity.y < 0.0:
		velocity.y *= config.jump_cut_multiplier


func _handle_down() -> void:
	if not _has_movement_control() or not _controller.is_down_just_pressed():
		return
	if is_on_floor():
		if is_on_one_way_platform():
			_set_drop_through(true)
			_drop_through_timer = config.drop_through_sec
			position.y += DROP_THROUGH_NUDGE
	elif velocity.y >= 0.0:
		_is_fast_falling = true
		velocity.y = config.fast_fall_speed


func _consume_jump() -> void:
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_is_fast_falling = false


func _on_grounded() -> void:
	_air_jumps_left = config.air_jumps
	_coyote_timer = config.coyote_time_sec
	_is_fast_falling = false


func _set_drop_through(enabled: bool) -> void:
	set_collision_mask_value(Platform.ONE_WAY_LAYER, not enabled)
	if not enabled:
		_drop_through_timer = 0.0


func _set_blocking(enabled: bool) -> void:
	if enabled == _is_blocking:
		return
	_is_blocking = enabled
	_hurtbox.is_blocking = enabled
	queue_redraw()


func _on_hit_received(attack: AttackData, _attacker: Node2D, direction: float) -> void:
	_damage += attack.damage
	damage_changed.emit(_damage)
	velocity = attack.get_knockback(_damage, direction)
	_hitstop_timer = attack.hitstop_sec
	_hitstun_timer = attack.hitstun_sec
	_is_fast_falling = false
	_attack.cancel()
	_set_blocking(false)


func _on_attack_hit_connected(attack: AttackData) -> void:
	_hitstop_timer = attack.hitstop_sec
