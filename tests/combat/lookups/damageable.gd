extends GdUnitTestSuite


func _make_enemy_stub_with_hp(hp: float) -> Node2D:
	var stub: Node2D = auto_free(Node2D.new())
	stub.add_to_group(Damageable.ENEMY_GROUP)
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_hp = hp
	hc.hp = hp
	stub.add_child(hc)
	add_child(stub)
	return stub


func test_try_damage_applies_and_returns_true_for_enemy() -> void:
	var enemy := _make_enemy_stub_with_hp(20.0)
	var source: Node = auto_free(Node.new())
	add_child(source)
	var hc: HealthComponent = enemy.get_node("HealthComponent") as HealthComponent
	var hit: bool = Damageable.try_damage(enemy, 7.0, source)
	assert_bool(hit).is_true()
	assert_float(hc.hp).is_equal_approx(13.0, 0.001)


func test_try_damage_returns_false_for_non_enemy() -> void:
	var noise: Node2D = auto_free(Node2D.new())
	add_child(noise)
	var source: Node = auto_free(Node.new())
	add_child(source)
	assert_bool(Damageable.try_damage(noise, 7.0, source)).is_false()


func test_try_damage_returns_false_for_body_without_hc() -> void:
	var stub: Node2D = auto_free(Node2D.new())
	stub.add_to_group(Damageable.ENEMY_GROUP)
	add_child(stub)
	var source: Node = auto_free(Node.new())
	add_child(source)
	assert_bool(Damageable.try_damage(stub, 7.0, source)).is_false()


func test_try_damage_returns_false_for_null_body() -> void:
	var source: Node = auto_free(Node.new())
	add_child(source)
	assert_bool(Damageable.try_damage(null, 5.0, source)).is_false()


func test_try_damage_emits_damage_dealt() -> void:
	var enemy := _make_enemy_stub_with_hp(20.0)
	var source: Node = auto_free(Node.new())
	add_child(source)
	monitor_signals(EventBus, false)
	Damageable.try_damage(enemy, 7.0, source)
	await assert_signal(EventBus).is_emitted("damage_dealt", [source, enemy, 7.0])
