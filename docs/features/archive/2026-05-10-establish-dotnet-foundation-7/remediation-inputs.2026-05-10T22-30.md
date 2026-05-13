# Remediation Inputs — Issue #7 (Prompt C1 — Establish .NET Foundation)

- Timestamp: 2026-05-10T22-30
- Source review artifacts:
  - `docs/features/active/2026-05-10-establish-dotnet-foundation-7/policy-audit.2026-05-10T22-30.md`
  - `docs/features/active/2026-05-10-establish-dotnet-foundation-7/code-review.2026-05-10T22-30.md`
  - `docs/features/active/2026-05-10-establish-dotnet-foundation-7/feature-audit.2026-05-10T22-30.md`

## Blocking Findings (must be resolved before merge)

### R1 — Add unit-test coverage for new C# production files

- Severity: Blocker (FAIL)
- Source: policy-audit F1; code-review Blocker row.
- Files lacking coverage:
  - `src/TaskMaster.Api/Program.cs` (new)
  - `src/TaskMaster.Api/HealthResponse.cs` (new)
  - `src/TaskMaster.Domain/AssemblyMarker.cs` (new)
- Required outcome: line coverage >= 85%, branch coverage >= 75% on each of the above per the uniform tier rule in `.claude/rules/quality-tiers.md`.
- Recommended approach (non-prescriptive):
  1. Add a new xUnit test project `tests/TaskMaster.Api.Tests` referencing `Microsoft.AspNetCore.Mvc.Testing`, `FluentAssertions`, `NSubstitute`, and the API project.
  2. Add `InternalsVisibleTo("TaskMaster.Api.Tests")` to `src/TaskMaster.Api` so `WebApplicationFactory<Program>` can resolve the entry type (`Program` is implicit `internal partial class` under top-level statements).
  3. Add at least two xUnit `[Fact]` tests: one resolves `/health` and asserts the response shape `HealthResponse(Status="ok")`; one touches `TaskMaster.Domain.AssemblyMarker.AssemblyName` to exercise the marker constant.
  4. Register the new test project in `quality-tiers.yml` at tier T4.
  5. Re-run `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"` and verify the cobertura report shows `lines-valid > 0` and the per-file coverage meets the uniform tier rule.

### R2 — Produce canonical C# coverage artifact at `artifacts/csharp/coverage.xml`

- Severity: Blocker (FAIL)
- Source: policy-audit F2; code-review Blocker row.
- Required outcome: a coverage file at the path `artifacts/csharp/coverage.xml` (cobertura or LCOV form acceptable per the workflow contract; the path is the contract).
- Recommended approach:
  - Extend `.github/actions/dotnet-test/action.yml` to copy the generated `TestResults/<run-guid>/coverage.cobertura.xml` to `artifacts/csharp/coverage.xml` after `dotnet test`. PowerShell sketch:
    ```pwsh
    New-Item -ItemType Directory -Force -Path artifacts/csharp | Out-Null
    Get-ChildItem TestResults -Recurse -Filter coverage.cobertura.xml |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1 |
      Copy-Item -Destination artifacts/csharp/coverage.xml -Force
    ```
  - Add the same step to any local QA-gate skill so the artifact lands at the canonical path on local runs.
  - Ensure `artifacts/csharp/` is git-ignored (currently uncertain; reviewer did not inspect `.gitignore` for this path).

## Major Findings (should be addressed before merge; orchestrator may accept as deviations)

### R3 — NSwag emission is silently suppressed

- Severity: Major (PARTIAL)
- Source: code-review Major row; policy-audit F3; executor deviation #4.
- File: `src/TaskMaster.Api/TaskMaster.Api.csproj` lines 16-23.
- Required outcome: either (a) the NSwag target fails loudly when emission fails, or (b) the target is gated by an explicit opt-out property until upstream net10 support lands, and the hand-authored `artifacts/openapi/current.json` is documented as the interim source of truth.
- Recommended approach:
  - Replace `ContinueOnError="true" IgnoreExitCode="true"` with a property guard, e.g. `Condition="'$(EnableNSwagEmission)' == 'true'"` with `EnableNSwagEmission` defaulting to `false` until net10 launcher support is released.
  - Add a TODO comment referencing the NSwag GitHub issue tracking net10 support.

### R4 — Domain-vs-Infrastructure architecture fact not negative-tested

- Severity: Major (PARTIAL)
- Source: code-review Major row; executor deviation #6.
- File: `tests/TaskMaster.ArchitectureTests/NoComArchitectureTests.cs` lines 69-87.
- Required outcome: a documented or executable negative test that proves the assertion fires on a violating type.
- Recommended approach:
  - When Phase B introduces real Infrastructure types, add a temporary in-tree probe class in `tests/TaskMaster.ArchitectureTests` that intentionally violates the rule, and verify the fact returns `IsSuccessful == false`. Capture as evidence and revert the probe.
  - Alternatively, switch the assertion strategy to `Types.That().ResideInNamespaceStartingWith(...).Should().NotHaveDependencyOnAny(typeof(...).FullName)` once a real type list exists.

## Minor / Info Findings (defer-acceptable)

- R5 — Redundant `<ImplicitUsings>enable</ImplicitUsings>` in three csproj files. Remove or accept (see code-review Minor rows).
- R6 — Empty `stage-3-dotnet-typecheck` pipeline job. Remove or convert to a guard (see code-review Minor row).
- R7 — `--no-build` flag in `.github/actions/dotnet-test/action.yml` may fail in CI because build output is not shared across jobs (see code-review Info row).
- R8 — Spec/plan-level `T:` vs `P:` mismatch for `Random.Shared` in narrative text only; file is correct (see code-review Minor row).

## Acceptance Criteria Impact

- Reviewer outcome verdict O6 PARTIAL is addressed by R4.
- Reviewer outcome verdict O7 PARTIAL is addressed by R3.
- The cross-cutting coverage shortfall (policy-audit F1, F2) is addressed by R1 and R2. This shortfall does not map to a specific issue.md AC but is a uniform policy gate.

## Suggested Remediation Plan File

Recommended target path for the remediation plan handoff:

`docs/features/active/2026-05-10-establish-dotnet-foundation-7/remediation-plan.2026-05-10T22-30.md`

## Re-Verification Checklist

After remediation, re-run and re-evaluate:

1. `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"` and confirm per-file coverage on `Program.cs`, `HealthResponse.cs`, `AssemblyMarker.cs` meets the uniform tier rule.
2. Confirm `artifacts/csharp/coverage.xml` exists and is current.
3. Confirm NSwag target behavior is either loud-fail or explicitly gated.
4. Confirm Domain-vs-Infrastructure fact has documented or executable negative test evidence.
5. Re-run the feature-review-workflow to generate fresh policy-audit / code-review / feature-audit artifacts and verify all blocking findings clear.
