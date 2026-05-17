extends GdUnitTestSuite


func before_test() -> void:
	Game.start_run()


func test_panel_hidden_until_run_ends() -> void:
	var panel: Control = preload("res://ui/damage_summary_panel.tscn").instantiate()
	add_child(auto_free(panel))
	await get_tree().process_frame
	assert_bool(panel.visible).is_false()


func test_panel_shows_all_weapons_on_run_ended() -> void:
	Game.run_state.stats.add_damage(&"blaster", 300.0)
	Game.run_state.stats.add_damage(&"aura", 100.0)
	var panel: Control = preload("res://ui/damage_summary_panel.tscn").instantiate()
	add_child(auto_free(panel))
	await get_tree().process_frame
	Game.end_run(false)
	await get_tree().process_frame
	assert_bool(panel.visible).is_true()
	var list: VBoxContainer = panel.get_node("Body/List")
	assert_int(list.get_child_count()).is_equal(2)


func test_panel_displays_totals() -> void:
	Game.run_state.stats.add_damage(&"blaster", 500.0)
	var panel: Control = preload("res://ui/damage_summary_panel.tscn").instantiate()
	add_child(auto_free(panel))
	await get_tree().process_frame
	Game.end_run(true)
	await get_tree().process_frame
	var total_label: Label = panel.get_node("Body/Header/TotalLabel")
	assert_str(total_label.text).contains("500")
