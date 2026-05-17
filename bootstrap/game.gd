extends Node

var run_state: RunState
var _run_ended_emitted: bool = false


func _ready() -> void:
	run_state = RunState.new()


func _process(delta: float) -> void:
	if run_state != null and not run_state.is_over:
		run_state.time_elapsed += delta


func start_run() -> void:
	run_state = RunState.new()
	run_state.xp = 0
	run_state.level = 1
	run_state.time_elapsed = 0.0
	run_state.upgrades_taken = []
	run_state.is_over = false
	_run_ended_emitted = false
	EventBus.run_started.emit()


func end_run(victory: bool) -> void:
	if _run_ended_emitted:
		return
	_run_ended_emitted = true
	run_state.is_over = true
	EventBus.run_ended.emit(victory)


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
	var xp: int
	var level: int
	var time_elapsed: float
	var upgrades_taken: Array[Resource] = []
	var is_over: bool = false
