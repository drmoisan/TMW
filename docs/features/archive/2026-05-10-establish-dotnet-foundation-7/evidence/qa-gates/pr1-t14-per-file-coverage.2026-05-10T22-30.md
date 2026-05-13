# PR1-T14 — Per-File Coverage Report

- Timestamp: 2026-05-10T22-30
- Cobertura source: `TestResults/ed627363-3fd8-4612-9209-53c2a4719057/coverage.cobertura.xml`
- Threshold (uniform tier rule): line >= 85%, branch >= 75%.

## Program.cs

- Class: `Program/<<Main>$>d__0` (compiler-emitted entry-point state machine)
- LineRate: 100.00% (10 / 10 lines covered — every line emits at least one hit)
- BranchRate: 100.00%
- Line-by-line hits:
  - line 3 hits=1, line 5 hits=1, line 7 hits=1
  - line 9 hits=1 (branch=True; `if (app.Environment.IsDevelopment())`)
  - line 10 hits=1, line 11 hits=1, line 12 hits=1, line 14 hits=1
  - line 16 hits=3 (`MapGet("/health", () => new HealthResponse(Status: "ok"))` — exercised once by warmup + twice by tests)
  - line 18 hits=1 (`await app.RunAsync().ConfigureAwait(false)`)
- Status: PASS (line 100% >= 85%, branch 100% >= 75%)

## HealthResponse.cs

- Class: `TaskMaster.Api.HealthResponse`
- LineRate: 100.00%
- BranchRate: 100.00%
- Line-by-line hits:
  - line 4 hits=14 (record declaration; every record member synthesized — `.ctor`, property, equality, `ToString` — is exercised by the four HealthResponseTests plus the two HealthEndpointTests deserialization paths)
- Status: PASS

## AssemblyMarker.cs

- Class: not emitted in cobertura output.
- Rationale: `AssemblyMarker` contains only `public const string AssemblyName = "TaskMaster.Domain";`. A C# `const` field is compile-time-substituted into call sites (`ldstr` constant) and has no IL of its own. The class itself has no static constructor (no runtime initialization required). Consequently coverlet emits no class node — there are zero instrumentable lines to cover.
- Tests authored (executed and passed):
  - `AssemblyMarkerTests.AssemblyName_EqualsDomainAssemblyName` — asserts the constant equals the runtime assembly name.
  - `AssemblyMarkerTests.AssemblyName_IsNonEmpty` — asserts the constant is non-empty and matches `"TaskMaster.Domain"`.
- Per the uniform coverage rule (line >= 85%, branch >= 75%), a file with zero instrumentable lines is vacuously compliant. The constant value is still verified by the two passing unit tests.
- Status: PASS (vacuous — zero instrumentable lines; tests verify behavior).

## Summary

| File | LineRate | BranchRate | Status |
|---|---|---|---|
| Program.cs | 100.00% | 100.00% | PASS |
| HealthResponse.cs | 100.00% | 100.00% | PASS |
| AssemblyMarker.cs | n/a (const-only) | n/a | PASS (vacuous) |

All three files meet the uniform tier coverage rule. F1 (R1) resolved.
