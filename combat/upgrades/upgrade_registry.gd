extends Node

const DATA_DIR: String = "res://combat/upgrades/data"
const MAX_HP_BONUS: float = 20.0
const MOVE_SPEED_MULTIPLIER: float = 1.15

var pool: Array[UpgradeData] = []


func _ready() -> void:
	if pool.is_empty():
		pool = _load_pool()


func _load_pool() -> Array[UpgradeData]:
	# ResourceLoader.list_directory is remap-aware: in an exported PCK, `.tres`
	# files are converted to binary `.res` and DirAccess scans return zero
	# matches. See Godot docs class_diraccess.rst:92.
	var loaded: Array[UpgradeData] = []
	for entry in ResourceLoader.list_directory(DATA_DIR):
		if not (entry.ends_with(".tres") or entry.ends_with(".res")):
			continue
		var res := load("%s/%s" % [DATA_DIR, entry])
		if res is UpgradeData:
			loaded.append(res)
	return loaded


func pick_random_3() -> Array[UpgradeData]:
	var picks: Array[UpgradeData] = []
	var remaining: Array[UpgradeData] = pool.duplicate()
	var n: int = min(3, remaining.size())
	for i in n:
		var chosen: UpgradeData = _pick_one_weighted(remaining)
		if chosen == null:
			break
		picks.append(chosen)
		remaining.erase(chosen)
	return picks


func _pick_one_weighted(candidates: Array[UpgradeData]) -> UpgradeData:
	if candidates.is_empty():
		return null
	var total: float = 0.0
	for u in candidates:
		total += u.weight
	if total <= 0.0:
		return candidates[randi() % candidates.size()]
	var r := randf() * total
	var acc: float = 0.0
	for u in candidates:
		acc += u.weight
		if r <= acc:
			return u
	return candidates[candidates.size() - 1]


func apply(upgrade: UpgradeData, player: Node) -> void:
	if upgrade == null or player == null:
		return
	var hc: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	match upgrade.id:
		&"max_hp_20":
			if hc != null:
				hc.set_max_hp(hc.max_hp + MAX_HP_BONUS)
				hc.set_hp(hc.max_hp)
		&"move_speed_15":
			if "speed" in player:
				player.set("speed", player.get("speed") * MOVE_SPEED_MULTIPLIER)
		&"heal_to_full":
			if hc != null:
				hc.set_hp(hc.max_hp)
		&"blaster_damage_25":
			pass
		&"blaster_fire_rate_30":
			pass
		_:
			push_warning("UpgradeRegistry: no apply() branch for id=%s" % upgrade.id)
