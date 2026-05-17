class_name WeaponHost
extends Node

@export var starter_weapons: Array[WeaponData] = []

var weapons: Array[WeaponInstance] = []
var _shooter: Node2D


func _ready() -> void:
	_shooter = get_parent() as Node2D
	for data: WeaponData in starter_weapons:
		add_weapon(data)


func add_weapon(data: WeaponData) -> WeaponInstance:
	var inst := WeaponInstance.new(data)
	weapons.append(inst)
	if data.weapon_scene != null and _shooter != null:
		inst.node = data.weapon_scene.instantiate()
		_shooter.add_child(inst.node)
		if inst.node.has_method("configure"):
			inst.node.configure(inst)
	return inst


func owned_weapon_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for w: WeaponInstance in weapons:
		if w.data != null:
			ids.append(w.data.id)
	return ids


func _physics_process(delta: float) -> void:
	if _shooter == null:
		return
	for weapon: WeaponInstance in weapons:
		if weapon.node != null and weapon.node.has_method("_owned_tick"):
			weapon.node._owned_tick(delta)
			continue
		weapon.tick(delta)
		if not weapon.can_fire():
			continue
		_try_fire(weapon)


func _try_fire(weapon: WeaponInstance) -> void:
	if weapon.data == null or weapon.data.projectile_scene == null:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var target := WeaponInstance.find_nearest_target(
		_shooter.global_position, enemies, weapon.data.range
	)
	if target == null:
		return
	_spawn_pellets(weapon, target)
	weapon.reset_cooldown()


func _spawn_pellets(weapon: WeaponInstance, target: Node2D) -> void:
	var count: int = max(
		1, weapon.data.pellet_count + weapon.count_upgrade(&"spread_pellets_plus_1")
	)
	if count == 1:
		_spawn_single(weapon, target.global_position)
		return
	var to_target: Vector2 = target.global_position - _shooter.global_position
	var base_angle: float = to_target.angle()
	var spread_deg: float = 30.0
	var step: float = deg_to_rad(spread_deg) / float(count - 1)
	var first_angle: float = base_angle - deg_to_rad(spread_deg) * 0.5
	var radius: float = to_target.length()
	for i: int in count:
		var angle: float = first_angle + step * float(i)
		var aim_point: Vector2 = _shooter.global_position + Vector2(cos(angle), sin(angle)) * radius
		_spawn_single(weapon, aim_point)


func _spawn_single(weapon: WeaponInstance, aim_point: Vector2) -> void:
	var projectile: Node = weapon.data.projectile_scene.instantiate()
	if projectile is Node2D:
		(projectile as Node2D).global_position = _shooter.global_position
	if projectile.has_method("set_target_position"):
		projectile.set_target_position(aim_point)
	if "damage" in projectile:
		projectile.damage = weapon.effective_damage()
	_shooter.get_parent().add_child(projectile)
