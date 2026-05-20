---
name: project-bundle-mirror-map
description: TMW repo does not maintain a uniform .claude bundle mirror set; which mirrors exist must be probed per file
metadata:
  type: project
---

TMW does not maintain a uniform `.claude/` -> `.codex/`/`.agents/`/`.github/` bundle mirror set. Which mirror exists must be probed per changed file before syncing.

Observed mirror facts (verified 2026-05-19, branch feature/orchestration-missing-ci-green-gate-26):
- `.agents/skills/orchestrate/SKILL.md` EXISTS; `.agents/skills/feature-review-workflow/SKILL.md` EXISTS.
- `.github/skills/feature-review-workflow/SKILL.md` EXISTS; there is NO `.github/skills/orchestrate`.
- `.codex/` has no `skills/` and no `rules/` tree (only `prompts/`, `agents/`, `hooks/`, plan files).
- `.agents/` has `skills/` but NO `rules/` tree.
- `.github/` has `skills/` (partial coverage) and `instructions/*.instructions.md`, but NO `rules/` tree.
- `.github/workflows/` has no bundled mirror at all.
- New `.claude/rules/*.md` files therefore have NO mirror target anywhere.

**Why:** A planner/executor that assumes a 1:1 mirror set will either invent non-existent mirror targets or miss real ones. This caused the Phase 6 mirror-sync tasks for issue #26 to require an explicit per-file probe (P6-T2) rather than a uniform copy.

**How to apply:** When a feature changes any `.claude/` file, run a Test-Path probe across `.agents/`, `.codex/`, `.github/` for that exact relative path. Sync only mirrors that exist; record `NO <root> MIRROR` for the rest. Verify parity by sha256. See [[project-bundle-mirror-map]] in the atomic-planner memory for the same map.
