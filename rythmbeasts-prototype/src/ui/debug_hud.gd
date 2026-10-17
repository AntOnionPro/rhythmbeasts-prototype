class_name DebugHud
extends CanvasLayer
## Tuning overlay: active difficulty, the timing of the last judged hit and combo progress.

const ON_TIME_TEXT: String = "ON TIME"
const OFF_WINDOW_TEXT: String = "off window"
const NO_COMBO_TEXT: String = "-"
const BROKEN_TEXT: String = "broken"

var _difficulty_text: String = "-"
var _last_hit_text: String = "-"
var _combo_text: String = NO_COMBO_TEXT

@onready var _info: Label = %Info


func _ready() -> void:
	EventBus.hit_judged.connect(_on_hit_judged)
	EventBus.combo_advanced.connect(_on_combo_advanced)
	EventBus.combo_finished.connect(_on_combo_finished)
	EventBus.combo_broken.connect(_on_combo_broken)
	_refresh()


func show_difficulty(profile: DifficultyProfile) -> void:
	_difficulty_text = "%s (+-%d ms)" % [profile.display_name, roundi(profile.window_ms)]
	_refresh()


func _refresh() -> void:
	_info.text = "Difficulty: %s\nLast hit: %s\nCombo: %s" % [_difficulty_text, _last_hit_text, _combo_text]


func _on_hit_judged(_attacker: Node2D, attack: AttackData, on_time: bool, offset_ms: float) -> void:
	_last_hit_text = "%s  %+.0f ms  %s" % [attack.id, offset_ms, ON_TIME_TEXT if on_time else OFF_WINDOW_TEXT]
	_refresh()


func _on_combo_advanced(_attacker: Node2D, hits: Array[StringName]) -> void:
	var letters: PackedStringArray = []
	for hit: StringName in hits:
		letters.append(String(hit).left(1).to_upper())
	_combo_text = " ".join(letters)
	_refresh()


func _on_combo_finished(_attacker: Node2D, combo: ComboData) -> void:
	_combo_text += "  -> %s!" % combo.display_name.to_upper()
	_refresh()


func _on_combo_broken(_attacker: Node2D) -> void:
	_combo_text = BROKEN_TEXT
	_refresh()
