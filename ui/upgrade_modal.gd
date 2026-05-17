class_name UpgradeModal
extends Control

signal picked(upgrade: UpgradeData)

const UPGRADE_CARD_SCENE := preload("res://ui/upgrade_card.tscn")

@onready var _card_row: HBoxContainer = $Center/Panel/Margin/CardRow

var _cards: Array[UpgradeCard] = []


func show_options(options: Array[UpgradeData]) -> void:
	for child in _card_row.get_children():
		child.queue_free()
	_cards.clear()
	for upgrade in options:
		var card: UpgradeCard = UPGRADE_CARD_SCENE.instantiate()
		_card_row.add_child(card)
		card.bind(upgrade)
		card.picked.connect(_on_card_picked)
		_cards.append(card)
	if not _cards.is_empty():
		_cards[0].call_deferred("grab_focus")


func _on_card_picked(upgrade: UpgradeData) -> void:
	get_viewport().set_input_as_handled()
	picked.emit(upgrade)
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	var index: int = -1
	match key_event.keycode:
		KEY_1:
			index = 0
		KEY_2:
			index = 1
		KEY_3:
			index = 2
	if index < 0 or index >= _cards.size():
		return
	accept_event()
	_on_card_picked(_cards[index]._upgrade)
