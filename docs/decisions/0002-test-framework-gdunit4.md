# ADR 0002 — Test framework: GdUnit4

**Status:** Accepted (resolved at M1.0).

## Context

Godot 4 has two mature test frameworks: [GUT](https://github.com/bitwes/Gut) and [GdUnit4](https://github.com/MikeSchulze/gdUnit4). Per the project's "one idiomatic way" rule, we pick one and stick with it.

`docs/architecture.md` originally said "decision pending — first one added wins." GdUnit4 went in at M1.0 and has been the de-facto framework since; this ADR records that choice retroactively so a future contributor doesn't re-litigate.

## Decision

**GdUnit4.**

Reasoning:

- **Fluent assertions** (`assert_int(x).is_equal(3)`) read closer to the production code's typed style than GUT's `assert_eq(x, 3, "message")` form.
- **First-class CLI runner** (`addons/gdUnit4/bin/GdUnitCmdTool.gd`) integrates cleanly with our `tests/run.sh` wrapper.
- **Signal monitoring** (`monitor_signals(obj, false)` + `await assert_signal(obj).is_emitted("name", [args])`) is essential for our event-bus-heavy architecture, and gdUnit4's pattern is well-documented.
- **Static-typing-friendly:** test fixtures can declare typed params and return types without fighting framework macros.

GUT is also fine in absolute terms — the decision is to commit, not to evaluate which is "best."

## Consequences

- Test suites live in `tests/` with the `extends GdUnitTestSuite` base class.
- Runner is `./tests/run.sh [test_path]` — wraps `godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a "res://<path>" --ignoreHeadlessMode`.
- `auto_free()` for node lifecycle; `add_child(auto_free(x))` when tree state matters.
- Drop `--headless` (use windowed mode) when the test needs real Area2D body/area signals, Tweens, input events, or anything time/render-driven (project memory `godot_tests_windowed_mode`).
- Autoload state persists across tests in the same process — fixture discipline (`Game.start_run()` in `before_test()`, manual signal disconnects) is required to avoid cross-test pollution.
- gdUnit4 addon files live under `addons/gdUnit4/` and are gitignored at the test-fixture level via `.gdignore` to keep their internal `class_name`s from colliding with project class_names (project memory `gdunit4_player_collision`).
