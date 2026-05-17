extends GdUnitTestSuite


func _make_data(fire_rate: float = 1.0, p_range: float = 500.0) -> WeaponData:
	var d := WeaponData.new()
	d.id = &"blaster"
	d.base_damage = 10.0
	d.fire_rate = fire_rate
	d.range = p_range
	return d


func test_starts_able_to_fire() -> void:
	var w := WeaponInstance.new(_make_data())
	assert_bool(w.can_fire()).is_true()
	assert_float(w.cooldown_remaining).is_equal(0.0)


func test_reset_cooldown_uses_fire_rate() -> void:
	var w := WeaponInstance.new(_make_data(2.0))  # 2 shots/s = 0.5s cooldown
	w.reset_cooldown()
	assert_float(w.cooldown_remaining).is_equal_approx(0.5, 0.001)
	assert_bool(w.can_fire()).is_false()


func test_tick_decrements_cooldown() -> void:
	var w := WeaponInstance.new(_make_data(1.0))
	w.reset_cooldown()
	w.tick(0.3)
	assert_float(w.cooldown_remaining).is_equal_approx(0.7, 0.001)
	w.tick(0.7)
	assert_bool(w.can_fire()).is_true()


func test_tick_clamps_cooldown_at_zero() -> void:
	var w := WeaponInstance.new(_make_data(1.0))
	w.reset_cooldown()
	w.tick(999.0)
	assert_float(w.cooldown_remaining).is_equal(0.0)


func test_find_nearest_target_returns_null_when_empty() -> void:
	var target := WeaponInstance.find_nearest_target(Vector2.ZERO, [], 500.0)
	assert_object(target).is_null()


func test_find_nearest_target_picks_closest_in_range() -> void:
	var n1: Node2D = auto_free(Node2D.new())
	n1.position = Vector2(100, 0)
	var n2: Node2D = auto_free(Node2D.new())
	n2.position = Vector2(50, 0)
	var n3: Node2D = auto_free(Node2D.new())
	n3.position = Vector2(300, 0)
	var target := WeaponInstance.find_nearest_target(Vector2.ZERO, [n1, n2, n3], 500.0)
	assert_object(target).is_same(n2)


func test_find_nearest_target_respects_range() -> void:
	var far: Node2D = auto_free(Node2D.new())
	far.position = Vector2(1000, 0)
	var target := WeaponInstance.find_nearest_target(Vector2.ZERO, [far], 500.0)
	assert_object(target).is_null()


func test_find_nearest_target_skips_non_node2d() -> void:
	var n2d: Node2D = auto_free(Node2D.new())
	n2d.position = Vector2(50, 0)
	var plain: Node = auto_free(Node.new())
	var target := WeaponInstance.find_nearest_target(Vector2.ZERO, [plain, n2d], 500.0)
	assert_object(target).is_same(n2d)


# Game.run_state is shared autoload state. Every test that mutates upgrades_taken
# MUST call _reset_upgrades() before and after to avoid leaking state across tests.
func _upgrade(p_id: StringName) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = p_id
	return u


func _reset_upgrades() -> void:
	Game.run_state.upgrades_taken = []


func test_effective_damage_no_upgrades_returns_base() -> void:
	_reset_upgrades()
	var w := WeaponInstance.new(_make_data())
	assert_float(w.effective_damage()).is_equal(10.0)


func test_effective_damage_one_upgrade_multiplies() -> void:
	_reset_upgrades()
	Game.run_state.upgrades_taken = [_upgrade(&"blaster_damage_25")]
	var w := WeaponInstance.new(_make_data())
	assert_float(w.effective_damage()).is_equal_approx(12.5, 0.001)
	_reset_upgrades()


func test_effective_damage_compounds() -> void:
	_reset_upgrades()
	Game.run_state.upgrades_taken = [
		_upgrade(&"blaster_damage_25"),
		_upgrade(&"blaster_damage_25"),
		_upgrade(&"blaster_damage_25"),
	]
	var w := WeaponInstance.new(_make_data())
	# 10 * 1.25^3 = 19.531...
	assert_float(w.effective_damage()).is_equal_approx(19.531, 0.01)
	_reset_upgrades()


func test_effective_damage_ignores_unrelated_upgrades() -> void:
	_reset_upgrades()
	Game.run_state.upgrades_taken = [_upgrade(&"max_hp_20"), _upgrade(&"move_speed_15")]
	var w := WeaponInstance.new(_make_data())
	assert_float(w.effective_damage()).is_equal(10.0)
	_reset_upgrades()


func test_effective_fire_rate_compounds() -> void:
	_reset_upgrades()
	Game.run_state.upgrades_taken = [
		_upgrade(&"blaster_fire_rate_30"),
		_upgrade(&"blaster_fire_rate_30"),
	]
	var w := WeaponInstance.new(_make_data(1.0))
	# 1.0 * 1.30^2 = 1.69
	assert_float(w.effective_fire_rate()).is_equal_approx(1.69, 0.001)
	_reset_upgrades()


func test_level_counts_weapon_affecting_upgrades() -> void:
	_reset_upgrades()
	Game.run_state.upgrades_taken = [
		_upgrade(&"blaster_damage_25"),
		_upgrade(&"blaster_fire_rate_30"),
		_upgrade(&"max_hp_20"),  # not weapon-affecting
	]
	var w := WeaponInstance.new(_make_data())
	assert_int(w.level()).is_equal(3)  # 1 base + 2 weapon upgrades
	_reset_upgrades()


func test_effective_damage_per_weapon_id_isolation() -> void:
	_reset_upgrades()
	# Aura upgrade should not affect a Blaster instance.
	Game.run_state.upgrades_taken = [_upgrade(&"aura_damage_25")]
	var w := WeaponInstance.new(_make_data())  # id = "blaster"
	assert_float(w.effective_damage()).is_equal(10.0)
	_reset_upgrades()


func test_count_upgrade_counts_matching_ids() -> void:
	_reset_upgrades()
	Game.run_state.upgrades_taken = [
		_upgrade(&"orbital_count_plus_1"),
		_upgrade(&"orbital_count_plus_1"),
		_upgrade(&"aura_radius_25"),
	]
	var w := WeaponInstance.new(_make_data())
	assert_int(w.count_upgrade(&"orbital_count_plus_1")).is_equal(2)
	assert_int(w.count_upgrade(&"aura_radius_25")).is_equal(1)
	assert_int(w.count_upgrade(&"spread_pellets_plus_1")).is_equal(0)
	_reset_upgrades()


func test_level_counts_per_weapon_prefix_only() -> void:
	_reset_upgrades()
	Game.run_state.upgrades_taken = [
		_upgrade(&"blaster_damage_25"),
		_upgrade(&"blaster_fire_rate_30"),
		_upgrade(&"aura_damage_25"),
	]
	var w := WeaponInstance.new(_make_data())  # blaster
	assert_int(w.level()).is_equal(3)  # 1 base + 2 blaster_*
	_reset_upgrades()


func test_effective_pellet_count_defaults_to_data() -> void:
	_reset_upgrades()
	var d := _make_data()
	d.pellet_count = 3
	var w := WeaponInstance.new(d)
	assert_int(w.effective_pellet_count()).is_equal(3)
	_reset_upgrades()


func test_effective_pellet_count_does_not_leak_across_weapons() -> void:
	_reset_upgrades()
	# spread_pellets_plus_1 must affect Spread only, not Blaster.
	Game.run_state.upgrades_taken = [
		_upgrade(&"spread_pellets_plus_1"),
		_upgrade(&"spread_pellets_plus_1"),
	]
	var blaster := WeaponInstance.new(_make_data())  # id = "blaster"
	assert_int(blaster.effective_pellet_count()).is_equal(1)
	_reset_upgrades()


func test_effective_pellet_count_stacks_per_weapon_key() -> void:
	_reset_upgrades()
	var spread_data := _make_data()
	spread_data.id = &"spread"
	spread_data.pellet_count = 3
	Game.run_state.upgrades_taken = [
		_upgrade(&"spread_pellets_plus_1"),
		_upgrade(&"spread_pellets_plus_1"),
	]
	var spread := WeaponInstance.new(spread_data)
	assert_int(spread.effective_pellet_count()).is_equal(5)
	_reset_upgrades()
