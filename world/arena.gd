class_name Arena
extends Node2D

const ENEMY_SCENE := preload("res://combat/enemies/enemy.tscn")
const XP_GEM_SCENE := preload("res://world/xp_gem.tscn")
const ENEMY_DATA := preload("res://combat/enemies/data/basic_walker.tres")
const ENEMY_SPAWN_POSITION := Vector2(800, 400)
const RESPAWN_DELAY: float = 2.0

@onready var enemies_container: Node2D = $Enemies


func _ready() -> void:
	Game.start_run()
	EventBus.enemy_killed.connect(_on_enemy_killed)
	_spawn_test_enemy()


func _spawn_test_enemy() -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = ENEMY_DATA
	enemy.global_position = ENEMY_SPAWN_POSITION
	enemies_container.add_child(enemy)


func _on_enemy_killed(_enemy: Node, at: Vector2) -> void:
	_drop_xp_gem(at)
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(_spawn_test_enemy)


func _drop_xp_gem(at: Vector2) -> void:
	var gem: XpGem = XP_GEM_SCENE.instantiate()
	gem.value = ENEMY_DATA.xp_value
	gem.global_position = at
	add_child(gem)
