# Spec — Prompt C1: Establish .NET Foundation (Issue #7)

This spec captures the design-level decisions and constraints for the .NET foundation. The authoritative requirements list is `issue.md`. This file expands the rationale and operational expectations the planner should encode as atomic tasks.

## Scope

Phase 1 — Rule baseline + operational artifact updates (documentation/tooling files):
- `.claude/rules/csharp.md`
- `.github/instructions/csharp-code-change.instructions.md`
- `.github/instructions/csharp-unit-test.instructions.md`
- `.claude/agents/csharp-typed-engineer.md`
- `.claude/skills/csharp-qa-gate/SKILL.md`
- `.claude/skills/invoke-csharp-engineer/SKILL.md`
- `.claude/skills/feature-review-workflow/SKILL.md`
- `.github/agents/csharp-typed-engineer.agent.md`
- Any `.github/skills/` mirrors of the modified `.claude/skills/` files

Phase 2 — .NET CI infrastructure (new files at solution root):
- `Directory.Build.props` (solution root)
- `Directory.Packages.props` (solution root)
- `BannedSymbols.txt` (solution root or analyzer-specific path)
- `.editorconfig` updates
- `.config/dotnet-tools.json` (CSharpier as local tool)
- An empty skeleton solution `TaskMaster.sln` with:
  - one placeholder library project (T2 or T1) to attach Directory.Build.props effects against
  - one `*.ArchitectureTests` xUnit project with NetArchTest.Rules
- Test SDK references: xUnit, FluentAssertions, NSubstitute, Microsoft.Extensions.TimeProvider.Testing, WireMock.Net, Testcontainers, Microsoft.AspNetCore.Mvc.Testing
- NSwag setup writing OpenAPI to `artifacts/openapi/current.json`
- PR pipeline workflow extensions (`.github/workflows/pr-pipeline.yml` or equivalent) adding .NET stages 1-5
- `quality-tiers.yml` updated to include the new projects

## Architectural Constraints

- No project depends on `Microsoft.Office.Interop.Outlook` (No-COM architecture).
- Forbidden namespaces: `System.Windows.Forms`, `System.Web`, `Microsoft.VisualBasic`.
- Domain projects MUST NOT depend on infrastructure projects.
- Coverage thresholds are uniform: line >= 85%, branch >= 75% across T1-T4.
- Mutation score >= 75% on T1 modules (via Stryker.NET).

## Analyzer Stack

All projects reference, via `<PackageReference>` with `PrivateAssets="all"`:
- `Meziantou.Analyzer`
- `SonarAnalyzer.CSharp`
- `Roslynator.Analyzers`
- `AsyncFixer`
- `SecurityCodeScan.VS2019`
- `Microsoft.CodeAnalysis.BannedApiAnalyzers`

## Banned APIs

`BannedSymbols.txt` bans the following outside an explicit allowlist:
- `T:System.DateTime.Now`
- `T:System.DateTime.UtcNow`
- `P:System.Random.Shared`
- `M:System.Threading.Thread.Sleep(System.Int32)`
- `M:System.Threading.Tasks.Task.Delay(System.Int32)`

Tests must inject `TimeProvider` (via `Microsoft.Extensions.TimeProvider.Testing`) rather than calling `DateTime.UtcNow` directly.

## DI Seams Update

- `TimeProvider` is the preferred clock seam for new code.
- `IClock` remains acceptable in legacy or pre-.NET 8 contexts only.
- Test code injects `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing`.

## Test Framework Migration

- xUnit replaces MSTest. `[Fact]` and `[Theory]` replace `[TestClass]`/`[TestMethod]`.
- NSubstitute replaces Moq. Example: `var sut = Substitute.For<IService>(); sut.Get().Returns(value);`.
- `[Theory]` + `[InlineData]` for parameterized tests.
- `IClassFixture<T>` for shared expensive setup.
- FluentAssertions retained for assertions.

## Property-Based, Mutation, and Golden Tests

- `CsCheck` for property tests: >= 1 per pure function on T1/T2 modules.
- `Stryker.NET` for mutation testing on T1 modules (>= 75% score).
- `Verify.Xunit` for golden tests on T1 classifier-output modules.

## PR Pipeline Stages (.NET extension)

Stages 1-5 must execute on every PR push for the .NET solution:
1. Format: `dotnet csharpier check .`
2. Lint: `dotnet build` (analyzers enforce; TreatWarningsAsErrors=true)
3. Type-check: nullable analysis enforced via `<Nullable>enable</Nullable>` in `Directory.Build.props`
4. Architecture tests: `dotnet test` against `*.ArchitectureTests` project
5. Unit tests: `dotnet test --collect:"XPlat Code Coverage"` against all test projects

## Validation Evidence

Phase 1 evidence: a captured grep run showing zero matches against forbidden tokens in the listed files.

Phase 2 evidence:
- CI run log showing all .NET stages green on empty skeleton
- Three demonstration runs showing representative violations (banned API, architecture rule, analyzer rule) each block the build

Evidence is written under `docs/features/active/2026-05-10-establish-dotnet-foundation-7/evidence/`.

## Non-Goals

- No production C# code beyond the empty solution skeleton and one architecture test project.
- No actual SpamBayes/Triage/ToDo domain modules — those arrive in later prompts.
- No Graph adapter implementation — only the WireMock.Net reference and infrastructure.
