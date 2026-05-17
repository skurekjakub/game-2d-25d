class_name WalkTowardPlayerComponent
extends Node

const NEAR_ZERO_DISTANCE_PX: float = 0.001

@export var speed: float = 60.0
var target: Node2D


static func compute_velocity(from: Vector2, to: Vector2, p_speed: float) -> Vector2:
	var diff: Vector2 = to - from
	if diff.length() <= NEAR_ZERO_DISTANCE_PX:
		return Vector2.ZERO
	return diff.normalized() * p_speed
