class_name Enemy
extends CharacterBody2D

@export var data: EnemyData

@onready var health: HealthComponent = $HealthComponent
@onready var movement: WalkTowardPlayerComponent = $WalkTowardPlayerComponent
@onready var visual: Polygon2D = $Visual
@onready var hurtbox: Area2D = $Hurtbox
@onready var contact_damage: ContactDamageComponent = $ContactDamageComponent


func _ready() -> void:
	add_to_group("enemies")
	if data != null:
		health.max_hp = data.max_hp
		health.hp = data.max_hp
		movement.speed = data.speed
		visual.color = data.visual_color
		contact_damage.damage = data.contact_damage
	movement.target = PlayerLocator.find(get_tree())
	health.died.connect(_on_died)


func _physics_process(_delta: float) -> void:
	if movement.target == null:
		return
	velocity = WalkTowardPlayerComponent.compute_velocity(
		global_position, movement.target.global_position, movement.speed
	)
	move_and_slide()


func _on_died(_killer: Node) -> void:
	hurtbox.set_deferred("monitoring", false)
	EventBus.enemy_killed.emit(self, global_position)
	queue_free()
