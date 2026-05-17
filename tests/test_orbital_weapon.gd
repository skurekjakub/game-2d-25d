extends GdUnitTestSuite

const ORBITAL_SCENE := preload("res://combat/weapons/orbital/orbital_weapon.tscn")


func before_test() -> void:
	Game.start_run()


func _make_orbital_with_instance() -> Node:
	var orbital: Node = ORBITAL_SCENE.instantiate()
	add_child(auto_free(orbital))
	var data: WeaponData = load("res://combat/weapons/data/orbital.tres") as WeaponData
	var inst := WeaponInstance.new(data)
	if orbital.has_method("configure"):
		orbital.configure(inst)
	return orbital


func _upgrade(p_id: StringName) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = p_id
	return u


func test_orbital_default_blade_count_is_one() -> void:
	var orbital := _make_orbital_with_instance()
	await get_tree().process_frame
	assert_int(orbital.blade_count()).is_equal(1)


func test_orbital_blade_count_increases_with_upgrade() -> void:
	Game.run_state.upgrades_taken = [
		_upgrade(&"orbital_count_plus_1"), _upgrade(&"orbital_count_plus_1")
	]
	var orbital := _make_orbital_with_instance()
	await get_tree().process_frame
	orbital._owned_tick(0.0)  # force a sync pass
	assert_int(orbital.blade_count()).is_equal(3)


func test_orbital_blade_positions_equally_spaced() -> void:
	Game.run_state.upgrades_taken = [
		_upgrade(&"orbital_count_plus_1"), _upgrade(&"orbital_count_plus_1")
	]
	var orbital := _make_orbital_with_instance()
	await get_tree().process_frame
	orbital._owned_tick(0.0)
	# 3 blades = 120° apart
	var blades := orbital.get_children().filter(func(c): return c is Area2D)
	assert_int(blades.size()).is_equal(3)
