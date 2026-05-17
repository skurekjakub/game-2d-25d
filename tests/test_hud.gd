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


func test_hud_weapon_list_scales_to_owned_weapons() -> void:
	var hud: Control = auto_free(preload("res://ui/hud.tscn").instantiate())
	add_child(hud)
	# Build a player-with-host owning 3 weapons.
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(auto_free(player))
	var host := WeaponHost.new()
	host.name = "WeaponHost"
	player.add_child(host)
	for wid: StringName in [&"blaster", &"aura", &"orbital"]:
		var d := WeaponData.new()
		d.id = wid
		d.display_name = String(wid).capitalize()
		host.weapons.append(WeaponInstance.new(d))
	await get_tree().process_frame
	# Trigger HUD refresh.
	EventBus.upgrade_applied.emit(UpgradeData.new())
	await get_tree().process_frame
	var weapon_list: VBoxContainer = hud.get_node("WeaponList")
	assert_int(weapon_list.get_child_count()).is_equal(3)
