class_name SpeedMultiplierEffect
extends UpgradeEffect

@export var multiplier: float = 1.0


func execute(player: Player) -> void:
	if player == null:
		return
	player.speed *= multiplier
