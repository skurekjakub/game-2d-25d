class_name NoopEffect
extends UpgradeEffect

# Concrete no-op effect type — exists so the .tres inspector's resource
# picker offers a selectable entry (assigning the abstract UpgradeEffect
# base leaves an empty dropdown row). Used by mechanical per-weapon
# upgrades like blaster_damage_25 whose behavior happens lazily at fire
# time via WeaponInstance.effective_*.
