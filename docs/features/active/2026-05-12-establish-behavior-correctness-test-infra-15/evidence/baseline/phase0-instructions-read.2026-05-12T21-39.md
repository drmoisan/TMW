---
Timestamp: 2026-05-12T21-39
Policy Order:
  1. .claude/rules/general-code-change.md
  2. .claude/rules/general-unit-test.md
  3. .claude/rules/typescript.md
  4. .claude/rules/typescript-suppressions.md
  5. .claude/rules/csharp.md
  6. .claude/rules/quality-tiers.md
  7. .claude/rules/architecture-boundaries.md
---

# Phase 0 — Policy Files Read

All seven required policy files were read in the order specified by the plan.

## Files Read

1. `.claude/rules/general-code-change.md` — Cross-language code change policy (design principles, toolchain loop, file size limits, error handling, naming, dependencies).
2. `.claude/rules/general-unit-test.md` — Cross-language unit test policy (independence, isolation, fast execution, determinism, readability; coverage >= 85% line / >= 75% branch).
3. `.claude/rules/typescript.md` — TypeScript-specific toolchain (Prettier, ESLint, TSC, Vitest); coding standards; ESLint stack; property-based and mutation testing; golden tests; runtime determinism.
4. `.claude/rules/typescript-suppressions.md` — Pre-authorized suppression patterns; explicitly prohibited patterns (`eslint-disable`, `@ts-ignore`, `@ts-nocheck`).
5. `.claude/rules/csharp.md` — C#-specific toolchain (CSharpier, .NET analyzers, nullable, xUnit); analyzer stack; banned APIs (`DateTime.Now`, `DateTime.UtcNow`, `Random.Shared`, `Thread.Sleep`, `Task.Delay`); DI seams; prohibited behaviors.
6. `.claude/rules/quality-tiers.md` — T1–T4 tier definitions; uniform gate matrix (line >= 85%, branch >= 75%); tier-dependent gates (property tests, mutation score, golden tests).
7. `.claude/rules/architecture-boundaries.md` — No-COM architecture assertions; layer boundary rules for TypeScript and .NET; enforcement via dependency-cruiser and NetArchTest.Rules.

## Key Constraints Noted

- Line coverage >= 85%, branch coverage >= 75% — uniform across all tiers.
- No temporary files in tests.
- File size limit: 500 lines (production + test code).
- No new runtime dependencies without approval.
- Stryker.NET mutation >= 75% for T1 modules.
- CSharpier formatting required; `dotnet format` prohibited.
- File-scoped namespaces required in C#.
- `fast-check` + `@fast-check/vitest` for TypeScript property tests (T1/T2 modules).
