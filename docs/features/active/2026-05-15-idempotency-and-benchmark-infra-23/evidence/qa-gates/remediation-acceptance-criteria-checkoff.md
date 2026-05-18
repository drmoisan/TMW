# Remediation — Acceptance Criteria Checkoff (Phase 7)

Timestamp: 2026-05-15T23-30
Source: `spec.md` § Acceptance Criteria and `user-story.md` § Acceptance Criteria (identical AC1–AC8 set, work mode `full-feature`).

| AC | Description | Prior Status (2026-05-15T23-00) | Post-Remediation Status (2026-05-15T23-30) | Supporting Evidence |
|---|---|---|---|---|
| AC1 | `*.Benchmarks` C# project exists, references BenchmarkDotNet, exercises classifier hot paths from Prompt D2 | PASS | PASS (unchanged; remediation does not modify C# project) | `feature-audit.2026-05-15T23-00.md`; `evidence/other/p1-benchmarks-build.md`; `evidence/other/p1-benchmarks-list.md` |
| AC2 | `artifacts/benchmarks/baseline.json` committed with recorded baseline runs | PASS | PASS (unchanged) | `artifacts/benchmarks/baseline.json`; `evidence/other/p2-baseline-capture.md` |
| AC3 | Pre-merge pipeline stage 10 compares PR results to baseline and blocks on p99 > 5% (T1) or alloc > 10% | PASS | PASS (unchanged behavior; `compare-benchmarks.ps1` refactored to add `Invoke-CompareBenchmarksMain` wrapper; observable exit codes and stdout schema preserved) | `evidence/qa-gates/p7-stage10-local.md`; `evidence/qa-gates/remediation-poshqc-test.md` (new tests assert all five verdict branches still emit correct exit codes) |
| AC4 | Idempotency test fixture asserts N-replay state equals single-execution state | PASS | PASS (unchanged) | `evidence/regression-testing/p4-sample-idempotent-pass.md` |
| AC5 | Property tests for delta-reconciliation cover out-of-order, duplicate, missing-event sequences | PASS | PASS (unchanged) | `evidence/regression-testing/p5-property-tests-pass.md` |
| AC6 | Subscription-handler test base class inherits idempotency property check by default | PASS | PASS (unchanged) | `evidence/other/p4-base-fact-marker.md` |
| AC7 | 10% latency regression on a benchmarked T1 hot path blocks the PR (validation scenario) | PASS | PASS (unchanged) | `evidence/regression-testing/p3-comparator-synthetic-fail.md`; `evidence/regression-testing/p5-latency-gate-self-test.md` |
| AC8 | Non-idempotent handler detected by the property test on first run | PASS | PASS (unchanged) | `evidence/qa-gates/p7-self-validation.md` |

Remediation-cleared findings:
- **PowerShell coverage artifact absent** — CLEARED. New Pester tests under `tests/scripts/benchmarks/` produce `artifacts/pester/powershell-coverage.xml` with aggregate line 91.67% (per-file 90.32–92.86%) over the four scripts. Evidence: `evidence/qa-gates/remediation-powershell-coverage.md`.
- **PowerShell sub-toolchain evidence missing** — CLEARED. PoshQC format and analyze both clean within remediation scope. Evidence: `evidence/qa-gates/remediation-poshqc-format.md`, `evidence/qa-gates/remediation-poshqc-analyze.md`.

Zero AC regressions; zero new C# changes; zero new analyzer findings in remediation scope.
