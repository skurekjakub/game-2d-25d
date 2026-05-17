class_name NumberFormat
extends RefCounted


static func compact(amount: float) -> String:
	if amount >= 1_000_000.0:
		return "%.1fM" % (amount / 1_000_000.0)
	if amount >= 10_000.0:
		return "%.1fk" % (amount / 1000.0)
	return "%d" % int(amount)
