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

- Pure-logic functions get tested with [GUT](https://github.com/bitwes/Gut) or built-in `GdUnit4` (decision pending — first one added wins per "one idiomatic way").
- Integration / scene tests run against headless Godot (`godot --headless --script ...`).

---

## Future-target constraints

Decisions made now to keep doors open without paying for them yet:

- **Mobile (iOS / Android)** — possible future target. Today: Forward+ renderer, desktop-first. To keep the door open at low cost: all input through `InputMap` actions (touch-retrofittable), no shaders that assume desktop-class GPU, asset import settings sane for compression. Active porting work (renderer switch to Mobile/Compatibility, touch UI layer, perf budget tightening) is deferred until mobile is confirmed as a target.
