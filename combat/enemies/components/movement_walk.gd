class_name WalkTowardPlayerComponent
extends Node

@export var speed: float = 60.0
var target: Node2D


static func compute_velocity(from: Vector2, to: Vector2, p_speed: float) -> Vector2:
	var diff: Vector2 = to - from
	if diff.length() <= 0.001:
		return Vector2.ZERO
	return diff.normalized() * p_speed
