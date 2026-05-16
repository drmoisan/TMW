---
Timestamp: 2026-05-16T01-40
Policy Order:
  1. .claude/rules/general-code-change.md
  2. .claude/rules/general-unit-test.md
  3. .claude/rules/quality-tiers.md
  4. .claude/rules/csharp.md
  5. .claude/rules/architecture-boundaries.md
---

## Files Read

1. `.claude/rules/general-code-change.md` — cross-language code change policy (design principles, module rigor tiers, mandatory toolchain loop, file size limits, error handling, naming, public APIs, dependencies, I/O boundaries).
2. `.claude/rules/general-unit-test.md` — cross-language unit test policy (independence, isolation, determinism, coverage >= 85% line / >= 75% branch, scenario completeness, AAA structure, no temp files, no external services).
3. `.claude/rules/quality-tiers.md` — T1–T4 tier system; uniform coverage thresholds (line >= 85%, branch >= 75%) across all tiers; tier-dependent gates (property tests, mutation score, contract checks, etc.).
4. `.claude/rules/csharp.md` — CSharpier formatting, .NET analyzers (TreatWarningsAsErrors), nullable analysis, xUnit + NSubstitute + FluentAssertions testing, banned APIs (DateTime.Now/UtcNow, Random.Shared, Thread.Sleep, Task.Delay), TimeProvider/FakeTimeProvider, no-temp-file rule in tests, DI seam preferences.
5. `.claude/rules/architecture-boundaries.md` — No-COM architecture rules; .NET layer boundary assertions (Domain → Application only, adapters may depend on Domain/Application, domain must not depend on adapters); NetArchTest.Rules enforcement.

## Summary

All five required policy files read in order. Key constraints for this remediation:
- CSharpier auto-format before lint/build/test.
- `dotnet build` with `TreatWarningsAsErrors=true` — zero warnings required.
- No temp files in tests (plan note 3 addresses `Path.GetTempFileName` concern — use `InternalsVisibleTo` approach or process-based integration tests for SchemaDiffBreakingChangeTests).
- Branch coverage for `TaskMaster.Infrastructure.Tests` must exceed 36.11% post-remediation.
- File-scoped namespaces required.
- `FakeTimeProvider` for clock seams; `NSubstitute` for mocks.
