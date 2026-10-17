extends Node2D
## Manual test: visual pulse and a click on every beat to validate Conductor sync by ear.
## Space/Enter (ui_accept) shows the offset of the tap to the nearest eighth note.

const PULSE_BASE_RADIUS: float = 60.0
const PULSE_EXTRA_RADIUS: float = 40.0
## Higher = sharper decay of the pulse after each beat.
const PULSE_EXPONENT: float = 3.0
const PULSE_COLOR: Color = Color(0.95, 0.35, 0.55)
const STEP_DOT_RADIUS: float = 8.0
const STEP_DOT_SPACING: float = 32.0
const STEP_DOT_OFFSET_Y: float = 140.0
const STEP_DOT_ON_COLOR: Color = Color(1.0, 0.9, 0.3)
const STEP_DOT_OFF_COLOR: Color = Color(0.3, 0.3, 0.3)
const STEPS_PER_BEAT_DRAWN: int = Conductor.Subdivision.SIXTEENTH
const TAP_SUBDIVISION: Conductor.Subdivision = Conductor.Subdivision.EIGHTH
const MS_PER_SECOND: float = 1000.0

@export var track: MusicTrack
## Play the clock track audibly to compare its kick against the click.
@export var clock_audible: bool = false
## Trigger the click ahead by the output latency so it is heard on the beat.
@export var compensate_latency: bool = true

var _next_click_beat: int = 0
var _last_tap_text: String = "-"

@onready var _click: AudioStreamPlayer = %Click
@onready var _info: Label = %Info


func _ready() -> void:
	Conductor.beat_ticked.connect(_on_beat_ticked)
	Conductor.start(track, clock_audible)


func _exit_tree() -> void:
	Conductor.stop()


func _process(_delta: float) -> void:
	if compensate_latency:
		var lookahead_beats: float = Conductor.get_lookahead_position_beats()
		if lookahead_beats >= _next_click_beat:
			_click.play()
			_next_click_beat = floori(lookahead_beats) + 1
	_update_info()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var snap: BeatSnap = Conductor.get_nearest_subdivision_now(TAP_SUBDIVISION)
		_last_tap_text = "step %d (beat %.2f)  offset %+.1f ms" % [snap.step, snap.beat, snap.offset_ms]


func _draw() -> void:
	var center: Vector2 = get_viewport_rect().size / 2.0
	var beats: float = maxf(Conductor.get_song_position_beats(), 0.0)
	var beat_phase: float = fposmod(beats, 1.0)
	var pulse: float = pow(1.0 - beat_phase, PULSE_EXPONENT)
	draw_circle(center, PULSE_BASE_RADIUS + PULSE_EXTRA_RADIUS * pulse, PULSE_COLOR)

	var current_step: int = floori(beat_phase * STEPS_PER_BEAT_DRAWN)
	var first_dot_x: float = center.x - STEP_DOT_SPACING * (STEPS_PER_BEAT_DRAWN - 1) / 2.0
	var i: int = 0
	while i < STEPS_PER_BEAT_DRAWN:
		var dot_pos: Vector2 = Vector2(first_dot_x + i * STEP_DOT_SPACING, center.y + STEP_DOT_OFFSET_Y)
		var dot_color: Color = STEP_DOT_ON_COLOR if i == current_step else STEP_DOT_OFF_COLOR
		draw_circle(dot_pos, STEP_DOT_RADIUS, dot_color)
		i += 1


func _update_info() -> void:
	_info.text = "BPM: %.1f\nBeat: %.3f\nOutput latency: %.1f ms\nLatency compensation: %s\nLast tap: %s" % [
		Conductor.get_bpm(),
		Conductor.get_song_position_beats(),
		AudioServer.get_output_latency() * MS_PER_SECOND,
		"on" if compensate_latency else "off",
		_last_tap_text,
	]


func _on_beat_ticked(_beat: int) -> void:
	if not compensate_latency:
		_click.play()
