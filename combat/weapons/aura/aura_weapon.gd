class_name AuraWeapon
extends Area2D

const BASE_RADIUS: float = 80.0
const RADIUS_UPGRADE_MULTIPLIER: float = 1.25
const TICK_INTERVAL_SEC: float = 0.5

@onready var _shape: CollisionShape2D = $Shape
@onready var _visual: Polygon2D = $Visual

var instance: WeaponInstance
var _tick_remaining: float = TICK_INTERVAL_SEC


func _ready() -> void:
	collision_layer = 0
	collision_mask = CollisionLayers.ENEMIES
	monitoring = true
	monitorable = false
	_apply_radius()


func configure(weapon_instance: WeaponInstance) -> void:
	instance = weapon_instance
	if is_node_ready():
		_apply_radius()


func _owned_tick(delta: float) -> void:
	_apply_radius()  # cheap; lets radius upgrades take effect immediately
	_tick_remaining -= delta
	if _tick_remaining > 0.0:
		return
	_tick_remaining = TICK_INTERVAL_SEC
	_apply_tick_damage()


func _apply_radius() -> void:
	if _shape == null:
		return
	var r: float = BASE_RADIUS
	if instance != null:
		var bonus: int = instance.count_upgrade(&"aura_radius_25")
		r *= pow(RADIUS_UPGRADE_MULTIPLIER, bonus)
	(_shape.shape as CircleShape2D).radius = r
	# Visual polygon is hard-coded at BASE_RADIUS in the .tscn; scale the node
	# to track the live collision radius so the blue ring matches damage reach.
	if _visual != null:
		_visual.scale = Vector2.ONE * (r / BASE_RADIUS)


func _apply_tick_damage() -> void:
	if instance == null:
		return
	var dmg: float = instance.effective_damage()
	for body: Node2D in get_overlapping_bodies():
		if not body.is_in_group("enemies"):
			continue
		var hc := body.get_node_or_null("HealthComponent") as HealthComponent
		if hc != null:
			hc.take_damage(dmg, self)
			EventBus.damage_dealt.emit(self, body, dmg)
