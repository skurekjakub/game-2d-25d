extends GdUnitTestSuite


func test_spawn_phase_class_exists_with_defaults() -> void:
	var p: SpawnPhase = SpawnPhase.new()
	assert_int(p.starts_at_seconds).is_equal(0)
	assert_int(p.duration_seconds).is_equal(30)
	assert_float(p.spawn_rate_per_sec).is_equal(1.0)
	assert_object(p.enemy_data).is_null()


func test_end_time_seconds_returns_start_plus_duration() -> void:
	var p: SpawnPhase = SpawnPhase.new()
	p.starts_at_seconds = 30
	p.duration_seconds = 30
	assert_int(p.end_time_seconds()).is_equal(60)
