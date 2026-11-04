extends GutTest
## Tests for snapping an instant to the nearest step of the beat grid
## (Conductor.get_nearest_subdivision -> BeatSnap).
##
## Uses the Conductor autoload while it is stopped: snapping only depends on the beat duration,
## so no audio plays. Expected values derive from Conductor.get_seconds_per_beat().

const SUBDIVISIONS: Array[Conductor.Subdivision] = [
	Conductor.Subdivision.QUARTER,
	Conductor.Subdivision.EIGHTH,
	Conductor.Subdivision.SIXTEENTH,
]
## Arbitrary step away from 0, so a wrong step index cannot pass by accident.
const STEP_INDEX: int = 5
## Distance from a step used for early/late hits. Must stay under half the shortest step.
const SMALL_OFFSET_SEC: float = 0.01
const FLOAT_TOLERANCE: float = 0.0001
const HALF: float = 0.5


func test_small_offset_is_under_half_the_shortest_step() -> void:
	# Guards the other tests: a larger offset would legitimately snap to a neighbour step.
	var shortest_step_sec: float = _step_sec(Conductor.Subdivision.SIXTEENTH)
	assert_lt(SMALL_OFFSET_SEC, shortest_step_sec * HALF)


func test_instant_on_a_step_snaps_to_it_with_zero_offset() -> void:
	for sub: Conductor.Subdivision in SUBDIVISIONS:
		var time_sec: float = STEP_INDEX * _step_sec(sub)
		var snap: BeatSnap = Conductor.get_nearest_subdivision(time_sec, sub)
		assert_eq(snap.step, STEP_INDEX, _label(sub))
		assert_almost_eq(snap.time_sec, time_sec, FLOAT_TOLERANCE, _label(sub))
		assert_almost_eq(snap.offset_ms, 0.0, FLOAT_TOLERANCE, _label(sub))


func test_late_instant_snaps_back_with_positive_offset() -> void:
	for sub: Conductor.Subdivision in SUBDIVISIONS:
		var time_sec: float = STEP_INDEX * _step_sec(sub) + SMALL_OFFSET_SEC
		var snap: BeatSnap = Conductor.get_nearest_subdivision(time_sec, sub)
		assert_eq(snap.step, STEP_INDEX, _label(sub))
		assert_almost_eq(snap.offset_ms, SMALL_OFFSET_SEC * Conductor.MS_PER_SECOND,
				FLOAT_TOLERANCE, _label(sub))


func test_early_instant_snaps_forward_with_negative_offset() -> void:
	for sub: Conductor.Subdivision in SUBDIVISIONS:
		var time_sec: float = STEP_INDEX * _step_sec(sub) - SMALL_OFFSET_SEC
		var snap: BeatSnap = Conductor.get_nearest_subdivision(time_sec, sub)
		assert_eq(snap.step, STEP_INDEX, _label(sub))
		assert_almost_eq(snap.offset_ms, -SMALL_OFFSET_SEC * Conductor.MS_PER_SECOND,
				FLOAT_TOLERANCE, _label(sub))


func test_instant_just_before_beat_zero_snaps_to_step_zero() -> void:
	for sub: Conductor.Subdivision in SUBDIVISIONS:
		var snap: BeatSnap = Conductor.get_nearest_subdivision(-SMALL_OFFSET_SEC, sub)
		assert_eq(snap.step, 0, _label(sub))
		assert_almost_eq(snap.time_sec, 0.0, FLOAT_TOLERANCE, _label(sub))
		assert_lt(snap.offset_ms, 0.0, _label(sub))


func test_snap_reports_its_subdivision_and_position_in_beats() -> void:
	for sub: Conductor.Subdivision in SUBDIVISIONS:
		var time_sec: float = STEP_INDEX * _step_sec(sub)
		var snap: BeatSnap = Conductor.get_nearest_subdivision(time_sec, sub)
		assert_eq(snap.steps_per_beat, int(sub), _label(sub))
		assert_almost_eq(snap.beat, float(STEP_INDEX) / int(sub), FLOAT_TOLERANCE, _label(sub))


## Length of one grid step, in seconds, for the given subdivision.
func _step_sec(sub: Conductor.Subdivision) -> float:
	return Conductor.get_seconds_per_beat() / int(sub)


func _label(sub: Conductor.Subdivision) -> String:
	return "subdivision: %s" % Conductor.Subdivision.find_key(sub)
