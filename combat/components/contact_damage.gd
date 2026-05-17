class_name ContactDamageComponent
extends Node

## Ticks `damage` to overlapping bodies once per `tick_interval` seconds.
## Bind the hurtbox via `hurtbox_path` (NodePath, resolved in _ready).
## Per-body timers stored in a dict by instance_id — entering an already-tracked
## body resets the timer and fires an immediate tick; exiting clears it.

@export var damage: float = 5.0
@export var tick_interval: float = 1.0
@export var hurtbox_path: NodePath

var _hurtbox: Area2D
var _timers: Dictionary = {}


func _ready() -> void:
	_hurtbox = get_node_or_null(hurtbox_path) as Area2D
	assert(_hurtbox != null, "ContactDamageComponent: hurtbox_path must resolve to an Area2D")
	_hurtbox.body_entered.connect(_on_body_entered)
	_hurtbox.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if _timers.is_empty():
		return
	for body_id in _timers.keys():
		_timers[body_id] -= delta
	for body_id in _timers.keys():
		if _timers[body_id] > 0.0:
			continue
		var body: Node = instance_from_id(body_id) as Node
		if body == null or not is_instance_valid(body):
			_timers.erase(body_id)
			continue
		_apply_tick(body)
		_timers[body_id] = tick_interval


func _on_body_entered(body: Node) -> void:
	if not _is_damageable(body):
		return
	_apply_tick(body)
	_timers[body.get_instance_id()] = tick_interval


func _on_body_exited(body: Node) -> void:
	_timers.erase(body.get_instance_id())


func _is_damageable(body: Node) -> bool:
	return _find_health(body) != null


func _apply_tick(body: Node) -> void:
	var health: HealthComponent = _find_health(body)
	if health == null:
		return
	health.take_damage(damage, get_parent())


static func _find_health(body: Node) -> HealthComponent:
	for child in body.get_children():
		if child is HealthComponent:
			return child
	return null
