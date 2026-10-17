class_name ComboTracker
extends Node
## Tracks each attacker's recent counting hits and reports when they complete a combo.
## The owner decides whether a hit counts or breaks the combo and calls register_hit().

signal combo_advanced(attacker: Node2D, hits: Array[StringName])
signal combo_finished(attacker: Node2D, combo: ComboData)
signal combo_broken(attacker: Node2D)

@export var combos: Array[ComboData] = []
## The combo resets if more than this many beats pass between counting hits.
@export var max_gap_beats: float = 2.0

var _states: Dictionary[Node2D, ComboState] = {}


class ComboState:
	var hits: Array[StringName] = []
	var last_hit_beat: float = 0.0


func _process(_delta: float) -> void:
	if not Conductor.is_running():
		return
	var now_beat: float = Conductor.get_song_position_beats()
	for attacker: Node2D in _states:
		var state: ComboState = _states[attacker]
		if not state.hits.is_empty() and now_beat - state.last_hit_beat > max_gap_beats:
			_break(attacker, state)


## beat: when the hit was pressed, in beats. counts: whether it adds to the combo.
## breaks: whether it resets the combo instead.
func register_hit(attacker: Node2D, attack_id: StringName, beat: float, counts: bool, breaks: bool) -> void:
	var state: ComboState = _states.get(attacker)
	if state == null:
		state = ComboState.new()
		_states[attacker] = state
	if breaks:
		_break(attacker, state)
		return
	if not counts:
		return

	state.hits.append(attack_id)
	state.last_hit_beat = beat
	var longest: int = _longest_sequence_size()
	while state.hits.size() > longest:
		state.hits.remove_at(0)
	combo_advanced.emit(attacker, state.hits.duplicate())

	var combo: ComboData = _find_completed(state.hits)
	if combo == null:
		return
	combo_finished.emit(attacker, combo)
	if combo.is_finisher:
		state.hits.clear()


func reset() -> void:
	_states.clear()


func _break(attacker: Node2D, state: ComboState) -> void:
	if state.hits.is_empty():
		return
	state.hits.clear()
	combo_broken.emit(attacker)


## The longest combo whose sequence matches the end of hits, or null.
func _find_completed(hits: Array[StringName]) -> ComboData:
	var best: ComboData = null
	for combo: ComboData in combos:
		var size: int = combo.sequence.size()
		if size == 0 or size > hits.size():
			continue
		if hits.slice(hits.size() - size) == combo.sequence:
			if best == null or size > best.sequence.size():
				best = combo
	return best


func _longest_sequence_size() -> int:
	var longest: int = 0
	for combo: ComboData in combos:
		longest = maxi(longest, combo.sequence.size())
	return longest
