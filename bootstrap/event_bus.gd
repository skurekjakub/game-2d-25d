extends Node

# Combat events
signal damage_dealt(source: Node, target: Node, amount: float)
signal enemy_killed(enemy: Node, position: Vector2)

# Progression events
signal xp_gained(amount: int)
signal level_up(new_level: int)

# Phase / boss events
signal boss_spawned(boss: Node)
signal boss_killed(boss: Node)

# Run lifecycle
signal run_started
signal run_ended(victory: bool)

# Spawner lifecycle
signal spawn_phase_changed(phase_idx: int)
signal wave_completed
