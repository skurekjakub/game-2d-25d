extends Node

const UPGRADE_MODAL_SCENE := preload("res://ui/upgrade_modal.tscn")

var _modal: UpgradeModal


func _ready() -> void:
	EventBus.level_up.connect(_on_level_up)


func _on_level_up(_new_level: int) -> void:
	if _modal != null and is_instance_valid(_modal):
		return
	if _player_is_dead():
		return
	var options := UpgradeRegistry.pick_random_3()
	if options.is_empty():
		return
	get_tree().paused = true
	_modal = UPGRADE_MODAL_SCENE.instantiate()
	add_child(_modal)
	_modal.picked.connect(_apply_pick)
	_modal.show_options(options)


func _apply_pick(upgrade: UpgradeData) -> void:
	var players := get_tree().get_nodes_in_group("player")
	var player: Node = players[0] if not players.is_empty() else null
	UpgradeRegistry.apply(upgrade, player)
	Game.run_state.upgrades_taken.append(upgrade)
	# Clear modal ref + unpause BEFORE emitting. The emit synchronously chains
	# into Game._maybe_emit_level_up, which may re-emit `level_up` and re-enter
	# _on_level_up. If that re-entry sees a stale `_modal`, the queued modal is
	# silently dropped (and is_instance_valid stays true on a same-frame
	# queue_free'd node — Godot issue #99239).
	_modal = null
	get_tree().paused = false
	EventBus.upgrade_applied.emit(upgrade)


func _player_is_dead() -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return true
	var p: Node = players[0]
	return p.get("_is_dead") == true
