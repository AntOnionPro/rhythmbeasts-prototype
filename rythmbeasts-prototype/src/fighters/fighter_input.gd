class_name FighterInput
extends FighterController
## Human controller: reads the Input Map actions named <action_prefix><action>
## (e.g. "p1_jump"), using the fighter's action_prefix.

const LEFT: String = "left"
const RIGHT: String = "right"
const JUMP: String = "jump"
const DOWN: String = "down"
const LIGHT: String = "light"
const HEAVY: String = "heavy"
const BLOCK: String = "block"

var _left: StringName
var _right: StringName
var _jump: StringName
var _down: StringName
var _light: StringName
var _heavy: StringName
var _block: StringName


func setup(fighter: Fighter) -> void:
	var prefix: String = fighter.action_prefix
	_left = StringName(prefix + LEFT)
	_right = StringName(prefix + RIGHT)
	_jump = StringName(prefix + JUMP)
	_down = StringName(prefix + DOWN)
	_light = StringName(prefix + LIGHT)
	_heavy = StringName(prefix + HEAVY)
	_block = StringName(prefix + BLOCK)
	for action: StringName in [_left, _right, _jump, _down, _light, _heavy, _block]:
		if not InputMap.has_action(action):
			push_error("FighterInput: missing Input Map action '%s'." % action)


func get_move_axis() -> float:
	return 0.0 if not enabled else Input.get_axis(_left, _right)


func is_jump_just_pressed() -> bool:
	return enabled and Input.is_action_just_pressed(_jump)


func is_jump_just_released() -> bool:
	return enabled and Input.is_action_just_released(_jump)


func is_down_just_pressed() -> bool:
	return enabled and Input.is_action_just_pressed(_down)


func is_light_just_pressed() -> bool:
	return enabled and Input.is_action_just_pressed(_light)


func is_heavy_just_pressed() -> bool:
	return enabled and Input.is_action_just_pressed(_heavy)


func is_block_held() -> bool:
	return enabled and Input.is_action_pressed(_block)
