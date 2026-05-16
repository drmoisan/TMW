# Remediation Plan — idempotency-and-benchmark-infra (Issue #23, Pass 1)

- Timestamp: 2026-05-15T23-00
- Feature folder: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/`
- Plan file (this document): `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/remediation-plan.2026-05-15T23-00.md`
- Inputs: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/remediation-inputs.2026-05-15T23-00.md`
- Source audits:
  - `policy-audit.2026-05-15T23-00.md`
  - `code-review.2026-05-15T23-00.md`
  - `feature-audit.2026-05-15T23-00.md`
- Work Mode: full-feature (remediation pass within active full-feature workflow)
- Canonical evidence root: `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/`

## Scope and Constraints

- Resolve both blocking findings from the remediation inputs:
  1. Add Pester unit tests under `tests/scripts/benchmarks/` for the four PowerShell scripts in `scripts/benchmarks/` covering the cases enumerated in the inputs.
  2. Run the PoshQC toolchain (format -> analyze -> test with coverage) and capture evidence into `evidence/qa-gates/`; emit `artifacts/pester/powershell-coverage.xml` meeting >= 85% line / >= 75% branch on the four scripts.
- No production code changes outside Pester tests. A minimal `Invoke-Main` wrapper is permitted in a benchmark script only if strictly required to test an `exit`-bearing branch via dot-sourcing; the preferred path is AST-level function extraction and direct invocation of helper functions, plus assertion via the `exit` keyword being trapped by Pester `Should -Throw` patterns after dot-sourcing a function-scoped form. If a wrapper is required, it must be additive (no semantic change for existing callers).
- Mocking: per `.claude/rules/powershell.md` Mocking Rules. Mock at wrapper-function seams (for example `Read-BenchmarkReport`, `Copy-Report`, `Get-Percentile`, `Get-ChildItem`, `Get-Content`, `Set-Content`, `New-Item`, `Test-Path`). Do not mock executables.
- Evidence paths under `<FEATURE>/evidence/<kind>/` only; no `artifacts/baselines/`, `artifacts/qa/`, `artifacts/qa-gates/`, `artifacts/evidence/`, `artifacts/coverage/`. The PoshQC coverage XML location (`artifacts/pester/powershell-coverage.xml`) is the tool's output artifact contract referenced by audits and is not an evidence document; it remains under `artifacts/pester/` while all narrative/QA-gate evidence is mirrored under `<FEATURE>/evidence/qa-gates/`.
- Acceptance Criteria AC1-AC8 must remain PASS (they were not regressed); the final phase re-verifies via PR-context refresh and AC checkoff.

## Acceptance for this Remediation Pass

- All four scripts have Pester test files at `tests/scripts/benchmarks/<ScriptBase>.Tests.ps1` covering every case enumerated in remediation-inputs § 1.
- `mcp__drm-copilot__run_poshqc_format` returns clean (exit 0) on the four scripts and the four test files; evidence at `evidence/qa-gates/remediation-poshqc-format.md`.
- `mcp__drm-copilot__run_poshqc_analyze` returns clean (exit 0) on the four scripts and the four test files; evidence at `evidence/qa-gates/remediation-poshqc-analyze.md`.
- `mcp__drm-copilot__run_poshqc_test` returns clean (exit 0); coverage XML at `artifacts/pester/powershell-coverage.xml` reports >= 85% line and >= 75% branch on the four target scripts; evidence at `evidence/qa-gates/remediation-poshqc-test.md` and `evidence/qa-gates/remediation-powershell-coverage.md`.
- Refreshed `policy-audit`, `code-review`, and `feature-audit` artifacts at timestamp `2026-05-15T23-30` (or later) record the coverage finding as PASS and AC1-AC8 as PASS.

---

### Phase 0 — Baseline Capture

- [x] [P0-T1] Read `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/powershell.md`, `.claude/rules/tonality.md`, and `CLAUDE.md`; record file list, byte counts, and timestamp at `evidence/baseline/remediation-phase0-instructions-read.md` (fields: `Timestamp`, `Policy Order`, `Files Read`).
- [x] [P0-T2] Read remediation inputs `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/remediation-inputs.2026-05-15T23-00.md`, plus the three audit artifacts referenced therein. Record list and timestamps at `evidence/baseline/remediation-phase0-inputs-read.md`.
- [x] [P0-T3] Capture the existing four target script files (paths and line counts) at `evidence/baseline/remediation-phase0-target-scripts.md`. Required fields: `Timestamp`, `Command: Get-Item ... | Measure-Object -Line`, `EXIT_CODE`, `Output Summary` (one line per script with line count).
- [x] [P0-T4] Run `mcp__drm-copilot__run_poshqc_format` against `scripts/benchmarks/*.ps1` (the four target scripts) in check mode. Capture full output at `evidence/baseline/remediation-poshqc-format-baseline.md` with fields `Timestamp`, `Command`, `EXIT_CODE`, `Output Summary`.
- [x] [P0-T5] Run `mcp__drm-copilot__run_poshqc_analyze` against `scripts/benchmarks/*.ps1`. Capture output at `evidence/baseline/remediation-poshqc-analyze-baseline.md` with fields `Timestamp`, `Command`, `EXIT_CODE`, `Output Summary` (rule violation counts).
- [x] [P0-T6] Run `mcp__drm-copilot__run_poshqc_test` against `tests/scripts/` to confirm baseline Pester state (no tests yet under `tests/scripts/benchmarks/`). Capture output at `evidence/baseline/remediation-poshqc-test-baseline.md` with fields `Timestamp`, `Command`, `EXIT_CODE`, `Output Summary` (existing tests passed/failed; record absence of benchmarks tests).
- [x] [P0-T7] Confirm absence of `artifacts/pester/powershell-coverage.xml`. Record at `evidence/baseline/remediation-coverage-artifact-absent.md` with `Timestamp`, `Command: Test-Path artifacts/pester/powershell-coverage.xml`, `EXIT_CODE`, `Output Summary: False` (or actual result if present pre-existing).

### Phase 1 — Pester Test Authoring for compare-benchmarks.ps1

- [x] [P1-T1] Create directory `tests/scripts/benchmarks/` if absent and add a Pester `BeforeAll` helper module file `tests/scripts/benchmarks/_helpers/Import-ScriptFunctions.ps1` that, given a script path, parses the file with `[System.Management.Automation.Language.Parser]::ParseFile`, extracts top-level `function` definitions, and returns them as a `[scriptblock]` to be dot-sourced into the test scope. This helper enables function-level testing without executing top-level script statements that call `exit`. Acceptance: file <= 80 lines, has Pester `Describe`-less utility surface, no external I/O beyond `Test-Path`/`Get-Content`.
- [x] [P1-T2] Create `tests/scripts/benchmarks/compare-benchmarks.Tests.ps1`. In `BeforeAll`, import `Get-PercentDelta` and `Read-BenchmarkReport` via the helper from P1-T1. File path defined: `tests/scripts/benchmarks/compare-benchmarks.Tests.ps1`. Acceptance: file parses, `BeforeAll` block dot-sources the two helper functions into the test scope.
- [x] [P1-T3] In `compare-benchmarks.Tests.ps1` add `Describe 'Get-PercentDelta'` with four `It` blocks: baseline > 0 returns `((current-baseline)/baseline)*100`; baseline = 0 and current > 0 returns `[double]::PositiveInfinity`; baseline = 0 and current = 0 returns `0.0`; baseline < 0 returns `[double]::PositiveInfinity`. Each `It` is arrange-act-assert and contains exactly one behavioural assertion. Acceptance: all four `It` pass when run via `mcp__drm-copilot__run_poshqc_test`.
- [x] [P1-T4] In `compare-benchmarks.Tests.ps1` add `Describe 'Read-BenchmarkReport'` with three `It` blocks covering: missing file (mock `Test-Path` to return `$false`, expect `exit 2` behavior trapped via `Should -Throw` on a `[System.Management.Automation.RuntimeException]` wrapper, or via redirecting `[Console]::Error` and asserting the error stream); malformed JSON (mock `Get-Content` to return `'{not json'`, expect exit-2 path); JSON missing `Benchmarks` array (mock `Get-Content` to return a JSON object without `Benchmarks`, expect exit-2 path). Mocks must declare named parameters matching production signatures (`-LiteralPath` for `Get-Content`/`Test-Path`). Acceptance: three `It` pass; no real filesystem reads.
- [x] [P1-T5] Add `Describe 'compare-benchmarks script body'` with five `It` blocks exercising the script's top-level loop via dot-sourcing the body inside a function `Invoke-CompareBenchmarksBody` constructed at test time from the parsed AST (re-using P1-T1 helper extended to also capture top-level statements as a script block parameterized by `$BaselinePath`, `$CurrentPath`, `$T1BenchmarkIdPattern`, `$LatencyThresholdPercent`, `$AllocationThresholdPercent`). The five `It` cases: (a) `SKIP_NO_BASELINE` row emitted when current id is not in baseline map; (b) all-pass returns exit code 0 (assert via `$LASTEXITCODE` after invoking inside a Pester `InModuleScope`-equivalent, or via a sentinel: replace `exit` with `throw [ExitException]::new($code)` only at body-extraction time so the body is testable); (c) regression triggers exit 1; (d) verdict transitions to `FAIL_ALLOC` when only allocation exceeds threshold; (e) verdict transitions to `FAIL_LATENCY_AND_ALLOC` when both exceed thresholds. Acceptance: five `It` pass; no real exit of the test host occurs.
- [x] [P1-T6] If P1-T5 cannot be implemented without modifying `compare-benchmarks.ps1` (because top-level `exit` cannot be intercepted from a dot-sourced body), add a minimal additive wrapper to `scripts/benchmarks/compare-benchmarks.ps1`: introduce a function `Invoke-CompareBenchmarksMain` that contains the current top-level loop and returns an integer exit code; the script's top-level then becomes `exit (Invoke-CompareBenchmarksMain @PSBoundParameters)`. Acceptance: behaviour for production callers unchanged (same stdout, same exit codes); script line count remains <= 500; `mcp__drm-copilot__run_poshqc_format` clean; `mcp__drm-copilot__run_poshqc_analyze` clean. Mark this task `[skipped]` in evidence if P1-T5 succeeds without it.

### Phase 2 — Pester Test Authoring for enrich-bdn-report.ps1

- [x] [P2-T1] Create `tests/scripts/benchmarks/enrich-bdn-report.Tests.ps1`. In `BeforeAll` import `Get-Percentile` via the P1-T1 helper. Acceptance: file parses; helper imports succeed.
- [x] [P2-T2] Add `Describe 'Get-Percentile'` with two `It` blocks: single-value set returns that value; multi-value set computes linear interpolation correctly (assert on a known fixture, e.g. values `[1..100]` returns 99.01 at P99 within tolerance). Acceptance: both `It` pass.
- [x] [P2-T3] Add `Describe 'enrich-bdn-report script body'` with three `It` blocks: (a) enrichment success — mock `Get-Content` to return a BDN-shaped JSON without P99, mock `Set-Content` to capture written output, assert P99 added and `Set-Content` invoked once with content containing `"P99"`; (b) file-missing failure — mock `Get-Content` to throw `[System.IO.FileNotFoundException]`, assert the script propagates (Pester `Should -Throw`); (c) idempotent re-enrichment — input JSON already has `P99` and `-Force` not supplied; `Set-Content` is still invoked (per current behaviour writing the unchanged document) but the captured output contains the original P99 unchanged; running the script twice in succession on the same captured payload produces byte-equal output. Mocks declare matching named parameters (`-LiteralPath`, `-Raw`, `-Encoding`). Acceptance: three `It` pass; no real file I/O.

### Phase 3 — Pester Test Authoring for make-synthetic-fixtures.ps1

- [x] [P3-T1] Create `tests/scripts/benchmarks/make-synthetic-fixtures.Tests.ps1`. In `BeforeAll` import `Copy-Report` via the P1-T1 helper. Acceptance: file parses; helper import succeeds.
- [x] [P3-T2] Add `Describe 'Copy-Report'` with one `It`: returns deserialized object equal to source JSON. Mock `Get-Content` to return a known JSON string; assert result has expected `.Benchmarks` array. Acceptance: `It` passes.
- [x] [P3-T3] Add `Describe 'make-synthetic-fixtures script body'` with two `It` blocks: (a) latency-fixture write — mock `Test-Path` for `$BaselinePath` to `$true`, mock `Get-Content` to return a JSON with one benchmark whose FullName contains `Classify_Command` and a `Statistics.Percentiles.P99` of 100.0; mock `Set-Content` to capture writes; assert `Set-Content` invoked with a path ending in `SyntheticLatencyRegressionFixture.json` and content where the matching benchmark's P99 is 110.0; (b) allocation-fixture write — similar, with a benchmark whose FullName contains `InputNormalization_EdgePath` and `Memory.BytesAllocatedPerOperation` of 1000; assert `Set-Content` invoked with a path ending in `SyntheticAllocationRegressionFixture.json` and content where the matching benchmark's bytes-per-op is 1105. Mock `Test-Path` for `$OutputDirectory` to `$true` to avoid `New-Item` calls; if `New-Item` is invoked, also mock it. Acceptance: two `It` pass; no real filesystem writes.

### Phase 4 — Pester Test Authoring for parse-cobertura.ps1

- [x] [P4-T1] Create `tests/scripts/benchmarks/parse-cobertura.Tests.ps1`. Because `parse-cobertura.ps1` has no top-level functions, the test exercises the script body via the P1-T1 extraction helper (top-level statements wrapped as a parameterized scriptblock). Acceptance: file parses.
- [x] [P4-T2] Add `Describe 'parse-cobertura script body'` with three `It` blocks: (a) malformed XML — mock `Get-ChildItem` to return one fake file info; mock `Get-Content` to return `'<not-xml'`; assert the body throws (cast to `[xml]` raises) and the test traps via `Should -Throw`; (b) missing line-rate/branch-rate attribute — mock `Get-Content` to return XML with a `<coverage>` element missing those attributes; assert numeric attributes default to 0 and `AGGREGATE` output line reports `lines-covered=0/0` and `branches-covered=0/0`; (c) aggregation correctness across multiple cobertura files — mock `Get-ChildItem` to return three fake file infos; mock `Get-Content` to return three distinct XML docs with `lines-covered`/`lines-valid`/`branches-covered`/`branches-valid` of (10/20, 30/40, 5/10) and (8/16, 24/32, 4/8); assert the `AGGREGATE:` row reports `lines-covered=45/76` (sum) and `branches-covered=68/96` (sum) and percentages match `45/76` and `68/96`. Mock `Get-Content` signature: `param([Parameter(Mandatory)][string]$LiteralPath)`. Acceptance: three `It` pass.

### Phase 5 — PoshQC Toolchain Run and Coverage Evidence

- [x] [P5-T1] Run `mcp__drm-copilot__run_poshqc_format` over both `scripts/benchmarks/*.ps1` and `tests/scripts/benchmarks/**/*.ps1`. If any file is reformatted, restart from P5-T1 after committing the formatting change. Capture final clean run at `evidence/qa-gates/remediation-poshqc-format.md` (fields: `Timestamp`, `Command`, `EXIT_CODE: 0`, `Output Summary`).
- [x] [P5-T2] Run `mcp__drm-copilot__run_poshqc_analyze` over the same scope with repo settings. Resolve any rule violations introduced by the new test files (zero analyzer errors required; warnings tolerated only if pre-existing in the four scripts and not introduced by tests). Capture final clean run at `evidence/qa-gates/remediation-poshqc-analyze.md`.
- [x] [P5-T3] Run `mcp__drm-copilot__run_poshqc_test` with coverage enabled, scoped to `tests/scripts/benchmarks/` with code-coverage targets `scripts/benchmarks/compare-benchmarks.ps1`, `scripts/benchmarks/enrich-bdn-report.ps1`, `scripts/benchmarks/make-synthetic-fixtures.ps1`, `scripts/benchmarks/parse-cobertura.ps1`. Use the repo Pester runsettings at `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`. Acceptance: all tests pass; coverage XML written to `artifacts/pester/powershell-coverage.xml`.
- [x] [P5-T4] Parse `artifacts/pester/powershell-coverage.xml` and record numeric line and branch coverage per file plus aggregate at `evidence/qa-gates/remediation-powershell-coverage.md` (fields: `Timestamp`, `Command`, `EXIT_CODE`, `Output Summary` including: aggregate line %, aggregate branch %, per-file line %, per-file branch %). Acceptance: aggregate line coverage >= 85%, aggregate branch coverage >= 75%, per-file line coverage >= 85% and branch coverage >= 75% on each of the four target scripts.
- [x] [P5-T5] Capture the final `mcp__drm-copilot__run_poshqc_test` console summary at `evidence/qa-gates/remediation-poshqc-test.md` (fields: `Timestamp`, `Command`, `EXIT_CODE: 0`, `Output Summary` with passed/failed/skipped counts).

### Phase 6 — Full QA Loop (Format -> Analyze -> Type -> Test) and Coverage Delta

- [x] [P6-T1] Run `mcp__drm-copilot__run_poshqc_format` repo-scoped (all `**/*.ps1`/`**/*.psm1`/`**/*.psd1`). If files change, restart from P6-T1. Capture at `evidence/qa-gates/remediation-final-poshqc-format.md`.
- [x] [P6-T2] Run `mcp__drm-copilot__run_poshqc_analyze` repo-scoped with repo settings. Acceptance: 0 errors; no new warnings attributable to this remediation. Capture at `evidence/qa-gates/remediation-final-poshqc-analyze.md`.
- [x] [P6-T3] Type checking: not applicable for PowerShell (per `.claude/rules/powershell.md`); skip with explicit `N/A` record at `evidence/qa-gates/remediation-final-typecheck.md` (fields: `Timestamp`, `Command: N/A`, `EXIT_CODE: 0`, `Output Summary: PowerShell — type checking not applicable per policy`).
- [x] [P6-T4] Run `mcp__drm-copilot__run_poshqc_test` repo-scoped with coverage. Acceptance: all tests pass; coverage XML refreshed at `artifacts/pester/powershell-coverage.xml`; aggregate thresholds still satisfied; no regression on changed lines. Capture at `evidence/qa-gates/remediation-final-poshqc-test.md` (fields: `Timestamp`, `Command`, `EXIT_CODE: 0`, `Output Summary` with totals and coverage headline).
- [x] [P6-T5] Verify no C# files were touched by this remediation. Run `git diff --name-only origin/main...HEAD -- '*.cs' '*.csproj' '*.sln'` and confirm empty output. Capture at `evidence/qa-gates/remediation-final-dotnet-untouched.md` (fields: `Timestamp`, `Command`, `EXIT_CODE`, `Output Summary: 0 C# files changed`). Acceptance: empty diff; no .NET QA re-run required.

### Phase 7 — PR-Context Refresh and Acceptance Criteria Checkoff

- [x] [P7-T1] Re-issue feature-review-workflow: regenerate `policy-audit.<timestamp>.md`, `code-review.<timestamp>.md`, and `feature-audit.<timestamp>.md` at a new ISO timestamp (`2026-05-15T23-30` or later). Acceptance: each refreshed artifact records the prior PowerShell coverage finding as PASS with citation to `evidence/qa-gates/remediation-powershell-coverage.md` and to `artifacts/pester/powershell-coverage.xml`.
- [x] [P7-T2] Confirm AC1-AC8 each remain PASS in the refreshed `feature-audit.<timestamp>.md`. Capture an explicit checkoff table at `evidence/qa-gates/remediation-acceptance-criteria-checkoff.md` listing each AC, its prior status, its post-remediation status, and the supporting evidence path. Acceptance: AC1-AC8 all PASS; zero regressions.
- [x] [P7-T3] Update issue #23 with a remediation-completion comment. Mirror the exact posted text at `evidence/issue-updates/issue-23.<timestamp>.md` with fields: `Timestamp`, posted body, `PostedAs: comment`, GitHub URL, and a reference to `evidence/qa-gates/remediation-acceptance-criteria-checkoff.md`. Acceptance: mirror artifact exists; if posting is blocked, record `POSTING BLOCKED` with the reason.
- [x] [P7-T4] Final remediation summary at `evidence/qa-gates/remediation-summary.2026-05-15T23-30.md` linking every artifact produced during phases 0-7 and stating: remediation pass 1 complete; blocking findings cleared; AC1-AC8 PASS; PowerShell aggregate coverage >= 85% line / >= 75% branch with per-file values. Acceptance: file exists and references all required evidence paths.

---

## Plan-Path Continuity

This plan file (`docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/remediation-plan.2026-05-15T23-00.md`) is the single target for all preflight revisions in this remediation cycle. Revisions update this file in place; no sibling timestamped plan files will be created during this cycle.

## Validator Gate

This plan must pass `mcp__drm-copilot__validate_orchestration_artifacts` with `artifact_type: "plan"` and `artifact_path: docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/remediation-plan.2026-05-15T23-00.md` before it can be treated as approved.
