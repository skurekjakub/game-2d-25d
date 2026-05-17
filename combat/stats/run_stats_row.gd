class_name RunStatsRow
extends RefCounted

var weapon_id: StringName
var display_name: String
var damage: float
var dps: float
var bar_fill_fraction: float


func _init(
	p_weapon_id: StringName,
	p_display_name: String,
	p_damage: float,
	p_dps: float,
	p_bar_fill_fraction: float
) -> void:
	weapon_id = p_weapon_id
	display_name = p_display_name
	damage = p_damage
	dps = p_dps
	bar_fill_fraction = p_bar_fill_fraction
