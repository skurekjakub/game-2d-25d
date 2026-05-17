# Upgrade pipeline

Source-of-truth: `Game.run_state.upgrades_taken: Array[UpgradeData]`.
Pure-functional reads at fire time (ADR-0003). Modal-driven pick.

Will be **revised at M1.6** when `UpgradeEffect` Strategy lands —
`UpgradeRegistry.apply()` collapses from a 12-arm match into
`upgrade.effect.execute(player)`. This doc describes the current
post-Bundle-1 shape; the M1.6 plan tracks the upcoming change.

---

## Components

```
                        ┌──────────────────────────────────┐
                        │      UpgradeRegistry (autoload)  │
                        │                                  │
                        │   pool: Array[UpgradeData]       │  loaded from
                        │   known_weapon_ids: [StringName] │  combat/upgrades/data/
                        │                                  │  and combat/weapons/data/
                        │   pick_random_3()  ──┐           │  at _ready (drift-proof)
                        │   pick_random_3_for( │           │
                        │     player: Player)  │           │
                        │   _available_for_    │           │
                        │     picker(player)   │           │
                        │   apply(             │           │
                        │     upgrade,         │           │
                        │     player: Player)  │           │  ← typed Player
                        └──────────────────────┼───────────┘     post-Bundle-1
                                               │
                  ┌────────────────────────────┘
                  │
                  ▼
        ┌───────────────────────────────────────────────────────┐
        │             pick_random_3_for(player) flow             │
        │                                                       │
        │   pool (14 UpgradeData)                               │
        │      │                                                │
        │      ▼                                                │
        │   _available_for_picker(player)                       │
        │      │                                                │
        │      │   for each upgrade:                            │
        │      │     id starts with "acquire_"?                 │
        │      │       └→ hide if player already owns weapon    │
        │      │     id has known weapon prefix?                │
        │      │       └→ show only if player owns that weapon  │
        │      │     else: stat upgrade → always show           │
        │      │                                                │
        │      ▼                                                │
        │   weighted random pick × 3 (no duplicates)            │
        │                                                       │
        └───────────────────┬───────────────────────────────────┘
                            │
                            ▼  Array[UpgradeData]
                  ┌──────────────────────┐
                  │  UpgradePicker (UI)  │  pauses tree, shows 3 cards
                  └──────────┬───────────┘
                             │  on click:
                             ▼
                  ┌──────────────────────────────────────┐
                  │  _apply_pick(upgrade)                │
                  │                                      │
                  │  1. run_state.upgrades_taken.append(  │  ← append FIRST so
                  │       upgrade)                       │     downstream sees
                  │  2. UpgradeRegistry.apply(           │     canonical list
                  │       upgrade, player)               │
                  │  3. _modal = null                    │  ← clear BEFORE
                  │  4. tree.paused = false              │     emit (queued
                  │  5. EventBus.upgrade_applied.emit    │     modal otherwise
                  │       (upgrade)                      │     drops)
                  └────────────┬─────────────────────────┘
                               │
                  ┌────────────┴─────────────────┐
                  │   apply() match arms          │
                  │                              │
                  │  STAT upgrades:               │
                  │  &"max_hp_20"     → hc.set_max_hp + set_hp │
                  │  &"move_speed_15" → player.speed *= 1.15   │
                  │  &"heal_to_full"  → hc.set_hp(max_hp)      │
                  │                              │
                  │  WEAPON-MECHANICAL (lazy):    │
                  │  &"blaster_damage_25"  → pass (read at fire)│
                  │  &"blaster_fire_rate_30" → pass             │
                  │  &"spread_*"           → pass               │
                  │  &"aura_*"             → pass               │
                  │  &"orbital_*"          → pass               │
                  │                              │
                  │  ACQUIRES:                    │
                  │  &"acquire_spread"  → player.weapon_host  │
                  │  &"acquire_aura"    │   .add_weapon(...) │  ← post-Bundle-1
                  │  &"acquire_orbital" │                    │     (was inline
                  │                              │                  get_node_or_null)
                  │  _: push_warning             │
                  └──────────────────────────────┘
                               │
                               ▼
                  ┌──────────────────────────────┐
                  │  WeaponInstance.effective_*   │  walks upgrades_taken
                  │  (at fire/tick time)          │  for matching ids
                  │                              │  (no mutation of
                  │  damage_key =                 │   WeaponData!)
                  │    "{wid}_damage_25"          │
                  │  fire_rate_key =              │
                  │    "{wid}_fire_rate_30"       │
                  │  pellets_key =                │
                  │    "{wid}_pellets_plus_1"     │
                  └──────────────────────────────┘
```

---

## Why pure-functional reads (ADR-0003 recap)

If `apply()` mutated `WeaponData` fields directly
(`weapon.damage_mult *= 1.25`), every `WeaponData.tres` instance shared
across runs would corrupt — Resources are shared by ref.

Instead, `WeaponInstance.effective_damage()` walks
`Game.run_state.upgrades_taken` at fire time. Picking +25% Blaster
Damage 3 times = list has 3 entries with id `&"blaster_damage_25"` =
fire returns `base_damage × 1.25³`. List clears on `start_run`. No
mutation of shared state.

---

## Pool gating — auto-derived weapon roster

`known_weapon_ids` is scanned from `combat/weapons/data/*.tres` at
`_ready` (not hand-maintained). When a 5th weapon ships, the gating
classifier picks it up automatically — drift-proof per the final
M1.5 duck verdict.

---

## Bundle 1 changes to this pipeline

| Before | After |
|---|---|
| `apply(upgrade, player: Node)` | `apply(upgrade, player: Player)` |
| `pick_random_3_for(player: Node)` | `pick_random_3_for(player: Player)` |
| 4 inline `player.get_node_or_null("WeaponHost") as WeaponHost` | `player.weapon_host` |
| `player.set("speed", player.get("speed") * 1.15)` (dynamic dispatch) | `player.speed *= MOVE_SPEED_MULTIPLIER` (typed) |
| Test `_PlayerStub(extends Node)` with manual `var speed: float = 200.0` | Real Player scene via `TestWorld.player_with_weapons` or `_make_player_with_hc` |

The pipeline shape didn't change; the **types and the lookup discipline
across the boundary** did. New apply-arm authors can no longer pass a
random Node — the compiler enforces Player.

---

## M1.6 forward look

`apply()` will become:

```gdscript
func apply(upgrade: UpgradeData, player: Player) -> void:
    if upgrade == null or player == null or upgrade.effect == null:
        return
    upgrade.effect.execute(player)
```

Each `.tres` will embed a typed `effect` sub-resource:
- `MaxHpBumpEffect(amount: float)`
- `SpeedMultiplierEffect(multiplier: float)`
- `HealToFullEffect`
- `WeaponAcquireEffect(weapon_data: WeaponData)`
- `NoopEffect`

The 12-arm match block disappears. Pool gating stays as-is — it doesn't
need to know about effect types.

---

## Tests

- `tests/combat/upgrades/upgrade_registry.gd` — pool gating + apply behavior
- `tests/ui/upgrade_picker.gd` — modal-pick chain + multi-level
- `tests/combat/weapons/weapon_instance.gd` — effective_damage / fire_rate /
  pellets / level read-through-list

---

## Related

- `combat/upgrades/upgrade_registry.gd`
- `combat/weapons/weapon_instance.gd`
- `ui/upgrade_picker.gd`
- `docs/decisions/0003-pure-functional-upgrade-system.md`
- `docs/architecture/lookups-and-helpers.md`
- `docs/plans/2026-05-17-milestone-1.6-damage-meter.md` — M1.6 will
  add `RunStats` aggregation to this pipeline
