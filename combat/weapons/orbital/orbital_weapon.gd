class_name OrbitalWeapon
extends Node2D

const BASE_RADIUS: float = 60.0
const ROTATION_PERIOD_SEC: float = 1.5
const BLADE_SCENE := preload("res://combat/weapons/orbital/orbital_blade.tscn")

var instance: WeaponInstance
var _angle: float = 0.0


func configure(weapon_instance: WeaponInstance) -> void:
	instance = weapon_instance
	_sync_blade_count()


func blade_count() -> int:
	if instance == null:
		return 1
	return 1 + instance.count_upgrade(&"orbital_count_plus_1")


func _owned_tick(delta: float) -> void:
	_sync_blade_count()
	_angle += delta * TAU / ROTATION_PERIOD_SEC
	var blades := _blades()
	var n: int = blades.size()
	if n == 0:
		return
	var step: float = TAU / float(n)
	var damage: float = instance.effective_damage() if instance != null else 0.0
	for i in n:
		var blade: OrbitalBlade = blades[i]
		var a: float = _angle + step * float(i)
		blade.position = Vector2(cos(a), sin(a)) * BASE_RADIUS
		blade.damage = damage
		blade.owned_tick(delta)


func _sync_blade_count() -> void:
	var desired: int = blade_count()
	var actual: int = _blades().size()
	while actual < desired:
		var blade: OrbitalBlade = BLADE_SCENE.instantiate()
		add_child(blade)
		actual += 1
	while actual > desired:
		var blades := _blades()
		# queue_free is deferred — track count locally so the loop doesn't re-free
		# the same blade next iteration.
		blades[blades.size() - 1].queue_free()
		actual -= 1


func _blades() -> Array:
	return get_children().filter(func(c: Node) -> bool: return c is OrbitalBlade)
