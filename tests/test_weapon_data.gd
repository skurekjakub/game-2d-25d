extends GdUnitTestSuite


func test_weapon_data_class_exists_with_defaults() -> void:
	var data: WeaponData = WeaponData.new()
	assert_float(data.base_damage).is_equal(10.0)
	assert_float(data.fire_rate).is_equal(1.0)
	assert_float(data.range).is_equal(600.0)
	assert_int(data.targeting).is_equal(WeaponData.Targeting.NEAREST)


func test_basic_blaster_resource_loads_from_disk() -> void:
	var data: WeaponData = load("res://combat/weapons/data/basic_blaster.tres") as WeaponData
	assert_object(data).is_not_null()
	assert_str(data.id).is_equal("basic_blaster")
	assert_float(data.base_damage).is_equal(10.0)
	assert_float(data.fire_rate).is_equal(1.0)
