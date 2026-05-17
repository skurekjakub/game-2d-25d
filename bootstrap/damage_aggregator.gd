# Observer subscriber: aggregates damage_dealt into RunStats. Sole writer.
extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	EventBus.damage_dealt.connect(_on_damage_dealt)


func _process(delta: float) -> void:
	if Game.run_state == null or Game.run_state.is_over:
		return
	var owned: Array[StringName] = _owned_weapon_ids()
	if owned.is_empty():
		return
	Game.run_state.stats.tick_alive_time(owned, delta)


func _on_damage_dealt(source: Node, _target: Node, amount: float) -> void:
	if Game.run_state == null:
		return
	var weapon_id: StringName = DamageSourceResolver.resolve(source)
	Game.run_state.stats.add_damage(weapon_id, amount)


func _owned_weapon_ids() -> Array[StringName]:
	var player: Player = PlayerLocator.find(get_tree())
	if player == null:
		return []
	return player.weapon_host.owned_weapon_ids()
