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
