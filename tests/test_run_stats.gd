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
