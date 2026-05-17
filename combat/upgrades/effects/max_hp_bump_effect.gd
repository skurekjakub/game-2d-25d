class_name MaxHpBumpEffect
extends UpgradeEffect

@export var amount: float = 0.0


func execute(player: Player) -> void:
	if player == null:
		return
	player.health.set_max_hp(player.health.max_hp + amount)
	player.health.set_hp(player.health.max_hp)
