# Bundled Mirror Inventory

Timestamp: 2026-05-18T22-05
Command: Get-ChildItem -Recurse -File .codex,.agents,.github | Where-Object Name -match 'quality-tiers|general-code-change|benchmark|pr-pipeline'
EXIT_CODE: 0
Output Summary: Mirror inventory below.

## .codex/
- No directory found (Get-ChildItem -ErrorAction SilentlyContinue returned no results for `.codex`).

## .agents/
- No directory found (Get-ChildItem -ErrorAction SilentlyContinue returned no results for `.agents`).

## .github/
Discovered:
- `.github/instructions/general-code-change.instructions.md` (12243 bytes) — bundled mirror of `.claude/rules/general-code-change.md`. Frontmatter `applyTo: "**"` + `name: general-code-change-policy`. Must be resynced in P5-T2.
- `.github/instructions/quality-tiers.instructions.md` (2924 bytes) — bundled mirror of `.claude/rules/quality-tiers.md`. Frontmatter `applyTo: "**"` + `name: quality-tiers-policy`. Must be resynced in P5-T1.
- `.github/scripts/validate-quality-tiers.ps1` (3586 bytes) — validator script, NOT a content mirror of the rule file; out of scope for resync.
- `.github/workflows/_benchmark-gate-self-validation.yml` (1626 bytes) — the live workflow file itself; will be deleted in P1-T2 (not a mirror).
- `.github/workflows/_stage-10-benchmark-regression.yml` (1596 bytes) — the live workflow file itself; will be deleted in P1-T1.
- `.github/workflows/benchmark-baseline-refresh.yml` (2672 bytes) — the live workflow file itself; will be deleted in P1-T3.
- `.github/workflows/pr-pipeline.yml` (2042 bytes) — the live workflow file itself; will be edited in P4-T1 (not a mirror).

## Mapping to P5 tasks
- P5-T1 (`.claude/rules/quality-tiers.md`): mirror exists at `.github/instructions/quality-tiers.instructions.md` — RESYNC REQUIRED.
- P5-T2 (`.claude/rules/general-code-change.md`): mirror exists at `.github/instructions/general-code-change.instructions.md` — RESYNC REQUIRED.
- P5-T3 (`.github/workflows/pr-pipeline.yml`): no mirror discovered — record "no mirror to resync" in P5-T3.
- P5-T4 (deleted workflows): no bundled mirrors discovered for any of the three deleted workflow files — record "no mirror to delete" in P5-T4.
