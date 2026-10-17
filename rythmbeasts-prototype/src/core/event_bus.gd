extends Node
## Cross-system signals. Emitters and listeners never reference each other directly.

signal fighter_fell_off_stage(fighter: Fighter)
signal attack_started(attacker: Node2D, attack: AttackData)
signal hit_landed(attacker: Node2D, target: Node2D, attack: AttackData)
signal hit_blocked(attacker: Node2D, target: Node2D, attack: AttackData)
## A landed hit was judged against the beat grid (offset from the moment it was pressed).
signal hit_judged(attacker: Node2D, attack: AttackData, on_time: bool, offset_ms: float)
## A hit's sample started playing, on the grid.
signal note_played(attacker: Node2D, attack: AttackData)
## A counting hit extended the attacker's combo. hits: the current sequence of attack ids.
signal combo_advanced(attacker: Node2D, hits: Array[StringName])
signal combo_finished(attacker: Node2D, combo: ComboData)
## The combo was reset by a timeout or an off-window hit on a strict difficulty.
signal combo_broken(attacker: Node2D)
## A combo layer (wobble, drop) started playing, on a bar.
signal music_layer_started(sound_id: StringName, duration_sec: float)
## The countdown finished and fighters can act.
signal match_started
## winner_index is MatchDirector.DRAW (-1) when nobody wins.
signal match_finished(winner_index: int)
