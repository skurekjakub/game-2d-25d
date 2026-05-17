extends GdUnitTestSuite


func _make_data(fire_rate: float = 1.0, p_range: float = 500.0) -> WeaponData:
	var d := WeaponData.new()
	d.id = &"test"
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
