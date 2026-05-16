# Vampire Survivors Clone — Design

**Status:** Draft, awaiting user approval.
**Author:** Brainstorming session, 2026-05-16.
**Scope:** Phase 1 (loop-only arcade game) and Phase 2 (meta-progression layer) of the first game built in this project.

---

## 1. Meta

### Elevator pitch

A bounded-arena Vampire Survivors clone in top-down 2.5D. Runs last 25-30 minutes and are punctuated by major boss waves every ~5 minutes. Pure auto-aim — the player only moves, weapons fire themselves. 15-20 weapons total, permanent stat upgrades and weapon unlocks between runs.

### Pillars

1. **Build over reflex.** Skill is choosing what to level up and where to stand, not aiming.
2. **Readable chaos.** Hundreds of entities on screen, but the player can always tell what to do next.
3. **Tight runs.** 25-30 min, never wasted; boss waves provide tension peaks.
4. **Data, not code, for content.** Weapons and enemies are designer-tunable `.tres` files; adding a weapon means editing a resource, not writing code.

### Target experience (MDA aesthetics)

- **Sensation:** visual overwhelm that gradually becomes legible.
- **Challenge:** optimization puzzle — which weapon to level up, when to take a passive vs a weapon, when to flee vs commit.
- **Submission:** meditative flow state of constant motion + automatic firing.
- **Discovery:** each run reveals new weapon combinations and synergies.

### Locked decisions

| | |
|---|---|
| Goal | Mini-roguelite (~5-10 h playtime, real meta-progression) |
| Perspective | Top-down + Y-sort 2.5D (Hades-style) |
| Run shape | Hybrid continuous + boss waves, ~25-30 min |
| Aiming | Pure auto-aim, all weapons |
| Theme | Deferred; prototype with shapes |
| Meta-progression | Stat upgrades + weapon unlocks (one character, no roster) |
| Map | Bounded arena per run |
| Approach | Loop-first, meta-deferred (Phase 1 = arcade, Phase 2 = meta) |

---

## 2. Architecture overview

```
                       ┌───────────────────┐
                       │   Game (autoload) │     global game state, current run
                       └─────────┬─────────┘
                                 │ owns
              ┌──────────────────┼──────────────────┐
              │                  │                  │
         ┌────▼────┐        ┌────▼────┐        ┌────▼────┐
         │  Arena  │        │  Hud    │        │ EventBus│
         │ (scene) │        │ (scene) │        │(autoload)│
         └────┬────┘        └─────────┘        └────▲────┘
              │ contains                            │
   ┌──────────┼──────────┬──────────┐               │
   │          │          │          │               │
┌──▼───┐  ┌───▼───┐  ┌───▼────┐ ┌───▼─────┐         │  signals
│Player│  │Enemies│  │Weapons │ │ Spawner │─────────┘  (damage_dealt,
└──┬───┘  └───┬───┘  └────────┘ │ Director│            xp_gained,
   │          │                 └─────────┘            enemy_killed,
   └──signals─┴─────────────────────────────► EventBus boss_spawned, ...)
```

**Layers, from outer to inner:**

- **`Game` (autoload)** — single global. Holds current run state (HP, XP, level, time elapsed, gold-for-Phase-2). Emits signals on state change. Webdev analogy: a Redux/Zustand store.
- **`EventBus` (autoload)** — pure signal hub. Systems emit gameplay events without knowing listeners. Webdev analogy: pub-sub / `window.dispatchEvent`.
- **`Arena` (scene)** — the playable level. Tilemap, player, enemy container, weapon nodes, `SpawnerDirector`. One arena per run for Phase 1.
- **`Hud` (scene)** — overlay UI driven by signals.
- **`SpawnerDirector` (Node)** — the one place that decides when/where/what to spawn. Reads a `SpawnSchedule` resource.
- **`Player`, `Enemy`, `Weapon`** — `CharacterBody2D` / `Node2D` scenes composed of small behavior components.

**Why this shape:**

- Adding a new weapon = create one `.tres` file. No code change.
- Adding a new system (e.g., audio) = subscribe to EventBus. No edits to existing systems.
- Phase 2 meta-progression bolts on cleanly: a `MetaState` autoload + `Game.start_run()` consults it for unlocked weapons and stat bonuses. No other system changes.

---

## 3. Data model

All content lives in Resources (`.tres` files), not code.

### `WeaponData` — `combat/weapons/data/`

```gdscript
class_name WeaponData extends Resource

@export var id: StringName              # "whip", "garlic_aura"
@export var display_name: String
@export var max_level: int = 8
@export var base_damage: float
@export var base_fire_rate: float        # shots per second
@export var base_area: float = 1.0
@export var projectile_scene: PackedScene
@export var targeting: Targeting        # NEAREST | RANDOM_IN_RANGE | FIXED_AROUND_PLAYER | DIRECTION_OF_MOVEMENT
@export var level_modifiers: Array[WeaponLevelMod]
```

`WeaponLevelMod` is `{level, damage_add, fire_rate_mult, area_add, projectile_count_add, ...}`. Leveling = applying modifiers.

### `EnemyData` — `combat/enemies/data/`

```gdscript
class_name EnemyData extends Resource

@export var id: StringName
@export var sprite_frames: SpriteFrames   # placeholder = colored circle for now
@export var max_hp: float
@export var speed: float
@export var contact_damage: float
@export var xp_value: int
@export var ai: EnemyAI                  # WALK_TOWARD_PLAYER | ZIGZAG | LEAP | STATIONARY_SHOOTER
@export var is_boss: bool = false
```

### `SpawnSchedule` — `world/data/`

One source of truth for the difficulty curve. An array of phases:

```gdscript
class_name SpawnPhase extends Resource

@export var starts_at_seconds: int        # 0, 60, 120, ...
@export var spawn_rate_per_sec: float
@export var enemy_weights: Dictionary    # {EnemyData_resource: weight}
@export var boss_to_spawn: EnemyData     # null = no boss this phase
```

`SpawnerDirector` consumes phases by `Game.run_time`. Tuning difficulty = editing one `.tres`.

### `RunState` — in-memory only, lives in `Game`

```gdscript
class RunState:
    var hp: float
    var max_hp: float
    var xp: int
    var level: int
    var time_elapsed: float
    var weapons: Array[WeaponInstance]   # runtime; not WeaponData
    var picked_passives: Array[PassiveData]
```

`WeaponInstance` wraps a `WeaponData` with current level + cooldown timer. Owned by Player. **Intentionally not a Resource** — runs are not saved/resumed in Phase 1.

---

## 4. Core loop systems

### Player

- `CharacterBody2D`, `move_and_slide()` in `_physics_process`.
- WASD input via `InputMap` actions (`move_left`, etc.) — never raw key codes (touch-retrofit hook from `architecture.md`).
- Hosts `WeaponInstance` children. Each weapon ticks independently.
- HP/XP/level read from `Game.run_state` — not held on the player node.

### Weapons (the most nuanced system)

Each `WeaponInstance` on `_process(delta)`:

1. Tick cooldown.
2. If ready: query world via `targeting` mode to pick target/position.
3. Spawn `projectile_scene` (or apply effect for AoE auras).
4. Reset cooldown = `1.0 / current_fire_rate`.

**Targeting modes** (enum, dispatched in code):

- `NEAREST` — closest enemy in range
- `RANDOM_IN_RANGE` — VS-style Magic Wand
- `FIXED_AROUND_PLAYER` — orbiting auras (Garlic-style)
- `DIRECTION_OF_MOVEMENT` — fires where the player walks

**Projectile pooling is required.** Naive `instance` / `queue_free` will GC-thrash with hundreds of entities. Autoload `ProjectilePool` recycles instances. Webdev analogy: object pool from canvas/WebGL.

**Level-up flow:**

1. Player picks up XP gem → `Game.add_xp(amount)` → maybe emits `level_up`.
2. HUD pauses game (`get_tree().paused = true`), shows 3 random upgrade options.
3. Options = level up existing weapon OR new weapon (from unlocked pool not currently owned).
4. Pick → modifier applied → unpause.

### Enemies

- `CharacterBody2D` scene + `MovementComponent` (selected by `EnemyData.ai`) + `HealthComponent` + `ContactDamageComponent`.
- Composition: 4-5 AI behaviors from 4-5 component classes, no N×M class explosion.
- On death: emit `enemy_killed` to EventBus → spawn `XpGem` → recycle via enemy pool (decide on first perf measurement; start with `queue_free`).

### SpawnerDirector

In `_process`:

1. Find current `SpawnPhase` based on `Game.run_state.time_elapsed`.
2. Accumulate spawn budget = `spawn_rate_per_sec × delta`. When ≥1, spawn.
3. Pick enemy via weighted random from current phase.
4. Spawn position = random point on circle of `spawn_radius` around player, clamped just off-camera.
5. At phase boundary, if `boss_to_spawn != null`: also spawn the boss and reduce normal spawns to 30% until it dies.

### Boss waves

- Boss spawns from `SpawnPhase.boss_to_spawn` at phase start.
- Normal spawns drop to 30% while alive.
- Boss has HP bar shown in HUD (the only enemy that does).
- On death: explosion of XP gems + guaranteed item drop + normal spawn rate resumes.

### XP and leveling

`xp_needed(level) = 5 + level * 3`. Linear-quadratic, tunable. Just a function on `Game`.

---

## 5. Scene structure & file layout

Top-level dirs are features (per `architecture.md`):

```
bootstrap/
  main.tscn               # boot scene → loads MainMenu
  main.gd
  game.gd                 # Game autoload (game state, run lifecycle)
  event_bus.gd            # EventBus autoload (signal hub)
  projectile_pool.gd      # ProjectilePool autoload

player/
  player.tscn             # CharacterBody2D + Sprite2D + CollisionShape2D + WeaponHost
  player.gd
  weapon_host.gd          # holds WeaponInstance children
  weapon_instance.gd      # runtime wrapper around WeaponData

combat/
  weapons/
    weapon_data.gd
    weapon_level_mod.gd
    data/                 # .tres files, one per weapon (5 in Phase 1)
      whip.tres
      garlic_aura.tres
      ...
    projectiles/
      basic_projectile.tscn / .gd
      piercing_projectile.tscn / .gd
      ...
  enemies/
    enemy_data.gd
    enemy.tscn            # base enemy scene
    enemy.gd
    components/
      movement_walk.gd
      movement_zigzag.gd
      movement_leap.gd
      health.gd
      contact_damage.gd
    data/
      goblin.tres
      bat.tres
      ...
  damage.gd               # shared damage calc

world/
  arena.tscn              # the level: tilemap + spawner + enemy container
  arena.gd
  spawner_director.gd
  spawn_schedule.gd
  spawn_phase.gd
  data/
    schedule_default.tres
  xp_gem.tscn / .gd

ui/
  hud.tscn / .gd          # HP, XP bar, time, weapons, FPS
  level_up_dialog.tscn / .gd
  pause_menu.tscn / .gd
  death_screen.tscn / .gd
  main_menu.tscn / .gd

assets/                   # shared placeholder shapes / fonts / future sprites

docs/design/              # this doc + future design docs
```

**Per-feature assets** (sprites, sounds) live inside their feature dir next to the code that uses them — only truly shared assets go in `assets/`.

---

## 6. Phase 1 vs Phase 2 — clean boundary

### Phase 1 — shippable arcade game (no persistence)

Everything above. The MVP definition:

- 1 player character
- 5 weapons (each with 5-8 levels)
- 6 enemies (3 normal, 2 mid-tier, 1 boss)
- 1 arena with 1 `SpawnSchedule`
- Full leveling loop, level-up dialog, pause menu, death/victory screens
- HUD, debug skip (see §7)
- Placeholder shapes for all sprites

"Done" definition: a stranger can run the executable, play one full 25-min run, lose (or win at 30 min), and the game feels fun for the first 10 min.

### Phase 2 — meta-progression layer

Added on top of Phase 1 without disturbing it. New code:

- `MetaState` autoload — owns persistent data (gold, unlocked weapons, stat upgrade levels)
- `SaveManager` autoload — JSON save file in `user://save.json` (Godot's user data dir)
- `between_runs.tscn` — shop / unlock list / "start next run" screen
- `Game.start_run()` modified to read `MetaState` for unlocked weapons and stat bonuses
- `Game.end_run()` modified to commit gold/unlocks and trigger save
- Achievement triggers: subscribe to EventBus, check thresholds, unlock weapons on first trigger

Phase 2 content scope:

- +10 weapons (total 15)
- +1-2 stages (different `SpawnSchedule` + arena tilemap variants)
- ~15 stat upgrade slots (max HP, move speed, damage %, pickup radius, etc.)
- ~10 weapon unlocks tied to achievements

---

## 7. Testing & debug

### Pure-logic tests

Test framework choice (GdUnit4 vs GUT) deferred to the first implementation task per `docs/architecture.md` ("first one added wins per 'one idiomatic way'"). Both target Godot 4; pick whichever installs cleanest at impl time. Tests for:

- Weapon damage calc with modifiers stacked at all levels
- XP curve
- Spawn weight selection (statistical: 10k spawns, distribution within ±5%)
- Level-up option pool exclusion (no dupes, no maxed weapons)

Run headless (command will depend on test framework chosen).

### Debug autoload

`bootstrap/debug.gd` (autoload, only active in editor / debug builds). Hotkeys:

- **F1** — +1 level
- **F2** — +60 s elapsed
- **F3** — spawn boss now
- **F4** — toggle god mode (player invincible)
- **F5** — kill all enemies
- **F6** — fill all weapons to max level
- **F7** — toggle 4× game speed
- **F12** — toggle visual overlay (spawn radius circle, hit boxes, FPS, entity count)

The point: never playtest a 25-min run to verify boss code. Jump there in 2 seconds.

### Visual debug

`F12` overlay renders:

- Spawn radius circle around player (shows where enemies will appear)
- All hitboxes (collision shapes)
- FPS, frame time, entity count, projectile pool size
- Current `SpawnPhase` info (rate, weights)

---

## 8. Out of scope for Phase 1 (anti-design)

Equally important. First-game scope discipline.

- **No music or full SFX system.** Placeholder beeps via `AudioStreamPlayer` for hit/level-up are fine. Full audio in Phase 2 polish.
- **No story or cutscenes.** Run starts when you click "Play."
- **No localization.** English only; strings hard-coded for now.
- **No mobile/touch input.** Desktop only. (Input goes through `InputMap`, so touch retrofit later is cheap — see `architecture.md`.)
- **No multiplayer or leaderboards.**
- **No achievements UI.** (Phase 2 has internal achievement *triggers* for weapon unlocks; no UI.)
- **No daily challenges, no seeds.**
- **No deep accessibility options.** Font is readable; that's it.
- **No character roster.** One character. (Per locked decisions.)
- **No theme art.** Colored shapes. (Per locked decisions.)
- **No save during run.** Run ends, you start over. (Per `RunState` design.)
- **No controller support.** Keyboard + mouse only in Phase 1. (Add via `InputMap` action remapping in Phase 2 polish.)

If you find yourself building any of these in Phase 1, stop and ask whether it's worth blowing the scope.

---

## 9. Scope for the implementation plan

When this design transitions to `writing-plans`, **the plan should target Phase 1 only.** Phase 2 is sketched here for architectural foresight (so Phase 1 doesn't paint Phase 2 into a corner), not for immediate execution. A separate design+plan cycle starts Phase 2 once Phase 1 ships.

---

## 10. Appendix — open questions for implementation

Things deliberately left undecided; will be resolved during Phase 1 implementation:

- **Tile size.** 32×32? 16×16? Decide when we have first placeholder sprites.
- **Camera follow style.** Strict lock to player vs. dead-zone follow? Dead-zone gives the player slight peripheral vision.
- **Pickup radius.** Default attraction range for XP gems. Tune via playtest.
- **Weapon evolution mechanic** (VS-style "Whip + Hollow Heart → Bloody Tear"). Defer to Phase 2 if at all.
- **Per-frame perf budget.** Target 60 fps at 500 entities; if we miss, decide between fewer enemies, smarter culling, or moving more to GPU.
