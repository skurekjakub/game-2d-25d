class_name UpgradeEffect
extends Resource

# Strategy base for "what does this upgrade do to the Player at pick time?"
# Subclasses are stored as sub-resources inside each UpgradeData.tres.
# UpgradeRegistry.apply delegates to effect.execute(player) — no match block.
#
# CAUTION: script paths in this directory are referenced by every
# combat/upgrades/data/*.tres ExtResource line. Renaming or moving any
# effect script silently breaks the .tres files. If you must move one,
# grep-replace its path across combat/upgrades/data/ in the same commit.


# Default no-op. Subclasses override.
func execute(_player: Player) -> void:
	pass
