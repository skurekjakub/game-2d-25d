class_name HealthComponent
extends Node

signal damaged(amount: float, new_hp: float)
signal died(killer: Node)

@export var max_hp: float = 100.0
var hp: float = 0.0


func _ready() -> void:
	hp = max_hp


func take_damage(amount: float, source: Node = null) -> void:
	if hp <= 0.0:
		return
	hp = max(0.0, hp - amount)
	damaged.emit(amount, hp)
	if hp <= 0.0:
		died.emit(source)
