extends Node2D

const ARENA_SCENE := preload("res://world/arena.tscn")


func _ready() -> void:
	print("game-2d-25d boot ok — loading arena")
	var arena: Node2D = ARENA_SCENE.instantiate()
	add_child(arena)
