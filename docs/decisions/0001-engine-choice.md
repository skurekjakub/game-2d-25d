# ADR 0001 — Engine choice

**Status:** Accepted (locked in at M1.0; revisit only if mobile becomes a confirmed target).

## Context

Project is a 2D / 2.5D game. Engine not yet selected. Selection should weigh:

- Fit for 2.5D rendering (depth sorting, billboarded sprites, isometric or projected camera).
- Agent-friendliness — how legibly an AI coding agent can read and edit the project.
- Iteration speed and tooling.

## Options under consideration

- **Godot 4.x** — plain-text `.tscn` scenes, single-idiom GDScript, no GUID indirection. Highest agent legibility out of the box. Strong 2D/2.5D support.
- **Bevy (Rust)** — code-only, ECS, data-driven. Strong correctness story via the Rust compiler. Smaller editor/tooling story; mostly text + code.
- **Unity** — dominant ecosystem, mature MCP bridges, but YAML scenes are GUID-indirected and the same task has multiple idiomatic patterns (UnityEvents / C# events / ScriptableObject channels / message bus), which dilutes agent guidance.
- **Unreal** — strong rendering, growing MCP ecosystem (Flop, mcp-unreal, Aura), but Blueprint binary format is opaque to agents without a binary reader bridge.

## Decision

**Godot 4.x.**

Driven by two factors that compound:

1. **Agent legibility.** Plain-text `.tscn` / `.tres` files, GDScript's single-idiom API, and no GUID indirection mean an AI agent can read, diff, and edit the entire project with the same tools it uses for code. Unity's GUID-referenced YAML, Unreal's binary Blueprints, and Unity's editor-cache/domain-reload "compiles but is integration-wrong" trap all directly hurt agent reliability.
2. **2.5D / isometric tooling is first-class.** Native isometric `TileMapLayer`, built-in Y-sort, and 2D lighting with occluders/shadows ship in the engine — no third-party stack to assemble (Bevy) and no fighting a 3D-first pipeline (Unreal).

Bevy was the runner-up — ECS purity and Rust correctness are real wins — but its 2D ecosystem is third-party glue (`bevy_ecs_tilemap` + `bevy_ecs_tiled`/`bevy_ecs_ldtk`), which costs early-stage velocity at exactly the wrong time. Unity remains viable for 2D but its agent-friendliness disadvantages don't justify giving up Godot's iteration speed and MIT license.

## Consequences

- Engine-specific addendum lives at the bottom of `docs/architecture.md`.
- Project layout is feature-based (`bootstrap/`, `world/`, `player/`, `combat/`, `ui/`, `assets/`) with `.tscn` / `.gd` files co-located by feature.
- Rendering method: **Forward+** for now (desktop-first, full 2D lighting). If mobile becomes a real target, revisit and likely switch to Mobile or Compatibility — see "Future-target constraints" in `docs/architecture.md`.
- All scenes and resources stay in text form (`.tscn`, `.tres`) — never `.scn` or `.res` — so they remain diff- and agent-legible.
