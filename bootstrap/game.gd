extends Node

var run_state: RunState


func _ready() -> void:
	run_state = RunState.new()


func _process(delta: float) -> void:
	if run_state != null:
		run_state.time_elapsed += delta


func start_run() -> void:
	run_state = RunState.new()
	run_state.max_hp = 100.0
	run_state.hp = run_state.max_hp
	run_state.xp = 0
	run_state.level = 1
	run_state.time_elapsed = 0.0
	EventBus.run_started.emit()


func xp_needed(for_level: int) -> int:
	return 5 + for_level * 3


func add_xp(amount: int) -> void:
	run_state.xp += amount
	EventBus.xp_gained.emit(amount)
	while run_state.xp >= xp_needed(run_state.level):
		run_state.xp -= xp_needed(run_state.level)
		run_state.level += 1
		EventBus.level_up.emit(run_state.level)


class RunState:
	var hp: float
	var max_hp: float
	var xp: int
	var level: int
	var time_elapsed: float
