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
