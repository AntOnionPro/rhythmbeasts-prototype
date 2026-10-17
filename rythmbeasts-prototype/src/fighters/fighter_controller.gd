class_name FighterController
extends Node
## Source of a fighter's intentions: FighterInput (human) or CpuController.
## The fighter calls update() and then polls the queries once per physics tick.
## The base class reads as neutral input.

## When false every query reads as neutral (no movement, nothing pressed).
var enabled: bool = true


func setup(_fighter: Fighter) -> void:
	pass


## The opponent and the main ground area. Only controllers that need them use them.
func set_context(_opponent: Fighter, _ground_rect: Rect2) -> void:
	pass


## Called once per physics tick, before the queries.
func update(_delta: float) -> void:
	pass


func get_move_axis() -> float:
	return 0.0


func is_jump_just_pressed() -> bool:
	return false


func is_jump_just_released() -> bool:
	return false


func is_down_just_pressed() -> bool:
	return false


func is_light_just_pressed() -> bool:
	return false


func is_heavy_just_pressed() -> bool:
	return false


func is_block_held() -> bool:
	return false
