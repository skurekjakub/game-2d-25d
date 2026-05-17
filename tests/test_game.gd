extends GdUnitTestSuite


func _make_game() -> Node:
	# auto_free prevents Node-instance leak warnings; we never add to the tree.
	return auto_free(load("res://bootstrap/game.gd").new())


func test_start_run_initializes_state() -> void:
	var game: Node = _make_game()
	game.start_run()
	assert_float(game.run_state.hp).is_equal(game.run_state.max_hp)
	assert_int(game.run_state.xp).is_equal(0)
	assert_int(game.run_state.level).is_equal(1)
	assert_float(game.run_state.time_elapsed).is_equal(0.0)


func test_add_xp_below_threshold_does_not_level_up() -> void:
	var game: Node = _make_game()
	game.start_run()
	game.add_xp(3)
	assert_int(game.run_state.xp).is_equal(3)
	assert_int(game.run_state.level).is_equal(1)


func test_add_xp_at_threshold_levels_up() -> void:
	var game: Node = _make_game()
	game.start_run()
	# xp_needed(1) = 5 + 1*3 = 8
	game.add_xp(8)
	assert_int(game.run_state.level).is_equal(2)
	assert_int(game.run_state.xp).is_equal(0)


func test_add_xp_overflow_carries_to_next_level() -> void:
	var game: Node = _make_game()
	game.start_run()
	game.add_xp(10)  # 8 to level up, 2 carry
	assert_int(game.run_state.level).is_equal(2)
	assert_int(game.run_state.xp).is_equal(2)


func test_xp_needed_curve() -> void:
	var game: Node = _make_game()
	assert_int(game.xp_needed(1)).is_equal(8)
	assert_int(game.xp_needed(2)).is_equal(11)
	assert_int(game.xp_needed(10)).is_equal(35)


func test_time_elapsed_advances_when_process_ticks() -> void:
	# Game is an autoload, so just probe Game directly — but we can also
	# construct a fresh instance to test process behavior in isolation.
	var g: Node = auto_free(load("res://bootstrap/game.gd").new())
	g.start_run()
	var initial: float = g.run_state.time_elapsed
	g._process(0.5)
	assert_float(g.run_state.time_elapsed).is_equal_approx(initial + 0.5, 0.001)
