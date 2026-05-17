class_name BasicProjectile
extends Area2D

@export var speed: float = 400.0
@export var lifetime: float = 2.0
@export var damage: float = 10.0

var direction: Vector2 = Vector2.ZERO
var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func set_target_position(target_pos: Vector2) -> void:
	var here: Vector2 = global_position if is_inside_tree() else position
	var diff: Vector2 = target_pos - here
	if diff.length() <= 0.001:
		direction = Vector2.RIGHT
		return
	direction = diff.normalized()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	var health := body.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		return
	health.take_damage(damage, self)
	EventBus.damage_dealt.emit(self, body, damage)
	queue_free()
