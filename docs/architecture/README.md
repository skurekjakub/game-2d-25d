# Architecture — component-level diagrams

Companion to `docs/architecture.md` (project-wide rules) and
`docs/systems/weapons.md` (M1.5 weapons deep-dive). This folder holds
**single-component** views — one file per cohesive subsystem — so a
new contributor can orient themselves in 5 minutes without reading
half the repo.

## Index

- [Player](player.md) — what Player owns, what it exposes, how it
  connects to the rest of the world.
- [Damage pipeline](damage-pipeline.md) — every path that ends in
  `HealthComponent.take_damage`. Cooldown-fire, scene-owned tick,
  Damageable helper.
- [Upgrade pipeline](upgrade-pipeline.md) — pool → gating → modal pick
  → apply. Will be revised at M1.6 when `UpgradeEffect` Strategy lands.
- [Lookups and helpers](lookups-and-helpers.md) — `PlayerLocator`,
  `Player.weapon_host`, `Damageable`, `TestWorld`. The Bundle-1 SoC
  refactor introduced these; this is the cheat sheet for using them.

## When to add a doc here

- The system has **3+ files** that only make sense together (e.g., a
  weapon scene + its data + its tests).
- A new contributor will reach for the system in their first week.
- The "how do these classes connect" question takes more than one
  glance at `find` to answer.

If a doc would be a single class with one method, write a docstring
instead.
