# Phase 0 — Policy Read Evidence (Issue #45)

Timestamp: 2026-06-01T14-22

Policy Order: per `.claude/skills/policy-compliance-order/SKILL.md`

Files read (in required order):

1. `CLAUDE.md` (standing instructions, auto-loaded into context)
2. `.claude/rules/general-code-change.md` (cross-language code change policy)
3. `.claude/rules/general-unit-test.md` (cross-language unit test policy)
4. `.claude/rules/powershell.md` (PowerShell-specific toolchain and coding standards)
5. `.claude/rules/quality-tiers.md` (module rigor tiers; uniform coverage thresholds)
6. `.claude/rules/tonality.md` (required professional tone)
7. `.claude/skills/evidence-and-timestamp-conventions/SKILL.md` (canonical evidence paths and timestamp format)

Supporting references read for this execution:

- `.claude/rules/benchmark-baselines.md`
- `.claude/rules/ci-workflows.md`
- `.claude/skills/atomic-plan-contract/SKILL.md`
- `.claude/skills/acceptance-criteria-tracking/SKILL.md`
- Feature spec (AC source): `docs/features/active/2026-06-01-autonomous-execution-human-runbooks-45/spec.md`
- Approved plan: `docs/features/active/2026-06-01-autonomous-execution-human-runbooks-45/plan.2026-06-01T14-22.md`

Key constraints carried into execution:

- 500-line file cap per production/test/script file.
- PowerShell per-batch cap: <= 3 production + <= 3 test files.
- PowerShell toolchain order: format -> analyze -> test; restart from format on any change/failure.
- Coverage thresholds (uniform T1-T4): line >= 85%, branch >= 75%; no regression on changed lines.
- Hooks must remain dot-sourceable (entrypoint guard `if ($MyInvocation.InvocationName -eq '.') { return }`) and deterministic (no temp files; injectable scriptblock seams).
- Schema root `additionalProperties: true` preserved; exception invariant mirrors the existing `$defs.cycle` `allOf`/`if`/`then` style.
- Do NOT modify `.github/workflows/**` or `.claude/settings.json`; do NOT touch the iFile feature folder.
- Evidence only under `docs/features/active/2026-06-01-autonomous-execution-human-runbooks-45/evidence/<kind>/`.
