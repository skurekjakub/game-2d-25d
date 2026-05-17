class_name DamageMeterRow
extends HBoxContainer


func apply(row: RunStatsRow) -> void:
	($NameLabel as Label).text = row.display_name
	($ValueLabel as Label).text = NumberFormat.compact(row.damage)
	($PercentBar as ProgressBar).value = clamp(row.bar_fill_fraction * 100.0, 0.0, 100.0)
