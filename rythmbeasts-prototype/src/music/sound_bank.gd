class_name SoundBank
extends Resource
## Maps sound ids (attack ids, combo layer ids) to samples. Logic never references sample paths directly.

@export var entries: Array[SoundBankEntry] = []


## Returns the entry for sound_id, or null if there is none.
func find_entry(sound_id: StringName) -> SoundBankEntry:
	for entry: SoundBankEntry in entries:
		if entry.sound_id == sound_id:
			return entry
	return null
