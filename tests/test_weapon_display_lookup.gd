extends GdUnitTestSuite

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")


func before_test() -> void:
	Game.start_run()


func test_for_id_returns_display_name_when_found() -> void:
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	add_child(player)
	await get_tree().process_frame
	var data := WeaponData.new()
	data.id = &"test_sword"
	data.display_name = "Test Sword"
	player.weapon_host.weapons.append(WeaponInstance.new(data))
	var result: String = WeaponDisplayLookup.for_id(get_tree(), &"test_sword")
	assert_str(result).is_equal("Test Sword")


func test_for_id_returns_capitalized_fallback_when_not_found() -> void:
	var result: String = WeaponDisplayLookup.for_id(get_tree(), &"unknown_weapon")
	assert_str(result).is_equal("Unknown Weapon")
