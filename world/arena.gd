class_name Arena
extends Node2D

const XP_GEM_SCENE := preload("res://world/xp_gem.tscn")
const BASIC_WALKER_DATA := preload("res://combat/enemies/data/basic_walker.tres")


func _ready() -> void:
	Game.start_run()
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.wave_completed.connect(_on_wave_completed)


func _on_enemy_killed(_enemy: Node, at: Vector2) -> void:
	_drop_xp_gem(at)


func _drop_xp_gem(at: Vector2) -> void:
	var gem: XpGem = XP_GEM_SCENE.instantiate()
	# enemy_data.xp_value is used as the gem value; for M1.2 all enemies are
	# basic_walker so we read from that const. M1.3+ should read from the dead
	# enemy's data ref carried in the enemy_killed payload (signal shape change).
	gem.value = BASIC_WALKER_DATA.xp_value
	gem.global_position = at
	# Deferred because _on_enemy_killed runs inside a body_entered callback chain;
	# adding an Area2D mid-physics-flush is rejected by the server.
	# See project memory godot_signal_callback_addchild.md.
	call_deferred("add_child", gem)


func _on_wave_completed() -> void:
	print("[Arena] Wave 1 complete — no further spawns. Existing enemies remain.")
