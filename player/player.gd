class_name Player
extends CharacterBody2D

@export var speed: float = 200.0

@onready var _health: HealthComponent = $HealthComponent
@onready var _weapon_host: Node = $WeaponHost

var _is_dead: bool = false


func _ready() -> void:
	add_to_group("player")
	_health.died.connect(_on_died)


static func compute_velocity(input_vector: Vector2, p_speed: float) -> Vector2:
	if input_vector == Vector2.ZERO:
		return Vector2.ZERO
	return input_vector.normalized() * p_speed


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	)
	velocity = compute_velocity(input_vector, speed)
	move_and_slide()


func _on_died(_killer: Node) -> void:
	if _is_dead:
		return
	_is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	_weapon_host.set_process(false)
	_weapon_host.set_physics_process(false)
	EventBus.run_ended.emit(false)
