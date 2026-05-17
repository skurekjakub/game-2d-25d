extends GdUnitTestSuite


func test_upgrade_data_defaults() -> void:
	var u := UpgradeData.new()
	assert_str(u.display_name).is_equal("")
	assert_str(u.description).is_equal("")
	assert_float(u.weight).is_equal(1.0)


func test_upgrade_data_fields_settable() -> void:
	var u := UpgradeData.new()
	u.id = &"max_hp_20"
	u.display_name = "+20 Max HP"
	u.description = "Take more hits."
	u.weight = 2.0
	assert_str(String(u.id)).is_equal("max_hp_20")
	assert_str(u.display_name).is_equal("+20 Max HP")
	assert_float(u.weight).is_equal(2.0)
