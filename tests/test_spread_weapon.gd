extends GdUnitTestSuite


func before_test() -> void:
	Game.start_run()


func _spread_data() -> WeaponData:
	return load("res://combat/weapons/data/spread.tres") as WeaponData


func test_spread_data_defaults_to_3_pellets() -> void:
	var d := _spread_data()
	assert_int(d.pellet_count).is_equal(3)


func test_spread_data_uses_basic_projectile_scene() -> void:
	var d := _spread_data()
	assert_object(d.projectile_scene).is_not_null()


func test_acquire_spread_adds_weapon_to_host() -> void:
	var player: Player = await TestWorld.player_with_weapons(self, [])
	UpgradeRegistry.apply(
		load("res://combat/upgrades/data/acquire_spread.tres") as UpgradeData, player
	)
	assert_bool(StringName("spread") in player.weapon_host.owned_weapon_ids()).is_true()
