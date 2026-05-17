class_name Damageable
extends RefCounted

const ENEMY_GROUP: StringName = &"enemies"


# Returns true if damage was applied. The weapon → enemy damage contract:
# enemy-group gate + HealthComponent lookup + take_damage + EventBus emit.
# Out of scope: enemy → Player damage (Player listens to its own
# HealthComponent.damaged signal directly — no group filter applies).
static func try_damage(body: Node, amount: float, source: Node) -> bool:
	if body == null or not body.is_in_group(ENEMY_GROUP):
		return false
	var hc := body.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null:
		return false
	hc.take_damage(amount, source)
	EventBus.damage_dealt.emit(source, body, amount)
	return true
