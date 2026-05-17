extends GdUnitTestSuite


# Helpers

func _make_phase(starts_at: int, duration: int, rate: float) -> SpawnPhase:
	var p := SpawnPhase.new()
	p.starts_at_seconds = starts_at
	p.duration_seconds = duration
	p.spawn_rate_per_sec = rate
	return p


func _make_schedule(phases: Array) -> SpawnSchedule:
	var s := SpawnSchedule.new()
	# Re-type-cast — phases is Array[SpawnPhase] in production but Array in test helpers.
	var typed: Array[SpawnPhase] = []
	for p in phases:
		typed.append(p)
	s.phases = typed
	return s


# compute_spawn_position — pure math, no engine state

func test_compute_spawn_position_is_on_radius_around_player() -> void:
	var player_pos := Vector2(100.0, 200.0)
	var radius: float = 500.0
	# Angle 0 rad → spawn at (player.x + radius, player.y)
	var pos := SpawnerDirector.compute_spawn_position(player_pos, radius, 0.0)
	assert_float(pos.x).is_equal_approx(600.0, 0.001)
	assert_float(pos.y).is_equal_approx(200.0, 0.001)


func test_compute_spawn_position_at_pi_over_2_is_above_player() -> void:
	var player_pos := Vector2.ZERO
	var radius: float = 100.0
	# Angle PI/2 rad → spawn at (0, +radius) in Godot's Y-down convention.
	var pos := SpawnerDirector.compute_spawn_position(player_pos, radius, PI * 0.5)
	assert_float(pos.x).is_equal_approx(0.0, 0.001)
	assert_float(pos.y).is_equal_approx(100.0, 0.001)


func test_compute_spawn_position_distance_to_player_equals_radius() -> void:
	var player_pos := Vector2(50.0, 50.0)
	var radius: float = 400.0
	for angle in [0.0, 0.7, 1.5, 3.0, 4.5, 6.0]:
		var pos := SpawnerDirector.compute_spawn_position(player_pos, radius, angle)
		assert_float(pos.distance_to(player_pos)).is_equal_approx(radius, 0.01)


# Budget accumulation

func test_starts_with_zero_spawn_budget() -> void:
	var dir: SpawnerDirector = auto_free(SpawnerDirector.new())
	assert_float(dir.spawn_budget).is_equal(0.0)


func test_accumulate_budget_at_rate_1_for_half_second_gives_half() -> void:
	var dir: SpawnerDirector = auto_free(SpawnerDirector.new())
	dir.accumulate_budget(0.5, 1.0)
	assert_float(dir.spawn_budget).is_equal_approx(0.5, 0.001)


func test_accumulate_budget_does_not_overflow_past_one_full_spawn() -> void:
	# Budget represents "fractional spawns owed"; we never cap it at 1, because
	# at rate=10 with delta=0.2 we'd legitimately want to spawn 2 in one tick.
	var dir: SpawnerDirector = auto_free(SpawnerDirector.new())
	dir.accumulate_budget(1.0, 10.0)
	assert_float(dir.spawn_budget).is_equal_approx(10.0, 0.001)


func test_consume_one_spawn_subtracts_one_from_budget() -> void:
	var dir: SpawnerDirector = auto_free(SpawnerDirector.new())
	dir.spawn_budget = 2.5
	dir.consume_one_spawn()
	assert_float(dir.spawn_budget).is_equal_approx(1.5, 0.001)


# Phase transition tracking

func test_emits_phase_advanced_when_phase_index_advances() -> void:
	var dir: SpawnerDirector = auto_free(SpawnerDirector.new())
	dir.schedule = _make_schedule([_make_phase(0, 30, 1.0), _make_phase(30, 30, 2.0)])
	var captured := [-99]
	dir.phase_advanced.connect(func(idx: int) -> void: captured[0] = idx)
	# Simulate phase 0 → phase 1 transition.
	dir._last_phase_index = 0
	dir._on_time_advanced(30.5)
	assert_int(captured[0]).is_equal(1)


func test_emits_wave_ended_once_when_time_exceeds_total_duration() -> void:
	var dir: SpawnerDirector = auto_free(SpawnerDirector.new())
	dir.schedule = _make_schedule([_make_phase(0, 30, 1.0), _make_phase(30, 30, 2.0)])
	var fire_count := [0]
	dir.wave_ended.connect(func() -> void: fire_count[0] += 1)
	# First crossing → emit.
	dir._on_time_advanced(60.0)
	# Second crossing → no re-emit.
	dir._on_time_advanced(75.0)
	assert_int(fire_count[0]).is_equal(1)
