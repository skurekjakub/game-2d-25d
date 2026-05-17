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
	# Build a minimal player tree with a WeaponHost.
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(auto_free(player))
	var host := WeaponHost.new()
	host.name = "WeaponHost"
	player.add_child(host)
	# Apply acquire upgrade.
	var u := UpgradeData.new()
	u.id = &"acquire_spread"
	UpgradeRegistry.apply(u, player)
	# Player now owns Spread.
	var ids := host.owned_weapon_ids()
	assert_bool(StringName("spread") in ids).is_true()
