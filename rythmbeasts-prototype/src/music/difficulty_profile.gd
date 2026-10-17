class_name DifficultyProfile
extends Resource
## How strict hit timing is. Sounds always land on the grid; difficulty only decides
## whether a hit counts for the musical combo (see docs/prototype.md).

## What happens to the combo when a hit falls outside the window.
enum OffWindowRule { COUNTS, DOES_NOT_COUNT, BREAKS_COMBO }

@export var display_name: String = ""
## Max distance (either side) from the nearest judge step for a hit to be on time.
@export var window_ms: float = 50.0
@export var judge_subdivision: Conductor.Subdivision = Conductor.Subdivision.EIGHTH
@export var off_window_rule: OffWindowRule = OffWindowRule.DOES_NOT_COUNT
