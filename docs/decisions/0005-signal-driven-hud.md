# ADR 0005 — Signal-driven HUD (no Player reference)

**Status:** Accepted (M1.4).

## Context

The HUD needs to display HP, XP, level, run timer, weapons list, FPS. The naive shape is to grab a Player reference at HUD `_ready` (or via `@export var player: Player`) and poll Player's fields in `_process`:

```gdscript
# naive
@onready var _player: Player = get_node("/root/Arena/Player")

func _process(_delta):
    _hp_bar.value = _player._health.hp     # cross-boundary private-member read
    _hp_bar.max_value = _player._health.max_hp
    _level_label.text = "Lv %d" % Game.run_state.level
```

Problems:
- **HUD reaches into Player's internals.** `_player._health` is a private member; the HUD shouldn't know Player's internal node structure.
- **Stored Player ref breaks on scene reload.** When Player is freed and re-instantiated (death-restart in M2.0), the HUD's stored ref dangles.
- **Per-frame polling for event-driven data** burns CPU on values that change rarely (level changes ~10×/run; polled 60×/sec = 6000× wasted reads).

## Decision

**Pure signal-driven HUD.** HUD subscribes to `EventBus` signals in `_ready` and updates child widgets in the handlers. It never stores a Player reference.

Subscriptions:
- `EventBus.run_started` → reset to defaults.
- `EventBus.run_ended(victory)` → dim/brighten via `modulate`.
- `EventBus.player_health_changed(hp, max_hp)` → HP bar.
- `EventBus.xp_gained(amount)` → XP bar.
- `EventBus.level_up(new_level)` → level label + XP bar reset.
- `EventBus.upgrade_applied(upgrade)` → refresh weapons list.

Two genuinely-time-continuous values stay in `_process`:
- Run timer reads `Game.run_state.time_elapsed` (Game is an autoload, always accessible; no per-tick signal worth emitting).
- FPS reads `Engine.get_frames_per_second()` (engine value with no signal).

Player is the **canonical re-emitter** for HP changes. Player listens to its own HealthComponent's `hp_changed` / `max_hp_changed` signals (which fire on every mutation through `take_damage` or `set_hp` / `set_max_hp`) and re-emits to `EventBus.player_health_changed`. This keeps HealthComponent generic (works for enemies too) while giving HUD a single "Player's HP changed" event to subscribe to.

The weapons list is the one exception that needs Player state: it reads `WeaponHost.weapons` to enumerate. The lookup uses `get_tree().get_nodes_in_group("player")` — no stored ref — and only runs on `upgrade_applied` (not every frame).

## Consequences

- **HUD has zero `player._*` references.** Audit-friendly; survives Player death + respawn cycles.
- **HUD can be added to or removed from any scene** without Player code changes.
- **Direct `hc.hp = X` writes are a bug** — they bypass the signal pipeline. M1.4 shipped this initially (UpgradeRegistry's `heal_to_full` did `hc.hp = hc.max_hp` directly, no signal); the fix was adding `set_hp` as a setter (ADR-adjacent; documented in architecture.md HealthComponent section).
- **Pause-safe by accident:** signal handlers fire even when the tree is paused. The HUD's `_on_upgrade_applied → _refresh_weapon_list` chain runs cleanly during a modal-driven pause.
- **Tests don't need a Player scene** — they can emit signals directly on the `EventBus` autoload and assert HUD state changed.
- **Bus cost:** four extra signal emits per damage event (Player re-emits `player_health_changed`; HUD updates one widget). Negligible at any realistic damage rate.
