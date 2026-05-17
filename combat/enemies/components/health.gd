class_name HealthComponent
extends Node

# damaged.amount is the REQUESTED damage (pre-clamp). Callers needing absorbed damage compute hp_before - new_hp.
signal damaged(amount: float, new_hp: float)
signal died(killer: Node)

@export var max_hp: float = 100.0
var hp: float = 0.0
var _died_emitted: bool = false


func _ready() -> void:
	hp = max_hp
	_died_emitted = false


func take_damage(amount: float, source: Node = null) -> void:
	if hp <= 0.0:
		return
	hp = max(0.0, hp - amount)
	damaged.emit(amount, hp)
	# Re-entrancy guard: a `damaged` handler may call take_damage recursively,
	# transitioning hp to 0 and emitting `died` before we reach this line.
	# `_died_emitted` prevents a second emission from this outer call frame.
	if hp <= 0.0 and not _died_emitted:
		_died_emitted = true
		died.emit(source)
