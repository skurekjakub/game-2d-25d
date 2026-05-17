extends GdUnitTestSuite


func test_hud_scene_loads() -> void:
	var hud: Control = auto_free(preload("res://ui/hud.tscn").instantiate())
	add_child(hud)
	await get_tree().process_frame
	assert_object(hud).is_not_null()


func test_hud_updates_hp_bar_on_player_health_changed() -> void:
	var hud: Control = auto_free(preload("res://ui/hud.tscn").instantiate())
	add_child(hud)
	await get_tree().process_frame
	EventBus.player_health_changed.emit(40.0, 100.0)
	await get_tree().process_frame
	var hp_bar: ProgressBar = hud.get_node("HpBar")
	assert_float(hp_bar.max_value).is_equal(100.0)
	assert_float(hp_bar.value).is_equal(40.0)


func test_hud_updates_level_label_on_level_up() -> void:
	var hud: Control = auto_free(preload("res://ui/hud.tscn").instantiate())
	add_child(hud)
	await get_tree().process_frame
	EventBus.level_up.emit(7)
	await get_tree().process_frame
	var level_label: Label = hud.get_node("LevelLabel")
	assert_str(level_label.text).contains("7")


func test_hud_resets_on_run_started() -> void:
	var hud: Control = auto_free(preload("res://ui/hud.tscn").instantiate())
	add_child(hud)
	await get_tree().process_frame
	# Pre-fill state.
	EventBus.level_up.emit(5)
	EventBus.xp_gained.emit(10)
	await get_tree().process_frame
	# Reset.
	EventBus.run_started.emit()
	await get_tree().process_frame
	var level_label: Label = hud.get_node("LevelLabel")
	assert_str(level_label.text).contains("1")
