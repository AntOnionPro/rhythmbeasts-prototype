class_name MatchHud
extends CanvasLayer
## Match overlay: timer, each player's damage and stocks in their color, and big
## center messages (countdown, result).

const SECONDS_PER_MINUTE: int = 60
## Countdown texts stay on screen this many beats.
const COUNTDOWN_MESSAGE_BEATS: float = 1.0
const DRAW_TEXT: String = "DRAW"
const WIN_TEXT: String = "P%d WINS!"
const RESTART_HINT: String = "Press Enter to play again"

var _match: MatchDirector
var _fighters: Array[Fighter] = []
var _stocks: Array[int] = []
## Song time (seconds) after which the countdown message is cleared.
var _message_until_sec: float = INF

@onready var _timer_label: Label = %Timer
@onready var _status_labels: Array[Label] = [%P1Status, %P2Status]
@onready var _message_label: Label = %Message


func _process(_delta: float) -> void:
	if _match == null:
		return
	var remaining: int = ceili(_match.get_remaining_sec())
	@warning_ignore("integer_division")
	_timer_label.text = "%d:%02d" % [remaining / SECONDS_PER_MINUTE, remaining % SECONDS_PER_MINUTE]
	if Conductor.get_song_time_sec() > _message_until_sec:
		_message_label.text = ""
		_message_until_sec = INF


func setup(match_director: MatchDirector, fighters: Array[Fighter]) -> void:
	_match = match_director
	_fighters = fighters
	_stocks.clear()
	for i: int in _fighters.size():
		_stocks.append(0)
		_status_labels[i].modulate = _fighters[i].config.body_color
		_fighters[i].damage_changed.connect(_on_damage_changed.bind(i))
	_match.countdown_ticked.connect(_on_countdown_ticked)
	_match.stocks_changed.connect(_on_stocks_changed)
	_match.match_finished.connect(_on_match_finished)
	_message_label.text = ""


func _refresh_status(player_index: int) -> void:
	_status_labels[player_index].text = "P%d  %d%%   Stocks %d" % [
		player_index + 1, roundi(_fighters[player_index].get_damage()), _stocks[player_index]]


func _on_damage_changed(_damage: float, player_index: int) -> void:
	_refresh_status(player_index)


func _on_stocks_changed(player_index: int, stocks: int) -> void:
	_stocks[player_index] = stocks
	_refresh_status(player_index)


func _on_countdown_ticked(text: String) -> void:
	_message_label.text = text
	_message_until_sec = Conductor.get_song_time_sec() + Conductor.beat_to_time_sec(COUNTDOWN_MESSAGE_BEATS)


func _on_match_finished(winner_index: int) -> void:
	var result: String = DRAW_TEXT if winner_index == MatchDirector.DRAW else WIN_TEXT % (winner_index + 1)
	_message_label.text = "%s\n%s" % [result, RESTART_HINT]
	_message_until_sec = INF
