class_name MusicTrack
extends Resource
## Musical data for a looping track used as clock source and/or audible music.

const DEFAULT_BPM: float = 140.0
const DEFAULT_LENGTH_BEATS: int = 16
const SECONDS_PER_MINUTE: float = 60.0

@export var stream: AudioStream
@export var bpm: float = DEFAULT_BPM
## Loop length in beats. The audio file must last exactly this many beats.
@export var length_beats: int = DEFAULT_LENGTH_BEATS
## Lead-in before beat 0, in seconds.
@export var first_beat_offset_sec: float = 0.0


func get_seconds_per_beat() -> float:
	return SECONDS_PER_MINUTE / bpm


func get_loop_length_sec() -> float:
	return length_beats * get_seconds_per_beat()
