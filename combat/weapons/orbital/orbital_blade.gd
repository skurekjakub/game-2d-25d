class_name OrbitalBlade
extends Area2D

const RE_HIT_COOLDOWN_SEC: float = 0.5

var damage: float = 5.0

# Per-enemy re-hit cooldown table, keyed by enemy instance_id. Per-blade (not
# per-weapon) by design: more blades = more hit opportunities on the same enemy
# during the cooldown window. instance_ids are not reused in Godot 4.x within
# a session (validator counter), so freed enemies can't inherit stale cooldowns.
var _hit_cooldowns: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.ENEMIES
	monitoring = true
	monitorable = false


func owned_tick(delta: float) -> void:
	# Decrement cooldowns; cull entries that elapsed.
	for key in _hit_cooldowns.keys():
		_hit_cooldowns[key] -= delta
		if _hit_cooldowns[key] <= 0.0:
			_hit_cooldowns.erase(key)
	for body in get_overlapping_bodies():
		if not body.is_in_group("enemies"):
			continue
		var key: int = body.get_instance_id()
		if key in _hit_cooldowns:
			continue
		var hc := body.get_node_or_null("HealthComponent") as HealthComponent
		if hc == null:
			continue
		hc.take_damage(damage, self)
		_hit_cooldowns[key] = RE_HIT_COOLDOWN_SEC
