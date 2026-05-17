extends GdUnitTestSuite


func test_enemy_data_class_exists_with_defaults() -> void:
	var data: EnemyData = EnemyData.new()
	assert_float(data.max_hp).is_equal(30.0)
	assert_float(data.speed).is_equal(60.0)
	assert_int(data.xp_value).is_equal(1)


func test_basic_walker_resource_loads_from_disk() -> void:
	var data: EnemyData = load("res://combat/enemies/data/basic_walker.tres") as EnemyData
	assert_object(data).is_not_null()
	assert_str(data.id).is_equal("basic_walker")
	assert_float(data.max_hp).is_equal(30.0)
	assert_int(data.xp_value).is_equal(1)
