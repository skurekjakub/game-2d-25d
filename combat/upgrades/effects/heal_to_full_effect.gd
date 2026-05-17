class_name HealToFullEffect
extends UpgradeEffect


func execute(player: Player) -> void:
	if player == null:
		return
	player.health.set_hp(player.health.max_hp)
