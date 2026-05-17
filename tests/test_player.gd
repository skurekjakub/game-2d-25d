extends GdUnitTestSuite

# Tests the pure input-to-velocity computation, no scene tree required.


func test_no_input_yields_zero_velocity() -> void:
	var velocity := Player.compute_velocity(Vector2.ZERO, 200.0)
	assert_vector(velocity).is_equal(Vector2.ZERO)


func test_full_right_input_yields_rightward_velocity() -> void:
	var velocity := Player.compute_velocity(Vector2.RIGHT, 200.0)
	assert_vector(velocity).is_equal(Vector2(200.0, 0.0))


func test_diagonal_input_is_normalized_to_speed_magnitude() -> void:
	var velocity := Player.compute_velocity(Vector2(1.0, 1.0), 200.0)
	assert_float(velocity.length()).is_equal_approx(200.0, 0.001)


func test_player_scene_loads_and_instantiates() -> void:
	var scene := load("res://player/player.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var node: Node = auto_free(scene.instantiate())
	assert_object(node).is_not_null()
	assert_str(node.name).is_equal("Player")


func test_died_emits_run_ended_false_and_disables_physics() -> void:
	var scene := load("res://player/player.tscn") as PackedScene
	var player: Node = auto_free(scene.instantiate())
	add_child(player)
	var captured := {fired = false, victory = true}
	EventBus.run_ended.connect(
		func(victory: bool) -> void:
			captured.fired = true
			captured.victory = victory
	)
	var health: HealthComponent = player.get_node("HealthComponent")
	health.take_damage(9999.0)
	assert_bool(captured.fired).is_true()
	assert_bool(captured.victory).is_false()
	assert_bool(player.is_physics_processing()).is_false()
