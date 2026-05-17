# Weapons System (M1.5)

Snapshot of how weapons are designed, coupled, attached to the Player, and how
damage propagates. Updated as of `milestone-1.5`.

For the rationale, see ADR-0003 (pure-functional upgrade system). For run-end
invariants, see ADR-0004.

---

## 1. Class graph

```
                           ┌─────────────────────┐
                           │   WeaponData        │  Resource (.tres on disk)
                           │   (Resource)        │  Shared / immutable at runtime.
                           │─────────────────────│  One file per weapon kind:
                           │ id: StringName      │    basic_blaster.tres
                           │ display_name        │    spread.tres
                           │ base_damage         │    aura.tres
                           │ fire_rate           │    orbital.tres
                           │ range               │
                           │ projectile_scene    │
                           │ weapon_scene  ◄─────┼─┐  Only set for scene-owned
                           │ pellet_count        │ │  weapons (Aura, Orbital).
                           └─────────▲───────────┘ │  Null for cooldown-fire
                                     │             │  (Blaster, Spread).
                                     │ data: WeaponData
                                     │
                           ┌─────────┴───────────┐
                           │   WeaponInstance    │  RefCounted (per-acquisition)
                           │   (RefCounted)      │  One per weapon the Player owns.
                           │─────────────────────│
                           │ data: WeaponData    │
                           │ cooldown_remaining  │
                           │ node: Node = null ──┼─┐  Set ONLY for scene-owned
                           │─────────────────────│ │  weapons. Points at the
                           │ effective_damage()  │ │  Aura/Orbital scene root
                           │ effective_fire_rate()│ │  spawned as a Player child.
                           │ effective_pellet_   │ │
                           │   count()           │ │
                           │ level()             │ │
                           │ count_upgrade(id)   │ │
                           │ tick(delta)         │ │
                           │ can_fire()          │ │
                           │ reset_cooldown()    │ │
                           └─────────▲───────────┘ │
                                     │             │
                                     │ weapons: Array[WeaponInstance]
                                     │             │
        ┌──────────┐       ┌─────────┴───────────┐ │
        │  Player  │───────│   WeaponHost        │ │  Node (child of Player)
        │ Char-    │ child │   (Node)            │ │  Owns + drives weapons.
        │ Body2D   │       │─────────────────────│ │
        └────┬─────┘       │ weapons: [WInst]    │ │
             │             │ _shooter: Node2D    │ │
             │             │ starter_weapons     │ │   @export
             │             │─────────────────────│ │
             │             │ _physics_process()  │ │   ← drives EVERYTHING:
             │             │   ├ cooldown-fire   │ │     - WInst.tick + fire
             │             │   └ _owned_tick     │ │     - or node._owned_tick
             │             │ add_weapon(data) ───┼─┘
             │             │ owned_weapon_ids()  │
             │             │ _spawn_pellets()    │   ← cone-fan, count from
             │             │ _spawn_single()     │     WInst.effective_pellet_count()
             │             └─────────────────────┘
             │
             │ child
             ▼
        ┌──────────────────────┐    ┌───────────────────────────────────────┐
        │ HealthComponent      │    │ Spawned weapon nodes (children of      │
        │ (Node)               │    │ Player, set up by WeaponHost.add_weapon)│
        │──────────────────────│    │                                       │
        │ hp, max_hp           │    │   AuraWeapon : Area2D                  │
        │ set_hp / set_max_hp  │    │     ├ Shape (CollisionShape2D)         │
        │ take_damage()        │    │     └ Visual (Polygon2D)               │
        │──────────────────────│    │                                       │
        │ signals:             │    │   OrbitalWeapon : Node2D               │
        │   damaged            │    │     └ OrbitalBlade : Area2D × N        │
        │   died               │    │           ├ Shape                      │
        │   hp_changed         │    │           └ Visual                     │
        │   max_hp_changed     │    └───────────────────────────────────────┘
        └──────────────────────┘
```

---

## 2. Two weapon shapes — one host

`WeaponHost` is the single driver. Per physics frame it iterates `weapons` and
branches on `weapon.node`:

```
WeaponHost._physics_process(delta)
    │
    ├─ if Game.run_state.is_over: return        ← ADR-0004 victory/death guard
    │
    └─ for weapon in weapons:
         │
         ├─ if weapon.node != null and weapon.node.has_method("_owned_tick"):
         │     │
         │     └─ weapon.node._owned_tick(delta)     ← SCENE-OWNED PATH
         │        continue                            (Aura, Orbital)
         │
         └─ COOLDOWN-FIRE PATH                       ← Blaster, Spread
            weapon.tick(delta)
            if not weapon.can_fire(): continue
            _try_fire(weapon)
              ├ find_nearest_target(...)
              ├ _spawn_pellets(weapon, target)
              │    └ count = weapon.effective_pellet_count()
              │      if count == 1: _spawn_single(weapon, target_pos)
              │      else:           fan cone of `count` projectiles, 30° wide
              │
              └ weapon.reset_cooldown()
```

Why two shapes:
- **Cooldown-fire** is stateless tick-and-spawn — projectile owns the rest.
- **Scene-owned** weapons (Aura, Orbital) need persistent presence in the world:
  Aura is a continuous overlap zone; Orbital owns rotating blade children that
  must keep their relative position frame-to-frame. They get their own scene
  tree branch and self-manage in `_owned_tick(delta)`.

---

## 3. Upgrades — pure-functional read-through-list

Source of truth: `Game.run_state.upgrades_taken: Array[UpgradeData]`.
Weapons NEVER mutate `WeaponData` (shared resource — would leak across runs).

```
                    Game.run_state.upgrades_taken  ◄──── modal pick appends here
                    [UpgradeData, UpgradeData, ...]
                                ▲
                                │ walked at fire time
                                │
    ┌───────────────────────────┴───────────────────────┐
    │                                                   │
WeaponInstance.effective_damage()       AuraWeapon._apply_radius()
    var d := data.base_damage              instance.count_upgrade(
    for upgrade in upgrades_taken:           &"aura_radius_25")
      if upgrade.id == "<id>_damage_25":   * 1.25 per stack
        d *= 1.25
    return d                            OrbitalWeapon.blade_count()
                                           1 + instance.count_upgrade(
                                              &"orbital_count_plus_1")
```

**Key construction is always per-weapon:** `<weapon_id>_<kind>_<value>`.
Example for an aura damage upgrade: `aura_damage_25`.
This is enforced by `effective_damage()`, `effective_fire_rate()`, and
`effective_pellet_count()` building keys from `data.id`. The
`spread_pellets_plus_1` upgrade cannot leak into Blaster because Blaster's
`effective_pellet_count()` builds `blaster_pellets_plus_1` and finds no match.

---

## 4. Pool gating

`UpgradeRegistry.pick_random_3_for(player)` filters the pool by ownership BEFORE
running the weighted random pick.

```
                          pool: Array[UpgradeData]  (14 entries)
                                       │
                                       ▼
                          _available_for_picker(player)
                                       │
       ┌───────────────────────────────┼───────────────────────────────┐
       ▼                               ▼                               ▼
  id startswith "acquire_"?     _weapon_prefix_of(id) ≠ ""?      stat upgrade
       │                               │                               │
   wid in owned?                  prefix in owned?                  always
   ├─ yes: drop                   ├─ yes: keep                       eligible
   └─ no:  keep (offer it)        └─ no:  drop (gated)

  owned_ids come from: player.get_node("WeaponHost").owned_weapon_ids()
  known_weapon_ids loaded once at _ready from combat/weapons/data/*.tres
  (drift-proof — see the duck-A finding fixed in da43beb)
```

Examples:
- Player owns Blaster only → pool sees 3 stat + 3 acquires + 2 blaster = 8 eligible
- Player owns all 4 → pool sees 3 stat + 0 acquires + 8 per-weapon = 11 eligible
- Player owns Blaster + Aura → pool sees 3 stat + 2 acquires + 4 per-weapon = 9

---

## 5. Acquisition — modal pick → weapon spawn

```
  Player levels up
       │
       ▼
  EventBus.level_up(new_level)
       │
       ▼
  UpgradePicker._on_level_up
       │  pause tree, open modal
       ▼
  modal shows pick_random_3_for(player)  ← gating runs here
       │  player clicks a card
       ▼
  UpgradePicker._apply_pick(upgrade)
       │  ① run_state.upgrades_taken.append(upgrade)    ← append FIRST so
       │  ② UpgradeRegistry.apply(upgrade, player)         downstream listeners
       │  ③ _modal = null; tree.paused = false             see the canonical list
       │  ④ EventBus.upgrade_applied.emit(upgrade)
       │
       ▼
  UpgradeRegistry.apply matches upgrade.id:
       │
       ├─ acquire_aura: ─────── host.add_weapon(load("res://combat/weapons/data/aura.tres"))
       ├─ acquire_orbital: ──── host.add_weapon(load("res://combat/weapons/data/orbital.tres"))
       ├─ acquire_spread: ───── host.add_weapon(load("res://combat/weapons/data/spread.tres"))
       │
       ├─ max_hp_20: ────────── hc.set_max_hp(+20); hc.set_hp(max_hp)
       ├─ move_speed_15: ────── player.speed *= 1.15
       ├─ heal_to_full: ─────── hc.set_hp(hc.max_hp)
       │
       └─ blaster_*, aura_*, orbital_*, spread_* (all per-weapon mechanical):
            pass    ← consumed lazily at fire time by WeaponInstance.effective_*

  WeaponHost.add_weapon(data):
       │
       ├─ inst := WeaponInstance.new(data)
       ├─ weapons.append(inst)
       │
       └─ if data.weapon_scene != null:                   ← scene-owned branch
             inst.node = data.weapon_scene.instantiate()
             _shooter.add_child(inst.node)                ← Player becomes the
             if inst.node.has_method("configure"):           parent of the new
                inst.node.configure(inst)                    weapon scene
```

`HUD._refresh_weapon_list` listens on `EventBus.upgrade_applied` and rebuilds the
"Blaster Lv.1 / Aura Lv.2 / ..." labels by walking `WeaponHost.weapons`.

---

## 6. Damage paths

There are 3 distinct damage application sites — all converge on
`HealthComponent.take_damage(amount, source)`.

```
       ┌──────────────────────────────────────────────────────────────────┐
       │                                                                  │
       │   COOLDOWN-FIRE (Blaster, Spread)                                │
       │                                                                  │
       │   WeaponHost._spawn_single() → BasicProjectile (Area2D)          │
       │       │   projectile.damage = weapon.effective_damage()          │
       │       │   added to _shooter.get_parent() so it stays in arena    │
       │       │   when player moves                                      │
       │       ▼                                                          │
       │   BasicProjectile._on_body_entered(enemy)                        │
       │       │   set_deferred("monitoring", false)  ← prevent double-fire│
       │       │   enemy.HealthComponent.take_damage(damage, self)        │
       │       │   EventBus.damage_dealt.emit(self, enemy, damage)        │
       │       │   queue_free()                                           │
       │       ▼                                                          │
       │   HealthComponent.take_damage                                    │
       │                                                                  │
       └──────────────────────────────────────────────────────────────────┘

       ┌──────────────────────────────────────────────────────────────────┐
       │                                                                  │
       │   AURA (persistent zone)                                         │
       │                                                                  │
       │   WeaponHost._physics_process                                    │
       │       │  if Game.run_state.is_over: return                       │
       │       ▼                                                          │
       │   AuraWeapon._owned_tick(delta)                                  │
       │       │  _apply_radius()                                         │
       │       │  _tick_remaining -= delta                                │
       │       │  if _tick_remaining > 0: return                          │
       │       │  _tick_remaining = TICK_INTERVAL_SEC (0.5)               │
       │       ▼                                                          │
       │   _apply_tick_damage()                                           │
       │       │  dmg = instance.effective_damage()                       │
       │       │  for body in get_overlapping_bodies():                   │
       │       │    if body in "enemies":                                 │
       │       │      body.HealthComponent.take_damage(dmg, self)         │
       │                                                                  │
       └──────────────────────────────────────────────────────────────────┘

       ┌──────────────────────────────────────────────────────────────────┐
       │                                                                  │
       │   ORBITAL (rotating blades)                                      │
       │                                                                  │
       │   WeaponHost._physics_process                                    │
       │       │  if Game.run_state.is_over: return                       │
       │       ▼                                                          │
       │   OrbitalWeapon._owned_tick(delta)                               │
       │       │  _sync_blade_count()                                     │
       │       │  _angle += delta * TAU / ROTATION_PERIOD_SEC             │
       │       │  for blade in _blades():                                 │
       │       │    blade.position = polar(BASE_RADIUS, _angle + step*i)  │
       │       │    blade.damage = instance.effective_damage()            │
       │       │    blade.owned_tick(delta)                               │
       │       ▼                                                          │
       │   OrbitalBlade.owned_tick(delta)                                 │
       │       │  decrement _hit_cooldowns; cull elapsed                  │
       │       │  for body in get_overlapping_bodies():                   │
       │       │    if body in "enemies" and body.id NOT in _hit_cooldowns:│
       │       │      hc.take_damage(damage, self)                        │
       │       │      _hit_cooldowns[body.get_instance_id()] = 0.5        │
       │                                                                  │
       │   Cooldown is PER BLADE — 3 blades passing the same enemy in     │
       │   quick succession can each apply damage (intentional).          │
       │                                                                  │
       └──────────────────────────────────────────────────────────────────┘
```

All three converge on `HealthComponent.take_damage`, which:
1. Early-outs if already dead (`hp <= 0`).
2. Subtracts amount, clamps to 0.
3. Emits `hp_changed(new_hp)` (HP-bar consumers).
4. Emits `damaged(amount, new_hp)` (visual flash, screen shake hook).
5. If hp reached 0, emits `died(source)` exactly once (guarded by
   `_died_emitted`).

`Player._on_died` → `Game.end_run(false)` → `run_state.is_over = true` →
`WeaponHost._physics_process` early-outs next frame → all weapons stop.

---

## 7. Lifecycle gates — what stops when

```
  Death path:                         Victory path:
  ═══════════                         ═════════════
  enemy hits Player                   SpawnerDirector schedule complete
       │                                   │
       ▼                                   ▼
  HC.take_damage → hp=0                Game.end_run(true)
       │                                   │
       ▼                                   ▼
  HC.died.emit                         run_state.is_over = true
       │                               EventBus.run_ended(true)
       ▼                                   │
  Player._on_died                          ▼
       │                               (no Player-side handler)
       ├ set_physics_process(false)        │
       ├ _weapon_host.set_phys(false)      │
       └ Game.end_run(false)                │
           │                                │
           ▼                                ▼
           run_state.is_over = true   ┌────────────────────────────────┐
           EventBus.run_ended(false)  │ WeaponHost._physics_process    │
                                      │ early-outs on is_over          │
                                      │ → all scene-owned weapons stop │
                                      │   ticking, no more damage      │
                                      └────────────────────────────────┘
                                      (fix shipped in 943935b — see
                                       final duck A IMPORTANT)
```

`Game.end_run` is the single guarded mutation site (ADR-0004): if either path
fires first, the second is a no-op. `run_state.is_over` is the canonical flag
checked by `Game._process` (timer freeze), `Game.add_xp` (no post-death twitch),
and now `WeaponHost._physics_process` (no post-death/victory damage).

---

## 8. Data file layout

```
combat/
├── weapons/
│   ├── weapon_data.gd          ← Resource subclass
│   ├── weapon_instance.gd      ← RefCounted, walks upgrades_taken
│   ├── weapon_host.gd          ← Node, child of Player
│   │
│   ├── data/                   ← WeaponData .tres (scanned at registry _ready)
│   │   ├── basic_blaster.tres      id = &"blaster"
│   │   ├── spread.tres             id = &"spread"
│   │   ├── aura.tres               id = &"aura"     weapon_scene = aura.tscn
│   │   └── orbital.tres            id = &"orbital"  weapon_scene = orbital.tscn
│   │
│   ├── projectiles/
│   │   ├── basic_projectile.gd/.tscn  ← Blaster + Spread use this
│   │
│   ├── aura/
│   │   ├── aura_weapon.gd          ← class AuraWeapon : Area2D
│   │   └── aura_weapon.tscn
│   │
│   └── orbital/
│       ├── orbital_weapon.gd       ← class OrbitalWeapon : Node2D
│       ├── orbital_weapon.tscn
│       ├── orbital_blade.gd        ← class OrbitalBlade : Area2D
│       └── orbital_blade.tscn
│
└── upgrades/
    ├── upgrade_data.gd         ← Resource (id, display_name, description, weight)
    ├── upgrade_registry.gd     ← Autoload: pool, gating, apply()
    │
    └── data/                   ← UpgradeData .tres (scanned at registry _ready)
        ├── max_hp_20.tres
        ├── move_speed_15.tres
        ├── heal_to_full.tres
        ├── blaster_damage_25.tres
        ├── blaster_fire_rate_30.tres
        ├── spread_damage_25.tres
        ├── spread_pellets_plus_1.tres
        ├── acquire_spread.tres
        ├── aura_damage_25.tres
        ├── aura_radius_25.tres
        ├── acquire_aura.tres
        ├── orbital_damage_25.tres
        ├── orbital_count_plus_1.tres
        └── acquire_orbital.tres
```

---

## 9. Adding a 5th weapon — concrete checklist

To add weapon `whip`:

1. Drop `combat/weapons/data/whip.tres` with `id = &"whip"`. If it's
   scene-owned, set `weapon_scene = <whip_weapon.tscn>`; otherwise leave null and
   set `projectile_scene` for cooldown-fire.
2. (If scene-owned) Create `combat/weapons/whip/whip_weapon.gd` + `.tscn`. The
   script must have `_owned_tick(delta: float)` and optionally `configure(inst)`.
3. Drop `acquire_whip.tres` + 2 mechanical upgrades (e.g.
   `whip_damage_25.tres`, `whip_length_25.tres`).
4. Add 3 match arms in `UpgradeRegistry.apply` — typically `pass` for the
   mechanical ones, `host.add_weapon(load(WHIP_DATA_PATH))` for the acquire.
5. (Nothing else.) `known_weapon_ids` derives from `combat/weapons/data/*.tres`
   so pool-gating picks the new weapon up automatically (drift-fixed in commit
   `da43beb`).

That's it. The `WeaponInstance.effective_*` methods all key on `data.id`, so the
new weapon's mechanical upgrades work without touching that file.

---

## 10. Known non-obvious behaviors

- **Aura recomputes radius every physics frame** — cheap (microseconds), lets
  picked `aura_radius_25` upgrades resize the zone on the next frame. Could be
  optimized to an `upgrade_applied` listener; deferred.
- **Orbital re-hit cooldown is per blade, not per weapon.** 3 blades passing
  through one enemy in quick succession each apply damage. Intentional —
  documented in `orbital_blade.gd`.
- **Orbital instance_ids are session-unique** (Godot 4 validator counter on
  ObjectIDs, PR #36189), so a freed enemy cannot inherit a stale cooldown
  entry from a previous enemy with the same slot.
- **WeaponInstance.level() prefix-matches `<id>_*`** — weapon ids must not be
  prefixes of other weapon ids (e.g., `blaster` + `blaster_v2` would
  double-count). Documented in `weapon_data.gd:id`.
- **Projectiles parent to `_shooter.get_parent()`** (the Arena), not to the
  shooter, so they don't follow the Player's movement.
- **`set_deferred("monitoring", false)` before `queue_free()`** on every Area2D
  that frees from `body_entered` — prevents double-damage from a same-frame
  re-entry of the signal. See project memory `godot_area2d_pickup_pattern`.

---

## 11. Related docs

- `docs/architecture.md` — overall project architecture + Godot addendum
- `docs/decisions/0003-pure-functional-upgrade-system.md` — why upgrades read,
  don't mutate
- `docs/decisions/0004-central-end-run-guard.md` — `Game.end_run` invariants
- `docs/decisions/0005-signal-driven-hud.md` — HUD subscribes to EventBus,
  never holds a Player ref
- `docs/design/2026-05-17-milestone-1.5-weapon-variety.md` — the M1.5 spec this
  system implements
