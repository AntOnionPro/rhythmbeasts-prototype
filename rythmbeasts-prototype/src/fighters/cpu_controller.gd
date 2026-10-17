class_name CpuController
extends FighterController
## CPU controller: chases the opponent across platforms, attacks on the beat grid following
## its profile's pattern, sometimes blocks, and recovers to the stage when knocked off.

const LIGHT_ID: StringName = &"light"
const HEAVY_ID: StringName = &"heavy"
const MS_PER_SECOND: float = 1000.0
## Stops approaching at this fraction of the attack range, so it ends up inside it.
const APPROACH_STOP_RATIO: float = 0.8
## Only blocks attacks started within this multiple of its attack range.
const BLOCK_RANGE_RATIO: float = 1.5
## Starts the recovery jump this far above the ground surface while falling.
const RECOVERY_JUMP_MARGIN: float = 40.0

@export var profile: CpuProfile

var _fighter: Fighter
var _opponent: Fighter
var _ground_rect: Rect2
var _axis: float = 0.0
var _jump_pressed: bool = false
var _down_pressed: bool = false
var _light_pressed: bool = false
var _heavy_pressed: bool = false
var _block_timer: float = 0.0
var _decision_cooldown: float = 0.0
var _pattern_index: int = 0
var _last_attack_beat: float = -INF
## Attack waiting for its grid step; empty when none.
var _scheduled_attack: StringName = &""
var _scheduled_attack_sec: float = 0.0
var _skip_scheduled_attack: bool = false
var _opponent_was_attacking: bool = false


func setup(fighter: Fighter) -> void:
	_fighter = fighter


func set_context(opponent: Fighter, ground_rect: Rect2) -> void:
	_opponent = opponent
	_ground_rect = ground_rect


func update(delta: float) -> void:
	_axis = 0.0
	_jump_pressed = false
	_down_pressed = false
	_light_pressed = false
	_heavy_pressed = false
	_decision_cooldown = maxf(_decision_cooldown - delta, 0.0)
	_block_timer = maxf(_block_timer - delta, 0.0)
	if not enabled or _opponent == null or not _opponent.visible or not Conductor.is_running():
		_scheduled_attack = &""
		return
	if _recover():
		return
	_update_block()
	if _block_timer > 0.0:
		return
	_chase()
	_update_attack()


func get_move_axis() -> float:
	return _axis if enabled else 0.0


func is_jump_just_pressed() -> bool:
	return enabled and _jump_pressed


func is_down_just_pressed() -> bool:
	return enabled and _down_pressed


func is_light_just_pressed() -> bool:
	return enabled and _light_pressed


func is_heavy_just_pressed() -> bool:
	return enabled and _heavy_pressed


func is_block_held() -> bool:
	return enabled and _block_timer > 0.0


## Off the stage and airborne: head back to the middle and jump when falling. Returns true
## while recovering.
func _recover() -> bool:
	var fighter_position: Vector2 = _fighter.global_position
	var off_stage: bool = (fighter_position.x < _ground_rect.position.x
		or fighter_position.x > _ground_rect.end.x)
	if not off_stage or _fighter.is_on_floor():
		return false
	_scheduled_attack = &""
	_axis = signf(_ground_rect.get_center().x - fighter_position.x)
	var falling: bool = _fighter.velocity.y > 0.0
	var near_ground_level: bool = fighter_position.y > _ground_rect.position.y - RECOVERY_JUMP_MARGIN
	if falling and near_ground_level and _decision_cooldown <= 0.0:
		_jump_pressed = true
		_decision_cooldown = profile.reaction_sec
	return true


func _update_block() -> void:
	var attacking: bool = _opponent.is_attacking()
	if attacking and not _opponent_was_attacking:
		var distance_x: float = absf(_opponent.global_position.x - _fighter.global_position.x)
		var close: bool = distance_x <= profile.attack_range.x * BLOCK_RANGE_RATIO
		if close and _fighter.is_on_floor() and randf() < profile.block_chance:
			_block_timer = profile.block_hold_sec
			_scheduled_attack = &""
	_opponent_was_attacking = attacking


func _chase() -> void:
	var to_opponent: Vector2 = _opponent.global_position - _fighter.global_position
	var direction: float = signf(to_opponent.x)
	if absf(to_opponent.x) > profile.attack_range.x * APPROACH_STOP_RATIO:
		_axis = direction
	elif direction != 0.0 and direction != _fighter.get_facing():
		_axis = direction  # turn around to face the opponent

	if _decision_cooldown > 0.0:
		return
	var opponent_above: bool = to_opponent.y < -profile.vertical_threshold
	var opponent_below: bool = to_opponent.y > profile.vertical_threshold
	if _fighter.is_on_floor():
		if opponent_above:
			_jump()
		elif opponent_below and _fighter.is_on_one_way_platform():
			_down_pressed = true
			_decision_cooldown = profile.reaction_sec
	elif opponent_above and _fighter.velocity.y >= 0.0 and _fighter.get_air_jumps_left() > 0:
		_jump()


func _jump() -> void:
	_jump_pressed = true
	_decision_cooldown = profile.reaction_sec


func _update_attack() -> void:
	var now_sec: float = Conductor.get_song_time_sec()
	if _scheduled_attack != &"":
		if now_sec >= _scheduled_attack_sec:
			if not _skip_scheduled_attack and _is_in_attack_range():
				_press_attack(_scheduled_attack, now_sec)
			_scheduled_attack = &""
		return
	if _fighter.is_attacking() or not _is_in_attack_range() or profile.attack_pattern.is_empty():
		return

	if Conductor.time_sec_to_beat(now_sec) - _last_attack_beat > profile.pattern_reset_beats:
		_pattern_index = 0
	var step_sec: float = Conductor.get_seconds_per_beat() / profile.attack_subdivision
	var next_step_sec: float = ceilf(now_sec / step_sec) * step_sec
	_scheduled_attack = profile.attack_pattern[_pattern_index % profile.attack_pattern.size()]
	_scheduled_attack_sec = next_step_sec + randfn(0.0, profile.timing_error_ms / MS_PER_SECOND)
	_skip_scheduled_attack = randf() > profile.attack_chance


func _press_attack(attack_id: StringName, now_sec: float) -> void:
	if attack_id == LIGHT_ID:
		_light_pressed = true
	elif attack_id == HEAVY_ID:
		_heavy_pressed = true
	_pattern_index += 1
	_last_attack_beat = Conductor.time_sec_to_beat(now_sec)


func _is_in_attack_range() -> bool:
	var to_opponent: Vector2 = _opponent.global_position - _fighter.global_position
	return (absf(to_opponent.x) <= profile.attack_range.x
		and absf(to_opponent.y) <= profile.attack_range.y
		and signf(to_opponent.x) == _fighter.get_facing())
