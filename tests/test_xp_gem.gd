extends GdUnitTestSuite


func test_xp_gem_scene_loads() -> void:
	var scene := load("res://world/xp_gem.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var node: Node = auto_free(scene.instantiate())
	assert_str(node.name).is_equal("XpGem")


func test_xp_gem_value_is_settable() -> void:
	var gem: XpGem = auto_free(load("res://world/xp_gem.tscn").instantiate())
	gem.value = 5
	assert_int(gem.value).is_equal(5)


func test_pickup_credits_xp_and_frees_gem_on_player_overlap() -> void:
	Game.start_run()
	var initial_xp: int = Game.run_state.xp
	# Do NOT use auto_free on gem: the pickup calls queue_free(), so it frees itself.
	# auto_free would hold a reference that prevents is_instance_valid from going false.
	var gem: XpGem = load("res://world/xp_gem.tscn").instantiate()
	gem.value = 3
	var player: CharacterBody2D = auto_free(CharacterBody2D.new())
	player.collision_layer = 2  # matches real Player; XpGem hurtbox scans layer 2.
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	(shape.shape as CircleShape2D).radius = 8.0
	player.add_child(shape)
	player.add_to_group("player")
	add_child(player)
	add_child(gem)
	# Same position so the gem's Area2D detects player overlap on next physics step.
	player.global_position = Vector2.ZERO
	gem.global_position = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	# Allow deferred queue_free() calls to resolve before asserting.
	await get_tree().process_frame
	assert_int(Game.run_state.xp).is_equal(initial_xp + 3)
	assert_bool(is_instance_valid(gem)).is_false()
