class_name WeaponAcquireEffect
extends UpgradeEffect

@export var weapon_data: WeaponData


func execute(player: Player) -> void:
	if player == null or weapon_data == null:
		return
	player.weapon_host.add_weapon(weapon_data)
