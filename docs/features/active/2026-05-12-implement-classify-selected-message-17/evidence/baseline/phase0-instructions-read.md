---
Timestamp: 2026-05-12T00-38
Policy Order:
  1. .claude/rules/general-code-change.md
  2. .claude/rules/general-unit-test.md
  3. .claude/rules/csharp.md
  4. .claude/rules/typescript.md
  5. .claude/rules/typescript-suppressions.md
  6. .claude/rules/architecture-boundaries.md
  7. .claude/rules/quality-tiers.md
---

## Files Read

1. `.claude/rules/general-code-change.md` — Cross-language code change policy (design principles, module rigor tiers, toolchain loop, file size limit, error handling, naming, public APIs, dependencies, I/O boundaries)
2. `.claude/rules/general-unit-test.md` — Cross-language unit test policy (core principles, coverage requirements >= 85% line / >= 75% branch, scenario completeness, AAA structure, external dependencies, determinism infrastructure)
3. `.claude/rules/csharp.md` — C#-specific toolchain and coding standards (CSharpier formatting, .NET analyzers, nullable analysis, xUnit + NSubstitute + FluentAssertions, TimeProvider, banned APIs, DI seams)
4. `.claude/rules/typescript.md` — TypeScript-specific toolchain and coding standards (Prettier, ESLint, TSC, Vitest, strong typing, ES modules, property-based testing with fast-check)
5. `.claude/rules/typescript-suppressions.md` — Pre-authorized ESLint and TypeScript suppression patterns (single-rule single-line disable, ts-expect-error, prohibited patterns)
6. `.claude/rules/architecture-boundaries.md` — Architecture boundary enforcement (No-COM assertions, layer boundary assertions for TypeScript and .NET, dependency-cruiser and NetArchTest.Rules enforcement)
7. `.claude/rules/quality-tiers.md` — Module rigor tier system T1–T4, uniform coverage thresholds, tier-dependent gate matrix
