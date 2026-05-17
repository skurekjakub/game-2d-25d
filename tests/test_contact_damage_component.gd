extends GdUnitTestSuite

# Tests the component's response to body_entered / body_exited and _process
# tick advancement. We bypass the Area2D connection (component's `_ready` is
# never triggered because we don't add it to the tree) and call the handlers
# directly with stub bodies. Integration with Area2D detection is covered by
# the visual smoke test in M1.3 Task 9.


func _make_damageable_body(max_hp: float = 100.0) -> Node:
	var body: Node = auto_free(Node.new())
	var health: HealthComponent = HealthComponent.new()
	health.max_hp = max_hp
	body.add_child(health)
	health._ready()  # not in tree → trigger init manually
	return body


func _make_component(damage: float = 5.0, tick_interval: float = 1.0) -> ContactDamageComponent:
	var c: ContactDamageComponent = auto_free(ContactDamageComponent.new())
	c.damage = damage
	c.tick_interval = tick_interval
	return c


func test_first_tick_fires_on_enter() -> void:
	var c := _make_component(5.0)
	var body := _make_damageable_body(100.0)
	var health: HealthComponent = body.get_child(0)
	c._on_body_entered(body)
	assert_float(health.hp).is_equal(95.0)


func test_ticks_at_interval() -> void:
	var c := _make_component(5.0, 1.0)
	var body := _make_damageable_body(100.0)
	var health: HealthComponent = body.get_child(0)
	c._on_body_entered(body)
	c._process(1.0)
	c._process(1.0)
	assert_float(health.hp).is_equal(85.0)


func test_partial_tick_does_not_fire() -> void:
	var c := _make_component(5.0, 1.0)
	var body := _make_damageable_body(100.0)
	var health: HealthComponent = body.get_child(0)
	c._on_body_entered(body)
	c._process(0.4)
	c._process(0.4)
	assert_float(health.hp).is_equal(95.0)


func test_no_tick_after_exit() -> void:
	var c := _make_component(5.0, 1.0)
	var body := _make_damageable_body(100.0)
	var health: HealthComponent = body.get_child(0)
	c._on_body_entered(body)
	c._on_body_exited(body)
	c._process(5.0)
	assert_float(health.hp).is_equal(95.0)


func test_exit_then_reenter_resets_timer() -> void:
	var c := _make_component(5.0, 1.0)
	var body := _make_damageable_body(100.0)
	var health: HealthComponent = body.get_child(0)
	c._on_body_entered(body)
	c._on_body_exited(body)
	c._on_body_entered(body)
	assert_float(health.hp).is_equal(90.0)


func test_non_damageable_body_ignored() -> void:
	var c := _make_component(5.0)
	var bare_body: Node = auto_free(Node.new())
	c._on_body_entered(bare_body)
	c._process(2.0)
	assert_int(c._timers.size()).is_equal(0)


func test_freed_body_does_not_crash_tick() -> void:
	var c := _make_component(5.0, 1.0)
	var body := _make_damageable_body(100.0)
	c._on_body_entered(body)
	body.free()
	c._process(2.0)
	assert_int(c._timers.size()).is_equal(0)
