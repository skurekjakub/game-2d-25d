class_name NumberFormat
extends RefCounted


static func compact(amount: float) -> String:
	# 999_950.0 boundary so the gap between "999.9k" and "1.0M" stays one decimal
	# wide instead of letting the k-branch print "1000.0k".
	if amount >= 999_950.0:
		return "%.1fM" % (amount / 1_000_000.0)
	if amount >= 10_000.0:
		return "%.1fk" % (amount / 1000.0)
	return "%d" % int(amount)
