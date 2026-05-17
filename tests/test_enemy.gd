extends GdUnitTestSuite


func test_enemy_scene_loads_with_required_children() -> void:
	var scene := load("res://combat/enemies/enemy.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var node: Node = auto_free(scene.instantiate())
	assert_str(node.name).is_equal("Enemy")
	assert_object(node.get_node_or_null("HealthComponent")).is_not_null()
	assert_object(node.get_node_or_null("WalkTowardPlayerComponent")).is_not_null()
	assert_object(node.get_node_or_null("CollisionShape2D")).is_not_null()
	assert_object(node.get_node_or_null("Visual")).is_not_null()
