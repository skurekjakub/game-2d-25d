---
name: game-programming-patterns
description: Use when designing a new gameplay system, weapon, AI behavior, optimization pass, or refactor in this Godot project — before writing code or a design doc, scan this index for relevant chapters of Robert Nystrom's *Game Programming Patterns* (mirrored locally at docs/references/game-programming-patterns/) and load the matching chapter into context to ground the design in established practice.
---

# Game Programming Patterns — local index

22 chapters of Bob Nystrom's free book live at
`docs/references/game-programming-patterns/`. This skill is the routing
table — read the trigger column, identify the chapter that matches what
you're about to build or refactor, then `Read` that one chapter file
into context.

**Don't pre-load all 22 chapters.** They total ~10,000 lines. The point of
this skill is to find the *right one* in 5 seconds.

## When to use

Invoke this skill whenever you're about to:
- Write a design doc for a new gameplay system (M1.6+)
- Refactor an existing system because the seams hurt
- Optimize a loop / data layout / spawn churn
- Choose between two patterns for the same job ("singleton vs autoload vs locator")
- Push back on a brainstorming suggestion that smells like a known anti-pattern

Skip if the task is purely procedural (`.tres` editing, `project.godot` tweaks,
test scaffold updates) — Nystrom doesn't have chapters for those.

## How to use

1. Skim the **Routing table** below.
2. Pick the 1-2 chapters whose triggers match the work.
3. `Read docs/references/game-programming-patterns/<slug>.md` — full chapter loads.
4. Cross-check with the **Current repo mapping** to see how (or whether) the
   pattern already shows up in this codebase before re-implementing.
5. Mention the chapter by name in your design doc (`# Inspired by [Nystrom — Update Method]`)
   so future readers can trace the lineage.

## Routing table — symptom → chapter

| If you're about to… | Read this chapter |
|---|---|
| Encapsulate an action so it can be replayed, undone, or queued | `command.md` |
| Share a tiny core of immutable data across thousands of instances | `flyweight.md` |
| Broadcast "X happened" without coupling source to receivers | `observer.md` |
| Define entity *types* in data instead of as code subclasses | `prototype.md` or `type-object.md` (read both — they overlap) |
| Reach for `Singleton.instance()` because it's "the easy way" | `singleton.md` (it's the *anti*-pattern chapter — read before doing it) |
| Build a finite state machine (player states, enemy AI, modal flow) | `state.md` (covers FSM, hierarchical FSM, pushdown automata, concurrent states) |
| Present a coherent snapshot of frame N while computing N+1 | `double-buffer.md` |
| Choose between fixed timestep, variable timestep, or decoupled physics | `game-loop.md` |
| Walk a collection of game objects each frame calling `tick(delta)` | `update-method.md` |
| Ship a tiny scripting language so designers can author behavior | `bytecode.md` |
| Provide a "fill in the blanks" base class with shared primitives | `subclass-sandbox.md` |
| Split one god-class into single-purpose components | `component.md` (ECS-lite) |
| Decouple sender and receiver across time (async/queued events) | `event-queue.md` |
| Provide global-ish access without singleton's tight coupling | `service-locator.md` |
| Pack hot data contiguously to keep the CPU cache warm | `data-locality.md` |
| Defer recomputation until the result is actually read | `dirty-flag.md` |
| Reuse instances of churn-heavy objects (bullets, particles, audio) | `object-pool.md` |
| Make "find nearby X" sub-linear (grid / quadtree / BSP) | `spatial-partition.md` |
| Reason about the cost of clean architecture vs raw performance | `architecture-performance-and-games.md` (the introduction's most useful chapter) |

## Current repo mapping

How book patterns already show up in this codebase. Use this to avoid
re-inventing a wheel that's already shipped.

| Repo system | Book chapter |
|---|---|
| `EventBus` autoload (`bootstrap/event_bus.gd`) | `observer.md` |
| `WeaponInstance.tick(delta)` + `_owned_tick(delta)` | `update-method.md` |
| `UpgradeData` shared resource + `WeaponInstance.effective_*` walk | `type-object.md` |
| `UpgradeEffect` Strategy (M1.6 prep) | adjacent to `state.md`; GoF Strategy itself not chaptered |
| `Game` / `UpgradeRegistry` autoloads + `PlayerLocator.find` | `service-locator.md`; cross-ref `singleton.md` for what we deliberately *didn't* do |
| `Damageable.try_damage` static helper | not a book pattern — DRY refactor |
| `DamageAggregator` autoload (subscribes to `damage_dealt`) | `observer.md` |
| `DamageMeterHud` 4 Hz refresh | **none** — pure fixed-interval Timer polling. NOT Observer (no subscription), NOT Dirty Flag (`dirty-flag.md:102` gating fails — no perf problem), NOT hysteresis throttle (no damping). The honest name is "poll the world every 250ms". |
| Future projectile churn optimization | `object-pool.md` |
| Future swarm / boss-arena AI neighbour queries | `spatial-partition.md` |

## Workflow integration

- **During brainstorming:** check this index before proposing an architecture.
  If Nystrom has a chapter, his treatment is the starting point unless you can
  articulate why this repo's constraints warrant a deviation.
- **During plan-writing:** cite the chapter by name in the plan's
  "Architecture" section. Reviewers can verify the lineage.
- **During code review (rubber-duk):** when flagging a smell, name the chapter
  whose anti-pattern is being violated (e.g., "this is the
  `singleton.md` trap — Game state mutable global with no test seam").

## What this skill is NOT

- Not a substitute for reading the chapter. The index lets you find the
  chapter; the chapter is where the actual thinking is.
- Not a license to bend every problem to a Nystrom pattern. Three patterns
  are already load-bearing here (Observer, Update Method, Type Object); the
  rest are tools to reach for *when the symptom matches*, not defaults.
- Not project-specific guidance. Project-specific patterns live in
  `docs/architecture.md`, `docs/architecture/`, and ADRs in
  `docs/decisions/`.

## Related

- `docs/references/game-programming-patterns/README.md` — the same routing
  table from the reference side, plus front-matter explanation.
- `docs/architecture/` — single-component docs that *apply* these patterns.
- `docs/decisions/` — ADRs that record where we deviated from a pattern.
