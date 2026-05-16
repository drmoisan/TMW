# Issue Update Mirror — Issue #23

Timestamp: 2026-05-15T23-30
PostedAs: unknown
POSTING BLOCKED: executor agent does not have authority to post GitHub comments in this session. Posting is deferred to the orchestrator or a manual follow-up.

Prepared comment body:

---

Remediation pass 1 complete for the PowerShell-coverage and PoshQC-evidence findings raised in the prior feature-review.

Cleared findings:
- PowerShell coverage artifact absent — CLEARED. `artifacts/pester/powershell-coverage.xml` now reports aggregate line coverage 91.67% over the four `scripts/benchmarks/*.ps1` files; per-file line coverage 90.32–92.86%, all above the 85% threshold. Branch counters are not emitted by Pester's JaCoCo exporter; decision-branch traceability is documented in `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/qa-gates/remediation-powershell-coverage.md`.
- PowerShell sub-toolchain evidence missing — CLEARED. PoshQC format and analyze both clean within the remediation scope (zero findings).

Acceptance criteria: AC1–AC8 all PASS (no regressions). Checkoff table at `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/qa-gates/remediation-acceptance-criteria-checkoff.md`.

Changes in this pass:
- Added 28 Pester tests under `tests/scripts/benchmarks/` covering every case enumerated in the remediation inputs (Get-PercentDelta four branches; Read-BenchmarkReport three error paths; Invoke-CompareBenchmarksMain five verdict branches; Get-Percentile single/multi/empty/integer-rank; enrichment success/idempotent/force-overwrite/no-Benchmarks/null-stats/file-missing; Copy-Report success; latency and allocation fixture writes; cobertura malformed/missing-attrs/aggregate).
- Helper module `tests/scripts/benchmarks/_helpers/Import-ScriptFunctions.ps1` extracts top-level function definitions via AST for unit-level testing without triggering top-level `exit` statements.
- Minor additive refactor of `scripts/benchmarks/compare-benchmarks.ps1`: top-level loop wrapped in `Invoke-CompareBenchmarksMain` returning an int; `Read-BenchmarkReport` converted from `exit 2` to throw with `ExitCode`; observable behaviour preserved for production callers via `$MyInvocation.InvocationName` guard.
- New repo-local Pester runsettings at `scripts/powershell/PoshQC/settings/pester.runsettings.psd1` scopes coverage to the four benchmark scripts.

Toolchain evidence (full set under `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/`):
- `evidence/baseline/remediation-poshqc-format-baseline.md`, `remediation-poshqc-analyze-baseline.md`, `remediation-poshqc-test-baseline.md`.
- `evidence/qa-gates/remediation-poshqc-format.md`, `remediation-poshqc-analyze.md`, `remediation-poshqc-test.md`, `remediation-powershell-coverage.md`.
- `evidence/qa-gates/remediation-final-poshqc-format.md`, `remediation-final-poshqc-analyze.md`, `remediation-final-typecheck.md`, `remediation-final-poshqc-test.md`, `remediation-final-dotnet-untouched.md`.

Refreshed audit artifacts:
- `policy-audit.2026-05-15T23-30.md`
- `code-review.2026-05-15T23-30.md`
- `feature-audit.2026-05-15T23-30.md`

Reference: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/qa-gates/remediation-acceptance-criteria-checkoff.md`.
