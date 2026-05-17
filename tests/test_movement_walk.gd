extends GdUnitTestSuite


func test_zero_velocity_when_at_target() -> void:
	var v := WalkTowardPlayerComponent.compute_velocity(
		Vector2(100, 100), Vector2(100, 100), 60.0)
	assert_vector(v).is_equal(Vector2.ZERO)


func test_velocity_toward_right_target() -> void:
	var v := WalkTowardPlayerComponent.compute_velocity(
		Vector2(0, 0), Vector2(10, 0), 60.0)
	assert_vector(v).is_equal(Vector2(60.0, 0.0))


func test_velocity_toward_diagonal_target_speed_preserved() -> void:
	var v := WalkTowardPlayerComponent.compute_velocity(
		Vector2(0, 0), Vector2(10, 10), 60.0)
	assert_float(v.length()).is_equal_approx(60.0, 0.001)
