class_name UpgradeCard
extends Button

signal picked(upgrade: UpgradeData)

@onready var _title_label: Label = $VBox/Title
@onready var _description_label: Label = $VBox/Description

var _upgrade: UpgradeData


func _ready() -> void:
	custom_minimum_size = Vector2(220, 160)
	pressed.connect(_on_pressed)


func bind(upgrade: UpgradeData) -> void:
	_upgrade = upgrade
	if is_node_ready():
		_render()
	else:
		ready.connect(_render, CONNECT_ONE_SHOT)


func _render() -> void:
	if _upgrade == null:
		return
	_title_label.text = _upgrade.display_name
	_description_label.text = _upgrade.description


func _on_pressed() -> void:
	if _upgrade != null:
		picked.emit(_upgrade)
