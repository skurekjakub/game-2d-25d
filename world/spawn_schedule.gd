class_name SpawnSchedule
extends Resource

@export var phases: Array[SpawnPhase] = []


func total_duration_seconds() -> int:
	if phases.is_empty():
		return 0
	return phases[phases.size() - 1].end_time_seconds()


func phase_at_time(time_elapsed: float) -> SpawnPhase:
	for phase in phases:
		if time_elapsed >= float(phase.starts_at_seconds) and time_elapsed < float(phase.end_time_seconds()):
			return phase
	return null


func phase_index_at_time(time_elapsed: float) -> int:
	for i in phases.size():
		var phase: SpawnPhase = phases[i]
		if time_elapsed >= float(phase.starts_at_seconds) and time_elapsed < float(phase.end_time_seconds()):
			return i
	return -1
