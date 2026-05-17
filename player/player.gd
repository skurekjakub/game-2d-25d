class_name Player
extends CharacterBody2D

@export var speed: float = 200.0


func _ready() -> void:
	add_to_group("player")


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
