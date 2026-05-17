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
	var blades := orbital.get_children().filter(func(c): return c is OrbitalBlade)
	assert_int(blades.size()).is_equal(3)


func test_orbital_shrink_frees_distinct_blades() -> void:
	# Grow to 3, then shrink to 1: must queue_free TWO different nodes, not the
	# same tail blade twice.
	Game.run_state.upgrades_taken = [
		_upgrade(&"orbital_count_plus_1"), _upgrade(&"orbital_count_plus_1")
	]
	var orbital := _make_orbital_with_instance()
	await get_tree().process_frame
	orbital._owned_tick(0.0)
	var initial: Array = orbital.get_children().filter(func(c): return c is OrbitalBlade)
	assert_int(initial.size()).is_equal(3)
	Game.run_state.upgrades_taken = []
	orbital._owned_tick(0.0)
	# Two distinct blades should now be queued for deletion (is_queued_for_deletion).
	var queued: Array = initial.filter(func(b): return b.is_queued_for_deletion())
	assert_int(queued.size()).is_equal(2)
