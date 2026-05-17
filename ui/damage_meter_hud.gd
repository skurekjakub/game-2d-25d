class_name DamageMeterHud
extends PanelContainer

const ROW_SCENE: PackedScene = preload("res://ui/damage_meter_row.tscn")
const REFRESH_INTERVAL_SEC: float = 0.25
const MAX_ROWS: int = 5

@onready var _list: VBoxContainer = $List
var _timer: Timer


func _ready() -> void:
	visible = false
	_timer = Timer.new()
	_timer.wait_time = REFRESH_INTERVAL_SEC
	_timer.one_shot = false
	_timer.timeout.connect(refresh_now)
	add_child(_timer)
	_timer.start()


func refresh_now() -> void:
	if Game.run_state == null:
		visible = false
		return
	var rows: Array[RunStatsRow] = Game.run_state.stats.sorted_top_n(MAX_ROWS, _display_name_for)
	if rows.is_empty():
		visible = false
		return
	visible = true
	_rebuild(rows)


func _rebuild(rows: Array[RunStatsRow]) -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	var top_damage: float = rows[0].damage
	for row_data: RunStatsRow in rows:
		var widget: DamageMeterRow = ROW_SCENE.instantiate()
		_list.add_child(widget)
		# Live meter fills the bar by rank-relative ratio (top weapon = full bar);
		# data layer leaves bar_fill_fraction = 0 so each view computes its own.
		var rank_data := RunStatsRow.new(
			row_data.weapon_id,
			row_data.display_name,
			row_data.damage,
			row_data.dps,
			row_data.damage / top_damage if top_damage > 0.0 else 0.0
		)
		widget.apply(rank_data)


func _display_name_for(weapon_id: StringName) -> String:
	return WeaponDisplayLookup.for_id(get_tree(), weapon_id)
