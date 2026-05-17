class_name DamageSourceResolver
extends RefCounted

# Contract: nodes participate in damage attribution via one of two protocols.
# Projectiles: carry `weapon_id: StringName` stamped by WeaponHost at spawn.
# Scene-owned weapons: root node implements `_owned_tick(delta: float)` and
# carries `instance: WeaponInstance` (Aura, Orbital). Children (OrbitalBlade)
# resolve by walking to that parent. Anything else returns &"" — the meter
# drops it via RunStats.add_damage's empty-id early-out.


static func resolve(source: Node) -> StringName:
	if source == null:
		return &""
	if "weapon_id" in source and source.weapon_id != &"":
		return source.weapon_id
	if source.has_method("_owned_tick") and "instance" in source and source.instance != null:
		var data: WeaponData = source.instance.data
		if data != null:
			return data.id
	var parent: Node = source.get_parent()
	if (
		parent != null
		and parent.has_method("_owned_tick")
		and "instance" in parent
		and parent.instance != null
	):
		var pdata: WeaponData = parent.instance.data
		if pdata != null:
			return pdata.id
	return &""
