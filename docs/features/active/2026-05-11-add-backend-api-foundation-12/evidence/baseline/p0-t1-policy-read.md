# Phase 0 — Policy Read Evidence

Timestamp: 2026-05-12T11-00

Policy Order:
1. `.claude/rules/general-code-change.md`
2. `.claude/rules/general-unit-test.md`
3. `.claude/rules/csharp.md`
4. `.claude/rules/architecture-boundaries.md`
5. `.claude/rules/quality-tiers.md`

## Files Read

- [x] `.claude/rules/general-code-change.md` — Cross-language code change policy. Key constraints: simplicity first, 500-line limit, no DateTime.UtcNow/Now, no banned APIs, mandatory toolchain loop (format → lint → type-check → arch → unit → contract → integration).
- [x] `.claude/rules/general-unit-test.md` — Unit test policy. Key constraints: independence, isolation, fast, deterministic, readable. Coverage >= 85% line / >= 75% branch uniform across all tiers. No temp files in tests. FakeTimeProvider for clock injection.
- [x] `.claude/rules/csharp.md` — C# standards. CSharpier for formatting, xUnit + NSubstitute + FluentAssertions for tests, TimeProvider injection, file-scoped namespaces required, TreatWarningsAsErrors=true, AnalysisMode=All. Banned: DateTime.Now, DateTime.UtcNow, Random.Shared, Thread.Sleep, Task.Delay (in prod). CsCheck property tests required for T1/T2 pure functions.
- [x] `.claude/rules/architecture-boundaries.md` — No-COM architecture. TaskMaster.Application may depend on TaskMaster.Domain only. No VSTO/COM/Outlook Interop references. Adapter projects may depend on Domain and Application; Domain must not depend on adapters.
- [x] `.claude/rules/quality-tiers.md` — T1-T4 tier system. Line coverage >= 85% and branch coverage >= 75% uniform across all tiers. Property tests required for T1/T2. TaskMaster.Application = T2, TaskMaster.Infrastructure = T3.

## Status: COMPLETE
All five policy files read and confirmed. All work in this feature must comply with the above policies.
