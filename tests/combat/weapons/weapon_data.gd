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
	assert_str(data.id).is_equal("blaster")
	assert_float(data.base_damage).is_equal(10.0)
	assert_float(data.fire_rate).is_equal(1.0)


func test_weapon_data_default_pellet_count_is_one() -> void:
	var d := WeaponData.new()
	assert_int(d.pellet_count).is_equal(1)


func test_weapon_data_weapon_scene_defaults_null() -> void:
	var d := WeaponData.new()
	assert_object(d.weapon_scene).is_null()


func test_blaster_tres_has_blaster_id() -> void:
	var d: WeaponData = load("res://combat/weapons/data/basic_blaster.tres") as WeaponData
	assert_str(String(d.id)).is_equal("blaster")
