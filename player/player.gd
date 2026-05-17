class_name Player
extends CharacterBody2D

@export var speed: float = 200.0
@export var contact_slow_multiplier: float = 0.5

@onready var _health: HealthComponent = $HealthComponent
@onready var _weapon_host: Node = $WeaponHost
@onready var _visual: Polygon2D = $Visual
@onready var _slow_zone: Area2D = $SlowZone

const FLASH_COLOR := Color(1.0, 0.3, 0.3, 1.0)
const FLASH_DURATION_SEC := 0.1

var _is_dead: bool = false
var _base_color: Color
var _flash_tween: Tween


func _ready() -> void:
	add_to_group("player")
	_base_color = _visual.color
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


static func compute_velocity(input_vector: Vector2, p_speed: float) -> Vector2:
	if input_vector == Vector2.ZERO:
		return Vector2.ZERO
	return input_vector.normalized() * p_speed


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	)
	var effective_speed := speed
	if _slow_zone.has_overlapping_bodies():
		effective_speed *= contact_slow_multiplier
	velocity = compute_velocity(input_vector, effective_speed)
	move_and_slide()


func _on_damaged(amount: float, _new_hp: float) -> void:
	EventBus.damage_dealt.emit(null, self, amount)
	_flash()


func _on_died(_killer: Node) -> void:
	if _is_dead:
		return
	_is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	_weapon_host.set_physics_process(false)
	EventBus.run_ended.emit(false)


func _flash() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_visual.color = FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(_visual, "color", _base_color, FLASH_DURATION_SEC)
