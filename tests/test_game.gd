extends GdUnitTestSuite


func _make_game() -> Node:
	# auto_free prevents Node-instance leak warnings; we never add to the tree.
	return auto_free(load("res://bootstrap/game.gd").new())


func test_start_run_initializes_state() -> void:
	var game: Node = _make_game()
	game.start_run()
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


func test_add_xp_overflow_carries_but_level_advances_at_most_once() -> void:
	var game: Node = _make_game()
	game.start_run()
	# xp_needed(1) = 8. Picking up 20 XP at level 1 used to stamp 2 levels.
	# Now: level advances to 2, carry = 12. Second level requires upgrade_applied.
	game.add_xp(20)
	assert_int(game.run_state.level).is_equal(2)
	assert_int(game.run_state.xp).is_equal(12)


func test_maybe_emit_level_up_emits_once_when_threshold_crossed() -> void:
	var game: Node = _make_game()
	game.start_run()
	monitor_signals(EventBus, false)
	game.add_xp(8)  # exactly xp_needed(1)
	await assert_signal(EventBus).is_emitted("level_up", [2])
	await assert_signal(EventBus).wait_until(200).is_not_emitted("level_up", [3])


func test_maybe_emit_level_up_drains_next_level_when_called_again() -> void:
	var game: Node = _make_game()
	game.start_run()
	# Stockpile enough XP for 2 levels: need(1)=8 + need(2)=11 = 19
	game.add_xp(19)
	# First call already drained one level (handled inside add_xp).
	assert_int(game.run_state.level).is_equal(2)
	# Now simulate the upgrade-applied callback re-draining.
	game._maybe_emit_level_up()
	assert_int(game.run_state.level).is_equal(3)


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


func test_start_run_initializes_upgrades_taken_empty() -> void:
	var game: Node = _make_game()
	game.start_run()
	assert_array(game.run_state.upgrades_taken).is_empty()


func test_start_run_initializes_is_over_false() -> void:
	var game: Node = _make_game()
	game.start_run()
	assert_bool(game.run_state.is_over).is_false()


func test_end_run_emits_run_ended_once() -> void:
	var game: Node = _make_game()
	game.start_run()
	monitor_signals(EventBus, false)
	game.end_run(false)
	game.end_run(true)
	await assert_signal(EventBus).is_emitted("run_ended", false)
	await assert_signal(EventBus).wait_until(200).is_not_emitted("run_ended", true)


func test_end_run_sets_is_over_true() -> void:
	var game: Node = _make_game()
	game.start_run()
	game.end_run(true)
	assert_bool(game.run_state.is_over).is_true()


func test_process_does_not_advance_time_after_end_run() -> void:
	var game: Node = _make_game()
	game.start_run()
	game.end_run(false)
	var before: float = game.run_state.time_elapsed
	game._process(0.5)
	assert_float(game.run_state.time_elapsed).is_equal(before)


func test_start_run_resets_run_ended_guard() -> void:
	var game: Node = _make_game()
	game.start_run()
	game.end_run(true)
	game.start_run()
	monitor_signals(EventBus, false)
	game.end_run(false)
	await assert_signal(EventBus).is_emitted("run_ended", false)
