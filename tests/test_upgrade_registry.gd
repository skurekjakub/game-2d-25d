extends GdUnitTestSuite


class _PlayerStub:
	extends Node
	var speed: float = 200.0


func _make_upgrade(p_id: StringName, w: float = 1.0) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = p_id
	u.display_name = String(p_id)
	u.weight = w
	return u


func _make_player_with_hc(speed: float, hc: HealthComponent) -> Node:
	var stub := _PlayerStub.new()
	stub.speed = speed
	hc.name = "HealthComponent"
	stub.add_child(hc)
	return auto_free(stub)


func _registry_with_pool(pool: Array[UpgradeData]) -> Node:
	var r: Node = auto_free(load("res://combat/upgrades/upgrade_registry.gd").new())
	r.pool = pool
	return r


func test_pick_random_3_returns_three_when_pool_has_five() -> void:
	var pool: Array[UpgradeData] = [
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
	var pool: Array[UpgradeData] = [
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
	var pool: Array[UpgradeData] = [_make_upgrade(&"a"), _make_upgrade(&"b")]
	var r := _registry_with_pool(pool)
	assert_int(r.pick_random_3().size()).is_equal(2)


func test_apply_max_hp_20_increases_max_and_heals() -> void:
	var r := _registry_with_pool([])
	var hc := HealthComponent.new()
	hc.max_hp = 100.0
	hc.hp = 30.0
	var player := _make_player_with_hc(200.0, hc)
	r.apply(_make_upgrade(&"max_hp_20"), player)
	assert_float(hc.max_hp).is_equal(120.0)
	assert_float(hc.hp).is_equal(120.0)


func test_apply_move_speed_15_scales_player_speed() -> void:
	var r := _registry_with_pool([])
	var hc := HealthComponent.new()
	var player := _make_player_with_hc(200.0, hc)
	r.apply(_make_upgrade(&"move_speed_15"), player)
	assert_float(player.get("speed")).is_equal_approx(230.0, 0.001)


func test_apply_heal_to_full_caps_at_max() -> void:
	var r := _registry_with_pool([])
	var hc := HealthComponent.new()
	hc.max_hp = 100.0
	hc.hp = 25.0
	var player := _make_player_with_hc(200.0, hc)
	r.apply(_make_upgrade(&"heal_to_full"), player)
	assert_float(hc.hp).is_equal(100.0)
	assert_float(hc.max_hp).is_equal(100.0)


func test_apply_weapon_upgrade_is_noop_at_apply_time() -> void:
	var r := _registry_with_pool([])
	var hc := HealthComponent.new()
	hc.max_hp = 100.0
	hc.hp = 100.0
	var player := _make_player_with_hc(200.0, hc)
	r.apply(_make_upgrade(&"weapon_damage_25"), player)
	r.apply(_make_upgrade(&"fire_rate_30"), player)
	assert_float(hc.max_hp).is_equal(100.0)
	assert_float(hc.hp).is_equal(100.0)
	assert_float(player.get("speed")).is_equal(200.0)
