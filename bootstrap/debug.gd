extends Node

var god_mode: bool = false
var time_scale: float = 1.0
var show_overlay: bool = false
var log_events: bool = true
# damage_dealt fires per-hit and floods the console; off by default.
var log_damage: bool = false


func _ready() -> void:
	if OS.is_debug_build():
		print("[Debug] enabled (debug build)")
	_wire_event_logging()


func _wire_event_logging() -> void:
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.spawn_phase_changed.connect(_on_spawn_phase_changed)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.level_up.connect(_on_level_up)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_killed.connect(_on_boss_killed)
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.damage_dealt.connect(_on_damage_dealt)


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_F3:
			log_events = not log_events
			print("[Debug] log_events = %s" % log_events)
		KEY_F4:
			god_mode = not god_mode
			print("[Debug] god_mode = %s" % god_mode)
		KEY_F12:
			show_overlay = not show_overlay
			print("[Debug] show_overlay = %s" % show_overlay)
		# F1/F2/F5/F6/F7 added in milestone 1.7 when their targets exist


func _log(msg: String) -> void:
	if not log_events:
		return
	print("[EventBus] %s" % msg)


func _on_run_started() -> void:
	_log("run_started")


func _on_run_ended(victory: bool) -> void:
	_log("run_ended victory=%s" % victory)


func _on_spawn_phase_changed(phase_idx: int) -> void:
	_log("spawn_phase_changed → idx=%d" % phase_idx)


func _on_wave_completed() -> void:
	_log("wave_completed")


func _on_level_up(new_level: int) -> void:
	_log("level_up → %d" % new_level)


func _on_boss_spawned(boss: Node) -> void:
	_log("boss_spawned %s" % boss.name)


func _on_boss_killed(boss: Node) -> void:
	_log("boss_killed %s" % boss.name)


func _on_xp_gained(amount: int) -> void:
	_log("xp_gained +%d" % amount)


func _on_enemy_killed(enemy: Node, pos: Vector2) -> void:
	_log("enemy_killed %s at %s" % [enemy.name, pos])


func _on_damage_dealt(_source: Node, target: Node, amount: float) -> void:
	if not log_damage:
		return
	_log("damage_dealt → %s -%.1f" % [target.name, amount])
