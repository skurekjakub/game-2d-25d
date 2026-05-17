# Observer subscriber: paints once on EventBus.run_ended.
class_name DamageSummaryPanel
extends PanelContainer

const ROW_SCENE: PackedScene = preload("res://ui/damage_meter_row.tscn")

@onready var _list: VBoxContainer = $Body/List
@onready var _total_label: Label = $Body/Header/TotalLabel
@onready var _duration_label: Label = $Body/Header/DurationLabel
@onready var _dps_label: Label = $Body/Header/DpsLabel


func _ready() -> void:
	visible = false
	EventBus.run_ended.connect(_on_run_ended)


func _on_run_ended(_victory: bool) -> void:
	_populate()
	visible = true


func _populate() -> void:
	if Game.run_state == null:
		return
	var stats: RunStats = Game.run_state.stats
	var total: float = stats.total_damage()
	_total_label.text = "TOTAL DAMAGE  %s" % NumberFormat.compact(total)
	_duration_label.text = "RUN DURATION  %s" % _format_mm_ss(stats.elapsed_seconds())
	_dps_label.text = "AVERAGE DPS   %d" % int(stats.average_dps())
	for child: Node in _list.get_children():
		child.queue_free()
	# Panel bars fill by share-of-total damage (sums to 100% across all rows).
	var rows: Array[RunStatsRow] = stats.sorted_all(_display_name_for)
	for row_data: RunStatsRow in rows:
		var widget: DamageMeterRow = ROW_SCENE.instantiate()
		_list.add_child(widget)
		var share_data := RunStatsRow.new(
			row_data.weapon_id,
			row_data.display_name,
			row_data.damage,
			row_data.dps,
			row_data.damage / total if total > 0.0 else 0.0
		)
		widget.apply(share_data)


func _display_name_for(weapon_id: StringName) -> String:
	return WeaponDisplayLookup.for_id(get_tree(), weapon_id)


static func _format_mm_ss(seconds: float) -> String:
	var total: int = int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
