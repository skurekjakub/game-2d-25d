# Architecture

Universal patterns for this project, independent of engine choice. When the engine is picked, this doc gets an engine-specific addendum but these principles stay.

## State as data

- Game state lives in plain data structures (records, structs, resources, components — whatever the chosen engine calls them).
- Rendered objects (nodes, actors, entities) are **views** over that state. They read state to display it; they do not own it.
- A scene/level can be torn down and rebuilt from its data with no behavior change. If that breaks, state has leaked into views.

## One idiomatic way

For each kind of task there is one pattern in this repo:

- One way to communicate between systems (events/signals, not direct method calls).
- One way to persist data.
- One way to schedule work over time.
- One way to load assets.

When a new agent (human or AI) needs a second way, that's a discussion, not a fait accompli. Add the new pattern to this doc and migrate the old one, or don't add it. Two coexisting patterns is the failure mode.

## Deterministic systems

- Systems are functions over state. Same input → same output.
- Side effects (rendering, audio, IO) happen at well-defined boundaries, not scattered through logic.
- Avoid hidden global state. If a system needs context, pass it in.

This is what ECS gives you for free, and what node-based engines can give you with discipline.

## Composition over inheritance

Build behavior by composing small pieces (components, traits, mixins) rather than deep class hierarchies. Easier to read, easier to test, easier for an agent to extend without breaking siblings.

## Testability

- Pure logic functions get unit tests with no engine running.
- Integration tests exist for cross-system flows.
- A change that compiles is not a change that works. After non-trivial edits, exercise the actual gameplay path.

## Naming

- Names describe purpose, not implementation. `PlayerHealth` not `HealthFloat`.
- Avoid generic suffixes that add no information (`Manager`, `Helper`, `Utils`) unless the role really is "owns this subsystem."
- Same concept → same name everywhere. If it's "tile" in one file and "cell" in another, rename one.

## Project layout (engine-agnostic intent)

Whatever engine we pick, the top-level layout should reflect features, not file types:

```
combat/        — everything for combat: data, systems, scenes, tests
inventory/
world/
ui/
```

Not:

```
scenes/
scripts/
assets/
tests/
```

(Some engines force a partial file-type split — that's fine, but feature-level grouping should be visible inside each.)

## What to write down

When you make a non-obvious decision (a workaround, a constraint from the engine, a deliberately-chosen tradeoff), record it. Architecture decisions go in `docs/decisions/` as ADRs. Subtle invariants go in a one-line comment at the relevant code site.

What *not* to write down: things derivable from reading the code (names, structure, what functions do).

---

## Godot addendum

Engine-specific application of the universal patterns above.

### File formats

- Scenes are `.tscn` (text), never `.scn`. Resources are `.tres` (text), never `.res`. This is non-negotiable — binary forms break agent legibility and git diffs.
- One scene per file. Composing scenes is done by instancing, not by stuffing multiple roots into one file.

### Layout

Top-level dirs are features, not file types:

```
bootstrap/   — boot scene + entry script
world/       — terrain, tilemaps, environment systems
player/      — player character, input, camera
combat/      — damage, hit detection, status effects
ui/          — HUD, menus, dialogs
assets/      — raw assets that don't belong to a single feature (shared fonts, etc.)
```

Inside each feature dir, `.tscn` / `.gd` / `.tres` files for that feature live together. Per-feature assets (sprites, sounds) live next to the code that uses them.

### State as data → Resources

- Game state lives in `Resource` subclasses (custom `class_name Foo extends Resource`).
- Nodes hold references to those resources and render them. Nodes do not own state.
- A scene torn down and rebuilt from its resource(s) must behave identically.

### Cross-system comms → Signals

- One way for systems to talk: **signals**.
- Direct method calls across feature boundaries (`world.player.health.take_damage(...)`) are the failure mode. Use signals, or a thin autoload event bus.
- Within a single feature, direct calls between siblings are fine.

### Global systems → Autoloads

- Globally-accessible systems (event bus, game state singleton, audio manager) are registered as Autoloads in Project Settings.
- Autoloads are explicit and discoverable — preferable to ad-hoc singletons hidden in scripts.
- Current autoloads (load order matters; later autoloads may depend on earlier ones):
  1. `EventBus` (`bootstrap/event_bus.gd`) — typed signal hub. Declared signals are the cross-feature contract; never use direct method calls between sibling systems.
  2. `Game` (`bootstrap/game.gd`) — `RunState` container + lifecycle (`start_run`, `end_run`, `add_xp`, `_maybe_emit_level_up`). Subscribes to `EventBus.upgrade_applied` in `_ready` to drain pending level-ups.
  3. `Debug` (`bootstrap/debug.gd`) — toggleable `[EventBus] event(args)` logging; `F3/F4/F12` keybinds.
  4. `UpgradeRegistry` (`combat/upgrades/upgrade_registry.gd`) — loads `combat/upgrades/data/*.tres` on `_ready` via `ResourceLoader.list_directory` (export-safe); exposes `pick_random_3()` + `apply(upgrade, player)`.
- Adding a 5th autoload requires justification — keep the global namespace small.

### Upgrade system (pure-functional read path)

- `Game.run_state.upgrades_taken: Array[UpgradeData]` is the source of truth for every upgrade picked in the current run.
- `UpgradeRegistry.apply(upgrade, player)` mutates per-instance state (Player.speed, HealthComponent.max_hp/hp) for stat upgrades; weapon-affecting upgrades are **no-op at apply time**.
- Weapon effective values (`damage`, `fire_rate`, `level`, mechanical counts) are computed live at fire/tick time by walking `upgrades_taken`. `WeaponInstance` + weapon-scene scripts (Aura, Orbital from M1.5) own the lookups.
- The picker appends to `upgrades_taken` BEFORE calling `apply()` — so `apply()` and any downstream listener see the list as canonical.
- **Never mutate `WeaponData.tres`** — Resources are reference-shared; mutating a template silently corrupts every future WeaponInstance that references the same `.tres`. The pure-functional read path is the architectural guardrail against this.
- Adding upgrade #20: drop a `.tres` in `combat/upgrades/data/` + add one `match upgrade.id:` arm in `UpgradeRegistry.apply()`. The `_:` `push_warning` fallthrough catches forgotten arms at runtime.

### Run lifecycle invariants

- `EventBus.run_ended` fires **at most once per run**. Both trigger sources (Player death, SpawnerDirector schedule completion) route through `Game.end_run(victory: bool)`, guarded by `_run_ended_emitted`. Never emit `EventBus.run_ended` directly from gameplay code — always go through `Game.end_run`.
- `Game.end_run` flips `run_state.is_over = true`. `Game._process` early-outs on `is_over` (timer freeze). `Game.add_xp` also early-outs on `is_over` (no post-death XP twitches).
- `Game.start_run` resets `_run_ended_emitted = false` — the only reset site.

### HealthComponent signal pattern

- `HealthComponent` exposes 4 signals: `damaged(amount, new_hp)` (for flash/effects), `died(killer)`, `max_hp_changed(new_max)`, `hp_changed(new_hp)`.
- All HP mutations go through `take_damage(amount)` or `set_hp(value)` — both emit `hp_changed`. `take_damage` ALSO emits `damaged` for non-HUD consumers (the flash, damage-dealt analytics).
- All max-HP mutations go through `set_max_hp(value)` — emits `max_hp_changed`.
- Player listens to `damaged` (flash trigger) + `hp_changed` (re-emit to `EventBus.player_health_changed`) + `max_hp_changed` (re-emit to `EventBus.player_health_changed`) + `died` (route to `Game.end_run(false)`).
- Direct field writes (`hc.hp = X`, `hc.max_hp = X`) are a bug — they bypass the signal pipeline and leave subscribers stale.

### HUD pattern (pure signal-driven)

- HUD never holds a Player reference and never polls `player._health.hp`. It subscribes to `EventBus` signals in `_ready` and updates child widgets in the handlers.
- Two exceptions are time-continuous values that don't have signals: `_process` reads `Game.run_state.time_elapsed` and `Engine.get_frames_per_second()` directly.
- The weapons list reads `WeaponHost.weapons` via group lookup (`get_tree().get_nodes_in_group("player")`) on `EventBus.upgrade_applied` — no stored Player ref.
- Decoupling rationale: lets Player be torn down and rebuilt (death, scene reload) without breaking HUD; lets HUD be added/removed from any scene without changing Player code.

### Collision layers

- 32-bit collision layers + masks are named in `project.godot` `[layer_names]` AND mirrored as a const class in `combat/collision_layers.gd`:
  - Layer 1 / `ENVIRONMENT` (walls, static geometry)
  - Layer 2 / `PLAYER` (Player body)
  - Layer 3 / `ENEMIES` (Enemy bodies)
- `collision_layer` = what you ARE. `collision_mask` = what you SCAN FOR. Interaction iff `a.mask & b.layer != 0`.
- Prefer the named const (`CollisionLayers.ENEMIES`) over raw int literals (`4`) in code; `.tscn` files use int values directly but with the `project.godot` names visible in the inspector.

### Colors → Palette

- Inline `Color(r, g, b, a)` literals scattered through scripts are a maintenance smell. All named colors live in `assets/palette.gd` as a const class (`Palette.ARENA_BG`, `Palette.PLAYER_BODY`, etc.).
- Scripts reference `Palette.<NAME>`; `.tscn` files keep their inline `color = Color(...)` lines for editor-friendliness.

### Pause + modal UI

- `get_tree().paused = true` halts every node by default. Modals opt back in via `process_mode = PROCESS_MODE_WHEN_PAUSED` on the Control root.
- Input discipline on modals (input bleed-through is the failure mode):
  - Modal root: `mouse_filter = STOP` + `process_mode = WHEN_PAUSED`.
  - Container ancestors of buttons: `mouse_filter = PASS`.
  - Buttons themselves: `mouse_filter = STOP` (default).
  - After dispatching a pick (mouse OR keyboard), call `get_viewport().set_input_as_handled()` (and `accept_event()` in `_unhandled_key_input`) to prevent the same Enter/click from bubbling.
  - First card auto-focused via `call_deferred("grab_focus")` so Tab/arrow + Enter works without a mouse.
- Godot gotcha: `body_entered` / `area_entered` do NOT fire on paused nodes (Godot #47326). Signal handlers DO fire. Tune accordingly — modal pickup detection wants the former; HUD updates want the latter.

### Rendering

- Renderer: Forward+ (default). Supports 2D lights, shadows, and `LightOccluder2D`.
- Y-sort is set at the `Node2D` / `TileMapLayer` level. Don't roll your own depth sorter.
- Tilemap shape: Isometric (set on the TileSet), tile size matching sprite footprint (e.g. 32×16 for 32×32 sprites).

### Input

- All input flows through Godot's `InputMap` actions (`Input.is_action_pressed("move_left")`), never raw `Input.is_key_pressed(KEY_A)` scattered through gameplay code.
- This is the touch-retrofit hook: actions can be bound to keys today and to on-screen buttons / gestures tomorrow without touching gameplay logic.

### Style

- GDScript with **static typing** wherever practical (`var x: int = 0`, `func foo(bar: String) -> void:`). Better IDE help, better agent suggestions, fewer runtime surprises.
- Snake_case for files, vars, funcs. PascalCase for `class_name` and node types.
- Signals named in past tense for events that happened (`damaged`, `picked_up`).

### Testing

- Test framework: [**GdUnit4**](https://github.com/MikeSchulze/gdUnit4) (chosen — see ADR-0002). Test suites live in `tests/`, runner at `tests/run.sh`.
- Pure-logic functions get unit tests against fresh constructed instances; node-based tests use `auto_free()` and may add to the tree when scene state matters.
- Default to **headless** runs (`./tests/run.sh tests/test_<name>.gd`). Drop `--headless` and run windowed when the test needs Tweens, real Area2D body/area signals, input events, or anything time/render-driven (project memory `godot_tests_windowed_mode`).
- Autoload state (`Game.run_state`, `EventBus` connections) **persists across tests** in the same process — use `Game.start_run()` in `before_test()` and disconnect any `EventBus.*.connect(listener)` you add in teardown.
- Hand-written `.tres`/`.tscn` in tests should omit UID attributes (project memory `godot_uid_handwritten_tres`); the editor normalizes them on first open.

---

## Future-target constraints

Decisions made now to keep doors open without paying for them yet:

- **Mobile (iOS / Android)** — possible future target. Today: Forward+ renderer, desktop-first. To keep the door open at low cost: all input through `InputMap` actions (touch-retrofittable), no shaders that assume desktop-class GPU, asset import settings sane for compression. Active porting work (renderer switch to Mobile/Compatibility, touch UI layer, perf budget tightening) is deferred until mobile is confirmed as a target.
