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
	Game.start_run()
	var scene := load("res://player/player.tscn") as PackedScene
	var player: Node = auto_free(scene.instantiate())
	add_child(player)
	var captured := {fired = false, victory = true}
	var listener := func(victory: bool) -> void:
		captured.fired = true
		captured.victory = victory
	EventBus.run_ended.connect(listener)
	var health: HealthComponent = player.get_node("HealthComponent")
	health.take_damage(9999.0)
	assert_bool(captured.fired).is_true()
	assert_bool(captured.victory).is_false()
	assert_bool(player.is_physics_processing()).is_false()
	EventBus.run_ended.disconnect(listener)


func test_damaged_emits_damage_dealt_eventbus() -> void:
	var scene := load("res://player/player.tscn") as PackedScene
	var player: Node = auto_free(scene.instantiate())
	add_child(player)
	var captured := {fired = false, amount = -1.0, target_name = ""}
	EventBus.damage_dealt.connect(
		func(_source: Node, target: Node, amount: float) -> void:
			captured.fired = true
			captured.amount = amount
			captured.target_name = target.name
	)
	var health: HealthComponent = player.get_node("HealthComponent")
	health.take_damage(7.5)
	assert_bool(captured.fired).is_true()
	assert_float(captured.amount).is_equal(7.5)
	assert_str(captured.target_name).is_equal("Player")


func test_player_reemits_health_changed_on_damage() -> void:
	var player: Player = auto_free(preload("res://player/player.tscn").instantiate())
	add_child(player)
	await get_tree().process_frame
	monitor_signals(EventBus, false)
	player._health.take_damage(15.0)
	await assert_signal(EventBus).is_emitted(
		"player_health_changed", [player._health.hp, player._health.max_hp]
	)


func test_player_reemits_health_changed_on_max_hp_change() -> void:
	var player: Player = auto_free(preload("res://player/player.tscn").instantiate())
	add_child(player)
	await get_tree().process_frame
	monitor_signals(EventBus, false)
	player._health.set_max_hp(150.0)
	await assert_signal(EventBus).is_emitted("player_health_changed", [player._health.hp, 150.0])


func test_player_death_routes_through_game_end_run() -> void:
	Game.start_run()
	var player: Player = auto_free(preload("res://player/player.tscn").instantiate())
	add_child(player)
	await get_tree().process_frame
	monitor_signals(EventBus, false)
	player._health.take_damage(99999.0)
	await assert_signal(EventBus).is_emitted("run_ended", [false])
	assert_bool(Game.run_state.is_over).is_true()
