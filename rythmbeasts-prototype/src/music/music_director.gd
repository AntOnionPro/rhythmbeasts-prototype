class_name MusicDirector
extends Node
## Turns combat hits into music. Each landed hit is judged against the beat grid
## (using the moment the attack was pressed) and its sample is scheduled on the next
## reachable grid step, triggered early by the output latency so it is heard on the step.
## Completed combos add layers (wobble, drop) that start on the next bar.

const MS_PER_SECOND: float = 1000.0
const BEATS_PER_BAR: int = 4

@export var sound_bank: SoundBank
@export var difficulty: DifficultyProfile
## Grid hit sounds snap to.
@export var sound_subdivision: Conductor.Subdivision = Conductor.Subdivision.SIXTEENTH
## A sound that would be heard at most this late after a grid step plays right away
## instead of waiting a whole step: the delay is imperceptible and feels responsive.
@export var late_tolerance_ms: float = 25.0
@export var max_polyphony: int = 16
@export var bus: StringName = &"Music"

var _player: AudioStreamPlayer
var _playback: AudioStreamPlaybackPolyphonic
var _pending: Array[ScheduledNote] = []
var _round_robin: Dictionary[StringName, int] = {}
var _press_times: Dictionary[Node2D, float] = {}
## Playing layer streams: sound id -> polyphonic stream id.
var _active_layers: Dictionary[StringName, int] = {}

@onready var _combo_tracker: ComboTracker = %ComboTracker


class ScheduledNote:
	var time_sec: float
	var stream: AudioStream
	var volume_db: float
	## Hit notes: who hit and with what. Null for layers.
	var attacker: Node2D
	var attack: AttackData
	## Layer notes: their sound id. Empty for hits.
	var layer_id: StringName = &""
	var cuts_layers: bool = false


func _ready() -> void:
	var polyphonic: AudioStreamPolyphonic = AudioStreamPolyphonic.new()
	polyphonic.polyphony = max_polyphony
	_player = AudioStreamPlayer.new()
	_player.name = "HitPlayer"
	_player.stream = polyphonic
	_player.bus = bus
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamPlaybackPolyphonic

	Conductor.started.connect(_on_conductor_started)
	EventBus.attack_started.connect(_on_attack_started)
	EventBus.hit_landed.connect(_on_hit_landed)
	_combo_tracker.combo_advanced.connect(_on_combo_advanced)
	_combo_tracker.combo_finished.connect(_on_combo_finished)
	_combo_tracker.combo_broken.connect(_on_combo_broken)


func _process(_delta: float) -> void:
	if _pending.is_empty() or not Conductor.is_running():
		return
	var lookahead_sec: float = _get_lookahead_sec()
	# Trigger when the target is closer than half a frame: error stays within +-half a frame.
	var half_frame_sec: float = get_process_delta_time() / 2.0
	var i: int = 0
	while i < _pending.size():
		var note: ScheduledNote = _pending[i]
		if note.time_sec - lookahead_sec <= half_frame_sec:
			_play(note)
			_pending.remove_at(i)
		else:
			i += 1


## Earliest song time at which a sound started now can be heard.
func _get_lookahead_sec() -> float:
	return Conductor.beat_to_time_sec(Conductor.get_lookahead_position_beats())


func _schedule_time_sec(earliest_sec: float) -> float:
	var snap: BeatSnap = Conductor.get_nearest_subdivision(earliest_sec, sound_subdivision)
	if snap.offset_ms <= 0.0:
		return snap.time_sec
	if snap.offset_ms <= late_tolerance_ms:
		return earliest_sec
	return snap.time_sec + Conductor.get_seconds_per_beat() / snap.steps_per_beat


func _next_bar_time_sec(earliest_sec: float) -> float:
	var bar: float = ceilf(Conductor.time_sec_to_beat(earliest_sec) / BEATS_PER_BAR)
	return Conductor.beat_to_time_sec(bar * BEATS_PER_BAR)


func _next_sample(entry: SoundBankEntry) -> AudioStream:
	var index: int = _round_robin.get(entry.sound_id, 0)
	_round_robin[entry.sound_id] = index + 1
	return entry.samples[index % entry.samples.size()]


func _find_entry(sound_id: StringName) -> SoundBankEntry:
	var entry: SoundBankEntry = sound_bank.find_entry(sound_id)
	if entry == null or entry.samples.is_empty():
		push_warning("MusicDirector: no samples for sound id '%s'." % sound_id)
		return null
	return entry


func _is_layer_pending(layer_id: StringName) -> bool:
	for note: ScheduledNote in _pending:
		if note.layer_id == layer_id:
			return true
	return false


func _play(note: ScheduledNote) -> void:
	if note.layer_id.is_empty():
		_playback.play_stream(note.stream, 0.0, note.volume_db, 1.0, AudioServer.PLAYBACK_TYPE_DEFAULT, bus)
		EventBus.note_played.emit(note.attacker, note.attack)
		return

	if note.cuts_layers:
		for layer_id: StringName in _active_layers:
			_playback.stop_stream(_active_layers[layer_id])
		_active_layers.clear()
	elif _active_layers.has(note.layer_id):
		_playback.stop_stream(_active_layers[note.layer_id])
	_active_layers[note.layer_id] = _playback.play_stream(
		note.stream, 0.0, note.volume_db, 1.0, AudioServer.PLAYBACK_TYPE_DEFAULT, bus)
	EventBus.music_layer_started.emit(note.layer_id, note.stream.get_length())


func _on_conductor_started() -> void:
	_pending.clear()
	_press_times.clear()
	_combo_tracker.reset()


func _on_attack_started(attacker: Node2D, _attack: AttackData) -> void:
	_press_times[attacker] = Conductor.get_song_time_sec()


func _on_hit_landed(attacker: Node2D, _target: Node2D, attack: AttackData) -> void:
	if not Conductor.is_running():
		return
	var press_sec: float = _press_times.get(attacker, Conductor.get_song_time_sec())
	var judge: BeatSnap = Conductor.get_nearest_subdivision(press_sec, difficulty.judge_subdivision)
	var on_time: bool = absf(judge.offset_ms) <= difficulty.window_ms
	EventBus.hit_judged.emit(attacker, attack, on_time, judge.offset_ms)

	var entry: SoundBankEntry = _find_entry(attack.id)
	if entry != null:
		var note: ScheduledNote = ScheduledNote.new()
		note.time_sec = _schedule_time_sec(_get_lookahead_sec())
		note.stream = _next_sample(entry)
		note.volume_db = entry.volume_db
		note.attacker = attacker
		note.attack = attack
		_pending.append(note)

	var rule: DifficultyProfile.OffWindowRule = difficulty.off_window_rule
	var counts: bool = on_time or rule == DifficultyProfile.OffWindowRule.COUNTS
	var breaks: bool = not on_time and rule == DifficultyProfile.OffWindowRule.BREAKS_COMBO
	_combo_tracker.register_hit(attacker, attack.id, Conductor.time_sec_to_beat(press_sec), counts, breaks)


func _on_combo_advanced(attacker: Node2D, hits: Array[StringName]) -> void:
	EventBus.combo_advanced.emit(attacker, hits)


func _on_combo_finished(attacker: Node2D, combo: ComboData) -> void:
	EventBus.combo_finished.emit(attacker, combo)
	if _is_layer_pending(combo.reward_sound_id):
		return
	var entry: SoundBankEntry = _find_entry(combo.reward_sound_id)
	if entry == null:
		return
	var note: ScheduledNote = ScheduledNote.new()
	note.time_sec = _next_bar_time_sec(_get_lookahead_sec())
	note.stream = _next_sample(entry)
	note.volume_db = entry.volume_db
	note.layer_id = combo.reward_sound_id
	note.cuts_layers = combo.is_finisher
	_pending.append(note)


func _on_combo_broken(attacker: Node2D) -> void:
	EventBus.combo_broken.emit(attacker)
