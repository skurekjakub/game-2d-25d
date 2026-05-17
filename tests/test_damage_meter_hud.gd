extends GdUnitTestSuite


func before_test() -> void:
	Game.start_run()


func test_meter_hidden_when_no_damage() -> void:
	var meter: Control = preload("res://ui/damage_meter_hud.tscn").instantiate()
	add_child(auto_free(meter))
	await get_tree().process_frame
	meter.refresh_now()
	assert_bool(meter.visible).is_false()


func test_meter_shows_rows_after_damage() -> void:
	Game.run_state.stats.add_damage(&"blaster", 100.0)
	Game.run_state.stats.add_damage(&"aura", 50.0)
	var meter: Control = preload("res://ui/damage_meter_hud.tscn").instantiate()
	add_child(auto_free(meter))
	await get_tree().process_frame
	meter.refresh_now()
	assert_bool(meter.visible).is_true()
	var list: VBoxContainer = meter.get_node("List")
	assert_int(list.get_child_count()).is_equal(2)


func test_meter_caps_at_5_rows() -> void:
	for wid: StringName in [&"a", &"b", &"c", &"d", &"e", &"f", &"g"]:
		Game.run_state.stats.add_damage(wid, 10.0)
	var meter: Control = preload("res://ui/damage_meter_hud.tscn").instantiate()
	add_child(auto_free(meter))
	await get_tree().process_frame
	meter.refresh_now()
	var list: VBoxContainer = meter.get_node("List")
	assert_int(list.get_child_count()).is_equal(5)
