class_name PlayerLocator
extends RefCounted


static func find(tree: SceneTree) -> Player:
	if tree == null:
		return null
	var players: Array = tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player
