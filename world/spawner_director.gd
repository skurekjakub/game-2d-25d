class_name SpawnerDirector
extends Node

# Local signals (also re-emitted to EventBus by the production paths;
# tests exercise these locally to stay pure-logic).
signal phase_advanced(phase_idx: int)
signal wave_ended

const ENEMY_SCENE := preload("res://combat/enemies/enemy.tscn")
const SPAWN_MARGIN: float = 64.0  # extra distance beyond the camera viewport diagonal

@export var schedule: SpawnSchedule
# Node-typed @exports don't auto-resolve from NodePath in .tscn in Godot 4.6
# (proposal godot-proposals#1048 not merged for non-Resource Node types).
# Use NodePath + manual resolve in _ready; tests set `enemies_container` directly.
@export var enemies_container_path: NodePath
@export var max_concurrent_enemies: int = 30
# Spawn positions get clamped to this rect (arena interior). Off-camera-ring
# spawns at the top/bottom can otherwise land outside walls — enemies pile up
# against the wall and never reach the player. Default is effectively unbounded
# so tests / standalone uses don't accidentally trap spawns at the origin.
@export var spawn_bounds: Rect2 = Rect2(-100000, -100000, 200000, 200000)

var enemies_container: Node2D
var spawn_budget: float = 0.0
var _last_phase_index: int = -1
var _wave_ended_emitted: bool = false
var _spawn_counter: int = 0


func _ready() -> void:
	_last_phase_index = -1
	_wave_ended_emitted = false
	if enemies_container == null and not enemies_container_path.is_empty():
		enemies_container = get_node_or_null(enemies_container_path) as Node2D


func _process(delta: float) -> void:
	if schedule == null:
		return
	var time_elapsed: float = Game.run_state.time_elapsed
	_on_time_advanced(time_elapsed)
	var phase: SpawnPhase = schedule.phase_at_time(time_elapsed)
	if phase == null:
		return
	accumulate_budget(delta, phase.spawn_rate_per_sec)
	while spawn_budget >= 1.0:
		if _enemy_count_at_cap():
			break
		_try_spawn_one(phase)
		consume_one_spawn()


# Pure math: spawn position on a circle around player.
static func compute_spawn_position(player_pos: Vector2, radius: float, angle_rad: float) -> Vector2:
	return player_pos + Vector2(cos(angle_rad), sin(angle_rad)) * radius


# Pure math: clamp a candidate spawn position to a rectangular bounds.
# Used when the off-camera ring would land outside the playable arena.
static func clamp_spawn_to_bounds(pos: Vector2, bounds: Rect2) -> Vector2:
	return Vector2(
		clamp(pos.x, bounds.position.x, bounds.end.x), clamp(pos.y, bounds.position.y, bounds.end.y)
	)


func accumulate_budget(delta: float, rate_per_sec: float) -> void:
	spawn_budget += delta * rate_per_sec


func consume_one_spawn() -> void:
	spawn_budget = max(0.0, spawn_budget - 1.0)


# Track phase index transitions (local signal + EventBus re-emit).
func _on_time_advanced(time_elapsed: float) -> void:
	if schedule == null:
		return
	var idx: int = schedule.phase_index_at_time(time_elapsed)
	if idx != _last_phase_index and idx >= 0:
		_last_phase_index = idx
		phase_advanced.emit(idx)
		if is_inside_tree():
			EventBus.spawn_phase_changed.emit(idx)
	if (
		idx < 0
		and not _wave_ended_emitted
		and time_elapsed >= float(schedule.total_duration_seconds())
	):
		_wave_ended_emitted = true
		wave_ended.emit()
		if is_inside_tree():
			EventBus.wave_completed.emit()


func _enemy_count_at_cap() -> bool:
	if enemies_container == null:
		return false
	return enemies_container.get_child_count() >= max_concurrent_enemies


func _try_spawn_one(phase: SpawnPhase) -> void:
	if phase.enemy_data == null or enemies_container == null:
		return
	var player_pos: Vector2 = _player_position()
	var radius: float = _spawn_radius()
	var angle: float = randf() * TAU
	var spawn_pos: Vector2 = compute_spawn_position(player_pos, radius, angle)
	spawn_pos = clamp_spawn_to_bounds(spawn_pos, spawn_bounds)
	_spawn_counter += 1
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.data = phase.enemy_data
	enemy.name = "%s_%d" % [String(phase.enemy_data.id), _spawn_counter]
	enemy.global_position = spawn_pos
	enemies_container.add_child(enemy)


# Player-position lookup via group; null-safe.
func _player_position() -> Vector2:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return Vector2.ZERO
	var p: Node = players[0]
	if p is Node2D:
		return (p as Node2D).global_position
	return Vector2.ZERO


# Spawn radius = viewport diagonal / 2 + SPAWN_MARGIN.
# Resolved from the current viewport rather than a Camera2D node, because the
# camera lives under Player and we don't want SpawnerDirector to know about it.
func _spawn_radius() -> float:
	var vp := get_viewport()
	if vp == null:
		return 800.0  # safe headless fallback
	var rect: Rect2 = vp.get_visible_rect()
	# Account for zoom: zoomed-in (zoom > 1) means smaller visible world rect.
	var zoom: Vector2 = _camera_zoom()
	var world_w: float = rect.size.x / zoom.x
	var world_h: float = rect.size.y / zoom.y
	var diagonal: float = sqrt(world_w * world_w + world_h * world_h)
	return diagonal * 0.5 + SPAWN_MARGIN


func _camera_zoom() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ONE
	var cam := vp.get_camera_2d()
	if cam == null:
		return Vector2.ONE
	return cam.zoom
