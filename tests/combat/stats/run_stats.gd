extends GdUnitTestSuite


func test_run_stats_starts_empty() -> void:
	var s := RunStats.new()
	assert_int(s.damage_by_weapon.size()).is_equal(0)
	assert_int(s.alive_time_by_weapon.size()).is_equal(0)
	assert_float(s.total_damage()).is_equal(0.0)


func test_run_stats_row_holds_fields() -> void:
	var r := RunStatsRow.new(&"blaster", "Blaster", 100.0, 25.0, 0.5)
	assert_str(String(r.weapon_id)).is_equal("blaster")
	assert_str(r.display_name).is_equal("Blaster")
	assert_float(r.damage).is_equal(100.0)
	assert_float(r.dps).is_equal(25.0)
	assert_float(r.bar_fill_fraction).is_equal(0.5)


func test_add_damage_accumulates_per_weapon() -> void:
	var s := RunStats.new()
	s.add_damage(&"blaster", 10.0)
	s.add_damage(&"blaster", 5.0)
	s.add_damage(&"aura", 3.0)
	assert_float(s.damage_by_weapon[&"blaster"]).is_equal(15.0)
	assert_float(s.damage_by_weapon[&"aura"]).is_equal(3.0)
	assert_float(s.total_damage()).is_equal(18.0)


func test_add_damage_drops_empty_id() -> void:
	# Resolver returns &"" when source can't be classified — don't pollute meter.
	var s := RunStats.new()
	s.add_damage(&"", 999.0)
	assert_float(s.total_damage()).is_equal(0.0)


func test_tick_alive_time_only_for_owned() -> void:
	var s := RunStats.new()
	s.tick_alive_time([&"blaster", &"aura"] as Array[StringName], 0.25)
	s.tick_alive_time([&"blaster"] as Array[StringName], 0.25)
	assert_float(s.alive_time_by_weapon[&"blaster"]).is_equal_approx(0.5, 0.001)
	assert_float(s.alive_time_by_weapon[&"aura"]).is_equal_approx(0.25, 0.001)


func test_dps_for_uses_alive_time() -> void:
	var s := RunStats.new()
	s.add_damage(&"spread", 300.0)
	s.alive_time_by_weapon[&"spread"] = 60.0  # 5 dps
	assert_float(s.dps_for(&"spread")).is_equal_approx(5.0, 0.001)


func test_dps_for_handles_zero_alive_time() -> void:
	var s := RunStats.new()
	s.add_damage(&"spread", 50.0)
	assert_float(s.dps_for(&"spread")).is_equal(0.0)


func test_elapsed_seconds_uses_started_and_ended() -> void:
	var s := RunStats.new()
	s.mark_run_started(100.0)
	assert_float(s.elapsed_seconds_at(160.0)).is_equal_approx(60.0, 0.001)
	s.mark_run_ended(160.0)
	assert_float(s.elapsed_seconds()).is_equal_approx(60.0, 0.001)


func test_percent_of_total_for() -> void:
	var s := RunStats.new()
	s.add_damage(&"blaster", 30.0)
	s.add_damage(&"aura", 10.0)
	assert_float(s.percent_of_total_for(&"blaster")).is_equal_approx(0.75, 0.001)
	assert_float(s.percent_of_total_for(&"aura")).is_equal_approx(0.25, 0.001)
	assert_float(s.percent_of_total_for(&"orbital")).is_equal(0.0)


func test_sorted_top_n_truncates_and_sorts() -> void:
	var s := RunStats.new()
	s.add_damage(&"blaster", 30.0)
	s.add_damage(&"aura", 10.0)
	s.add_damage(&"spread", 20.0)
	s.add_damage(&"orbital", 5.0)
	var rows := s.sorted_top_n(2, _display_lookup())
	assert_int(rows.size()).is_equal(2)
	assert_str(String(rows[0].weapon_id)).is_equal("blaster")
	assert_str(String(rows[1].weapon_id)).is_equal("spread")


func test_sorted_all_returns_every_weapon() -> void:
	var s := RunStats.new()
	s.add_damage(&"blaster", 1.0)
	s.add_damage(&"aura", 2.0)
	s.add_damage(&"spread", 3.0)
	var rows := s.sorted_all(_display_lookup())
	assert_int(rows.size()).is_equal(3)
	assert_str(String(rows[0].weapon_id)).is_equal("spread")  # highest first


func _display_lookup() -> Callable:
	return func(wid: StringName) -> String: return String(wid).capitalize()
