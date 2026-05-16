extends GdUnitTestSuite


func test_event_bus_has_damage_dealt_signal() -> void:
	var bus: Node = auto_free(load("res://bootstrap/event_bus.gd").new())
	assert_bool(bus.has_signal("damage_dealt")).is_true()


func test_event_bus_has_enemy_killed_signal() -> void:
	var bus: Node = auto_free(load("res://bootstrap/event_bus.gd").new())
	assert_bool(bus.has_signal("enemy_killed")).is_true()


func test_event_bus_has_xp_gained_signal() -> void:
	var bus: Node = auto_free(load("res://bootstrap/event_bus.gd").new())
	assert_bool(bus.has_signal("xp_gained")).is_true()


func test_event_bus_has_level_up_signal() -> void:
	var bus: Node = auto_free(load("res://bootstrap/event_bus.gd").new())
	assert_bool(bus.has_signal("level_up")).is_true()


func test_event_bus_has_boss_spawned_signal() -> void:
	var bus: Node = auto_free(load("res://bootstrap/event_bus.gd").new())
	assert_bool(bus.has_signal("boss_spawned")).is_true()
