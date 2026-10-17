class_name SoundBankEntry
extends Resource
## Samples for one sound id (an attack id or a combo layer id). Consecutive plays use
## the samples in order (round robin), so repeating a sample builds a phrase (e.g. F, F, Ab, Eb).

@export var sound_id: StringName = &""
@export var samples: Array[AudioStream] = []
@export var volume_db: float = 0.0
