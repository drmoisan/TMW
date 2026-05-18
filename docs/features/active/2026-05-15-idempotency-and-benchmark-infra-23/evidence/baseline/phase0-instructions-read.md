# Phase 0 — Policy Instructions Read

Timestamp: 2026-05-15T21-45
Policy Order:
1. CLAUDE.md (standing project instructions; auto-loaded)
2. .claude/rules/general-code-change.md
3. .claude/rules/general-unit-test.md
4. .claude/rules/quality-tiers.md
5. .claude/rules/csharp.md (language-specific, scope: **/*.cs, **/*.csproj)
6. .claude/rules/tonality.md

Files Read:
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-15-21-18\.claude\rules\general-code-change.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-15-21-18\.claude\rules\general-unit-test.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-15-21-18\.claude\rules\quality-tiers.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-15-21-18\.claude\rules\csharp.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-15-21-18\.claude\rules\tonality.md

Key constraints internalized:
- CSharpier is mandatory; `dotnet format` is prohibited.
- Coverage thresholds uniform across tiers: line >= 85%, branch >= 75%.
- TreatWarningsAsErrors is solution-wide; analyzer suppressions must be project-scoped with justification.
- Test code must use FakeTimeProvider; Thread.Sleep / Task.Delay / DateTime.UtcNow banned in tests.
- Central Package Management is active: new PackageReference entries must be versionless.
- Evidence path scheme is non-overridable: <FEATURE>/evidence/<kind>/.

EXIT_CODE: 0
Output Summary: All 5 policy files plus CLAUDE.md auto-context read; constraints recorded.
