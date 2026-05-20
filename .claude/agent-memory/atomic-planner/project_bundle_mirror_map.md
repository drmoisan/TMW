---
name: project-bundle-mirror-map
description: TMW bundle-mirror layout for .claude/ files is non-uniform; .codex/ has no skills/rules, .agents/ has skills but no rules, .github/ uses instructions/ naming and partial skills coverage.
metadata:
  type: project
---

When planning mirror-sync work for `.claude/skills/**` or `.claude/rules/**` changes in TMW, the mirror map is NOT uniform across roots. Verified by repo inspection 2026-05-19:

- `.codex/` contains only `prompts/` and a plan file. No `.codex/skills/`, no `.codex/rules/`.
- `.agents/` contains `skills/**` (e.g. `.agents/skills/orchestrate/SKILL.md`, `.agents/skills/feature-review-workflow/SKILL.md`) but NO `.agents/rules/`.
- `.github/` exposes `skills/` with PARTIAL coverage (e.g. `.github/skills/feature-review-workflow/SKILL.md` exists; `.github/skills/orchestrate/` does NOT) and uses `instructions/*.instructions.md` naming rather than a 1:1 `rules/` mirror.
- New `.claude/rules/*.md` files have no `.agents/rules/`, `.codex/rules/`, or 1:1 `.github/rules/` target.
- No python or Pester mirror/bundle contract test suite exists in `tests/` that pins these mirrors.

**Why:** A plan can over-specify mirror-sync tasks by assuming a fixed `.codex` + `.agents` + `.github` mirror set plus contract tests, none of which uniformly exist. Complements [[project_no_bundled_workflow_mirrors]] (which covers `.github/workflows/` specifically).

**How to apply:** Mirror-sync plan tasks MUST first probe the actual bundle layout per changed file and only edit mirrors that exist; record EXISTS/ABSENT per file. Do not require pytest/Pester mirror-contract gates unless one is discovered to exist. Re-verify before acting — bundle layout can change.
