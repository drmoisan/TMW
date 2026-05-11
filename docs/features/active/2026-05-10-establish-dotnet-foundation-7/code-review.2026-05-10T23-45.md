# Code Review — Issue #7 (Prompt C1 — Establish .NET Foundation) — Post-Remediation Re-Audit (Pass 2)

- Timestamp: 2026-05-10T23-45
- Base branch: `origin/main` @ merge-base `01d399c6`
- HEAD: `f6118ef5f47224aa8327b23e891ef23c68e5c4f4`
- Scope: full branch diff vs `origin/main`; particular emphasis on remediation patch (Phase R0-R6, timestamp `2026-05-10T22-30`).
- Prior-pass artifact: `code-review.2026-05-10T22-30.md`.

## Executive Summary

The remediation work removed both pass-1 blockers and both pass-1 major findings. A new xUnit test project `tests/TaskMaster.Api.Tests` exercises every new production code file (`Program.cs`, `HealthResponse.cs`, `AssemblyMarker.cs`); the canonical C# coverage artifact `artifacts/csharp/coverage.xml` is emitted by an extended `dotnet-test` composite action and the local QA-gate skill; the NSwag emission target is now property-gated and loud-fails when invoked (silent suppression attributes removed); and a deterministic Domain→Infrastructure probe demonstrates the `DomainProjectDoesNotDependOnInfrastructure` architecture fact fires on a real typed violation. The final single-pass QA loop (PR5-T1..T6) exits 0 across format, build, type-check, architecture, unit tests, and canonical coverage emission. Tests: 11/11 pass (3 architecture + 8 API).

Code added during remediation is small, idiomatic, well-isolated to the test project, and follows the rule files. The csproj edits are minimal and surgical. Probe artifacts have been removed cleanly (PR4-T5/PR4-T6). The minor / info items deferred under PR6-T1 remain present (redundant `<ImplicitUsings>`, empty `stage-3-dotnet-typecheck`, `--no-build` flag, narrative `T:`/`P:` mismatch), but are tracked and defer-acceptable.

## Findings Table (Pass 2)

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| (none) | — | — | No new findings. | — | — | — |

### Disposition of Pass-1 Findings

| Pass-1 Severity | Pass-1 File / Location | Pass-1 Finding | Pass-2 Disposition |
|---|---|---|---|
| Blocker | `Program.cs`, `HealthResponse.cs`, `AssemblyMarker.cs` (coverage) | New production code not exercised by any unit test | **RESOLVED**. `tests/TaskMaster.Api.Tests` adds 8 tests; per-file line/branch >= 85%/75% on the two instrumentable files; `AssemblyMarker` const-only file has two direct assertion tests and is vacuously compliant. Evidence: `pr1-t14-per-file-coverage.2026-05-10T22-30.md`, `pr5-t5-test-coverage.2026-05-10T22-30.txt`. |
| Blocker | repo root `artifacts/csharp/coverage.xml` | Canonical coverage artifact absent | **RESOLVED**. `.github/actions/dotnet-test/action.yml` copies the newest `TestResults/*/coverage.cobertura.xml` to `artifacts/csharp/coverage.xml` and fails if the source is missing. The same step is documented in `.claude/skills/csharp-qa-gate/SKILL.md` for local runs. Reviewer verified the file on disk via `Glob`. Evidence: `pr2-t1-action-edit-grep`, `pr2-t2-skill-grep`, `pr5-t6-canonical-coverage.2026-05-10T22-30.txt`. |
| Major | `src/TaskMaster.Api/TaskMaster.Api.csproj` NSwag target | `ContinueOnError`/`IgnoreExitCode` silently suppressed NSwag failures | **RESOLVED**. csproj now declares `<EnableNSwagEmission Condition="...">false</EnableNSwagEmission>`; target has `Condition="'$(EnableNSwagEmission)' == 'true'"`; suppression attributes removed; TODO comment links interim hand-authored OpenAPI and the upstream net10 tracking issue. Loud-fail demonstrated. Evidence: `pr3-t1-csproj-edit.2026-05-10T22-30.txt`, `pr3-t2-build-default.2026-05-10T22-30.txt`, `pr3-t3-nswag-loud-fail.2026-05-10T22-30.txt`, `pr3-t4-openapi-source-of-truth.2026-05-10T22-30.md`. |
| Major | `tests/TaskMaster.ArchitectureTests/NoComArchitectureTests.cs` `DomainProjectDoesNotDependOnInfrastructure` | Fact not negative-tested on a real Domain→Infrastructure typed reference | **RESOLVED**. Phase R4 introduced a temporary `TaskMaster.Infrastructure.Probe` project and a `TaskMaster.Domain.InfraDependencyProbe` static class with a typed reference to the probe; `dotnet test` against `TaskMaster.ArchitectureTests` reported the failing fact with `TaskMaster.Domain.InfraDependencyProbe` in the failing-types list. Probe reverted; 3/3 facts pass post-revert. Evidence: `pr4-t1` through `pr4-t6` (qa-gates) and `pr4-t4-domain-infra-expect-fail.2026-05-10T22-30.txt` (regression-testing). |
| Minor | three csproj files | Redundant `<ImplicitUsings>enable</ImplicitUsings>` | **DEFERRED** per PR6-T1. Still present in all three csproj files (reviewer confirmed `src/TaskMaster.Api/TaskMaster.Api.csproj` line 4, `tests/TaskMaster.Api.Tests/TaskMaster.Api.Tests.csproj` line 4). Defer-acceptable. |
| Minor | `BannedSymbols.txt` narrative | `T:`/`P:` mismatch for `Random.Shared` | **DEFERRED** per PR6-T1. File is correct; only plan/spec narrative is off. |
| Minor | `.github/workflows/pr-pipeline.yml` `stage-3-dotnet-typecheck` | Empty stage | **DEFERRED** per PR6-T1. |
| Minor | `src/TaskMaster.Api/Program.cs` | `InternalsVisibleTo` needed for `WebApplicationFactory<Program>` | **RESOLVED** by Phase R1. `src/TaskMaster.Api/TaskMaster.Api.csproj` now declares `<InternalsVisibleTo Include="TaskMaster.Api.Tests" />`. |
| Info | `.github/actions/dotnet-test/action.yml` `--no-build` flag | May fail in CI when jobs don't share build output | **DEFERRED** per PR6-T1. |
| Info | `src/TaskMaster.Domain/AssemblyMarker.cs` | Duplicates `typeof(...).Assembly.GetName().Name` | **DEFERRED** as documented; harmless. |
| Info | `tests/TaskMaster.ArchitectureTests/NoComArchitectureTests.cs` `LoadTaskMasterAssemblies` | Helper relies on AppDomain loading order | Forward-looking note unchanged. |

## Spot-Check of Remediation Code

### `tests/TaskMaster.Api.Tests/`

- `HealthEndpointTests.cs`: uses `IClassFixture<WebApplicationFactory<Program>>`, two `[Fact]` methods, FluentAssertions, JSON deserialization to `HealthResponse`, asserts `Status == "ok"` and `Content-Type` starts with `application/json`. Conforms to `csharp.md` testing standards (xUnit, FluentAssertions, NSubstitute available, AAA shape, deterministic).
- `HealthResponseTests.cs`: four `[Fact]` tests on record equality, property accessor, `ToString()` shape. Pure unit tests; no I/O.
- `AssemblyMarkerTests.cs`: two `[Fact]` tests on the const value and its relation to the runtime assembly name. Pure unit tests.
- `TaskMaster.Api.Tests.csproj`: central package management (no version attributes); references `Microsoft.AspNetCore.Mvc.Testing`, `Microsoft.NET.Test.Sdk`, `xunit`, `xunit.runner.visualstudio`, `FluentAssertions`, `NSubstitute`, `coverlet.collector`. Project references both `TaskMaster.Api` and `TaskMaster.Domain`. `IsPackable=false`. Aligned with rule file.

### `src/TaskMaster.Api/TaskMaster.Api.csproj`

- `<EnableNSwagEmission>` defaults to `false` and gates the target via `Condition`.
- TODO comment block above the target documents the interim policy and references the upstream NSwag issue search query.
- `<InternalsVisibleTo Include="TaskMaster.Api.Tests" />` enables `WebApplicationFactory<Program>` for the test project.
- Suppression attributes (`ContinueOnError`, `IgnoreExitCode`) are absent from the `<Exec>` element. Verified by reviewer reading the file.

### `tests/TaskMaster.ArchitectureTests/NoComArchitectureTests.cs`

- File unchanged from pass 1 (88 lines). Phase R4 did not require a rewrite — the existing assertion `Types.InAssembly(...).That().ResideInNamespaceStartingWith("TaskMaster.Domain").Should().NotHaveDependencyOn("TaskMaster.Infrastructure")` correctly detected the typed `Domain→Infrastructure.Probe` reference during PR4-T4, per `pr4-t4-domain-infra-expect-fail.2026-05-10T22-30.txt`. The PR4-T3 grep verification (`pr4-t3-arch-rewrite-grep.2026-05-10T22-30.txt`) confirmed the required tokens are present in the file.

### `.github/actions/dotnet-test/action.yml`

- Composite action extended with a final PowerShell step that materializes `artifacts/csharp/coverage.xml` from the newest cobertura output. Step fails when no cobertura file is found (no silent skip).

## Notes on Rule and Instruction Prose

`.claude/rules/csharp.md` (reviewed via the project-instruction context attached to this re-audit) continues to align with the toolchain decisions: analyzer stack, banned APIs, DI seams (TimeProvider preferred), uniform coverage thresholds (line >= 85% / branch >= 75%), CsCheck for property-based testing, Stryker.NET for mutation, Verify.Xunit for golden tests. Mirror discipline preserved: `.github/instructions/csharp-*.instructions.md` matches `.claude/rules/csharp.md`.

`.claude/skills/csharp-qa-gate/SKILL.md` includes the canonical coverage copy step (Phase R2 PR2-T2 evidence). `.github/skills/csharp-qa-gate/` mirror does not exist (recorded as `pr2-t3-mirror-absence.2026-05-10T22-30.md`).

## Out of Scope

- TypeScript, Python, PowerShell: no production files changed; no review performed.
- Documentation under `docs/features/active/...`: feature-folder updates only.

## Overall Verdict (Pass 2)

**PASS.** Code-level concerns from pass 1 are all addressed (blockers and majors) or explicitly deferred (minors / info). No new code-level findings.
