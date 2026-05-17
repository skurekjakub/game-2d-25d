# Milestones

A snapshot of where the project is and what's planned. Tagged milestones are pushed to `origin`; current work lives on `feature/milestone-<N>-*` branches.

## Shipped

| Tag | Topic | What landed |
|---|---|---|
| `milestone-1.0` | Foundations | Boot scene, Player CharacterBody2D + input, basic Arena scene, GdUnit4 wired (ADR-0002), `tests/run.sh`. |
| `milestone-1.1` | Combat loop | Enemy with HealthComponent, BasicProjectile, WeaponHost + WeaponInstance + WeaponData, nearest-target firing. |
| `milestone-1.2` | Spawner | SpawnSchedule / SpawnPhase resources, SpawnerDirector, enemy concurrency cap, XP gems on enemy death, basic XP bar. |
| `milestone-1.3` | Player HP + slow-zone | ContactDamageComponent on enemies, Player HP via HealthComponent, contact-slow Area2D, death routes through (then-direct) `EventBus.run_ended`. Palette + CollisionLayers conventions introduced. |
| `milestone-1.4` | HUD + level-up modal | Full 5-element HUD (HP/XP/level/timer/weapons/FPS), 3-card level-up modal, 5-upgrade pool, `RunState.upgrades_taken`, pure-functional upgrade read path (ADR-0003), central `Game.end_run` guard (ADR-0004), signal-driven HUD (ADR-0005), 10-phase × 60s schedule (10-min runs), `hp_changed` / `set_hp` symmetric signal/setter pattern. |

## In progress

| Branch | Topic | Status |
|---|---|---|
| `feature/milestone-1.5-weapon-variety` | Weapon variety | Design + plan complete. 10 tasks, 3 rubber-duk checkpoints. Adds 3 new weapons (Spread, Aura, Orbital) acquired via the modal pool, per-weapon upgrade ids, tiered pool gating. Weapon-scene-per-kind architecture (each weapon's behavior in its own scene). |

Plan: `docs/plans/2026-05-17-milestone-1.5-weapon-variety.md`. Design: `docs/design/2026-05-17-milestone-1.5-weapon-variety.md`.

## Planned

| Target | Topic | Notes |
|---|---|---|
| M1.6 | Enemy variety | 3-4 enemy kinds (ranged, fast, tough) + weighted SpawnPhase enemy mix. Revisits `max_concurrent_enemies` cap (currently 30, throttles late-phase 3.0/s spawn rate — see M1.5 risk register). |
| M1.7 | Boss wave | Single tough enemy at ~3-min mark with own HP bar via existing `player_health_changed` signal pattern reused on a boss-health bus. |
| M2.0 | Menus + restart | Main menu, game-over screen, restart loop. First "real" UI surface beyond the HUD/modal. Driven by `EventBus.run_ended` which is already centrally guarded (ADR-0004). |

## Conventions for adding milestones

1. **Brainstorm.** `docs/design/YYYY-MM-DD-<name>.md` via the brainstorming skill. Bulk-write to file, not section-by-section in chat (user preference).
2. **Pre-implementation rubber-duk.** Dispatch `rubber-duk` against the design doc before locking it. Address BLOCKERs in revision; defer NITs explicitly.
3. **Plan.** `docs/plans/YYYY-MM-DD-<name>.md` via the writing-plans skill. Bite-sized TDD tasks; rubber-duk every ~3 code tasks.
4. **Branch.** `feature/milestone-<N>-<topic>` off master. Land all work there.
5. **Execute.** Subagent-driven via `godot-implementer` for code tasks; inline for procedural (`.tres` writing, `.tscn` wiring, `project.godot` edits) per project memory `feedback_subagent_scope`.
6. **Visual smoke.** Manual windowed playtest against the design's smoke checklist before tagging.
7. **Tag + merge.** `git tag milestone-<N>` + fast-forward merge to master + push.
8. **Record decisions.** If the milestone made a non-obvious architectural choice, add an ADR under `docs/decisions/` so future contributors don't re-litigate it.
