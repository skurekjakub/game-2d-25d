extends GdUnitTestSuite

const PICKER_SCRIPT := preload("res://ui/upgrade_picker.gd")


func before_test() -> void:
	Game.start_run()


func _make_picker() -> Node:
	var picker: Node = auto_free(Node.new())
	picker.set_script(PICKER_SCRIPT)
	add_child(picker)
	return picker


func _make_upgrade(p_id: StringName) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = p_id
	u.display_name = String(p_id)
	return u


func test_apply_appends_to_upgrades_taken() -> void:
	var picker := _make_picker()
	var upgrade := _make_upgrade(&"max_hp_20")
	picker._apply_pick(upgrade)
	assert_int(Game.run_state.upgrades_taken.size()).is_equal(1)
	assert_str(String(Game.run_state.upgrades_taken[0].id)).is_equal("max_hp_20")


func test_apply_emits_upgrade_applied() -> void:
	var picker := _make_picker()
	var upgrade := _make_upgrade(&"heal_to_full")
	monitor_signals(EventBus, false)
	picker._apply_pick(upgrade)
	await assert_signal(EventBus).is_emitted("upgrade_applied", [any()])


func test_apply_unpauses_tree() -> void:
	get_tree().paused = true
	var picker := _make_picker()
	picker._apply_pick(_make_upgrade(&"heal_to_full"))
	# With no pending XP, the drain chain doesn't re-pause.
	assert_bool(get_tree().paused).is_false()


func test_apply_pick_chains_into_next_modal_when_level_pending() -> void:
	# Multi-level invariant from design §"Data flow on level-up":
	# back-to-back picks must drain queued level_ups synchronously after the
	# emit, opening modal B without the player losing an upgrade.
	#
	# Requires UpgradeRegistry pool to be non-empty (autoload _ready loads it)
	# and a "player" group node so the chained _on_level_up's dead-check passes.
	var picker := _make_picker()
	var player_stub: Node = auto_free(Node.new())
	player_stub.add_to_group("player")
	add_child(player_stub)
	# Pre-seed XP to cross the next threshold on the drain.
	Game.run_state.xp = Game.xp_needed(Game.run_state.level)
	monitor_signals(EventBus, false)
	picker._apply_pick(_make_upgrade(&"max_hp_20"))
	await assert_signal(EventBus).is_emitted("level_up", [Game.run_state.level])
	# Modal B should be open (and the tree paused again).
	assert_object(picker._modal).is_not_null()
	assert_bool(get_tree().paused).is_true()
	# Cleanup: free the modal so subsequent tests start clean.
	if picker._modal != null:
		picker._modal.queue_free()
	get_tree().paused = false
