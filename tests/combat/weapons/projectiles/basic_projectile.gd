extends GdUnitTestSuite


func _instance() -> BasicProjectile:
	return auto_free(load("res://combat/weapons/projectiles/basic_projectile.tscn").instantiate())


func test_projectile_scene_loads() -> void:
	var p := _instance()
	assert_object(p).is_not_null()
	assert_str(p.name).is_equal("BasicProjectile")


func test_set_target_position_normalizes_direction_right() -> void:
	var p := _instance()
	p.position = Vector2.ZERO
	p.set_target_position(Vector2(100, 0))
	assert_vector(p.direction).is_equal(Vector2.RIGHT)


func test_set_target_position_normalizes_direction_diagonal() -> void:
	var p := _instance()
	p.position = Vector2.ZERO
	p.set_target_position(Vector2(100, 100))
	assert_float(p.direction.length()).is_equal_approx(1.0, 0.001)


func test_set_target_position_zero_distance_falls_back_to_right() -> void:
	var p := _instance()
	p.position = Vector2(50, 50)
	p.set_target_position(Vector2(50, 50))
	assert_vector(p.direction).is_equal(Vector2.RIGHT)


func test_default_damage_is_settable() -> void:
	var p := _instance()
	p.damage = 25.0
	assert_float(p.damage).is_equal(25.0)
