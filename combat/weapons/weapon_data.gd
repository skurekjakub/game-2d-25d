class_name WeaponData
extends Resource

enum Targeting { NEAREST }

@export var id: StringName
@export var display_name: String
@export var base_damage: float = 10.0
@export var fire_rate: float = 1.0
@export var range: float = 600.0
@export var targeting: Targeting = Targeting.NEAREST
@export var projectile_scene: PackedScene
@export var pellet_count: int = 1
@export var weapon_scene: PackedScene
