class_name DamageSourceResolver
extends RefCounted


static func resolve(source: Node) -> StringName:
	if source == null:
		return &""
	# Cooldown-fire path: projectile carries weapon_id stamped by WeaponHost.
	if "weapon_id" in source and source.weapon_id != &"":
		return source.weapon_id
	# Scene-owned weapon root (Aura, future top-level scene weapons).
	if "instance" in source and source.instance != null:
		var data: WeaponData = source.instance.data
		if data != null:
			return data.id
	# Scene-owned weapon child (OrbitalBlade → parent OrbitalWeapon).
	var parent: Node = source.get_parent()
	if parent != null and "instance" in parent and parent.instance != null:
		var pdata: WeaponData = parent.instance.data
		if pdata != null:
			return pdata.id
	return &""
