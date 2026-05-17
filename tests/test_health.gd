extends GdUnitTestSuite


func _make_health(max_hp: float = 100.0) -> HealthComponent:
	var hc: HealthComponent = auto_free(HealthComponent.new())
	hc.max_hp = max_hp
	hc._ready()  # Not in tree; trigger init manually.
	return hc


func test_starts_at_max_hp() -> void:
	var hc := _make_health(50.0)
	assert_float(hc.hp).is_equal(50.0)


func test_take_damage_reduces_hp() -> void:
	var hc := _make_health(100.0)
	hc.take_damage(30.0)
	assert_float(hc.hp).is_equal(70.0)


func test_take_damage_clamps_at_zero() -> void:
	var hc := _make_health(50.0)
	hc.take_damage(1000.0)
	assert_float(hc.hp).is_equal(0.0)


func test_take_damage_emits_damaged_signal() -> void:
	var hc := _make_health(100.0)
	var captured := {amount = -1.0, new_hp = -1.0}
	hc.damaged.connect(func(amt: float, new_hp: float) -> void:
		captured.amount = amt
		captured.new_hp = new_hp)
	hc.take_damage(25.0)
	assert_float(captured.amount).is_equal(25.0)
	assert_float(captured.new_hp).is_equal(75.0)


func test_take_damage_emits_died_when_hp_reaches_zero() -> void:
	var hc := _make_health(20.0)
	var died_count := [0]
	hc.died.connect(func(_killer: Node) -> void: died_count[0] += 1)
	hc.take_damage(20.0)
	assert_int(died_count[0]).is_equal(1)


func test_take_damage_after_death_is_noop() -> void:
	var hc := _make_health(20.0)
	var died_count := [0]
	hc.died.connect(func(_killer: Node) -> void: died_count[0] += 1)
	hc.take_damage(50.0)  # kills
	hc.take_damage(10.0)  # already dead
	assert_int(died_count[0]).is_equal(1)
	assert_float(hc.hp).is_equal(0.0)
