class_name WeaponHost
extends Node

@export var starter_weapons: Array[WeaponData] = []

var weapons: Array[WeaponInstance] = []
var _shooter: Node2D


func _ready() -> void:
	_shooter = get_parent() as Node2D
	for data in starter_weapons:
		add_weapon(data)


func add_weapon(data: WeaponData) -> WeaponInstance:
	var inst := WeaponInstance.new(data)
	weapons.append(inst)
	return inst


func _physics_process(delta: float) -> void:
	if _shooter == null:
		return
	for weapon in weapons:
		weapon.tick(delta)
		if not weapon.can_fire():
			continue
		_try_fire(weapon)


func _try_fire(weapon: WeaponInstance) -> void:
	if weapon.data == null or weapon.data.projectile_scene == null:
		return
	# Passing Array[Node] from get_nodes_in_group directly; find_nearest_target
	# does its own `is Node2D` filter. See M1.1 Task 6 rubber-duk notes.
	var enemies := get_tree().get_nodes_in_group("enemies")
	var target := WeaponInstance.find_nearest_target(
		_shooter.global_position, enemies, weapon.data.range
	)
	if target == null:
		return
	_spawn_projectile(weapon, target)
	weapon.reset_cooldown()


func _spawn_projectile(weapon: WeaponInstance, target: Node2D) -> void:
	var projectile: Node = weapon.data.projectile_scene.instantiate()
	if projectile is Node2D:
		(projectile as Node2D).global_position = _shooter.global_position
	if projectile.has_method("set_target_position"):
		projectile.set_target_position(target.global_position)
	if "damage" in projectile:
		projectile.damage = weapon.data.base_damage
	# Projectiles live as siblings of the player (in the Arena), so they don't follow the player.
	_shooter.get_parent().add_child(projectile)
