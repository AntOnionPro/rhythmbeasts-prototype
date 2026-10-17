extends Node2D
## Entry point: builds the match scene, starts the musical clock and respawns fallen fighters.

@export var music_track: MusicTrack

@onready var _stage: Stage = %Stage
@onready var _fighter: Fighter = %Fighter
@onready var _music_director: MusicDirector = %MusicDirector
@onready var _debug_hud: DebugHud = %DebugHud


func _ready() -> void:
	EventBus.fighter_fell_off_stage.connect(_on_fighter_fell_off_stage)
	_debug_hud.show_difficulty(_music_director.difficulty)
	Conductor.start(music_track)
	_fighter.respawn_at(_stage.get_spawn_position())


func _exit_tree() -> void:
	Conductor.stop()


func _on_fighter_fell_off_stage(fighter: Fighter) -> void:
	fighter.respawn_at.call_deferred(_stage.get_spawn_position())
