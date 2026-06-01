# Phase 0 — Policy Read Evidence (Issue #43)

Timestamp: 2026-06-01T00-00

Policy Order:
1. CLAUDE.md (standing instructions, auto-loaded)
2. .claude/rules/general-code-change.md (cross-language code change policy)
3. .claude/rules/general-unit-test.md (cross-language unit test policy)
4. .claude/rules/quality-tiers.md (module rigor tiers T1–T4)
5. .claude/rules/architecture-boundaries.md (No-COM architecture boundaries)
6. .claude/rules/typescript.md (TypeScript toolchain + standards)
7. .claude/rules/typescript-suppressions.md (TS/ESLint suppression policy)
8. .claude/rules/csharp.md (C# toolchain + standards)
9. .claude/rules/tonality.md (professional-tone policy)

Files Read (explicit list):
- CLAUDE.md (loaded via context; benchmark-baselines, ci-workflows, general-code-change, general-unit-test, quality-tiers, tonality)
- .claude/rules/general-code-change.md
- .claude/rules/general-unit-test.md
- .claude/rules/quality-tiers.md
- .claude/rules/architecture-boundaries.md
- .claude/rules/typescript.md
- .claude/rules/typescript-suppressions.md
- .claude/rules/csharp.md
- .claude/rules/tonality.md

Output Summary: All nine policy files read in required order prior to executing [P0-T1]. Key constraints captured: seven-stage toolchain loop (format → lint → type-check → arch → unit/property → contract → integration), 500-line file cap, uniform coverage (line >= 85%, branch >= 75%, no regression on changed lines), No-COM boundaries (privileged Graph/OneDrive ops server-side; pure host-neutral TS modules client-side), >= 1 property-based test per pure function on T1/T2, contract tests at Office.js + Graph boundaries, generated src/api-client/v1.ts only via npm run generate:api, TS suppression policy (single-line authorized patterns only), CSharpier (no dotnet format), Directory.Build.props centralizes TreatWarningsAsErrors.
