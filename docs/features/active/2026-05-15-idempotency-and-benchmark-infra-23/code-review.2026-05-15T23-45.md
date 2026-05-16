# Code Review — idempotency-and-benchmark-infra (Issue #23), Pass 3 (R4 re-audit)

- Timestamp: 2026-05-15T23-45
- Prior reviews: `code-review.2026-05-15T23-00.md` (R3 initial), `code-review.2026-05-15T23-30.md` (R3 post-remediation refresh)
- Head: `feature/idempotency-and-benchmark-infra-23 @ 021abf69bf7d4607cd1885dd8d84eb5ee9f62f43`

## Scope of This Pass

Re-audit after remediation pass 1. The remediation introduced PowerShell Pester tests for the four scripts under `scripts/benchmarks/`, a small refactor of `compare-benchmarks.ps1` to allow unit-test seams, a helper module for AST-based function extraction, and a repo-local Pester runsettings file. No C# source under `src/` was modified.

## Design and Simplicity

- The comparator refactor (`Invoke-CompareBenchmarksMain` wrapper, conversion of `Read-BenchmarkReport`'s `exit 2` to a typed `throw` with `.Data['ExitCode']=2`) preserves observable behaviour: same stdout schema, same exit codes for production callers. The wrapper is the simplest change that supports both production exit-coded use and Pester unit isolation.
- The dot-source guard `if ($MyInvocation.InvocationName -ne '.')` correctly distinguishes production invocation from Pester dot-source. Tests use `& $scriptPath` for full-body execution with mocks at wrapper-function seams, and dot-source via the AST helper for pure helper-function tests (`Get-Percentile`, `Copy-Report`).
- `tests/scripts/benchmarks/_helpers/Import-ScriptFunctions.ps1` extracts top-level function definitions via `[System.Management.Automation.Language.Parser]::ParseFile` and returns a `[scriptblock]` for dot-source into Pester `BeforeAll`. The approach is targeted and idiomatic.

## PowerShell Code — Observations

- All four production scripts (`compare-benchmarks.ps1`, `enrich-bdn-report.ps1`, `make-synthetic-fixtures.ps1`, `parse-cobertura.ps1`) declare `#Requires -Version 7.0`, `[CmdletBinding()]`, `Set-StrictMode -Version Latest`, and `$ErrorActionPreference = 'Stop'`, consistent with `.claude/rules/powershell.md`.
- Three of the four scripts (`enrich-bdn-report.ps1`, `make-synthetic-fixtures.ps1`, `parse-cobertura.ps1`) are unchanged from pass 1; only the comparator was refactored.
- Named-parameter usage throughout. Mocks in test code declare matching named parameters where production calls use `-LiteralPath` / `-Path`.
- Pre-existing non-blocking observations carried forward from pass 1 (recorded in `remediation-inputs.2026-05-15T23-00.md`):
  - `LatencyRegressionGateTests` resolves `pwsh` from PATH (low-severity determinism note; mitigated by the self-validation job pinning the PowerShell version).
  - `enrich-bdn-report.ps1` / `make-synthetic-fixtures.ps1` mutate filesystem without `SupportsShouldProcess` (low-severity hygiene).

## C# Code

No C# source under `src/` is modified by this branch. Test/benchmark code (`tests/TaskMaster.Benchmarks/*`, `tests/TaskMaster.Worker.Tests/Subscriptions/*`, `tests/TaskMaster.Worker.Tests/Reconciliation/*`, `tests/TaskMaster.Worker.Tests/SelfValidation/*`) was reviewed in pass 1 with no blocking findings:

- `SubscriptionHandlerTestBase<THandler>` exposes `RunIdempotencyProperty(...)` and a `[Fact]` `Idempotency_RepeatedDelivery_ProducesSinglePostState` so any derived test class inherits the idempotency check by default (AC6).
- `DeltaReconciliationPropertyTests` uses CsCheck with explicit seed strings; failures are reproducible (AC5).
- `BenchmarkConfig` declares a single `Job.ShortRun.WithId("short-deterministic")` so benchmarks are deterministic (`spec.md` constraint).
- `DeltaReconciliationBenchmarks` is a documented disabled placeholder gated by `ENABLE_G2_BENCHMARK` and a `TODO(G2)` marker.

## Test Quality

- 28 Pester tests across `compare-benchmarks.Tests.ps1` (multiple Describe groups for `Get-PercentDelta`, `Read-BenchmarkReport`, `Invoke-CompareBenchmarksMain` verdict branches), `enrich-bdn-report.Tests.ps1`, `make-synthetic-fixtures.Tests.ps1`, `parse-cobertura.Tests.ps1`.
- Arrange–Act–Assert structure observed. Mocks declare matching named parameters; no real filesystem writes; no temporary files; deterministic.
- Floating-point assertions use absolute tolerance where JSON round-trip may introduce micro-deltas.
- Coverage attribution lands on production script files via the wrapper-seam mocking pattern (per `.claude/rules/powershell.md` § Mocking Rules).

## Determinism

`evidence/qa-gates/p5-banned-api-scan.md` (exit 0) confirms zero banned-API hits in `tests/TaskMaster.Worker.Tests`. CsCheck seed strings on every property test, `FakeTimeProvider` as the sole clock substitute, and BDN `Job.ShortRun` for benchmark determinism.

## Verdict

No blocking findings. The remediation pass introduces no new code-review concerns. Non-blocking observations carried from pass 1 remain non-blocking.
