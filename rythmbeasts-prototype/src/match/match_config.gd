class_name MatchConfig
extends Resource
## Rules of a match.

@export var duration_sec: float = 180.0
@export var stocks: int = 3
## Shown one per beat; the last one lands on a bar's downbeat and starts the fight.
@export var countdown_texts: Array[String] = ["3", "2", "1", "GO!"]
