class_name Stage
extends Node2D
## Reactive stage: platforms, one spawn point per player, kill zone and a background that
## pulses on the beat, flashes on every note and takes a layer's color while a combo layer plays.
## All animation derives from Conductor time, never from accumulated delta.

## Higher = sharper decay of the background pulse after each beat.
const PULSE_EXPONENT: float = 3.0
const NOTE_FLASH_SEC: float = 0.12
const NOTE_FLASH_STRENGTH: float = 0.35
## How dark the background gets between beats while a layer plays.
const LAYER_BASE_DARKEN: float = 0.6

@export var background_color: Color = Color(0.08, 0.06, 0.12)
@export var pulse_color: Color = Color(0.2, 0.1, 0.3)
@export var note_flash_color: Color = Color(1.0, 1.0, 1.0)
## Background color per combo layer sound id.
@export var layer_colors: Dictionary[StringName, Color] = {
	&"wobble": Color(0.45, 0.1, 0.75),
	&"drop": Color(0.85, 0.1, 0.25),
}

## Song time (seconds) of the last note, and when the current layer ends.
var _last_note_sec: float = -INF
var _layer_end_sec: float = -INF
var _layer_color: Color

@onready var _ground: Platform = %Ground
@onready var _spawn_points: Array[Marker2D] = [%SpawnPoint1, %SpawnPoint2]
@onready var _kill_zone: Area2D = %KillZone


func _ready() -> void:
	_kill_zone.collision_layer = 0
	_kill_zone.collision_mask = 0
	_kill_zone.set_collision_mask_value(Fighter.BODY_LAYER, true)
	_kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	EventBus.note_played.connect(_on_note_played)
	EventBus.music_layer_started.connect(_on_music_layer_started)
	Conductor.started.connect(_on_conductor_started)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var now_sec: float = Conductor.get_song_time_sec()
	var beats: float = maxf(Conductor.time_sec_to_beat(now_sec), 0.0)
	var pulse: float = pow(1.0 - fposmod(beats, 1.0), PULSE_EXPONENT)

	var color: Color
	if now_sec < _layer_end_sec:
		color = _layer_color.darkened(LAYER_BASE_DARKEN).lerp(_layer_color, pulse)
	else:
		color = background_color.lerp(pulse_color, pulse)

	var since_note_sec: float = now_sec - _last_note_sec
	if since_note_sec >= 0.0 and since_note_sec < NOTE_FLASH_SEC:
		var flash: float = (1.0 - since_note_sec / NOTE_FLASH_SEC) * NOTE_FLASH_STRENGTH
		color = color.lerp(note_flash_color, flash)
	draw_rect(get_viewport_rect(), color)


func get_spawn_position(player_index: int) -> Vector2:
	return _spawn_points[player_index].global_position


## The main ground's area in global coordinates; its top edge is the walkable surface.
func get_ground_rect() -> Rect2:
	var top_left: Vector2 = _ground.global_position - Vector2(_ground.size.x / 2.0, 0.0)
	return Rect2(top_left, _ground.size)


## +1 (right) or -1 (left): spawned fighters face the middle of the stage.
func get_spawn_facing(player_index: int) -> float:
	var middle_x: float = 0.0
	for spawn_point: Marker2D in _spawn_points:
		middle_x += spawn_point.global_position.x
	middle_x /= _spawn_points.size()
	return 1.0 if get_spawn_position(player_index).x < middle_x else -1.0


func _on_kill_zone_body_entered(body: Node2D) -> void:
	var fighter: Fighter = body as Fighter
	if fighter != null:
		EventBus.fighter_fell_off_stage.emit(fighter)


func _on_note_played(_attacker: Node2D, _attack: AttackData) -> void:
	_last_note_sec = Conductor.get_song_time_sec()


func _on_music_layer_started(sound_id: StringName, duration_sec: float) -> void:
	_layer_color = layer_colors.get(sound_id, pulse_color)
	_layer_end_sec = Conductor.get_song_time_sec() + duration_sec


func _on_conductor_started() -> void:
	_last_note_sec = -INF
	_layer_end_sec = -INF
