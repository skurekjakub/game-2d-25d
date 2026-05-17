class_name DamageMeterRow
extends HBoxContainer


func apply(row: RunStatsRow) -> void:
	($NameLabel as Label).text = row.display_name
	($ValueLabel as Label).text = _format_value(row.damage)
	($PercentBar as ProgressBar).value = clamp(row.bar_fill_fraction * 100.0, 0.0, 100.0)


static func _format_value(amount: float) -> String:
	if amount >= 1_000_000.0:
		return "%.1fM" % (amount / 1_000_000.0)
	if amount >= 10_000.0:
		return "%.1fk" % (amount / 1000.0)
	return "%d" % int(amount)
