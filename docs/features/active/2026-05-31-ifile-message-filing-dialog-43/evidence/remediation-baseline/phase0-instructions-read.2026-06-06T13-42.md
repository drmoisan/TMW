# Phase 0 — Policy Read Evidence — iFile #43 Cycle 4

Timestamp: 2026-06-06T13-42

Policy Order:
1. CLAUDE.md (standing instructions, always loaded)
2. .claude/rules/general-code-change.md (cross-language code change policy)
3. .claude/rules/general-unit-test.md (cross-language unit test policy)
4. .claude/rules/quality-tiers.md (module rigor tier system)
5. Language/domain-specific rules (TypeScript in scope):
   - .claude/rules/typescript.md
   - .claude/rules/typescript-suppressions.md
   - .claude/rules/architecture-boundaries.md
   - .claude/rules/benchmark-baselines.md
   - .claude/rules/tonality.md

Files Read:
- CLAUDE.md
- .claude/rules/general-code-change.md
- .claude/rules/general-unit-test.md
- .claude/rules/quality-tiers.md
- .claude/rules/typescript.md
- .claude/rules/typescript-suppressions.md
- .claude/rules/architecture-boundaries.md
- .claude/rules/benchmark-baselines.md
- .claude/rules/tonality.md

Output Summary: All nine policy files were read in the required order prior to execution.
TypeScript is the only production language in scope. Key applicable constraints: full
seven-stage TypeScript toolchain (format, lint, typecheck, dependency-cruiser including the
MSAL import-boundary rule, vitest+coverage, manifest validate/validate:xml); line coverage
>= 85% and branch coverage >= 75% with no regression on changed lines; the
`@azure/msal-browser` import boundary is restricted to `naa-token-acquirer.ts`; no secret
value may enter the repository; professional tone for all written output.
