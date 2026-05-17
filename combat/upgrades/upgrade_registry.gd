extends Node

const DATA_DIR: String = "res://combat/upgrades/data"
const MAX_HP_BONUS: float = 20.0
const MOVE_SPEED_MULTIPLIER: float = 1.15
const WEAPON_DAMAGE_MULTIPLIER: float = 1.25
const FIRE_RATE_MULTIPLIER: float = 1.30

var pool: Array = []


func _ready() -> void:
	if pool.is_empty():
		pool = _load_pool()


func _load_pool() -> Array:
	var loaded: Array = []
	var dir := DirAccess.open(DATA_DIR)
	if dir == null:
		return loaded
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.ends_with(".tres"):
			var res := load("%s/%s" % [DATA_DIR, name])
			if res is UpgradeData:
				loaded.append(res)
		name = dir.get_next()
	dir.list_dir_end()
	return loaded


func pick_random_3() -> Array:
	# Without replacement; weight-aware. For M1.4 all weights default 1.0 → uniform.
	var picks: Array = []
	var remaining: Array = pool.duplicate()
	var n: int = min(3, remaining.size())
	for i in n:
		var chosen: UpgradeData = _pick_one_weighted(remaining)
		if chosen == null:
			break
		picks.append(chosen)
		remaining.erase(chosen)
	return picks


func _pick_one_weighted(candidates: Array) -> UpgradeData:
	if candidates.is_empty():
		return null
	var total: float = 0.0
	for u: UpgradeData in candidates:
		total += u.weight
	if total <= 0.0:
		return candidates[randi() % candidates.size()] as UpgradeData
	var r := randf() * total
	var acc: float = 0.0
	for u: UpgradeData in candidates:
		acc += u.weight
		if r <= acc:
			return u
	return candidates[candidates.size() - 1] as UpgradeData


func apply(upgrade: UpgradeData, player: Node) -> void:
	if upgrade == null or player == null:
		return
	# HealthComponent is reachable two ways: as a child node "HealthComponent"
	# (real Player) or stashed in meta "_health" (test stubs). The meta path
	# keeps tests free of full Player scene instantiation.
	var hc: HealthComponent = null
	if player.has_meta("_health"):
		hc = player.get_meta("_health") as HealthComponent
	elif player.has_node("HealthComponent"):
		hc = player.get_node("HealthComponent") as HealthComponent
	match upgrade.id:
		&"max_hp_20":
			if hc != null:
				hc.set_max_hp(hc.max_hp + MAX_HP_BONUS)
				hc.hp = hc.max_hp
		&"move_speed_15":
			if player.has_meta("_speed"):
				player.set_meta("_speed", player.get_meta("_speed") * MOVE_SPEED_MULTIPLIER)
			elif "speed" in player:
				player.set("speed", player.get("speed") * MOVE_SPEED_MULTIPLIER)
		&"heal_to_full":
			if hc != null:
				hc.hp = hc.max_hp
		&"weapon_damage_25":
			pass  # consumed at fire time by WeaponInstance.effective_damage()
		&"fire_rate_30":
			pass  # consumed at fire time by WeaponInstance.effective_fire_rate()
