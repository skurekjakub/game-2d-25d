# ADR 0003 — Pure-functional upgrade system

**Status:** Accepted (M1.4).

## Context

The level-up modal lets the player pick stat or weapon upgrades. Two architectural shapes were considered:

1. **Mutate-in-place.** `apply(upgrade)` writes directly to per-weapon multiplier fields (`weapon.damage_mult *= 1.25`). Standard pattern in Godot tutorial code (Minoqi, EnhancedStat).
2. **Pure-functional read-through-list.** `Game.run_state.upgrades_taken: Array[UpgradeData]` is the only state. Weapons compute effective values at fire/tick time by walking the list. `apply()` is no-op for weapon-affecting upgrades.

The trigger for considering option 2 was the **shared-resource gotcha**: `WeaponData.tres` files are reference-shared across every `WeaponInstance`. Mutating `data.base_damage` directly silently corrupts every future instantiation. Option 1's mutate-in-place would need per-instance multiplier shadows, which works but proliferates fields and creates a "what's the source of truth" ambiguity.

## Decision

**Option 2: pure-functional.**

`Game.run_state.upgrades_taken: Array[UpgradeData]` is the source of truth. Weapons (`WeaponInstance.effective_damage()`, etc.) walk the list at fire time. `UpgradeRegistry.apply()` mutates per-instance state (Player.speed, HealthComponent.hp/max_hp) for stat upgrades; weapon-affecting upgrades are no-op at apply time.

## Consequences

- **Easy save/load (Phase 2):** serialize `Array[StringName]` of upgrade ids, reapply on load. No multiplier-field snapshotting needed.
- **No template mutation possible by construction:** weapon-affecting upgrades never touch `WeaponData`. The architecture is the guardrail.
- **Live values on every read:** picking +25% damage mid-fight takes effect on the very next shot — no stale fields to flush.
- **Cost:** O(N) walk per shot where N = upgrades_taken size. At expected scale (≤30 upgrades, ≤100 shots/sec), perf is microseconds — irrelevant. If N ever crosses ~50 AND fire rate crosses ~100/s, revisit by caching counts in `RunState`.
- **Upgrade keys are id-prefixed** (M1.5+: `<weapon_id>_<kind>_<value>` like `aura_damage_25`). The id is the lookup key; `UpgradeData` shape stays flat (no taxonomy enums).
- **Pool gating** at pick time uses the same `upgrades_taken` list + `WeaponHost.owned_weapon_ids()` to filter the available cards (M1.5).
- **Pick-order matters for queued multi-levels:** the picker emits `EventBus.upgrade_applied` AFTER appending to `upgrades_taken` and unpausing, so the synchronous chain into `Game._maybe_emit_level_up` and a re-entered modal sees the canonical list. (M1.4 originally got this ordering wrong; rubber-duk caught it.)
- **Adding upgrade #20** = drop a `.tres` + add one `match upgrade.id:` arm. The `_:` `push_warning` fallthrough catches forgotten arms at runtime.
