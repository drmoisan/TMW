# Remediation Inputs — idempotency-and-benchmark-infra (Issue #23)

- Timestamp: 2026-05-15T23-00
- Source artifacts:
  - `policy-audit.2026-05-15T23-00.md`
  - `code-review.2026-05-15T23-00.md`
  - `feature-audit.2026-05-15T23-00.md`

## Blocking Findings

### 1. PowerShell coverage artifact absent (FAIL)

- Origin: Policy audit § Coverage Verification; code review § PowerShell Code — Observations.
- Rule reference: `.claude/rules/powershell.md` § Testing Standards (line coverage >= 85%, branch coverage >= 75%); Feature-Review-Workflow § Coverage Verification ("If no coverage artifact is found for a language that has changed files, flag as FAIL").
- Affected files (~305 added lines, all PowerShell):
  - `scripts/benchmarks/compare-benchmarks.ps1` (127 lines)
  - `scripts/benchmarks/enrich-bdn-report.ps1` (80 lines)
  - `scripts/benchmarks/make-synthetic-fixtures.ps1` (67 lines)
  - `scripts/benchmarks/parse-cobertura.ps1` (31 lines)
- Required artifact (absent): `artifacts/pester/powershell-coverage.xml`.
- Required remediation:
  1. Add `tests/scripts/benchmarks/*.Tests.ps1` mirroring the script structure. Cover at minimum:
     - `compare-benchmarks.ps1`: `Get-PercentDelta` with baseline > 0, baseline = 0 with current > 0, baseline = 0 with current = 0, baseline < 0; `Read-BenchmarkReport` with missing file, malformed JSON, absent `Benchmarks` array; the `SKIP_NO_BASELINE` row path; the regression-triggers-exit-1 path; the all-pass-exit-0 path; both `FAIL_ALLOC` and `FAIL_LATENCY_AND_ALLOC` verdict branches.
     - `enrich-bdn-report.ps1`: enrichment success, file-missing failure, idempotent re-enrichment.
     - `make-synthetic-fixtures.ps1`: latency-fixture write, allocation-fixture write.
     - `parse-cobertura.ps1`: malformed XML, missing line-rate/branch-rate attribute, aggregation correctness across multiple cobertura files.
  2. Mock at the wrapper-function seam per `.claude/rules/powershell.md` § Mocking Rules; do not mock executables directly.
  3. Run via `mcp__drm-copilot__run_poshqc_test` and capture the resulting `powershell-coverage.xml` into `artifacts/pester/`.
  4. Capture format / analyze evidence under `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/qa-gates/` (mcp PoshQC format + analyze artifacts).

### 2. PowerShell sub-toolchain evidence missing (PARTIAL elevated for remediation alongside #1)

- Origin: Policy audit § Toolchain Loop.
- Rule reference: `.claude/rules/powershell.md` § Toolchain.
- Required artifacts:
  - Invoke-Formatter pass for the four scripts (`mcp__drm-copilot__run_poshqc_format`).
  - PSScriptAnalyzer pass with repo settings (`mcp__drm-copilot__run_poshqc_analyze`).
- Bundle with remediation #1.

## Non-Blocking Observations (not required to clear remediation)

These are recorded for awareness; they do not block the PR and do not appear as remediation triggers:

- `LatencyRegressionGateTests` resolves `pwsh` from PATH (low-severity determinism note).
- `enrich-bdn-report.ps1` / `make-synthetic-fixtures.ps1` mutate filesystem without `SupportsShouldProcess` (low-severity PowerShell hygiene).
- `DeltaReconciliationPropertyTests.PcgRandom` custom PRNG could be replaced with `Random(seed)` (informational).
- C# repo-wide absolute coverage is 32.70% line / 15.82% branch, below the uniform 85%/75% floor. Pre-existing baseline; this feature does not regress production-code coverage (no production code changed). Remediation is owned by the production projects (Domain / Application / Classifier / Infrastructure / Api) and is explicitly out of scope per `spec.md` § Non-Goals.

## Acceptance Criteria Impact

None of the eight acceptance criteria (AC1–AC8) are blocked by these remediation items. All AC are PASS with documented evidence. The remediation is policy-driven (uniform coverage gate and toolchain evidence completeness), not behavior-driven.

## Suggested Sequencing

1. Add Pester unit tests for the four `scripts/benchmarks/` scripts.
2. Run PoshQC format → analyze → test sequence; capture evidence.
3. Verify `artifacts/pester/powershell-coverage.xml` reports >= 85% line / >= 75% branch for the new scripts.
4. Re-issue feature review (`feature-review-workflow`) to refresh policy-audit / code-review / feature-audit timestamps; the coverage FAIL finding should clear to PASS.
