extends Node
## Musical clock. Time derives from audio playback, never from accumulated delta.
##
## Signals and position getters use "audible" time (what the player hears now):
## use them for visuals and for judging input. To trigger sounds on the grid, use
## get_lookahead_position_beats(), which runs ahead by the output latency.

signal beat_ticked(beat: int)
signal subdivision_ticked(step: int, steps_per_beat: int)
signal started
signal stopped

## Value = steps per beat.
enum Subdivision { QUARTER = 1, EIGHTH = 2, SIXTEENTH = 4 }

const BEATS_PER_BAR: int = 4
const MUSIC_BUS: StringName = &"Music"
const SILENT_VOLUME_LINEAR: float = 0.0
const AUDIBLE_VOLUME_LINEAR: float = 1.0
const MS_PER_SECOND: float = 1000.0
## Max allowed mismatch between the track's musical length and its audio length.
const LOOP_LENGTH_TOLERANCE_SEC: float = 0.001
## A backwards jump larger than this fraction of the loop counts as a loop wrap.
const LOOP_WRAP_THRESHOLD: float = 0.5

## Rate of subdivision_ticked.
var subdivision: Subdivision = Subdivision.SIXTEENTH

var _track: MusicTrack
var _bpm: float = MusicTrack.DEFAULT_BPM
var _seconds_per_beat: float = MusicTrack.SECONDS_PER_MINUTE / MusicTrack.DEFAULT_BPM
var _loop_length_sec: float = 0.0
var _first_beat_offset_sec: float = 0.0
var _output_latency_sec: float = 0.0
var _loop_count: int = 0
var _last_raw_pos: float = 0.0
var _song_time: float = 0.0
var _last_step: int = -1
var _last_steps_per_beat: int = Subdivision.SIXTEENTH
var _running: bool = false
var _clock_player: AudioStreamPlayer


func _ready() -> void:
	_clock_player = AudioStreamPlayer.new()
	_clock_player.name = "ClockPlayer"
	_clock_player.bus = MUSIC_BUS
	_clock_player.finished.connect(_on_clock_player_finished)
	add_child(_clock_player)


func _process(_delta: float) -> void:
	if not _running:
		return
	_update_song_time()
	_emit_pending_ticks()


## Starts (or restarts) the clock from beat 0 using the track as clock source.
## The track plays silently unless audible is true.
func start(track: MusicTrack, audible: bool = false) -> void:
	if track == null or track.stream == null:
		push_error("Conductor.start(): track or track.stream is null.")
		return
	if _running:
		_clock_player.stop()

	_track = track
	_bpm = track.bpm
	_seconds_per_beat = track.get_seconds_per_beat()
	_loop_length_sec = track.get_loop_length_sec()
	_first_beat_offset_sec = track.first_beat_offset_sec
	_output_latency_sec = AudioServer.get_output_latency()
	_check_loop_length(track)

	_loop_count = 0
	_last_raw_pos = 0.0
	_song_time = -(_output_latency_sec + _first_beat_offset_sec)
	_last_step = -1
	_last_steps_per_beat = subdivision

	_clock_player.stream = track.stream
	_clock_player.volume_linear = AUDIBLE_VOLUME_LINEAR if audible else SILENT_VOLUME_LINEAR
	_clock_player.play(0.0)
	_running = true
	started.emit()


func stop() -> void:
	if not _running:
		return
	_clock_player.stop()
	_running = false
	stopped.emit()


func is_running() -> bool:
	return _running


func get_track() -> MusicTrack:
	return _track


func get_bpm() -> float:
	return _bpm


## Volume of the clock track. Tween it to fade the base track in (Phase 2).
func set_track_volume_linear(value: float) -> void:
	_clock_player.volume_linear = value


## Audible song time in seconds (beat 0 = 0.0). Returns 0 when stopped.
func get_song_time_sec() -> float:
	if not _running:
		return 0.0
	_update_song_time()
	return _song_time


func get_song_position_beats() -> float:
	return time_sec_to_beat(get_song_time_sec())


func get_seconds_per_beat() -> float:
	return _seconds_per_beat


## Position of the audio currently being mixed, ahead of audible time by the
## output latency. A sound started when this crosses a beat is heard on that beat.
func get_lookahead_position_beats() -> float:
	if not _running:
		return 0.0
	return time_sec_to_beat(get_song_time_sec() + _output_latency_sec)


func beat_to_time_sec(beat: float) -> float:
	return beat * _seconds_per_beat


func time_sec_to_beat(time_sec: float) -> float:
	return time_sec / _seconds_per_beat


## Snaps time_sec (song seconds) to the nearest step of the given subdivision.
func get_nearest_subdivision(time_sec: float, sub: Subdivision) -> BeatSnap:
	var steps_per_beat: int = sub
	var step_length_sec: float = _seconds_per_beat / steps_per_beat
	var snap: BeatSnap = BeatSnap.new()
	snap.step = roundi(time_sec / step_length_sec)
	snap.steps_per_beat = steps_per_beat
	snap.beat = float(snap.step) / steps_per_beat
	snap.time_sec = snap.step * step_length_sec
	snap.offset_ms = (time_sec - snap.time_sec) * MS_PER_SECOND
	return snap


func get_nearest_subdivision_now(sub: Subdivision) -> BeatSnap:
	return get_nearest_subdivision(get_song_time_sec(), sub)


func _update_song_time() -> void:
	var playback_pos: float = _clock_player.get_playback_position()
	if playback_pos < _last_raw_pos - _loop_length_sec * LOOP_WRAP_THRESHOLD:
		_loop_count += 1
	_last_raw_pos = playback_pos

	var raw_time: float = (
		_loop_count * _loop_length_sec
		+ playback_pos
		+ AudioServer.get_time_since_last_mix()
		- _output_latency_sec
		- _first_beat_offset_sec
	)
	# Mix-chunk jitter can make raw_time step back slightly: never go backwards.
	_song_time = maxf(_song_time, raw_time)


func _emit_pending_ticks() -> void:
	var steps_per_beat: int = subdivision
	var current_step: int = floori(time_sec_to_beat(_song_time) * steps_per_beat)
	if steps_per_beat != _last_steps_per_beat:
		# Subdivision changed at runtime: resync without replaying past ticks.
		_last_steps_per_beat = steps_per_beat
		_last_step = current_step
		return

	while _last_step < current_step:
		_last_step += 1
		if _last_step % steps_per_beat == 0:
			@warning_ignore("integer_division")
			beat_ticked.emit(_last_step / steps_per_beat)
		subdivision_ticked.emit(_last_step, steps_per_beat)


func _check_loop_length(track: MusicTrack) -> void:
	var stream_length_sec: float = track.stream.get_length()
	if absf(stream_length_sec - _loop_length_sec) > LOOP_LENGTH_TOLERANCE_SEC:
		push_warning(
			"Conductor: track lasts %.4f s but length_beats implies %.4f s."
			% [stream_length_sec, _loop_length_sec]
		)


func _on_clock_player_finished() -> void:
	push_warning("Conductor: clock stream finished. Set its Loop Mode to Forward in the Import dock.")
	_running = false
	stopped.emit()
