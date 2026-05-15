# Phase 0 — Instructions Read Evidence

Timestamp: 2026-05-14T22-05

Policy Order: The repository policy reading order defined in the `policy-compliance-order` skill was followed:
1. `CLAUDE.md` (standing instructions, auto-loaded)
2. `.claude/rules/general-code-change.md` (cross-language code change policy)
3. `.claude/rules/general-unit-test.md` (cross-language unit test policy)
4. Language- and domain-specific rules for files in scope (C#, TypeScript, architecture).

## Files Read

Repository policy files:
- `CLAUDE.md` (auto-loaded standing instructions)
- `.claude/rules/general-code-change.md`
- `.claude/rules/general-unit-test.md`
- `.claude/rules/quality-tiers.md`
- `.claude/rules/tonality.md`
- `.claude/rules/csharp.md`
- `.claude/rules/typescript.md`
- `.claude/rules/typescript-suppressions.md`
- `.claude/rules/architecture-boundaries.md`

Skills:
- `.claude/skills/policy-compliance-order/SKILL.md`
- `.claude/skills/atomic-plan-contract/SKILL.md`
- `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`
- `.claude/skills/acceptance-criteria-tracking/SKILL.md`

## Key Constraints Acknowledged

- Mandatory seven-stage toolchain loop (format, lint, type-check, architecture, unit, contract, integration); restart on any failure or auto-fix.
- 500-line file size limit for production, test, and reusable script files.
- Coverage thresholds: line >= 85%, branch >= 75% uniform across tiers; no regression on changed lines.
- Evidence artifacts written only to `<FEATURE>/evidence/<kind>/` canonical paths.
- `artifacts/openapi/current.json` is a product artifact, not evidence.
- Professional tone; no policy-document edits; no secrets/.env files.
