class_name RunStats
extends Resource

var damage_by_weapon: Dictionary = {}
var alive_time_by_weapon: Dictionary = {}
var run_started_at: float = 0.0
var run_ended_at: float = 0.0


func total_damage() -> float:
	var t: float = 0.0
	for v: float in damage_by_weapon.values():
		t += v
	return t


func add_damage(weapon_id: StringName, amount: float) -> void:
	if weapon_id == &"" or amount <= 0.0:
		return
	damage_by_weapon[weapon_id] = damage_by_weapon.get(weapon_id, 0.0) + amount


func tick_alive_time(owned_ids: Array[StringName], dt: float) -> void:
	if dt <= 0.0:
		return
	for wid: StringName in owned_ids:
		alive_time_by_weapon[wid] = alive_time_by_weapon.get(wid, 0.0) + dt


func mark_run_started(now: float) -> void:
	run_started_at = now
	run_ended_at = 0.0


func mark_run_ended(now: float) -> void:
	run_ended_at = now


func elapsed_seconds() -> float:
	if run_ended_at > 0.0:
		return run_ended_at - run_started_at
	return 0.0


func elapsed_seconds_at(now: float) -> float:
	return now - run_started_at


func average_dps() -> float:
	var elapsed: float = elapsed_seconds()
	if elapsed <= 0.0:
		return 0.0
	return total_damage() / elapsed


func dps_for(weapon_id: StringName) -> float:
	var alive: float = alive_time_by_weapon.get(weapon_id, 0.0)
	if alive <= 0.0:
		return 0.0
	return damage_by_weapon.get(weapon_id, 0.0) / alive


func percent_of_total_for(weapon_id: StringName) -> float:
	var total: float = total_damage()
	if total <= 0.0:
		return 0.0
	return damage_by_weapon.get(weapon_id, 0.0) / total


func sorted_top_n(n: int, display_name_for: Callable) -> Array[RunStatsRow]:
	var rows: Array[RunStatsRow] = sorted_all(display_name_for)
	if rows.size() <= n:
		return rows
	return rows.slice(0, n)


func sorted_all(display_name_for: Callable) -> Array[RunStatsRow]:
	var rows: Array[RunStatsRow] = []
	for wid: StringName in damage_by_weapon.keys():
		var dmg: float = damage_by_weapon[wid]
		rows.append(RunStatsRow.new(wid, display_name_for.call(wid), dmg, dps_for(wid), 0.0))
	rows.sort_custom(func(a: RunStatsRow, b: RunStatsRow) -> bool: return a.damage > b.damage)
	return rows
