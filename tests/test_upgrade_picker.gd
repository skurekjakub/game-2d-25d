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
	# Level-up drain may re-pause if there's another pending. With no XP, no re-pause.
	assert_bool(get_tree().paused).is_false()
