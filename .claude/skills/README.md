# Vendored skills

These 15 skills are vendored from **[obra/superpowers](https://github.com/obra/superpowers)** (MIT-licensed, Jesse Vincent). See `LICENSE-superpowers` for the full license.

We're vendoring (not installing via plugin marketplace) so the skill set travels with the repo — every collaborator and CI run gets the same skills without an install step.

## What's here

- `using-superpowers/` — entry point; tells agents how to discover and use the rest
- `brainstorming/` — turn ideas into approved designs before code (hard gate)
- `writing-plans/` — turn an approved design into a step-by-step implementation plan
- `executing-plans/` — work through a plan with review checkpoints
- `subagent-driven-development/` — run plan steps via subagents for context isolation
- `dispatching-parallel-agents/` — fan out independent tasks across agents
- `test-driven-development/` — red-green-refactor enforced
- `systematic-debugging/` — structured approach to any bug or unexpected behavior
- `verification-before-completion/` — run and confirm before claiming done
- `requesting-code-review/` — invoke a review pass before merge
- `receiving-code-review/` — process review feedback with rigor, not deference
- `using-git-worktrees/` — isolated workspaces for parallel features
- `finishing-a-development-branch/` — structured merge / PR / cleanup options
- `iterative-research/` — three-round deepening WebSearch for open-ended research
- `writing-skills/` — meta-skill for creating new skills

## Updating

Re-vendor with:

```bash
cp -r ~/repositories/superpowers/skills/. .claude/skills/
```

(assuming `~/repositories/superpowers/` is kept in sync via `git pull`)
