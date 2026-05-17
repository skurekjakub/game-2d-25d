class_name XpGem
extends Area2D

@export var value: int = 1


func _ready() -> void:
	($Visual as Polygon2D).color = Palette.XP_GEM
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# queue_free() is deferred; without disabling monitoring, body_entered can fire
	# again in the same physics step and double-credit the XP. See:
	# https://docs.godotengine.org/en/stable/getting_started/first_2d_game/03.coding_the_player.html
	set_deferred("monitoring", false)
	Game.add_xp(value)
	queue_free()
