extends GdUnitTestSuite

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")


func before_test() -> void:
	Game.start_run()


func test_damage_dealt_routes_to_run_stats() -> void:
	var proj: BasicProjectile = (
		preload("res://combat/weapons/projectiles/basic_projectile.tscn").instantiate()
	)
	proj.weapon_id = &"blaster"
	add_child(auto_free(proj))
	var dummy_target := Node.new()
	add_child(auto_free(dummy_target))
	EventBus.damage_dealt.emit(proj, dummy_target, 12.5)
	await get_tree().process_frame
	assert_float(Game.run_state.stats.damage_by_weapon[&"blaster"]).is_equal(12.5)


func test_unresolvable_source_dropped() -> void:
	var noise := Node.new()
	add_child(auto_free(noise))
	EventBus.damage_dealt.emit(noise, noise, 999.0)
	await get_tree().process_frame
	assert_float(Game.run_state.stats.total_damage()).is_equal(0.0)


func test_process_ticks_alive_time_only_when_run_active() -> void:
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	add_child(player)
	await get_tree().process_frame
	await get_tree().process_frame
	var alive_during_run: float = Game.run_state.stats.alive_time_by_weapon.get(&"blaster", 0.0)
	assert_float(alive_during_run).is_greater(0.0)
	Game.end_run(false)
	var alive_at_end: float = Game.run_state.stats.alive_time_by_weapon[&"blaster"]
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(Game.run_state.stats.alive_time_by_weapon[&"blaster"]).is_equal_approx(
		alive_at_end, 0.001
	)


func test_player_contact_damage_does_not_pollute_meter() -> void:
	var player_stub := Node.new()
	add_child(auto_free(player_stub))
	EventBus.damage_dealt.emit(null, player_stub, 25.0)
	await get_tree().process_frame
	assert_float(Game.run_state.stats.total_damage()).is_equal(0.0)
