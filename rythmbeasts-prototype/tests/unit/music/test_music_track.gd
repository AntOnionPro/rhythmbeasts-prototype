extends GutTest
## Tests for MusicTrack: beat and loop durations derived from BPM and length in beats.

## 150 BPM -> 60 / 150 = 0.4 s per beat.
const TEST_BPM: float = 150.0
const EXPECTED_SECONDS_PER_BEAT: float = 0.4
## 16 bars of 4 beats at 150 BPM -> 64 * 0.4 = 25.6 s (the shape of the reference track loop).
const TEST_LENGTH_BEATS: int = 64
const EXPECTED_LOOP_LENGTH_SEC: float = 25.6
const FLOAT_TOLERANCE: float = 0.000001


func test_seconds_per_beat_is_sixty_divided_by_bpm() -> void:
	var track: MusicTrack = _make_track(TEST_BPM, TEST_LENGTH_BEATS)
	assert_almost_eq(track.get_seconds_per_beat(), EXPECTED_SECONDS_PER_BEAT, FLOAT_TOLERANCE)


func test_loop_length_is_length_in_beats_times_beat_duration() -> void:
	var track: MusicTrack = _make_track(TEST_BPM, TEST_LENGTH_BEATS)
	assert_almost_eq(track.get_loop_length_sec(), EXPECTED_LOOP_LENGTH_SEC, FLOAT_TOLERANCE)


func test_new_track_uses_default_bpm_and_length() -> void:
	var track: MusicTrack = MusicTrack.new()
	assert_eq(track.bpm, MusicTrack.DEFAULT_BPM)
	assert_eq(track.length_beats, MusicTrack.DEFAULT_LENGTH_BEATS)


func _make_track(bpm: float, length_beats: int) -> MusicTrack:
	var track: MusicTrack = MusicTrack.new()
	track.bpm = bpm
	track.length_beats = length_beats
	return track
