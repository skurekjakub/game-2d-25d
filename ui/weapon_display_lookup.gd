class_name WeaponDisplayLookup
extends RefCounted


static func for_id(tree: SceneTree, weapon_id: StringName) -> String:
	var player: Player = PlayerLocator.find(tree)
	if player != null:
		for w: WeaponInstance in player.weapon_host.weapons:
			if w.data != null and w.data.id == weapon_id:
				return w.data.display_name
	return String(weapon_id).capitalize()
