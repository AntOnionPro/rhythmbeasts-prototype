class_name ComboData
extends Resource
## A sequence of attacks that, landed in a row, adds a musical layer.

@export var display_name: String = ""
## Attack ids in order, e.g. [&"light", &"light", &"heavy"].
@export var sequence: Array[StringName] = []
## SoundBank id of the layer that plays when the combo completes.
@export var reward_sound_id: StringName = &""
## Finishers cut every other layer and reset the combo.
@export var is_finisher: bool = false
