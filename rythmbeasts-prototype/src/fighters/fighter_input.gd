class_name FighterInput
extends Node
## Reads one player's Input Map actions, named <action_prefix><action> (e.g. "p1_jump").

const LEFT: String = "left"
const RIGHT: String = "right"
const JUMP: String = "jump"
const DOWN: String = "down"
const LIGHT: String = "light"
const HEAVY: String = "heavy"
const BLOCK: String = "block"

@export var action_prefix: String = "p1_"

var _left: StringName
var _right: StringName
var _jump: StringName
var _down: StringName
var _light: StringName
var _heavy: StringName
var _block: StringName


func _ready() -> void:
	_left = StringName(action_prefix + LEFT)
	_right = StringName(action_prefix + RIGHT)
	_jump = StringName(action_prefix + JUMP)
	_down = StringName(action_prefix + DOWN)
	_light = StringName(action_prefix + LIGHT)
	_heavy = StringName(action_prefix + HEAVY)
	_block = StringName(action_prefix + BLOCK)
	for action: StringName in [_left, _right, _jump, _down, _light, _heavy, _block]:
		if not InputMap.has_action(action):
			push_error("FighterInput: missing Input Map action '%s'." % action)


func get_move_axis() -> float:
	return Input.get_axis(_left, _right)


func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(_jump)


func is_jump_just_released() -> bool:
	return Input.is_action_just_released(_jump)


func is_down_just_pressed() -> bool:
	return Input.is_action_just_pressed(_down)


func is_light_just_pressed() -> bool:
	return Input.is_action_just_pressed(_light)


func is_heavy_just_pressed() -> bool:
	return Input.is_action_just_pressed(_heavy)


func is_block_held() -> bool:
	return Input.is_action_pressed(_block)
