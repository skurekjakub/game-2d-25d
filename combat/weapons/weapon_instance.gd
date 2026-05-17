class_name WeaponInstance
extends RefCounted

# Defensive fallback when data.fire_rate is missing/invalid (<=0) — keeps the
# weapon ticking at 1 Hz instead of busy-firing every frame or never firing.
const INVALID_FIRE_RATE_FALLBACK_COOLDOWN_SEC: float = 1.0
const WEAPON_DAMAGE_MULTIPLIER: float = 1.25
const FIRE_RATE_MULTIPLIER: float = 1.30

var data: WeaponData
var cooldown_remaining: float = 0.0


func _init(weapon_data: WeaponData) -> void:
	data = weapon_data


static func find_nearest_target(from: Vector2, candidates: Array, max_range: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist_sq: float = max_range * max_range
	for c in candidates:
		if not c is Node2D:
			continue
		var n2d: Node2D = c
		var probe: Vector2 = n2d.position if not n2d.is_inside_tree() else n2d.global_position
		var d_sq: float = from.distance_squared_to(probe)
		if d_sq <= nearest_dist_sq:
			nearest_dist_sq = d_sq
			nearest = n2d
	return nearest


func tick(delta: float) -> void:
	cooldown_remaining = max(0.0, cooldown_remaining - delta)


func can_fire() -> bool:
	return cooldown_remaining <= 0.0


func reset_cooldown() -> void:
	var rate: float = effective_fire_rate()
	if rate <= 0.0:
		cooldown_remaining = INVALID_FIRE_RATE_FALLBACK_COOLDOWN_SEC
		return
	cooldown_remaining = 1.0 / rate


func effective_damage() -> float:
	if data == null:
		return 0.0
	var d: float = data.base_damage
	for upgrade: UpgradeData in Game.run_state.upgrades_taken:
		if upgrade.id == &"weapon_damage_25":
			d *= WEAPON_DAMAGE_MULTIPLIER
	return d


func effective_fire_rate() -> float:
	if data == null:
		return 0.0
	var r: float = data.fire_rate
	for upgrade: UpgradeData in Game.run_state.upgrades_taken:
		if upgrade.id == &"fire_rate_30":
			r *= FIRE_RATE_MULTIPLIER
	return r


func level() -> int:
	var n: int = 1
	for upgrade: UpgradeData in Game.run_state.upgrades_taken:
		if upgrade.id == &"weapon_damage_25" or upgrade.id == &"fire_rate_30":
			n += 1
	return n
