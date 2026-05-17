extends GdUnitTestSuite


func _make_upgrade(p_id: StringName, w: float = 1.0) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = p_id
	u.display_name = String(p_id)
	u.weight = w
	return u


# Returns a real Player instance with adjustable speed + HC. The Player scene
# already ships with a WeaponHost child; tests that want a specific weapon list
# should use TestWorld.player_with_weapons instead.
func _make_player_with_hc(speed: float, hc_max: float, hc_hp: float) -> Player:
	var player: Player = auto_free(preload("res://player/player.tscn").instantiate())
	add_child(player)
	await get_tree().process_frame
	player.speed = speed
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	hc.set_max_hp(hc_max)
	hc.set_hp(hc_hp)
	return player


func _registry_with_pool(pool: Array[UpgradeData]) -> Node:
	var r: Node = auto_free(load("res://combat/upgrades/upgrade_registry.gd").new())
	r.pool = pool
	r.known_weapon_ids = r._load_known_weapon_ids()
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
	var player := await _make_player_with_hc(200.0, 100.0, 30.0)
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	r.apply(load("res://combat/upgrades/data/max_hp_20.tres") as UpgradeData, player)
	assert_float(hc.max_hp).is_equal(120.0)
	assert_float(hc.hp).is_equal(120.0)


func test_apply_move_speed_15_scales_player_speed() -> void:
	var r := _registry_with_pool([])
	var player := await _make_player_with_hc(200.0, 100.0, 100.0)
	r.apply(load("res://combat/upgrades/data/move_speed_15.tres") as UpgradeData, player)
	assert_float(player.speed).is_equal_approx(230.0, 0.001)


func test_apply_heal_to_full_caps_at_max() -> void:
	var r := _registry_with_pool([])
	var player := await _make_player_with_hc(200.0, 100.0, 25.0)
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	r.apply(load("res://combat/upgrades/data/heal_to_full.tres") as UpgradeData, player)
	assert_float(hc.hp).is_equal(100.0)
	assert_float(hc.max_hp).is_equal(100.0)


func test_apply_weapon_upgrade_is_noop_at_apply_time() -> void:
	# Mechanical per-weapon upgrades carry NoopEffect; behavior happens lazily at
	# fire time via WeaponInstance.effective_*. Apply must NOT mutate player state.
	var r := _registry_with_pool([])
	var player := await _make_player_with_hc(200.0, 100.0, 100.0)
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	r.apply(load("res://combat/upgrades/data/blaster_damage_25.tres") as UpgradeData, player)
	r.apply(load("res://combat/upgrades/data/blaster_fire_rate_30.tres") as UpgradeData, player)
	assert_float(hc.max_hp).is_equal(100.0)
	assert_float(hc.hp).is_equal(100.0)
	assert_float(player.speed).is_equal(200.0)


const KNOWN_WEAPON_IDS: Array[StringName] = [&"blaster", &"aura", &"orbital", &"spread"]


func test_pool_gating_hides_acquire_for_owned_weapon() -> void:
	var r := _registry_with_pool(
		[
			_make_upgrade(&"acquire_aura"),
			_make_upgrade(&"max_hp_20"),
		]
	)
	var player: Player = await TestWorld.player_with_weapons(self, [&"aura"])
	var picks: Array = r.pick_random_3_for(player)
	for u in picks:
		assert_str(String(u.id)).is_not_equal("acquire_aura")


func test_pool_gating_hides_weapon_upgrade_for_unowned_weapon() -> void:
	var r := _registry_with_pool(
		[
			_make_upgrade(&"aura_damage_25"),
			_make_upgrade(&"max_hp_20"),
		]
	)
	var player: Player = await TestWorld.player_with_weapons(self, [&"blaster"])
	var picks: Array = r.pick_random_3_for(player)
	for u in picks:
		assert_str(String(u.id)).is_not_equal("aura_damage_25")


func test_pool_gating_surfaces_upgrades_after_acquisition() -> void:
	var r := _registry_with_pool(
		[
			_make_upgrade(&"aura_damage_25"),
		]
	)
	var player: Player = await TestWorld.player_with_weapons(self, [&"aura"])
	var picks: Array = r.pick_random_3_for(player)
	assert_int(picks.size()).is_equal(1)
	assert_str(String(picks[0].id)).is_equal("aura_damage_25")


func test_known_weapon_ids_derives_from_weapon_data_dir() -> void:
	var r := _registry_with_pool([])
	# Derived by scanning combat/weapons/data/*.tres — drift-proof vs hand-list.
	for expected: StringName in [&"blaster", &"aura", &"orbital", &"spread"]:
		assert_bool(expected in r.known_weapon_ids).is_true()


func test_every_upgrade_tres_has_effect() -> void:
	# Every UpgradeData on disk must carry a non-null effect — guarantees the
	# Strategy dispatch in apply() can delegate without push_warning fallthrough.
	const DATA_DIR: String = "res://combat/upgrades/data"
	for entry: String in ResourceLoader.list_directory(DATA_DIR):
		if not (entry.ends_with(".tres") or entry.ends_with(".res")):
			continue
		var u := load("%s/%s" % [DATA_DIR, entry]) as UpgradeData
		assert_object(u.effect).append_failure_message("%s has null effect" % entry).is_not_null()


func test_apply_acquire_aura_adds_weapon_to_host() -> void:
	var player: Player = await TestWorld.player_with_weapons(self, [])
	UpgradeRegistry.apply(
		load("res://combat/upgrades/data/acquire_aura.tres") as UpgradeData, player
	)
	assert_bool(StringName("aura") in player.weapon_host.owned_weapon_ids()).is_true()


func test_apply_acquire_orbital_adds_weapon_to_host() -> void:
	var player: Player = await TestWorld.player_with_weapons(self, [])
	UpgradeRegistry.apply(
		load("res://combat/upgrades/data/acquire_orbital.tres") as UpgradeData, player
	)
	assert_bool(StringName("orbital") in player.weapon_host.owned_weapon_ids()).is_true()
