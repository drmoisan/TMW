# Issue #7 — Prompt C1: Establish .NET Foundation

- Work Mode: full-feature
- Issue: https://github.com/drmoisan/TMW/issues/7
- Source Prompt: Prompt C1 — Establish .NET Foundation

## Goal

Stand up the .NET CI toolchain and update the C# rule baseline before any backend code is written. Two tightly coupled phases:

1. Update C# rule and instruction files to reflect No-COM .NET toolchain decisions (xUnit, NSubstitute, dotnet build, analyzer stack, TimeProvider, BannedSymbols, uniform coverage thresholds).
2. Install the .NET CI infrastructure that depends on those rules (Directory.Build.props, Directory.Packages.props, analyzer references, BannedSymbols.txt, CSharpier, xUnit/FluentAssertions/NSubstitute, *.ArchitectureTests with NetArchTest.Rules, WireMock.Net, Testcontainers, TimeProvider.Testing, NSwag, PR pipeline stages 1-5).

## Read First

- `.claude/rules/csharp.md`
- `.github/instructions/csharp-code-change.instructions.md`
- `.github/instructions/csharp-unit-test.instructions.md`
- Existing `.editorconfig`, if any
- `quality-tiers.yml`
- `.claude/rules/quality-tiers.md` and `.claude/rules/architecture-boundaries.md`

## Authoritative Decisions Carried Forward

1. Python formatting remains Black.
2. Coverage thresholds are uniform across all tiers (T1-T4): line >= 85%, branch >= 75%.

## Phase 1: C# Rule Baseline Updates

Update `.claude/rules/csharp.md`, `.github/instructions/csharp-code-change.instructions.md`, `.github/instructions/csharp-unit-test.instructions.md`:

- Replace MSTest with xUnit; `[TestClass]`/`[TestMethod]` -> `[Fact]`/`[Theory]`; `vstest.console.exe` -> `dotnet test`.
- Replace Moq with NSubstitute.
- Replace `msbuild TaskMaster.sln /t:Build ...` with `dotnet build`; remove `EnableNETAnalyzers`/`EnforceCodeStyleInBuild` properties (now in Directory.Build.props as `AnalysisLevel=latest-all`, `AnalysisMode=All`, `TreatWarningsAsErrors=true`, `Nullable=enable`).
- Add Analyzer Stack section: Meziantou.Analyzer, SonarAnalyzer.CSharp, Roslynator.Analyzers, AsyncFixer, SecurityCodeScan.VS2019, Microsoft.CodeAnalysis.BannedApiAnalyzers (all `PrivateAssets="all"`).
- Update DI Seams: add `TimeProvider` (with `Microsoft.Extensions.TimeProvider.Testing`) as preferred clock seam; `IClock` legacy/pre-.NET 8 only.
- Add Banned APIs section referencing `BannedSymbols.txt`: ban `DateTime.Now`, `DateTime.UtcNow`, `Random.Shared`, `Thread.Sleep`, `Task.Delay` outside allowlist.
- Replace coverage rule with uniform tier rule: line >= 85%, branch >= 75% all tiers; mutation >= 75% on T1.
- Add Property-based and mutation testing subsection: `CsCheck` (>= 1 per pure function T1/T2), `Stryker.NET` (T1).
- Add Golden tests subsection: `Verify.Xunit` for T1 classifier snapshots.
- Update fixture/parameterization guidance: `[Theory]` + `[InlineData]`; `IClassFixture<T>` for shared setup.

### Operational artifact updates

- `.claude/agents/csharp-typed-engineer.md`: frontmatter description MSTest -> xUnit; role/plan/QA bullets xUnit + NSubstitute; msbuild prose -> `dotnet build`.
- `.claude/skills/csharp-qa-gate/SKILL.md`: replace msbuild lines (build via `dotnet build`; nullable/warnings-as-errors moved into Directory.Build.props); replace vstest with `dotnet test --collect:"XPlat Code Coverage"`; MSTest -> xUnit; add architecture-tests run step.
- `.claude/skills/invoke-csharp-engineer/SKILL.md`: frontmatter + steps: `CSharpier -> .NET Analyzers -> Nullable Analysis -> xUnit`.
- `.claude/skills/feature-review-workflow/SKILL.md`: C# coverage command -> `dotnet test --collect:"XPlat Code Coverage"`.
- `.github/agents/csharp-typed-engineer.agent.md`: MSTest -> xUnit; Moq -> NSubstitute; example snippets updated.

Mirror discipline: any matching `.github/skills/` mirrors receive equivalent updates.

## Phase 2: .NET CI Infrastructure

- Solution-level `Directory.Build.props`: `<Nullable>enable</Nullable>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, `<AnalysisLevel>latest-all</AnalysisLevel>`, `<AnalysisMode>All</AnalysisMode>` for T1/T2.
- `Directory.Packages.props` central package management pinning analyzer + test versions.
- Analyzer stack via `<PackageReference>` with `PrivateAssets="all"`.
- `BannedSymbols.txt` bans `DateTime.Now`, `DateTime.UtcNow`, `Random.Shared`, `Thread.Sleep`, `Task.Delay` outside allowlist.
- CSharpier as local tool; `.editorconfig` covers naming, file-scoped namespaces, using-directive ordering.
- xUnit, FluentAssertions, NSubstitute referenced for test SDK.
- `*.ArchitectureTests` project with NetArchTest.Rules: no `Microsoft.Office.Interop.Outlook`; no `System.Windows.Forms`/`System.Web`/`Microsoft.VisualBasic`; domain projects do not depend on infrastructure.
- WireMock.Net for Graph stubs; Testcontainers; `Microsoft.AspNetCore.Mvc.Testing`.
- `Microsoft.Extensions.TimeProvider.Testing` referenced.
- NSwag emits OpenAPI to `artifacts/openapi/current.json`.
- PR pipeline stages 1-5 extended with .NET solution; `dotnet csharpier check`, `dotnet build`, `dotnet test`, architecture tests all gate the PR.
- All gates pass on empty solution skeleton.

## Validation

### Phase 1
- The grep pattern over the listed files returns no matches in active text.
- C# rule files reference the analyzer stack, `TimeProvider`, uniform tier coverage, `CsCheck`, `Stryker.NET`, `Verify.Xunit`.
- csharp-qa-gate skill issues `dotnet build` and `dotnet test --collect:"XPlat Code Coverage"`.
- Mirror discipline confirmed.

### Phase 2
- `dotnet build` succeeds with zero warnings.
- `dotnet csharpier check .`, `dotnet test`, architecture tests all pass.
- Representative violations (banned API, architecture rule, analyzer rule) detected and block build.

## Acceptance Criteria

1. `.claude/rules/csharp.md` contains no MSTest, Moq, TaskMaster.sln, or vstest.console references in active text.
2. `.claude/rules/csharp.md` includes an Analyzer Stack section listing the six required packages with `PrivateAssets="all"`.
3. `.claude/rules/csharp.md` DI Seams section names `TimeProvider` as preferred and `Microsoft.Extensions.TimeProvider.Testing` for tests; `IClock` marked legacy.
4. `.claude/rules/csharp.md` has a Banned APIs section referencing `BannedSymbols.txt`.
5. `.claude/rules/csharp.md` coverage rule states line >= 85% and branch >= 75% uniform across tiers; mutation >= 75% on T1.
6. `.claude/rules/csharp.md` includes Property-based and mutation testing subsection naming CsCheck and Stryker.NET.
7. `.claude/rules/csharp.md` includes Golden tests subsection naming `Verify.Xunit`.
8. `.github/instructions/csharp-code-change.instructions.md` mirrors all `.claude/rules/csharp.md` changes.
9. `.github/instructions/csharp-unit-test.instructions.md` references xUnit, `[Fact]`/`[Theory]`, `[InlineData]`, `IClassFixture<T>`, NSubstitute.
10. `.claude/agents/csharp-typed-engineer.md` frontmatter description says "xUnit toolchain"; body references xUnit + NSubstitute + `dotnet build`.
11. `.claude/skills/csharp-qa-gate/SKILL.md` toolchain command list uses `dotnet build` and `dotnet test --collect:"XPlat Code Coverage"`; includes architecture-tests run step.
12. `.claude/skills/invoke-csharp-engineer/SKILL.md` toolchain reads `CSharpier -> .NET Analyzers -> Nullable Analysis -> xUnit` everywhere.
13. `.claude/skills/feature-review-workflow/SKILL.md` C# coverage line uses `dotnet test --collect:"XPlat Code Coverage"`.
14. `.github/agents/csharp-typed-engineer.agent.md` replaces all MSTest with xUnit and all Moq with NSubstitute.
15. `Directory.Build.props` at solution root enables nullable, TreatWarningsAsErrors, AnalysisLevel=latest-all, AnalysisMode=All for T1/T2 projects.
16. `Directory.Packages.props` exists with central package management and pins analyzer versions.
17. Six analyzer packages referenced with `PrivateAssets="all"`.
18. `BannedSymbols.txt` exists and bans the five APIs.
19. CSharpier installed as local tool; `.editorconfig` covers naming, file-scoped namespaces, using-directive ordering.
20. xUnit + FluentAssertions + NSubstitute referenced.
21. `*.ArchitectureTests` project with NetArchTest.Rules and the three rule categories exists.
22. WireMock.Net, Testcontainers, `Microsoft.AspNetCore.Mvc.Testing` referenced.
23. `Microsoft.Extensions.TimeProvider.Testing` referenced.
24. NSwag wired to emit `artifacts/openapi/current.json`.
25. PR pipeline workflow extended with .NET stages 1-5 (csharpier check, dotnet build, dotnet test, architecture tests).
26. All gates pass on empty solution skeleton (CI green).
27. Representative banned-API violation blocks the build (evidence captured).
28. Representative architecture-rule violation blocks the build (evidence captured).
29. Representative analyzer-rule violation blocks the build (evidence captured).
30. `quality-tiers.yml` updated to register the new .NET solution projects with appropriate tier classifications.
