# ADR 0004 — Central `Game.end_run` guard

**Status:** Accepted (M1.4).

## Context

`EventBus.run_ended(victory: bool)` has two trigger sources:

1. **Player death** — `Player._on_died` (HealthComponent's `died` signal).
2. **Schedule completion** — `SpawnerDirector._on_time_advanced` when the last phase ends.

If both fire in the same run (player dies at t=599s, schedule ends at t=600s), naive direct-emit code produces TWO `run_ended` signals — once with `victory=false`, once with `victory=true`. This breaks downstream listeners' "one-shot" assumption (HUD modulate, future game-over UI in M2.0, debug log) and creates a confusing analytics signal.

Adding flags at each call site (Player has `_died_emitted`, Spawner has `_wave_ended_emitted`) doesn't fix this — those flags prevent the SAME path from re-firing, not different paths from cross-firing.

## Decision

**Single guarded mutation site: `Game.end_run(victory: bool)`.**

```gdscript
var _run_ended_emitted: bool = false

func end_run(victory: bool) -> void:
    if _run_ended_emitted:
        return
    _run_ended_emitted = true
    run_state.is_over = true
    EventBus.run_ended.emit(victory)

func start_run() -> void:
    ...
    _run_ended_emitted = false
```

Both trigger sources go through this site:
- `Player._on_died` calls `Game.end_run(false)`.
- `SpawnerDirector` calls `Game.end_run(true)` co-located with its existing `_wave_ended_emitted` guard.

## Consequences

- **Whichever trigger fires first wins.** Death-before-schedule-end → `run_ended(victory=false)` fires once; the spawner's later call is a no-op. Schedule-end-before-death → `run_ended(victory=true)` fires; the player's later death no-ops.
- **`run_state.is_over` becomes the canonical "run is over" flag.** Game._process early-outs on `is_over` (timer freezes). Game.add_xp early-outs on `is_over` (no post-death XP twitches).
- **Never emit `EventBus.run_ended` directly from gameplay code.** Always go through `Game.end_run`. This is enforced by convention + rubber-duk checklist — no static check.
- **Only one reset site:** `start_run()` resets `_run_ended_emitted = false`. `Game._ready` runs `start_run()`, so a new run always starts clean.
- **The invariant gets one test:** `test_end_run_emits_run_ended_once` calls `Game.end_run(false)` then `Game.end_run(true)` and asserts exactly one signal captured. Cheap, catches the failure mode forever.
