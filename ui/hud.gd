class_name Hud
extends Control

@onready var _hp_bar: ProgressBar = $HpBar
@onready var _xp_bar: ProgressBar = $XpBar
@onready var _level_label: Label = $LevelLabel
@onready var _timer_label: Label = $TimerLabel
@onready var _weapon_list: VBoxContainer = $WeaponList
@onready var _fps_label: Label = $FpsLabel

var _current_level: int = 1


func _ready() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.level_up.connect(_on_level_up)
	EventBus.upgrade_applied.connect(_on_upgrade_applied)
	_apply_reset_state()
	_refresh_weapon_list()


func _process(_delta: float) -> void:
	if Game.run_state != null:
		_timer_label.text = _format_mm_ss(Game.run_state.time_elapsed)
	_fps_label.text = "%d fps" % Engine.get_frames_per_second()


func _on_run_started() -> void:
	_apply_reset_state()
	_refresh_weapon_list()


func _on_run_ended(victory: bool) -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.6) if not victory else Color(1.2, 1.2, 1.0)


func _on_player_health_changed(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp


func _on_xp_gained(_amount: int) -> void:
	if Game.run_state == null:
		return
	_xp_bar.max_value = float(Game.xp_needed(Game.run_state.level))
	_xp_bar.value = float(Game.run_state.xp)


func _on_level_up(new_level: int) -> void:
	_current_level = new_level
	_level_label.text = "Lv %d" % new_level
	if Game.run_state != null:
		_xp_bar.max_value = float(Game.xp_needed(Game.run_state.level))
		_xp_bar.value = float(Game.run_state.xp)


func _on_upgrade_applied(_upgrade: UpgradeData) -> void:
	_refresh_weapon_list()


func _apply_reset_state() -> void:
	modulate = Color.WHITE
	_current_level = 1
	_level_label.text = "Lv 1"
	_xp_bar.value = 0.0
	if Game.run_state != null:
		_xp_bar.max_value = float(Game.xp_needed(1))
	else:
		_xp_bar.max_value = float(8)
	_hp_bar.max_value = 100.0
	_hp_bar.value = 100.0
	_timer_label.text = "00:00"


func _refresh_weapon_list() -> void:
	for child in _weapon_list.get_children():
		child.queue_free()
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var host := players[0].get_node_or_null("WeaponHost") as WeaponHost
	if host == null:
		return
	for weapon in host.weapons:
		var line := Label.new()
		var weapon_name: String = weapon.data.display_name if weapon.data != null else "?"
		line.text = "%s Lv.%d" % [weapon_name, weapon.level()]
		_weapon_list.add_child(line)


static func _format_mm_ss(seconds: float) -> String:
	var total: int = int(seconds)
	var m: int = total / 60
	var s: int = total % 60
	return "%02d:%02d" % [m, s]
