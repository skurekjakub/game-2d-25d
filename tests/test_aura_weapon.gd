extends GdUnitTestSuite

const AURA_SCENE := preload("res://combat/weapons/aura/aura_weapon.tscn")


func before_test() -> void:
	Game.start_run()


func _make_aura_with_instance() -> Node:
	var aura: Node = AURA_SCENE.instantiate()
	add_child(auto_free(aura))
	var data: WeaponData = load("res://combat/weapons/data/aura.tres") as WeaponData
	var inst := WeaponInstance.new(data)
	if aura.has_method("configure"):
		aura.configure(inst)
	return aura


func test_aura_scene_loads() -> void:
	var aura := _make_aura_with_instance()
	assert_object(aura).is_not_null()


func test_aura_tick_damages_overlapping_enemy() -> void:
	# Construct a stub enemy with a HealthComponent inside the aura's radius.
	var aura := _make_aura_with_instance()
	await get_tree().process_frame
	var enemy: Node2D = auto_free(load("res://combat/enemies/enemy.tscn").instantiate())
	enemy.global_position = Vector2.ZERO
	add_child(enemy)
	await get_tree().process_frame
	var hc: HealthComponent = enemy.get_node("HealthComponent")
	var hp_before: float = hc.hp
	# Advance time past one full tick interval.
	for i in 60:
		aura._owned_tick(0.05)
		await get_tree().process_frame
	assert_float(hc.hp).is_less(hp_before)


func test_aura_radius_upgrade_scales_radius() -> void:
	Game.run_state.upgrades_taken = [_upgrade(&"aura_radius_25")]
	var aura := _make_aura_with_instance()
	await get_tree().process_frame
	var shape: CollisionShape2D = aura.get_node("Shape")
	# Default radius 80; +25% = 100.
	assert_float((shape.shape as CircleShape2D).radius).is_equal_approx(100.0, 0.001)


func _upgrade(p_id: StringName) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = p_id
	return u
