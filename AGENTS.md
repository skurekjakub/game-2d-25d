# AGENTS.md

Contract for AI coding agents working in this repository. Engine-agnostic — engine choice is still open (see `docs/decisions/0001-engine-choice.md`).

This file is the source of truth. `CLAUDE.md` points here. Tools like Codex, Cursor, Windsurf, and Aider also read `AGENTS.md`.

## Project

A 2D / 2.5D isometric (or top-down) game built in **Godot 4.x**. Desktop-first; mobile (iOS/Android) is a possible future target — design choices should not actively close that door (see "Future-target constraints" in `docs/architecture.md`). Engine rationale: `docs/decisions/0001-engine-choice.md`. Engine conventions: Godot addendum at the bottom of `docs/architecture.md`.

## How agents should work here

1. **Read before writing.** Before modifying any system, read the related files and the architecture doc. Roughly 44% of agent errors come from misunderstanding repo-wide structure — `docs/architecture.md` exists to prevent that.
2. **One idiomatic way.** When the same task could be done with multiple patterns, pick the one already used in this repo. If nothing exists yet, pick the simplest and document it in `docs/architecture.md` so the next agent doesn't invent a second pattern.
3. **State is data, views are presentation.** Game state lives in plain data structures. Rendered nodes / entities / actors are views over that state. Cross-system communication goes through events or signals, never direct calls between sibling systems.
4. **Deterministic systems, pure functions.** Game logic should be testable without a running engine where possible. If a function depends on engine state, make that dependency an argument.
5. **No speculative abstraction.** Don't add layers, managers, or interfaces for hypothetical future engines. Three similar lines beats a premature abstraction.
6. **Verify integration, not just compilation.** Code that compiles can still be wrong. After non-trivial changes, run the game (or relevant scene/system) and confirm the change behaves correctly — say so explicitly. If you can't run it, say that explicitly instead of claiming success.
7. **Cite uncertainty.** If you guessed at a convention, name, or API, mark it in the response so the human can verify.
8. **Adversarial review before merge.** After completing any implementation task (especially TDD plan tasks), dispatch the `rubber-duk` subagent to review the change. Address its BLOCKER findings before committing; address IMPORTANTs unless you have a justified reason to defer. This is mandatory for subagent-driven plan execution.

## Style

- Terse responses. State results, not narration.
- Comments only when the *why* is non-obvious (a hidden constraint, a workaround, a subtle invariant). Don't describe what the code does — names do that.
- **No archaeology comments after refactors.** When you delete, move, or rename code, the new state stands alone. Do NOT write `# X was removed in Y`, `# moved to Z`, `# (was: ...)`, `# legacy path — see git log`, or any variant. The diff captures the change; the comment will rot. This is the highest-priority comment antipattern in this repo — flagged and enforced via hook, rubber-duk checklist, godot-implementer rules, and project memory `feedback_no_archaeology_comments`.
- No trailing summaries that just repeat the diff.

## Files

- `AGENTS.md` — this file. Universal agent contract.
- `CLAUDE.md` — thin pointer to this file for Claude Code.
- `docs/architecture.md` — universal architectural patterns + Godot addendum.
- `docs/decisions/` — Architecture Decision Records.
- `docs/design/` — design specs from the brainstorming skill (per-feature).
- `docs/plans/` — implementation plans from the writing-plans skill (per-milestone).
- `.claude/skills/` — vendored [Superpowers](https://github.com/obra/superpowers) skills (brainstorming, plans, TDD, review, debugging, research, etc.). See `.claude/skills/README.md`.
- `.claude/agents/` — project-local subagents. Currently: `rubber-duk` (adversarial Godot code reviewer; invoke after any code change, before commit / merge / milestone close).

## External references

- **Godot documentation, local clone:** `/home/jakub/repositories/godot-docs/` (sibling to this repo). Grep here BEFORE web-searching for any Godot API, node property, file format, or engine behavior question. It's the primary source for everything Godot. Cloned at Godot 4.6.2-stable; re-clone with `git clone --depth 1 https://github.com/godotengine/godot-docs.git` to refresh.
