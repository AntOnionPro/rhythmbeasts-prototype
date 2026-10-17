class_name FighterAttack
extends Node
## Runs one attack at a time through startup, active and recovery, and reports contacts
## on the EventBus. Input-agnostic: its owner decides when to start attacks and calls update().

## A hit landed or was blocked: the attacker should apply hitstop.
signal hit_connected(attack: AttackData)

enum Phase { IDLE, STARTUP, ACTIVE, RECOVERY }

@export var light_attack: AttackData
@export var heavy_attack: AttackData

var _attacker: Node2D
var _hitbox: Hitbox
var _own_hurtbox: Hurtbox
var _attack: AttackData
var _phase: Phase = Phase.IDLE
var _phase_timer: float = 0.0
var _facing: float = 1.0


func setup(attacker: Node2D, hitbox: Hitbox, own_hurtbox: Hurtbox) -> void:
	_attacker = attacker
	_hitbox = hitbox
	_own_hurtbox = own_hurtbox
	_hitbox.hurtbox_entered.connect(_on_hurtbox_entered)


func is_busy() -> bool:
	return _phase != Phase.IDLE


func start(attack: AttackData, facing: float) -> void:
	if is_busy() or attack == null:
		return
	_attack = attack
	_facing = facing
	_enter_phase(Phase.STARTUP)
	EventBus.attack_started.emit(_attacker, attack)


func cancel() -> void:
	if not is_busy():
		return
	_hitbox.deactivate()
	_attack = null
	_phase = Phase.IDLE


## Advances the current attack. Not called while the owner is in hitstop.
func update(delta: float) -> void:
	if _phase == Phase.IDLE:
		return
	_phase_timer -= delta
	if _phase_timer > 0.0:
		return
	match _phase:
		Phase.STARTUP:
			_enter_phase(Phase.ACTIVE)
		Phase.ACTIVE:
			_enter_phase(Phase.RECOVERY)
		Phase.RECOVERY:
			_enter_phase(Phase.IDLE)


func _enter_phase(phase: Phase) -> void:
	_phase = phase
	match phase:
		Phase.STARTUP:
			_phase_timer = _attack.startup_sec
		Phase.ACTIVE:
			_phase_timer = _attack.active_sec
			_hitbox.activate(_attack, _facing, _own_hurtbox)
		Phase.RECOVERY:
			_phase_timer = _attack.recovery_sec
			_hitbox.deactivate()
		Phase.IDLE:
			_attack = null


func _on_hurtbox_entered(hurtbox: Hurtbox) -> void:
	if _attack == null:
		return
	var attack: AttackData = _attack
	if hurtbox.receive_hit(attack, _attacker, _facing):
		EventBus.hit_landed.emit(_attacker, hurtbox.body, attack)
	else:
		EventBus.hit_blocked.emit(_attacker, hurtbox.body, attack)
	hit_connected.emit(attack)
