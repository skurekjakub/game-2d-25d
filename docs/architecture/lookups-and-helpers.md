# Lookups & helpers (Bundle 1 — pre-M1.6 SoC refactor)

Three classes + one test scaffold introduced in `refactor/pre-m1.6-soc`
to kill 4 duplicated lookup patterns and re-establish strict typing
across the player/weapon/upgrade boundary.

Per project memory `feedback_oop_dry_soc`.

---

## Before / after — the patterns this kills

### 1. "Find the player" (7 sites → 1 typed call)

```
BEFORE (7 sites):                          AFTER (1 site each):

  var players := get_tree()                  var p: Player =
    .get_nodes_in_group("player")              PlayerLocator.find(get_tree())
  if players.is_empty(): return              if p == null: return
  var p: Node = players[0]                   # p is already typed
  # caller now has Node, must cast
```

Sites collapsed: `world/spawner_director.gd:121`,
`ui/upgrade_picker.gd:28,47`, `ui/hud.gd:80`, `combat/enemies/enemy.gd:21`,
`combat/upgrades/upgrade_registry.gd:51`.

`PlayerLocator.find(tree) -> Player` casts the group lookup result to
`Player` exactly once, in one place. Callers receive a typed value
they can either use directly or null-check.

### 2. "Get the weapon host" (5 sites → 1 typed field)

```
BEFORE (5 inline):                         AFTER:

  var host := player                         player.weapon_host
    .get_node_or_null("WeaponHost")
    as WeaponHost
  if host == null: return
  host.add_weapon(...)
```

This was originally going to be a `WeaponHostLocator.of(player)` static.
Rubber-duk verdict: that's an over-abstraction hiding a stringly-typed
child lookup. The fix is to promote `Player._weapon_host: Node` (private,
weakly typed) to `Player.weapon_host: WeaponHost` (public, typed). The
caller already has a `Player`; ask the Player.

All `apply()` arms in `UpgradeRegistry` dropped their inline
`get_node_or_null` and now call `player.weapon_host.add_weapon(...)`
directly. Function signatures retyped from `Node` to `Player` through
the whole chain (`apply`, `pick_random_3_for`, `_available_for_picker`,
`_owned_weapon_ids_for`).

### 3. "Apply damage to a body" (3 weapons × 5 lines → 1 helper)

```
BEFORE (in every weapon):                  AFTER:

  if not body.is_in_group("enemies"):        Damageable.try_damage(body, dmg, self)
    return
  var hc := body
    .get_node_or_null("HealthComponent")
    as HealthComponent
  if hc == null: return
  hc.take_damage(dmg, self)
  EventBus.damage_dealt.emit(self, body, dmg)
```

`Damageable.try_damage(body, amount, source) -> bool`:
- Centralizes the group check, HC lookup, take_damage, and event emit.
- Returns true iff damage was actually applied (enabling OrbitalBlade's
  per-enemy cooldown to gate on success).
- Defines `Damageable.ENEMY_GROUP: StringName = &"enemies"` — the
  magic string "enemies" lives in exactly one file.

### 4. "Build a test player" (5 tests × ad-hoc → 1 scaffold)

```
BEFORE (in every test that needs it):      AFTER:

  var stub := Node2D.new()                   var p: Player = await
  stub.add_to_group("player")                  TestWorld.player_with_weapons(
  add_child(auto_free(stub))                     self, [&"aura", &"orbital"]
  var host := WeaponHost.new()                 )
  host.name = "WeaponHost"
  stub.add_child(host)
  for wid in ids:
    var d := WeaponData.new()
    d.id = wid
    host.weapons.append(
      WeaponInstance.new(d))
```

`TestWorld.player_with_weapons(case, weapon_ids) -> Player`:
- Instantiates the **real** Player scene (was bare `Node2D` stub →
  caused `PlayerLocator.find` casts to fail silently).
- Disables `WeaponHost._physics_process` so async tests don't trip on
  `Game.run_state` during `await get_tree().process_frame`.
- Returns a typed `Player`, so test bodies use `player.weapon_host`
  directly.

---

## Class graph

```
                ┌─────────────────────────────────────────┐
                │             Player (typed)              │
                │                                         │
                │   @onready var weapon_host: WeaponHost  │  ← PUBLIC, typed
                │   @onready var _health: HealthComponent │     (was private Node)
                │   @export var speed: float              │
                │                                         │
                └──────▲──────────────────────┬───────────┘
                       │ find(tree)           │ player.weapon_host
                       │                      │ player.speed
        ┌──────────────┴───────────┐   ┌──────┴─────────────────────┐
        │      PlayerLocator       │   │     consumers              │
        │                          │   │                            │
        │  static find(tree)       │   │   UpgradeRegistry.apply    │
        │    -> Player             │   │   UpgradeRegistry.gating   │
        │                          │   │   HUD.refresh_weapon_list  │
        │  ONE place that casts    │   │   Enemy._ready (movement)  │
        │  the group lookup to     │   │   SpawnerDirector          │
        │  Player.                 │   │     (player_position)      │
        └──────────────────────────┘   └────────────────────────────┘


                ┌──────────────────────────────────────────────┐
                │             Damageable (static)              │
                │                                              │
                │   const ENEMY_GROUP: StringName              │  ← magic string
                │                                              │     lives here
                │   static try_damage(body, amount, source)    │
                │     -> bool                                  │
                │                                              │
                │   ONE place that bundles:                    │
                │     is_in_group("enemies")                   │
                │     get_node_or_null("HealthComponent")      │
                │     hc.take_damage(amount, source)           │
                │     EventBus.damage_dealt.emit(...)          │
                └──────────────────────────────────────────────┘
                                      ▲
                       ┌──────────────┼──────────────┐
                       │              │              │
              BasicProjectile     AuraWeapon    OrbitalBlade
              (one call)          (one call)    (one call, used as gate
                                                 for cooldown dict)


        ┌──────────────────────────────────────────────────┐
        │           TestWorld (static, test-only)          │
        │                                                  │
        │   static player_with_weapons(case, weapon_ids)   │
        │     -> Player                                    │
        │                                                  │
        │   Instantiates REAL Player scene.                │
        │   Disables host._physics_process for async.      │
        │   Returns typed Player.                          │
        └──────────────────────────────────────────────────┘
```

---

## Why this matters

| Problem the old code had | What the new helpers prevent |
|---|---|
| Same 4-line player lookup duplicated 7 times — change one, the others rot. | Single call. Change once. |
| `Node` returned from group lookup, callers manually `as Player` — silent failures when test stubs aren't real Players. | `PlayerLocator.find` returns `Player` directly. Misuse fails at parse time, not runtime. |
| `UpgradeRegistry.apply()` took `player: Node` — could be called with anything, dynamic `player.set("speed", ...)` masked typing errors. | `apply(player: Player)` — `player.speed *= 1.15` is type-checked. |
| 3 weapons each implemented "filter to enemies, look up HC, deal damage, emit signal" — easy to forget the emit (M1.5's Aura/Orbital initially did!). | `Damageable.try_damage` always emits. New weapons can't skip it. |
| Magic string `"enemies"` scattered across 4 files. Renaming the group is a search-and-replace risk. | `Damageable.ENEMY_GROUP` is the one source. |
| Test stubs (bare `Node2D` in player group, `class _PlayerStub: extends Node`) drift from the real Player. New Player @exports silently miss in stubs. | `TestWorld.player_with_weapons` instantiates the actual scene. Drift impossible. |

---

## Migration touchpoints

When you write new code that needs any of these:

| Need | Use |
|---|---|
| The Player node | `PlayerLocator.find(get_tree())` |
| Player's weapon host | `player.weapon_host` (just access the field) |
| Apply weapon damage to a body | `Damageable.try_damage(body, amount, self)` |
| Build a player in a test | `await TestWorld.player_with_weapons(self, [&"blaster", &"aura"])` |
| The "enemies" group name | `Damageable.ENEMY_GROUP` (avoid the bare string) |

**Don't reach into** `player.get_node_or_null("WeaponHost")` — use the
typed field. Don't write `body.is_in_group("enemies")` — use
`Damageable.ENEMY_GROUP`. Don't construct test-only player stubs — use
the scaffold. New code that re-introduces these patterns will be flagged
in review.

---

## Related

- `combat/lookups/player_locator.gd`
- `combat/lookups/damageable.gd`
- `tests/scaffolds/world.gd`
- `player/player.gd:8` — the public `weapon_host` field
- `docs/plans/2026-05-17-pre-milestone-1.6-soc-refactor.md` — full plan
  with revisions table from duck critique
- `feedback_oop_dry_soc` memory — the *why*
