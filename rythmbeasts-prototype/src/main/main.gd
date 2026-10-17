extends Node2D
## Entry point: wires the match scene together, then starts the musical clock and the match.

@export var music_track: MusicTrack

@onready var _stage: Stage = %Stage
@onready var _fighters: Array[Fighter] = [%Fighter1, %Fighter2]
@onready var _music_director: MusicDirector = %MusicDirector
@onready var _match_director: MatchDirector = %MatchDirector
@onready var _match_hud: MatchHud = %MatchHud
@onready var _debug_hud: DebugHud = %DebugHud


func _ready() -> void:
	for i: int in _fighters.size():
		_music_director.assign_voice(_fighters[i], i)
		# 1v1: each fighter's opponent is the other one.
		_fighters[i].set_opponent(_fighters[_fighters.size() - 1 - i], _stage.get_ground_rect())
	_debug_hud.show_difficulty(_music_director.difficulty)
	_match_hud.setup(_match_director, _fighters)
	Conductor.start(music_track)
	_match_director.start(_fighters, _stage)


func _exit_tree() -> void:
	Conductor.stop()
