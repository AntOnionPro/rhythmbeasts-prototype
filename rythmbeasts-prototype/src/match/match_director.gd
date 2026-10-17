class_name MatchDirector
extends Node
## Match flow: beat-synced countdown, timer derived from Conductor time, stocks, respawns
## and result. A fighter loses a stock when it falls off the stage; the match ends when
## someone runs out of stocks or time runs out. ui_accept restarts a finished match.

signal countdown_ticked(text: String)
signal stocks_changed(player_index: int, stocks: int)
## winner_index is DRAW when nobody wins.
signal match_finished(winner_index: int)

enum State { IDLE, COUNTDOWN, FIGHTING, FINISHED }

const DRAW: int = -1

@export var config: MatchConfig

var _state: State = State.IDLE
var _fighters: Array[Fighter] = []
var _stage: Stage
var _stocks: Array[int] = []
var _countdown_start_beat: int = 0
var _fight_start_sec: float = 0.0
var _remaining_at_finish_sec: float = 0.0


func _ready() -> void:
	Conductor.beat_ticked.connect(_on_beat_ticked)
	EventBus.fighter_fell_off_stage.connect(_on_fighter_fell_off_stage)


func _process(_delta: float) -> void:
	if _state == State.FIGHTING and get_remaining_sec() <= 0.0:
		_finish(_winner_by_time())


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.FINISHED and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()


## Places the fighters and starts the countdown. Call after the Conductor has started.
func start(fighters: Array[Fighter], stage: Stage) -> void:
	_fighters = fighters
	_stage = stage
	_stocks.clear()
	for i: int in _fighters.size():
		_stocks.append(config.stocks)
		_respawn(i)
		_fighters[i].set_controls_enabled(false)
		stocks_changed.emit(i, config.stocks)

	# Count down so the last text lands on the next reachable bar downbeat.
	var last_step: int = config.countdown_texts.size() - 1
	var earliest_go_beat: int = ceili(Conductor.get_song_position_beats()) + last_step
	var go_beat: int = ceili(float(earliest_go_beat) / Conductor.BEATS_PER_BAR) * Conductor.BEATS_PER_BAR
	_countdown_start_beat = go_beat - last_step
	_state = State.COUNTDOWN


func get_remaining_sec() -> float:
	match _state:
		State.FIGHTING:
			return maxf(config.duration_sec - (Conductor.get_song_time_sec() - _fight_start_sec), 0.0)
		State.FINISHED:
			return _remaining_at_finish_sec
		_:
			return config.duration_sec


func get_stocks(player_index: int) -> int:
	return _stocks[player_index]


func _respawn(player_index: int) -> void:
	_fighters[player_index].respawn_at(
		_stage.get_spawn_position(player_index), _stage.get_spawn_facing(player_index))


func _begin_fight(go_beat: int) -> void:
	_state = State.FIGHTING
	_fight_start_sec = Conductor.beat_to_time_sec(go_beat)
	for fighter: Fighter in _fighters:
		fighter.set_controls_enabled(true)
	EventBus.match_started.emit()


func _finish(winner_index: int) -> void:
	_remaining_at_finish_sec = get_remaining_sec()
	_state = State.FINISHED
	for fighter: Fighter in _fighters:
		fighter.set_controls_enabled(false)
	match_finished.emit(winner_index)
	EventBus.match_finished.emit(winner_index)


## Most stocks wins; then least damage; otherwise a draw.
func _winner_by_time() -> int:
	var best_stocks: int = _stocks.max()
	var candidates: Array[int] = []
	for i: int in _fighters.size():
		if _stocks[i] == best_stocks:
			candidates.append(i)
	if candidates.size() == 1:
		return candidates[0]

	var winner: int = DRAW
	var lowest_damage: float = INF
	for i: int in candidates:
		var damage: float = _fighters[i].get_damage()
		if is_equal_approx(damage, lowest_damage):
			winner = DRAW
		elif damage < lowest_damage:
			lowest_damage = damage
			winner = i
	return winner


## The only fighter with stocks left, or DRAW.
func _last_standing() -> int:
	var standing: int = DRAW
	for i: int in _fighters.size():
		if _stocks[i] > 0:
			if standing != DRAW:
				return DRAW
			standing = i
	return standing


func _on_beat_ticked(beat: int) -> void:
	if _state != State.COUNTDOWN:
		return
	var step: int = beat - _countdown_start_beat
	if step < 0 or step >= config.countdown_texts.size():
		return
	countdown_ticked.emit(config.countdown_texts[step])
	if step == config.countdown_texts.size() - 1:
		_begin_fight(beat)


func _on_fighter_fell_off_stage(fighter: Fighter) -> void:
	var player_index: int = _fighters.find(fighter)
	if player_index == -1 or _state == State.FINISHED:
		return
	if _state == State.FIGHTING:
		_stocks[player_index] -= 1
		stocks_changed.emit(player_index, _stocks[player_index])
		if _stocks[player_index] <= 0:
			fighter.visible = false
			_finish(_last_standing())
			return
	_respawn.call_deferred(player_index)
