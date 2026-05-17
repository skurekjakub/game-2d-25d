class_name SpawnPhase
extends Resource

@export var starts_at_seconds: int = 0
@export var duration_seconds: int = 30
@export var spawn_rate_per_sec: float = 1.0
# enemy_data is single-entry for M1.2. M1.4+ replaces with a weighted Dictionary
# per the design doc; the field name change is the breaking refactor signal.
@export var enemy_data: EnemyData


func end_time_seconds() -> int:
	return starts_at_seconds + duration_seconds
