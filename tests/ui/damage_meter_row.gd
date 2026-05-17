extends GdUnitTestSuite


func test_apply_sets_labels_and_bar() -> void:
	var row: Control = preload("res://ui/damage_meter_row.tscn").instantiate()
	add_child(auto_free(row))
	await get_tree().process_frame
	var data := RunStatsRow.new(&"blaster", "Blaster", 1234.0, 25.0, 0.42)
	row.apply(data)
	var name_label: Label = row.get_node("NameLabel")
	var value_label: Label = row.get_node("ValueLabel")
	var bar: ProgressBar = row.get_node("PercentBar")
	assert_str(name_label.text).is_equal("Blaster")
	assert_str(value_label.text).contains("1234")
	assert_float(bar.value).is_equal_approx(42.0, 0.1)


func test_apply_clamps_bar_to_one() -> void:
	var row: Control = preload("res://ui/damage_meter_row.tscn").instantiate()
	add_child(auto_free(row))
	await get_tree().process_frame
	var data := RunStatsRow.new(&"x", "X", 100.0, 0.0, 1.5)
	row.apply(data)
	var bar: ProgressBar = row.get_node("PercentBar")
	assert_float(bar.value).is_equal_approx(100.0, 0.1)
