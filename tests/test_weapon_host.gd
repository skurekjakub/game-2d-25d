extends GdUnitTestSuite


func _make_blaster_data() -> WeaponData:
	var d := WeaponData.new()
	d.id = &"blaster"
	d.base_damage = 10.0
	d.fire_rate = 1.0
	d.range = 500.0
	d.projectile_scene = preload("res://combat/weapons/projectiles/basic_projectile.tscn")
	return d


func _make_host() -> WeaponHost:
	var shooter := Node2D.new()
	shooter.name = "Shooter"
	add_child(auto_free(shooter))
	var host := WeaponHost.new()
	host.name = "WeaponHost"
	shooter.add_child(host)
	return host


func test_add_weapon_appends_instance() -> void:
	var host := _make_host()
	host.add_weapon(_make_blaster_data())
	assert_int(host.weapons.size()).is_equal(1)
	assert_str(String(host.weapons[0].data.id)).is_equal("blaster")


func test_owned_weapon_ids_returns_ids() -> void:
	var host := _make_host()
	host.add_weapon(_make_blaster_data())
	var ids := host.owned_weapon_ids()
	assert_int(ids.size()).is_equal(1)
	assert_str(String(ids[0])).is_equal("blaster")


func test_add_weapon_with_scene_spawns_as_player_child() -> void:
	var host := _make_host()
	var data := _make_blaster_data()
	host.add_weapon(data)
	assert_object(host.weapons[0].node).is_null()


func test_physics_process_no_ops_when_run_is_over() -> void:
	Game.start_run()
	var host := _make_host()
	host.add_weapon(_make_blaster_data())
	var weapon: WeaponInstance = host.weapons[0]
	weapon.reset_cooldown()
	var before: float = weapon.cooldown_remaining
	Game.end_run(false)  # flips run_state.is_over = true
	host._physics_process(0.5)
	# Cooldown unchanged → weapon.tick() was not called.
	assert_float(weapon.cooldown_remaining).is_equal_approx(before, 0.0001)
