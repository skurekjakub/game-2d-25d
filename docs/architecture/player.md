# Player

`class Player extends CharacterBody2D`. Singleton-in-scene: there is
always exactly one Player in the active arena, registered in the
`"player"` group.

---

## Scene structure

```
  Player : CharacterBody2D            ← @export speed, contact_slow_multiplier
   ├ HealthComponent : Node           ← @onready _health (private — exposed
   │                                       to outside via EventBus re-emit)
   ├ WeaponHost : Node                ← @onready weapon_host (PUBLIC, typed)
   │   └ AuraWeapon | OrbitalWeapon   ← added at runtime by add_weapon()
   │       (when acquired)
   ├ Visual : Polygon2D               ← @onready _visual
   └ SlowZone : Area2D                ← @onready _slow_zone
                                         (contact-slow detection)
```

---

## Public surface

| Member | Type | Purpose |
|---|---|---|
| `speed` | `@export float = 200.0` | Move speed. Mutated by `move_speed_15` upgrade. |
| `contact_slow_multiplier` | `@export float = 0.5` | Movement penalty while overlapping enemies. |
| `weapon_host` | `@onready WeaponHost` | The player's WeaponHost child. Consumers reach in via this typed field. |

Everything else (`_health`, `_visual`, `_slow_zone`, `_is_dead`,
`_base_color`, `_flash_tween`) is private.

---

## Signal wiring (set up in `_ready`)

```
  HealthComponent.damaged        → Player._on_damaged
                                     ├ EventBus.damage_dealt.emit(null, self, amount)
                                     └ _flash() (Tween modulate)

  HealthComponent.died           → Player._on_died
                                     ├ velocity = ZERO
                                     ├ set_physics_process(false)
                                     ├ weapon_host.set_physics_process(false)
                                     └ Game.end_run(false)   ← ADR-0004

  HealthComponent.hp_changed     → Player._on_hp_changed
                                     └ EventBus.player_health_changed.emit(hp, max_hp)

  HealthComponent.max_hp_changed → Player._on_max_hp_changed
                                     └ EventBus.player_health_changed.emit(hp, max_hp)
```

**Re-emit pattern:** Player is the canonical re-emitter for
`player_health_changed`. HealthComponent emits its own signals (also
used by enemies); Player re-emits as a Player-specific EventBus signal
so the HUD can subscribe to one signal regardless of internal
component restructure.

---

## Lifecycle

```
                                                ┌────────────────────────────┐
                                                │ HealthComponent.died fires │
  Spawn / scene-load                            └──────────────┬─────────────┘
        │                                                      │
        ▼                                                      ▼
  Player._ready                                         Player._on_died
   ├ add_to_group("player")                              ├ _is_dead = true
   ├ _visual.color = Palette.PLAYER_BODY                 ├ velocity = ZERO
   ├ HC signals connected                                ├ set_physics_process(false)
   │                                                      ├ weapon_host
   ▼                                                      │    .set_physics_process(false)
  Per-frame (_physics_process)                            └ Game.end_run(false)
   ├ read Input.get_axis                                          │
   ├ effective_speed = speed                                      ▼
   │  × (slow_zone overlap ? 0.5 : 1.0)                    Game.run_state.is_over = true
   ├ velocity = compute_velocity(input, speed)             EventBus.run_ended.emit(false)
   └ move_and_slide()
```

`set_physics_process(false)` on death pauses movement input AND the
WeaponHost cooldown-fire / `_owned_tick` loops. Scene-owned weapons
(Aura, Orbital) freeze because their `_owned_tick(delta)` is driven
by `WeaponHost._physics_process` — when that stops, they stop.

---

## Why `weapon_host` is public + typed

Before the Bundle 1 SoC refactor: `@onready var _weapon_host: Node`.
Private, Node-typed. Callers (UpgradeRegistry's acquire arms, HUD's
weapon list refresh) reached in via
`player.get_node_or_null("WeaponHost") as WeaponHost` — stringly-typed,
needed a manual cast, repeated in 5 places.

After: `@onready var weapon_host: WeaponHost`. Public, typed. Callers
do `player.weapon_host.add_weapon(data)` directly. The stringly-typed
child name lives in exactly one file: `player.gd`, where it has to
match the scene tree anyway. See `docs/architecture/lookups-and-helpers.md`.

This is the "one idiomatic way" rule (AGENTS.md): when the same child
node is fetched from N callers, expose it as a typed accessor on the
parent that owns it.

---

## Finding the Player from elsewhere

```
  PlayerLocator.find(get_tree()) -> Player
```

Always go through `PlayerLocator`. Never call `get_nodes_in_group("player")`
directly — see `docs/architecture/lookups-and-helpers.md` for why.

---

## Tests

`tests/player/player.gd` — unit tests for damage / death / HP signal
re-emit / contact-slow. Some use the real Player scene via
`auto_free(preload(...))`; the new `TestWorld.player_with_weapons`
scaffold is preferred for tests that need a configurable weapon list.

---

## Related

- `player/player.gd`, `player/player.tscn`
- `combat/components/health.gd` — the HealthComponent child
- `docs/architecture/damage-pipeline.md` — how damage reaches Player
- `docs/decisions/0004-central-end-run-guard.md` — why `_on_died`
  routes through `Game.end_run`, not direct EventBus emit
- `docs/decisions/0005-signal-driven-hud.md` — HUD's re-emit pattern
