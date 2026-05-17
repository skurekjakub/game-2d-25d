# Damage pipeline

Every path that ends in `HealthComponent.take_damage`. Three weapon
sources, two component sources, one common sink.

---

## The funnel

```
   ┌──────────────────┐    ┌─────────────┐    ┌────────────────────┐
   │ BasicProjectile  │    │ AuraWeapon  │    │ OrbitalBlade       │
   │ (Blaster +       │    │ (continuous │    │ (rotating, per-    │
   │  Spread)         │    │  zone tick) │    │  enemy cooldown)   │
   └────────┬─────────┘    └──────┬──────┘    └─────────┬──────────┘
            │                     │                     │
            │  body_entered       │  _owned_tick →      │  owned_tick →
            │                     │  get_overlapping    │  get_overlapping
            ▼                     ▼                     ▼
                       ┌────────────────────────┐
                       │  Damageable.try_damage │  ◄── ONE call site for
                       │  (body, amount, source)│      "deal damage to body"
                       │                        │
                       │  1. is_in_group?       │
                       │  2. has HC?            │
                       │  3. hc.take_damage()   │
                       │  4. EventBus.emit      │
                       │  → returns bool        │
                       └───────────┬────────────┘
                                   │
                                   ▼
                  ┌──────────────────────────────────┐
                  │   HealthComponent.take_damage    │
                  │                                  │
                  │   if hp <= 0: return  (dead)     │
                  │   hp = max(0, hp - amount)       │
                  │   hp_changed.emit(hp)            │
                  │   damaged.emit(amount, hp)       │
                  │   if hp == 0 and not _emitted:   │
                  │     died.emit(source)            │
                  └──────────┬───────────────────────┘
                             │
                             ▼
                     ┌───────┴────────┐
                     │                │
                ENEMY death       PLAYER death
                     │                │
                     ▼                ▼
            Enemy._on_died   Player._on_died
              ├ XpGem spawn   ├ stop movement
              ├ EventBus      ├ stop weapons
              │   .enemy_     └ Game.end_run(false)
              │    killed         (ADR-0004 guard)
              └ queue_free

   Player-as-source (contact damage):
   ┌──────────────────────┐
   │ ContactDamageComp.   │  applies damage to Player on overlap
   │ (on enemy body)      │
   └──────────┬───────────┘
              │  hc.take_damage(amount, source)  ← direct call
              ▼                                     (no Damageable;
   Player.HealthComponent                            target is Player,
                                                     not enemies group)
```

---

## Why three weapon paths?

| Weapon kind | Trigger | State held by |
|---|---|---|
| **Cooldown-fire** (Blaster, Spread) | `_physics_process` ticks cooldown → fires projectile → projectile collides with body | `WeaponInstance.cooldown_remaining` + transient projectile node |
| **Continuous zone** (Aura) | `_owned_tick(delta)` decrements a tick timer → checks `get_overlapping_bodies()` | `AuraWeapon._tick_remaining` |
| **Rotating contact** (Orbital) | `_owned_tick(delta)` rotates blades + each blade checks overlap with per-enemy re-hit cooldown | `OrbitalBlade._hit_cooldowns` (dict keyed by enemy `get_instance_id()`) |

All three end up calling `Damageable.try_damage`. Adding a fourth
weapon kind = pick the closest pattern + reuse the helper. Don't
re-implement the "is enemy + has HC + take damage + emit" sequence
inline.

---

## Damageable contract

```
  static func try_damage(body: Node, amount: float, source: Node) -> bool
```

Returns `true` iff damage was actually applied. Returns `false` for:
- `body == null`
- body not in `ENEMY_GROUP` (`"enemies"`)
- body has no `HealthComponent` child

The bool return enables OrbitalBlade's per-enemy cooldown to gate on
success — only register a cooldown entry if the hit landed.

**Important — what try_damage does NOT do:**
- It does NOT check `is_instance_valid(body)` — bodies inside
  `get_overlapping_bodies()` are guaranteed live for the frame (snapshot
  semantics per `class_area2d.rst:597`).
- It does NOT disable `monitoring` on the source — that's the caller's
  responsibility (`BasicProjectile` does this BEFORE try_damage per
  the Area2D pickup pattern; Aura/Orbital don't queue_free so don't
  need it).
- It does NOT enforce per-enemy cooldowns — that's per-weapon logic.

---

## EventBus.damage_dealt

```
  signal damage_dealt(source: Node, target: Node, amount: float)
```

Emitted **once per hit**, **by Damageable** (centralized). Subscribers:
- `Debug._on_damage_dealt` — logs when `log_damage` flag is on (F5).
- Future: `DamageAggregator` (M1.6) — feeds the damage meter.

Player-as-target damage (contact damage from enemies) is **also**
emitted, but by `Player._on_damaged` directly (because the
`Damageable.ENEMY_GROUP` filter excludes Player). The signal shape is
the same — consumers don't care about the route.

---

## Run-lifecycle gates

```
                ┌──────────────────────────────┐
                │ Game.run_state.is_over flag  │
                │ (set by Game.end_run, ADR-04)│
                └──────────────┬───────────────┘
                               │
       Once is_over == true, these stop firing damage:
                               │
       ┌───────────────────────┼───────────────────────┐
       │                       │                       │
       ▼                       ▼                       ▼
  WeaponHost              Player._physics_       Enemy._physics_
  ._physics_process       process                process
  early-outs              halted by              (continues but
  (M1.5 fix in            set_physics_           enemies still
  943935b)                process(false)         move; only damage
                                                  pipeline gated)
```

`Damageable.try_damage` does NOT check `is_over` itself — by the time
weapons stop calling it, the question is moot. Adding the check there
would just hide bugs where a weapon kept ticking past death.

---

## Tests

| Test | Coverage |
|---|---|
| `tests/combat/lookups/damageable.gd` (5) | `try_damage` happy path + 4 negative cases (non-enemy, no HC, null body, emit verification) |
| `tests/combat/weapons/aura/aura_weapon.gd` | Aura damage flow including per-tick damage and damage-upgrade increase |
| `tests/combat/weapons/orbital/orbital_weapon.gd` | Re-hit cooldown prevents double-damage in same window |
| `tests/combat/weapons/weapon_host.gd` | Cone-fan projectile spawn + `is_over` halts ticks |
| `tests/player/player.gd` | Player damage + death + HC re-emit |

---

## Related

- `combat/lookups/damageable.gd` — the helper
- `combat/components/health.gd` — the sink
- `docs/decisions/0004-central-end-run-guard.md` — why `is_over`
  guards weapons but not Damageable directly
- `docs/architecture/lookups-and-helpers.md` — Bundle 1 context
