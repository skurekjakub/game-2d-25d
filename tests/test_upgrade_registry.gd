extends GdUnitTestSuite


func _make_upgrade(p_id: StringName, w: float = 1.0) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = p_id
	u.display_name = String(p_id)
	u.weight = w
	return u


func _registry_with_pool(pool: Array) -> Node:
	var r: Node = auto_free(load("res://combat/upgrades/upgrade_registry.gd").new())
	r.pool = pool
	return r


func test_pick_random_3_returns_three_when_pool_has_five() -> void:
	var pool := [
		_make_upgrade(&"a"),
		_make_upgrade(&"b"),
		_make_upgrade(&"c"),
		_make_upgrade(&"d"),
		_make_upgrade(&"e"),
	]
	var r := _registry_with_pool(pool)
	var picks: Array = r.pick_random_3()
	assert_int(picks.size()).is_equal(3)


func test_pick_random_3_returns_distinct() -> void:
	var pool := [
		_make_upgrade(&"a"),
		_make_upgrade(&"b"),
		_make_upgrade(&"c"),
		_make_upgrade(&"d"),
		_make_upgrade(&"e"),
	]
	var r := _registry_with_pool(pool)
	for trial in 20:
		var picks: Array = r.pick_random_3()
		var ids := {}
		for u in picks:
			ids[u.id] = true
		assert_int(ids.size()).is_equal(picks.size())


func test_pick_random_3_degrades_when_pool_smaller_than_three() -> void:
	var r := _registry_with_pool([_make_upgrade(&"a"), _make_upgrade(&"b")])
	assert_int(r.pick_random_3().size()).is_equal(2)


func test_apply_max_hp_20_increases_max_and_heals() -> void:
	var r := _registry_with_pool([])
	var hc: HealthComponent = auto_free(HealthComponent.new())
	hc.max_hp = 100.0
	hc.hp = 30.0
	var player_stub: Node = auto_free(Node.new())
	player_stub.set_meta("_speed", 200.0)
	player_stub.set_meta("_health", hc)
	r.apply(_make_upgrade(&"max_hp_20"), player_stub)
	assert_float(hc.max_hp).is_equal(120.0)
	assert_float(hc.hp).is_equal(120.0)


func test_apply_move_speed_15_scales_player_speed() -> void:
	var r := _registry_with_pool([])
	var hc: HealthComponent = auto_free(HealthComponent.new())
	var player_stub: Node = auto_free(Node.new())
	player_stub.set_meta("_speed", 200.0)
	player_stub.set_meta("_health", hc)
	r.apply(_make_upgrade(&"move_speed_15"), player_stub)
	assert_float(player_stub.get_meta("_speed")).is_equal_approx(230.0, 0.001)


func test_apply_heal_to_full_caps_at_max() -> void:
	var r := _registry_with_pool([])
	var hc: HealthComponent = auto_free(HealthComponent.new())
	hc.max_hp = 100.0
	hc.hp = 25.0
	var player_stub: Node = auto_free(Node.new())
	player_stub.set_meta("_health", hc)
	r.apply(_make_upgrade(&"heal_to_full"), player_stub)
	assert_float(hc.hp).is_equal(100.0)
	assert_float(hc.max_hp).is_equal(100.0)


func test_apply_weapon_upgrade_is_noop_at_apply_time() -> void:
	# Weapon-affecting upgrades must NOT mutate Player or HealthComponent;
	# they're consumed at fire time via WeaponInstance.effective_*().
	var r := _registry_with_pool([])
	var hc: HealthComponent = auto_free(HealthComponent.new())
	hc.max_hp = 100.0
	hc.hp = 100.0
	var player_stub: Node = auto_free(Node.new())
	player_stub.set_meta("_speed", 200.0)
	player_stub.set_meta("_health", hc)
	r.apply(_make_upgrade(&"weapon_damage_25"), player_stub)
	r.apply(_make_upgrade(&"fire_rate_30"), player_stub)
	assert_float(hc.max_hp).is_equal(100.0)
	assert_float(hc.hp).is_equal(100.0)
	assert_float(player_stub.get_meta("_speed")).is_equal(200.0)
