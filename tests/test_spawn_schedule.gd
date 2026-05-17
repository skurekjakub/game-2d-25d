extends GdUnitTestSuite


func _make_phase(starts_at: int, duration: int) -> SpawnPhase:
	var p := SpawnPhase.new()
	p.starts_at_seconds = starts_at
	p.duration_seconds = duration
	return p


func test_schedule_defaults_to_empty_phases() -> void:
	var s: SpawnSchedule = SpawnSchedule.new()
	assert_int(s.phases.size()).is_equal(0)


func test_total_duration_seconds_sums_last_phase_end() -> void:
	var s := SpawnSchedule.new()
	s.phases = [_make_phase(0, 30), _make_phase(30, 30)]
	assert_int(s.total_duration_seconds()).is_equal(60)


func test_total_duration_zero_when_empty() -> void:
	var s := SpawnSchedule.new()
	assert_int(s.total_duration_seconds()).is_equal(0)


func test_phase_at_time_returns_first_phase_during_its_window() -> void:
	var s := SpawnSchedule.new()
	var a := _make_phase(0, 30)
	var b := _make_phase(30, 30)
	s.phases = [a, b]
	assert_object(s.phase_at_time(0.0)).is_same(a)
	assert_object(s.phase_at_time(15.0)).is_same(a)
	assert_object(s.phase_at_time(29.999)).is_same(a)


func test_phase_at_time_returns_second_phase_after_boundary() -> void:
	var s := SpawnSchedule.new()
	var a := _make_phase(0, 30)
	var b := _make_phase(30, 30)
	s.phases = [a, b]
	assert_object(s.phase_at_time(30.0)).is_same(b)
	assert_object(s.phase_at_time(45.0)).is_same(b)


func test_phase_at_time_returns_null_after_wave_end() -> void:
	var s := SpawnSchedule.new()
	s.phases = [_make_phase(0, 30), _make_phase(30, 30)]
	assert_object(s.phase_at_time(60.0)).is_null()
	assert_object(s.phase_at_time(120.0)).is_null()


func test_phase_index_at_time_returns_minus_one_after_wave_end() -> void:
	var s := SpawnSchedule.new()
	s.phases = [_make_phase(0, 30), _make_phase(30, 30)]
	assert_int(s.phase_index_at_time(0.0)).is_equal(0)
	assert_int(s.phase_index_at_time(30.0)).is_equal(1)
	assert_int(s.phase_index_at_time(60.0)).is_equal(-1)
