extends GdUnitTestSuite

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")


func test_returns_first_player_in_group() -> void:
	var p: Player = auto_free(PLAYER_SCENE.instantiate())
	add_child(p)
	await get_tree().process_frame
	assert_object(PlayerLocator.find(get_tree())).is_same(p)


func test_returns_null_when_no_player() -> void:
	assert_object(PlayerLocator.find(get_tree())).is_null()


func test_returns_null_when_tree_null() -> void:
	assert_object(PlayerLocator.find(null)).is_null()
