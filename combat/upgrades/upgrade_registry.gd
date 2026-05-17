extends Node

const DATA_DIR: String = "res://combat/upgrades/data"
const WEAPONS_DATA_DIR: String = "res://combat/weapons/data"
const MAX_HP_BONUS: float = 20.0
const MOVE_SPEED_MULTIPLIER: float = 1.15
const SPREAD_DATA_PATH: String = "res://combat/weapons/data/spread.tres"
const AURA_DATA_PATH: String = "res://combat/weapons/data/aura.tres"
const ORBITAL_DATA_PATH: String = "res://combat/weapons/data/orbital.tres"

var pool: Array[UpgradeData] = []
var known_weapon_ids: Array[StringName] = []


func _ready() -> void:
	if pool.is_empty():
		pool = _load_pool()
	if known_weapon_ids.is_empty():
		known_weapon_ids = _load_known_weapon_ids()


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


func _load_known_weapon_ids() -> Array[StringName]:
	# Derives the weapon roster from WeaponData resources on disk so the gating
	# classifier stays in sync without a hand-maintained parallel list.
	var loaded: Array[StringName] = []
	for entry in ResourceLoader.list_directory(WEAPONS_DATA_DIR):
		if not (entry.ends_with(".tres") or entry.ends_with(".res")):
			continue
		var res := load("%s/%s" % [WEAPONS_DATA_DIR, entry])
		if res is WeaponData and res.id != &"":
			loaded.append(res.id)
	return loaded


func pick_random_3() -> Array[UpgradeData]:
	return pick_random_3_for(PlayerLocator.find(get_tree()))


func pick_random_3_for(player: Player) -> Array[UpgradeData]:
	var available: Array[UpgradeData] = _available_for_picker(player)
	var picks: Array[UpgradeData] = []
	var remaining: Array[UpgradeData] = available.duplicate()
	var n: int = min(3, remaining.size())
	for i in n:
		var chosen: UpgradeData = _pick_one_weighted(remaining)
		if chosen == null:
			break
		picks.append(chosen)
		remaining.erase(chosen)
	return picks


func _available_for_picker(player: Player) -> Array[UpgradeData]:
	var owned_ids: Array[StringName] = _owned_weapon_ids_for(player)
	var result: Array[UpgradeData] = []
	for u: UpgradeData in pool:
		var s: String = String(u.id)
		if s.begins_with("acquire_"):
			var wid := StringName(s.trim_prefix("acquire_"))
			if wid in owned_ids:
				continue  # already own it
			result.append(u)
			continue
		var weapon_prefix := _weapon_prefix_of(s)
		if weapon_prefix != &"":
			if weapon_prefix in owned_ids:
				result.append(u)  # owned → eligible
			# else: gated until acquired
			continue
		# Not weapon-related (stat upgrade) — always available.
		result.append(u)
	return result


func _owned_weapon_ids_for(player: Player) -> Array[StringName]:
	if player == null:
		return []
	return player.weapon_host.owned_weapon_ids()


func _weapon_prefix_of(s: String) -> StringName:
	for wid: StringName in known_weapon_ids:
		if s.begins_with(String(wid) + "_"):
			return wid
	return &""


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


func apply(upgrade: UpgradeData, player: Player) -> void:
	if upgrade == null or player == null:
		return
	var hc: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	match upgrade.id:
		&"max_hp_20":
			if hc != null:
				hc.set_max_hp(hc.max_hp + MAX_HP_BONUS)
				hc.set_hp(hc.max_hp)
		&"move_speed_15":
			player.speed *= MOVE_SPEED_MULTIPLIER
		&"heal_to_full":
			if hc != null:
				hc.set_hp(hc.max_hp)
		&"blaster_damage_25":
			pass
		&"blaster_fire_rate_30":
			pass
		&"spread_damage_25":
			pass
		&"spread_pellets_plus_1":
			pass
		&"acquire_spread":
			player.weapon_host.add_weapon(load(SPREAD_DATA_PATH))
		&"aura_damage_25":
			pass
		&"aura_radius_25":
			pass
		&"acquire_aura":
			player.weapon_host.add_weapon(load(AURA_DATA_PATH))
		&"orbital_damage_25":
			pass
		&"orbital_count_plus_1":
			pass
		&"acquire_orbital":
			player.weapon_host.add_weapon(load(ORBITAL_DATA_PATH))
		_:
			push_warning("UpgradeRegistry: no apply() branch for id=%s" % upgrade.id)
