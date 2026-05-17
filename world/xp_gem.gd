class_name XpGem
extends Area2D

@export var value: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	Game.add_xp(value)
	queue_free()
