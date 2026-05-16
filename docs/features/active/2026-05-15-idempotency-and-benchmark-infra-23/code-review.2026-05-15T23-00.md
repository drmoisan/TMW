# Code Review — idempotency-and-benchmark-infra (Issue #23)

- Timestamp: 2026-05-15T23-00
- Scope: full branch diff vs `0134bbfcd9a89f9439bb7d8645515d74ecc5b403`
- Files reviewed: 76 (4 PowerShell, 16 C#, 1 YAML, 3 JSON, 2 build config, 50 docs/evidence)

## Summary

The change set is gate-only infrastructure for the No-COM Phase G migration. It adds a `TaskMaster.Benchmarks` BDN project, a `TaskMaster.Worker.Tests` project containing an inheritable idempotency property check, delta-reconciliation property tests, two self-validation negative scenarios, four PowerShell scripts implementing the comparator and supporting utilities, and a pre-merge pipeline stage 10 with a separate `benchmark-gate-self-validation` job that proves both gates fire. The structure adheres to the project's design principles. The main remediation item is the absence of Pester unit tests for the new PowerShell scripts.

## Design Principles

| Principle | Assessment |
|---|---|
| Simplicity first | `SubscriptionHandlerTestBase` uses a single `[Fact]` for the inherited check; the comparator emits one CSV row per benchmark; CsCheck folds are minimal. No deep indirection. |
| Reusability | Generic base `SubscriptionHandlerTestBase<THandler, TNotification, TState>` is the intended reuse seam for Prompt G2 handler tests. `InMemoryStateStore` is shared between positive and negative scenarios. |
| Extensibility | Base class uses `protected virtual` for `ReplayCount` and four `protected abstract` template methods; derivations can plug in any handler/notification/state triple. `BenchmarkConfig` is a `ManualConfig` and is referenced via `[Config(typeof(BenchmarkConfig))]` so new benchmark classes inherit it by default. |
| Separation of concerns | Pure algorithmic folds (`Reconcile`) live alongside their property tests; I/O (process invocation in `LatencyRegressionGateTests`) is isolated to its own self-validation class; PowerShell scripts isolate I/O at the script boundary and keep `Get-PercentDelta` as a pure helper. |

## C# Code — Strengths

- `SubscriptionHandlerTestBase` precondition (`ReplayCount < 3 throws InvalidOperationException`) enforces the spec invariant at the seam where it can be violated, matching the "fail fast and explicit" rule.
- `FakeTimeProvider` is constructed once per fixture with a fixed instant (UTC 2026-05-15T00:00:00Z), which is deterministic and reproducible. `Clock.Advance` is documented for derived tests.
- CsCheck property tests pass explicit string seeds and bounded `iter:` counts (200) so reproducibility is deterministic and runtimes are predictable.
- `ArgumentNullException.ThrowIfNull(...)` is used uniformly in `SampleIdempotentHandler` and `NonIdempotentHandler`, consistent with current .NET guidance.
- `InMemoryStateStore` uses `StringComparer.Ordinal` everywhere; comparison semantics are explicit and culture-independent.
- All public test types carry XML doc comments explaining intent, derivation points, and acceptance-criteria mapping.
- `[Trait("Category","benchmark-gate-self-validation")]` cleanly partitions the inverted-outcome tests into a dedicated lane the default test filter excludes.

## C# Code — Observations / Minor

- `LatencyRegressionGateTests` invokes `pwsh` by short name and relies on `PATH` resolution; this is a deterministic-environment concern (`.claude/rules/csharp.md` § Deterministic Test Rules and `.claude/rules/powershell.md` warn about ambient PATH). For the CI runner (`windows-latest`) `pwsh` is on PATH, but a Test Explorer run from an arbitrary local environment could fail differently than the CLI. Consider a small `ProcessRunner` seam or environment variable override for repeatability. **Severity: low.** This is the only self-validation test that shells out and the failure mode is loud (`process.Should().NotBeNull()`).
- `DeltaReconciliationPropertyTests.PcgRandom` defines a small private PRNG. CsCheck supplies a seeded `Gen<long>`; the inline PCG is fine for shuffles, but a `Random(seed)` call would suffice and reduce custom-RNG surface area. **Severity: very low; informational.**
- `BenchmarkConfig` adds `JsonExporter.Full` and the `MemoryDiagnoser`. The comparator reads `Statistics.Percentiles.P99` and `Memory.BytesAllocatedPerOperation`; both fields are produced by this exporter. Wiring is consistent.
- `ClassifierBenchmarks` constructs its inputs once in `GlobalSetup`; this is correct BDN usage. The `TrainingState_Update` benchmark mutates `_trainingRepository` between iterations (the dictionary key is the same each call). This produces stable allocations only because the same key is written every invocation. The intent is "dictionary lookup and write cost" and the comment captures that. **Severity: very low; informational.**

## PowerShell Code — Strengths

- `compare-benchmarks.ps1` is well-bounded (127 lines), uses `[CmdletBinding()]`, `[Parameter(Mandatory = $true)]`, explicit parameter types, `$ErrorActionPreference = 'Stop'`, and `#Requires -Version 7.0`.
- Exit codes are explicit and documented in the `.SYNOPSIS` block (0 / 1 / 2 mean pass / regression / malformed input).
- `Get-PercentDelta` handles the `Baseline <= 0` edge case deterministically (returns `+Infinity` so the threshold trips), which is preferable to a divide-by-zero.
- Schema fields consumed (`FullName`, `Statistics.Percentiles.P99`, `Memory.BytesAllocatedPerOperation`) are documented inline matching `artifacts/benchmarks/README.md`.

## PowerShell Code — Observations / Minor

- No dedicated Pester unit tests for any of the four scripts. The comparator is exercised end-to-end by `LatencyRegressionGateTests` (negative path) and the manual self-comparison rows, but pure unit coverage of `Get-PercentDelta` boundaries (zero baseline, negative baseline, NaN), `Read-BenchmarkReport` failure modes (missing file path, malformed JSON, empty `Benchmarks` array), and the `SKIP_NO_BASELINE` row formatting is not present. **Severity: medium.** This is a remediation item under the policy audit.
- `Read-BenchmarkReport` calls `exit 2` from inside a function instead of throwing or returning a structured error. `exit` from a function terminates the calling script's session, which is the intended behavior here, but it bypasses any cleanup or `try/finally` higher up. The script has no `finally` paths so the impact is nil; flagging only because it interacts with mocking/seam guidance in `.claude/rules/powershell.md`. **Severity: very low; informational.**
- No `SupportsShouldProcess`. The four scripts are read-only (the comparator writes only to stdout; `enrich-bdn-report.ps1` writes back into the same JSON file and `make-synthetic-fixtures.ps1` writes fixture JSON files into the repo). `SupportsShouldProcess` would be appropriate for `enrich-bdn-report.ps1` and `make-synthetic-fixtures.ps1` because they mutate filesystem state. **Severity: low.**

## Error Handling and Logging

- C# tests use `Should().BeEquivalentTo(...)`, `Should().NotBe(...)` with descriptive failure-context strings ("comparator must complete within 60s", "comparator must fail on a synthetic +10% p99 regression against a T1 benchmark id", "ReplayCount must be at least 3 per the idempotency spec.") consistent with the AAA-with-explicit-reason convention.
- PowerShell uses `[Console]::Error.WriteLine` plus explicit `exit 2` for malformed-input cases; no silent swallowing observed.

## Naming

- C# follows `PascalCase` for public types and `_camelCase` for private fields throughout the new files.
- Test method names use the `Subject_Scenario_Expectation` shape (`Comparator_OnSyntheticLatencyRegressionFixture_ExitsNonZero`, `Idempotency_RepeatedDelivery_ProducesSinglePostState`, `OutOfOrder_ProducesSameState`).
- PowerShell uses approved verbs (`Read-BenchmarkReport`, `Get-PercentDelta`). Parameter names avoid the `Args` collision (`GitArgs`-style is not used here; parameters are domain-named).

## File Size

All new files under the 500-line ceiling. Largest: `compare-benchmarks.ps1` (127), `SubscriptionHandlerTestBase.cs` (92).

## Dependencies

`BenchmarkDotNet 0.14.0` added via Central Package Management; project consumes it versionless. `CsCheck` and `Microsoft.Extensions.TimeProvider.Testing` are referenced by the new `TaskMaster.Worker.Tests` project; both are sanctioned by `.claude/rules/csharp.md` (CsCheck for property tests on .NET; `FakeTimeProvider` is the only sanctioned clock substitute).

No new transitive dependencies on Office/COM/VSTO.

## Public API Surface

This feature adds public test infrastructure (intentional surface for derivation by future Phase G handler tests):

- `TaskMaster.Worker.Tests.Subscriptions.SubscriptionHandlerTestBase<THandler, TNotification, TState>` (public abstract; required so derived test classes outside the assembly can extend).
- `SampleNotification`, `SampleIdempotentHandler`, `NonIdempotentHandler`, `InMemoryStateStore` are public for the same reason.

The public surface is justified by the test-derivation pattern. No production-code public API is changed.

## I/O Boundaries

- `LatencyRegressionGateTests` is the only test that touches the filesystem and a subprocess; it is isolated to its own self-validation class and is excluded from the default test lane. This complies with the "isolate I/O" rule and the "no temporary files in tests" rule (the fixtures are committed under `tests/TaskMaster.Benchmarks/Fixtures/`).
- All other tests are pure in-memory (`InMemoryStateStore`, CsCheck folds, `FakeTimeProvider`).

## Findings Summary

| Severity | Category | Finding | Remediation |
|---|---|---|---|
| Medium | PowerShell coverage | No Pester unit tests for `compare-benchmarks.ps1`, `enrich-bdn-report.ps1`, `make-synthetic-fixtures.ps1`, `parse-cobertura.ps1` (~305 lines combined). | Add `*.Tests.ps1` covering `Get-PercentDelta` boundaries, `Read-BenchmarkReport` malformed/missing-file paths, and the `SKIP_NO_BASELINE` row in `compare-benchmarks.ps1`. Produce `artifacts/pester/powershell-coverage.xml`. |
| Low | C# determinism | `LatencyRegressionGateTests` resolves `pwsh` via PATH. | Resolve the full path via `RuntimeInformation.IsOSPlatform(Windows) ? "pwsh.exe" : "pwsh"` and validate existence; or thread the path through a `ProcessRunner` seam. |
| Low | PowerShell | `enrich-bdn-report.ps1` and `make-synthetic-fixtures.ps1` mutate filesystem without `SupportsShouldProcess`. | Add `[CmdletBinding(SupportsShouldProcess)]` and gate the write calls behind `$PSCmdlet.ShouldProcess(...)`. |
| Informational | C# | `DeltaReconciliationPropertyTests.PcgRandom` is a custom inline PRNG. | Optional: replace with `new Random(seed)`. |

## Overall Code-Review Verdict

**PARTIAL** — design and C# implementation are sound; the remediation item is PowerShell unit-test coverage for the four new scripts.
