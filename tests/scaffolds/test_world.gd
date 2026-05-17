class_name TestWorld
extends RefCounted

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")


# Instantiates the real Player scene as a child of `case`, with its
# WeaponHost.weapons replaced by fresh WeaponInstances built from
# `weapon_ids`. After the initial wire-up frame, disables the host's
# _physics_process so SUBSEQUENT awaits don't trip on Game.run_state.
# (The single wire-up frame is safe: WeaponHost._physics_process
# early-outs on null Game.run_state and finds no enemies in test scope.)
#
# Returns the typed Player; await this call so the @onready wiring
# settles before the caller inspects player.weapon_host.
static func player_with_weapons(case: GdUnitTestSuite, weapon_ids: Array[StringName]) -> Player:
	var player: Player = case.auto_free(PLAYER_SCENE.instantiate())
	case.add_child(player)
	await case.get_tree().process_frame
	var host: WeaponHost = player.weapon_host
	host.set_physics_process(false)
	host.weapons.clear()
	for wid: StringName in weapon_ids:
		var d := WeaponData.new()
		d.id = wid
		d.display_name = String(wid).capitalize()
		host.weapons.append(WeaponInstance.new(d))
	return player
