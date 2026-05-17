# Pre-M1.6 SoC/DRY Refactor Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`).

**Goal:** Pay down DRY + SoC debt accumulated through M1.5 so M1.6
(damage meter) lands on a cleaner base. Per project memory
`feedback_oop_dry_soc`.

**Architecture:** Two-bundle refactor.
1. **DRY bundle** — `PlayerLocator.find(tree) -> Player` (typed);
   promote `Player.weapon_host: WeaponHost` to public typed field
   (replaces a separate `WeaponHostLocator` — collapses two duck
   findings); add `Damageable.try_damage` helper; add `TestWorld`
   scaffold that calls `set_physics_process(false)` on the host so
   async tests don't trip on `Game.run_state`.
2. **UpgradeEffect Strategy** — split `UpgradeRegistry.apply()`'s
   12-arm match block into a Strategy pattern. Each `UpgradeData.tres`
   carries an `effect: UpgradeEffect` sub-resource; `apply()` becomes
   `upgrade.effect.execute(player)`. **Effect classes are typed per
   stat** — `MaxHpBumpEffect`, `SpeedMultiplierEffect`,
   `HealToFullEffect`, `WeaponAcquireEffect`, `NoopEffect`. Avoids
   dynamic `player.get(field)` reflection (would violate the
   static-typing rule).

**Bundles ship in order.** Bundle 2's `WeaponAcquireEffect` consumes
Bundle 1's `Player.weapon_host`, so the bundles are NOT parallelizable
despite the "two bundle" framing.

**Branch:** `refactor/pre-m1.6-soc` off `milestone-1.5`.

**Execution preference:** rubber-duk after each bundle (2 checkpoints
total). Total budget: ~5.5 h, ~9 new tests, 155 → ~164 suite.

**Required project memories:**
- `feedback_no_archaeology_comments` — refactor diffs MUST be clean.
- `feedback_oop_dry_soc` — the *why* of this whole effort.
- `godot_uid_handwritten_tres` — bundle 2 touches 14 .tres files.
- `godot_typed_resource_array_path_fragility` — bundle 2 introduces a
  new `UpgradeEffect` Resource hierarchy; serialize by `class_name` or
  script-path matters.

## Revisions (post-duck-critique — supersede in-task code where they conflict)

| Task | What changes | Why |
|---|---|---|
| Task 1 | `PlayerLocator.find` returns `Player`, not `Node`. Tests use the real `Player` type via `TestWorld.player_with_weapons` (Task 4) — no stub. | Static-typing rule (AGENTS.md + `feedback_oop_dry_soc`). Old plan widened return type to accommodate test stubs — circular. |
| Task 2 | **Drop the `WeaponHostLocator` class entirely.** Instead, edit `player/player.gd`: change `@onready var _weapon_host: Node = $WeaponHost` to `@onready var weapon_host: WeaponHost = $WeaponHost` (public, typed). 5 call sites in `upgrade_registry.gd` (lines 79, 95, 149, 157, 165) become `(PlayerLocator.find(get_tree()) as Player).weapon_host` or `player.weapon_host` where `player: Player` is already in scope. | Per "one idiomatic way" (AGENTS.md): typed public child accessor on the parent that owns it beats a separate locator class hiding stringly-typed `get_node_or_null("WeaponHost")`. |
| Task 3 | OrbitalBlade's pre-Damageable `is_in_group("enemies")` check stays (needed to gate the cooldown dict). Use `Damageable.ENEMY_GROUP` const so the magic string is centralized. | Group-check protects cooldown-dict pollution; `try_damage` returns false anyway but the gate is cheaper. |
| Task 5 | **No `StatBumpEffect`.** Instead: `MaxHpBumpEffect(amount: float)` calls `hc.set_max_hp + set_hp`; `SpeedMultiplierEffect(multiplier: float)` calls `player.speed *= multiplier` with `player: Player` typed. Each effect is single-purpose, no `player.get(field)` reflection. | Static-typing rule. The original `StatBumpEffect{field, multiplier, additive}` had a stringly-typed dispatch and a `max_hp` special case that broke the abstraction. |
| Task 7 | Extend `_make_upgrade(id, weight, effect)` (third optional arg). Rewrite 5 existing apply-tests (`test_apply_max_hp_20_*`, `test_apply_move_speed_15_*`, `test_apply_heal_to_full_*`, `test_apply_acquire_aura_*`, `test_apply_acquire_orbital_*`) to pass the right effect instance. | Without this fix, post-Task-7 commit lands with 5 RED tests (the old plan claimed they'd pass unchanged — wrong). |
| Self-review grep | Use: `grep -rn 'get_nodes_in_group("player")' --include="*.gd" combat/ ui/ world/ player/` (balanced quotes). | Old grep had unbalanced quotes; would return 0 hits and falsely confirm migration. |

---

## Risk register

| Risk | Mitigation |
|---|---|
| Existing `_make_upgrade(...)` apply-tests have `effect = null` post-Task 7 → 5 tests break (max_hp_20, move_speed_15, heal_to_full, 2 acquires) | Task 7 explicitly extends `_make_upgrade` to accept an optional `effect: UpgradeEffect` param, then rewrites the 5 apply-tests with the right effect. Inline test code spelled out in Task 7. |
| TestWorld scaffold's bare `Node2D` player + WeaponHost child ticks `_physics_process` and reads `Game.run_state` during async tests | Scaffold calls `host.set_physics_process(false)` before returning; documented in helper docstring. |
| Effect script paths (`combat/upgrades/effects/*.gd`) are load-bearing for 14 `.tres` ExtResource refs; rename = silent breakage | Post-refactor: directory layout is **frozen**. Any rename requires grep-replace across `combat/upgrades/data/*.tres`. Self-review step documents this. |
| 14 `.tres` hand-edits at Task 6 = high typo blast radius | `test_every_upgrade_tres_has_effect` catches missing effects; manual read-back of one `.tres` after `--headless --import` verifies editor normalization. |
| Re-tagging `milestone-1.5` to include refactor would be a destructive op (tag already pushed) | Tag refactor commits as `milestone-1.5.1` instead; merge decision deferred to Task 8 with user. |
| `Player._on_damaged` also emits `damage_dealt(null, self, amount)` — NOT migrated by Damageable | Out of scope: player-receive damage is a different domain (enemy → player, no enemies group filter). Damageable.try_damage covers weapon → enemy only. Noted in Task 3. |

---

## File Structure

**Bundle 1 (DRY):**
- Create: `combat/lookups/player_locator.gd` — `static find(tree) -> Player` (typed return — caller never casts).
- Modify: `player/player.gd` — promote `_weapon_host: Node` → `weapon_host: WeaponHost` (public, typed). Replaces a separate `WeaponHostLocator` helper.
- Create: `combat/lookups/damageable.gd` — `static try_damage(body, amount, source) -> bool` + `ENEMY_GROUP` const.
- Create: `tests/scaffolds/test_world.gd` — `static player_with_weapons(case, ids)`; disables `_physics_process` on the spawned host.
- Modify: 7 source files use the helpers.

**Bundle 2 (UpgradeEffect):**
- Create: `combat/upgrades/effects/upgrade_effect.gd` — abstract base (no-op default).
- Create: `combat/upgrades/effects/max_hp_bump_effect.gd` — `@export var amount: float`.
- Create: `combat/upgrades/effects/speed_multiplier_effect.gd` — `@export var multiplier: float`.
- Create: `combat/upgrades/effects/heal_to_full_effect.gd`
- Create: `combat/upgrades/effects/weapon_acquire_effect.gd` — `@export var weapon_data: WeaponData`.
- Create: `combat/upgrades/effects/noop_effect.gd` — concrete type for inspector resource picker.
- Modify: `combat/upgrades/upgrade_data.gd` — `@export var effect: UpgradeEffect`
- Modify: `combat/upgrades/upgrade_registry.gd` — `apply()` collapses to one delegate.
- Modify: all 14 upgrade `.tres` files — attach the right `effect` sub-resource.
- Tests: per-effect + registry-still-applies tests.

---

## Bundle 1 — DRY lookups

### Task 1: PlayerLocator

**Files:** `combat/lookups/player_locator.gd`, `tests/test_player_locator.gd`,
7 call-site updates.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/test_player_locator.gd
extends GdUnitTestSuite


func test_returns_first_player_in_group() -> void:
    var p := Node2D.new()
    p.add_to_group("player")
    add_child(auto_free(p))
    assert_object(PlayerLocator.find(get_tree())).is_same(p)


func test_returns_null_when_no_player() -> void:
    assert_object(PlayerLocator.find(get_tree())).is_null()
```

- [ ] **Step 2: Implement**

```gdscript
# combat/lookups/player_locator.gd
class_name PlayerLocator
extends RefCounted

static func find(tree: SceneTree) -> Node:
    if tree == null:
        return null
    var players: Array = tree.get_nodes_in_group("player")
    if players.is_empty():
        return null
    return players[0]
```

- [ ] **Step 3: Replace all 7 call sites**

| File | Line | Replace |
|---|---|---|
| `world/spawner_director.gd` | 121 | `PlayerLocator.find(get_tree())` |
| `ui/upgrade_picker.gd` | 28, 47 | same |
| `ui/hud.gd` | 80 | same |
| `combat/enemies/enemy.gd` | 21 | same |
| `combat/upgrades/upgrade_registry.gd` | 51 | same (within `pick_random_3`) |

After each replace, delete the local `var players :=` / `var player := ... if ... else null` lines that became redundant. Re-run scoped test then `./tests/run.sh`.

- [ ] **Step 4: Commit**

```bash
git add combat/lookups/player_locator.gd tests/test_player_locator.gd \
        world/spawner_director.gd ui/upgrade_picker.gd ui/hud.gd \
        combat/enemies/enemy.gd combat/upgrades/upgrade_registry.gd
git commit -m "refactor(lookups): extract PlayerLocator (DRY)"
```

---

### Task 2: WeaponHostLocator

**Files:** `combat/lookups/weapon_host_locator.gd`,
`tests/test_weapon_host_locator.gd`, 5 call-site updates (all in
`upgrade_registry.gd`).

- [ ] **Step 1: Write the failing test**

```gdscript
extends GdUnitTestSuite


func test_returns_host_when_present() -> void:
    var player := Node2D.new()
    add_child(auto_free(player))
    var host := WeaponHost.new()
    host.name = "WeaponHost"
    player.add_child(host)
    assert_object(WeaponHostLocator.of(player)).is_same(host)


func test_returns_null_when_player_null() -> void:
    assert_object(WeaponHostLocator.of(null)).is_null()


func test_returns_null_when_no_host_child() -> void:
    var player := Node2D.new()
    add_child(auto_free(player))
    assert_object(WeaponHostLocator.of(player)).is_null()
```

- [ ] **Step 2: Implement**

```gdscript
# combat/lookups/weapon_host_locator.gd
class_name WeaponHostLocator
extends RefCounted

static func of(player: Node) -> WeaponHost:
    if player == null:
        return null
    return player.get_node_or_null("WeaponHost") as WeaponHost
```

- [ ] **Step 3: Replace in upgrade_registry.gd**

Five `var host := player.get_node_or_null("WeaponHost") as WeaponHost` lines (95, 149, 157, 165, plus `_owned_weapon_ids_for` at 79) become `var host := WeaponHostLocator.of(player)`.

- [ ] **Step 4: Run + commit**

```bash
./tests/run.sh
git add combat/lookups/weapon_host_locator.gd \
        tests/test_weapon_host_locator.gd \
        combat/upgrades/upgrade_registry.gd
git commit -m "refactor(lookups): extract WeaponHostLocator (DRY)"
```

---

### Task 3: Damageable.try_damage helper

**Files:** `combat/lookups/damageable.gd`,
`tests/test_damageable.gd`, 3 weapon updates.

Single helper that bundles: `is_in_group("enemies")` check + HC lookup +
`take_damage` call + `EventBus.damage_dealt.emit`. Returns `true` if
damage was applied. Used by `BasicProjectile`, `AuraWeapon`,
`OrbitalBlade`.

- [ ] **Step 1: Write the failing test**

```gdscript
extends GdUnitTestSuite


func test_try_damage_applies_to_enemy_and_emits() -> void:
    var enemy: Node2D = auto_free(load("res://combat/enemies/enemy.tscn").instantiate())
    add_child(enemy)
    await get_tree().process_frame
    var source := Node.new()
    add_child(auto_free(source))
    var hc: HealthComponent = enemy.get_node("HealthComponent")
    var before: float = hc.hp
    var hit: bool = Damageable.try_damage(enemy, 7.0, source)
    assert_bool(hit).is_true()
    assert_float(hc.hp).is_equal_approx(before - 7.0, 0.001)


func test_try_damage_ignores_non_enemy() -> void:
    var noise := Node2D.new()
    add_child(auto_free(noise))
    var source := Node.new()
    add_child(auto_free(source))
    assert_bool(Damageable.try_damage(noise, 7.0, source)).is_false()


func test_try_damage_ignores_body_without_hc() -> void:
    var stub := Node2D.new()
    stub.add_to_group("enemies")
    add_child(auto_free(stub))
    var source := Node.new()
    add_child(auto_free(source))
    assert_bool(Damageable.try_damage(stub, 7.0, source)).is_false()
```

- [ ] **Step 2: Implement**

```gdscript
# combat/lookups/damageable.gd
class_name Damageable
extends RefCounted

const ENEMY_GROUP: StringName = &"enemies"


static func try_damage(body: Node, amount: float, source: Node) -> bool:
    if body == null or not body.is_in_group(ENEMY_GROUP):
        return false
    var hc := body.get_node_or_null("HealthComponent") as HealthComponent
    if hc == null:
        return false
    hc.take_damage(amount, source)
    EventBus.damage_dealt.emit(source, body, amount)
    return true
```

- [ ] **Step 3: Replace in 3 weapons**

`combat/weapons/projectiles/basic_projectile.gd`:

```gdscript
func _on_body_entered(body: Node2D) -> void:
    set_deferred("monitoring", false)
    Damageable.try_damage(body, damage, self)
    queue_free()
```

(Drops the manual `is_in_group` + HC lookup + emit — 5 lines collapse to 1. Keeps the `monitoring` deferred + queue_free.)

`combat/weapons/aura/aura_weapon.gd`:

```gdscript
func _apply_tick_damage() -> void:
    if instance == null:
        return
    var dmg: float = instance.effective_damage()
    for body: Node2D in get_overlapping_bodies():
        Damageable.try_damage(body, dmg, self)
```

`combat/weapons/orbital/orbital_blade.gd` (preserve the cooldown table):

```gdscript
func owned_tick(delta: float) -> void:
    for key in _hit_cooldowns.keys():
        _hit_cooldowns[key] -= delta
        if _hit_cooldowns[key] <= 0.0:
            _hit_cooldowns.erase(key)
    for body in get_overlapping_bodies():
        if not body.is_in_group(Damageable.ENEMY_GROUP):
            continue
        var key: int = body.get_instance_id()
        if key in _hit_cooldowns:
            continue
        if Damageable.try_damage(body, damage, self):
            _hit_cooldowns[key] = RE_HIT_COOLDOWN_SEC
```

(OrbitalBlade still needs the early `is_in_group` so it doesn't insert non-enemies into the cooldown dict. `Damageable.ENEMY_GROUP` keeps the group name centralized.)

- [ ] **Step 4: Run full suite + commit**

```bash
./tests/run.sh
git add combat/lookups/damageable.gd tests/test_damageable.gd \
        combat/weapons/projectiles/basic_projectile.gd \
        combat/weapons/aura/aura_weapon.gd \
        combat/weapons/orbital/orbital_blade.gd
git commit -m "refactor(weapons): collapse damage application via Damageable.try_damage"
```

---

### Task 4: Test world scaffold

**Files:** `tests/scaffolds/test_world.gd`, ~5 test updates.

- [ ] **Step 1: Implement scaffold**

```gdscript
# tests/scaffolds/test_world.gd
class_name TestWorld
extends RefCounted


# Returns the player Node2D (in the "player" group) with a WeaponHost child
# pre-populated with WeaponInstances built from the given ids.
static func player_with_weapons(
    case: GdUnitTestSuite, weapon_ids: Array[StringName]
) -> Node2D:
    var player := Node2D.new()
    player.add_to_group("player")
    case.add_child(case.auto_free(player))
    var host := WeaponHost.new()
    host.name = "WeaponHost"
    player.add_child(host)
    for wid: StringName in weapon_ids:
        var d := WeaponData.new()
        d.id = wid
        host.weapons.append(WeaponInstance.new(d))
    return player
```

- [ ] **Step 2: Replace inline scaffold blocks**

Tests with inline player+host build-out:
- `tests/test_upgrade_registry.gd` `_player_with_weapons` (delete; use scaffold)
- `tests/test_hud.gd` `test_hud_weapon_list_scales_to_owned_weapons` (replace inline block)
- Any future test in M1.6 that needs the same shape.

(Don't touch tests that have specific construction needs — only replace the literal duplicates.)

- [ ] **Step 3: Run + commit**

```bash
./tests/run.sh
git add tests/scaffolds/ tests/test_upgrade_registry.gd tests/test_hud.gd
git commit -m "refactor(tests): extract TestWorld scaffold for player+host"
```

**→ Rubber-duk checkpoint #1** (Bundle 1 closed — verify all 7 D1 sites
gone, all 3 D2/D3 weapons use Damageable, no stragglers).

---

## Bundle 2 — UpgradeEffect Strategy

### Task 5: UpgradeEffect base + leaf classes

**Files:** `combat/upgrades/effects/upgrade_effect.gd` + 4 concrete subs,
tests for each.

- [ ] **Step 1: Implement the base**

```gdscript
# combat/upgrades/effects/upgrade_effect.gd
class_name UpgradeEffect
extends Resource

# Subclasses override. Default: no-op (covers mechanical upgrades read
# lazily at fire time, e.g., blaster_damage_25).
func execute(_player: Node) -> void:
    pass
```

- [ ] **Step 2: Implement the 4 concrete types**

```gdscript
# combat/upgrades/effects/stat_bump_effect.gd
class_name StatBumpEffect
extends UpgradeEffect

@export var field: StringName       # "speed", "max_hp" (via HC), etc.
@export var multiplier: float = 1.0 # 0.0 means use additive instead
@export var additive: float = 0.0


func execute(player: Node) -> void:
    if player == null:
        return
    if field == &"max_hp":
        var hc := player.get_node_or_null("HealthComponent") as HealthComponent
        if hc == null:
            return
        hc.set_max_hp(hc.max_hp + additive)
        hc.set_hp(hc.max_hp)
        return
    if field == &"" or not (field in player):
        return
    var current: float = float(player.get(field))
    if multiplier != 1.0:
        player.set(field, current * multiplier)
    elif additive != 0.0:
        player.set(field, current + additive)
```

```gdscript
# combat/upgrades/effects/heal_to_full_effect.gd
class_name HealToFullEffect
extends UpgradeEffect


func execute(player: Node) -> void:
    if player == null:
        return
    var hc := player.get_node_or_null("HealthComponent") as HealthComponent
    if hc != null:
        hc.set_hp(hc.max_hp)
```

```gdscript
# combat/upgrades/effects/weapon_acquire_effect.gd
class_name WeaponAcquireEffect
extends UpgradeEffect

@export var weapon_data: WeaponData


func execute(player: Node) -> void:
    var host := WeaponHostLocator.of(player)
    if host != null and weapon_data != null:
        host.add_weapon(weapon_data)
```

(WeaponAcquireEffect references `WeaponData` directly as an
`ExtResource`, not a string path — kills the magic-path consts in
UpgradeRegistry.)

```gdscript
# combat/upgrades/effects/noop_effect.gd
class_name NoopEffect
extends UpgradeEffect
# Inherits the base's no-op execute(). Exists as a concrete type so the
# .tres file can declare "this upgrade is read lazily at fire time".
```

- [ ] **Step 3: Write per-effect tests**

`tests/test_upgrade_effects.gd` — one suite, 5 tests (one per effect +
base default).

- [ ] **Step 4: Run + commit**

```bash
./tests/run.sh tests/test_upgrade_effects.gd
git add combat/upgrades/effects/ tests/test_upgrade_effects.gd
git commit -m "feat(upgrades): UpgradeEffect Strategy types (stat/heal/acquire/noop)"
```

---

### Task 6: UpgradeData carries `effect`

**Files:** `combat/upgrades/upgrade_data.gd`, all 14 `.tres` files,
`tests/test_upgrade_data.gd`.

- [ ] **Step 1: Add `effect` export**

```gdscript
# combat/upgrades/upgrade_data.gd
class_name UpgradeData
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var weight: float = 1.0
@export var effect: UpgradeEffect
```

- [ ] **Step 2: Edit each `.tres` to attach the right effect sub-resource**

Per-tres mapping (all hand-edited per project convention — no UIDs added):

| .tres | Effect type | Effect fields |
|---|---|---|
| `max_hp_20.tres` | StatBumpEffect | field=&"max_hp", additive=20.0 |
| `move_speed_15.tres` | StatBumpEffect | field=&"speed", multiplier=1.15 |
| `heal_to_full.tres` | HealToFullEffect | (none) |
| `blaster_*.tres` (2) | NoopEffect | (none) |
| `spread_*.tres` (2) | NoopEffect | (none) |
| `aura_*.tres` (2) | NoopEffect | (none) |
| `orbital_*.tres` (2) | NoopEffect | (none) |
| `acquire_spread.tres` | WeaponAcquireEffect | weapon_data = spread.tres |
| `acquire_aura.tres` | WeaponAcquireEffect | weapon_data = aura.tres |
| `acquire_orbital.tres` | WeaponAcquireEffect | weapon_data = orbital.tres |

Use sub-resource syntax (the effect is embedded in the upgrade's `.tres`,
not its own file — keeps the upgrade pool self-contained). Example:

```
[gd_resource type="Resource" script_class="UpgradeData" load_steps=3 format=3]

[ext_resource type="Script" path="res://combat/upgrades/upgrade_data.gd" id="1_upgrade_data"]
[ext_resource type="Script" path="res://combat/upgrades/effects/stat_bump_effect.gd" id="2_effect"]

[sub_resource type="Resource" script_class="StatBumpEffect" id="StatBumpEffect_1"]
script = ExtResource("2_effect")
field = &"max_hp"
additive = 20.0

[resource]
script = ExtResource("1_upgrade_data")
id = &"max_hp_20"
display_name = "+20 Max HP"
description = "Permanent +20 HP and refill."
weight = 1.0
effect = SubResource("StatBumpEffect_1")
```

- [ ] **Step 3: Add a test that every .tres has a non-null effect**

```gdscript
# tests/test_upgrade_data.gd
func test_every_upgrade_tres_has_effect() -> void:
    var dir: String = "res://combat/upgrades/data"
    for entry in ResourceLoader.list_directory(dir):
        if not entry.ends_with(".tres"):
            continue
        var u := load("%s/%s" % [dir, entry]) as UpgradeData
        assert_object(u.effect).is_not_null()
```

- [ ] **Step 4: Re-import + run + commit**

```bash
godot --headless --import --path .
./tests/run.sh
git add combat/upgrades/upgrade_data.gd combat/upgrades/data/ \
        tests/test_upgrade_data.gd
git commit -m "feat(upgrades): UpgradeData carries effect sub-resource"
```

---

### Task 7: UpgradeRegistry.apply collapses to delegation

**Files:** `combat/upgrades/upgrade_registry.gd`,
`tests/test_upgrade_registry.gd`.

- [ ] **Step 1: Rewrite `apply()`**

```gdscript
func apply(upgrade: UpgradeData, player: Node) -> void:
    if upgrade == null or player == null:
        return
    if upgrade.effect == null:
        push_warning("UpgradeRegistry: upgrade %s has no effect" % upgrade.id)
        return
    upgrade.effect.execute(player)
```

Delete:
- `MAX_HP_BONUS`, `MOVE_SPEED_MULTIPLIER`, `SPREAD_DATA_PATH`,
  `AURA_DATA_PATH`, `ORBITAL_DATA_PATH` constants.
- The 12-arm match block.
- The unused `hc :=` line at the top of the old apply().

Keep all gating logic untouched.

- [ ] **Step 2: Update tests**

The existing `test_apply_*` tests in `tests/test_upgrade_registry.gd`
should pass unchanged — they assert observable behavior on the player,
not the internals of `apply`. Run them and confirm.

- [ ] **Step 3: Run full suite + commit**

```bash
./tests/run.sh
git add combat/upgrades/upgrade_registry.gd
git commit -m "refactor(upgrades): apply() collapses to effect.execute(player)"
```

**→ Rubber-duk checkpoint #2** (Bundle 2 closed — verify the 12-arm
match block is gone, all 14 .tres have effect sub-resources, gating
unaffected, no behavior regressions).

---

## Task 8: Merge to main milestone-1.5 branch (or stay separate)

**Files:** none (procedural; user decision).

- [ ] **Step 1: Run full suite + headless boot**

```bash
./tests/run.sh
godot --headless --quit --path .
```

- [ ] **Step 2: Decide merge target with user**

Options:
- Fast-forward into `feature/milestone-1.5-weapon-variety` so the
  M1.5 tag captures the cleanup.
- Land on `master` directly as a separate `refactor/` commit
  bundle, then start M1.6 off that.

Default: fast-forward into the M1.5 feature branch + re-tag
`milestone-1.5` to include the refactor.

---

## Self-Review

After Task 7:

1. **Spec coverage:** every D1-D4 and S1 from the scan note has a task?
2. **No leftovers:** `grep -r 'get_tree().get_nodes_in_group..player.."` returns 0 in source/. `grep -r 'get_node_or_null..HealthComponent..'` returns 0 in `combat/weapons/`.
3. **No archaeology comments:** scan diff.
4. **SoC kept:** PlayerLocator/WeaponHostLocator/Damageable have ONE job each. No effect type talks to other effect types.
5. **Test count delta:** ~+9 tests (4 from Bundle 1, 5 from Bundle 2). Suite goes ~155 → ~164.

---

## Execution Handoff

Subagent-Driven via `godot-implementer`. Bundles 1 and 2 are independent
enough that you could parallelize the duck checkpoints but tasks within
a bundle are sequential. Rubber-duk after Bundle 1 and Bundle 2.
