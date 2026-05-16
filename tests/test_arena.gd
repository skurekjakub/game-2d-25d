extends GdUnitTestSuite


## Smoke test only: verifies .tscn parses and has the expected child structure.
## Does NOT exercise Arena._ready (instantiate() doesn't fire _ready until the node enters
## a SceneTree). The Game.start_run() integration is covered by Task 9's headless boot check.
func test_arena_scene_parses_with_player_child() -> void:
	var scene := load("res://world/arena.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var node: Node = auto_free(scene.instantiate())
	assert_object(node).is_not_null()
	assert_str(node.name).is_equal("Arena")
	# Arena should contain Player as a child (instanced scene).
	var player := node.get_node_or_null("Player")
	assert_object(player).is_not_null()
