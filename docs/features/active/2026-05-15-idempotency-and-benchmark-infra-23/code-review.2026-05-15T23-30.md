# Code Review — idempotency-and-benchmark-infra (Issue #23), Pass 2 (post-remediation refresh)

- Timestamp: 2026-05-15T23-30
- Prior review: `code-review.2026-05-15T23-00.md`

## PowerShell Code — Observations

- `scripts/benchmarks/compare-benchmarks.ps1` refactored to add `Invoke-CompareBenchmarksMain` wrapper that returns an integer exit code. `Read-BenchmarkReport` converted from `exit 2` to `throw` with `.Data['ExitCode']=2`; the wrapper catches the typed exception and returns 2. Top-level guard `if ($MyInvocation.InvocationName -ne '.')` calls the wrapper via `exit (...)`. Observable behaviour preserved: same stdout schema, same exit codes for production callers.
- Three other scripts (`enrich-bdn-report.ps1`, `make-synthetic-fixtures.ps1`, `parse-cobertura.ps1`) unchanged.
- New helper module `tests/scripts/benchmarks/_helpers/Import-ScriptFunctions.ps1` extracts top-level function definitions from a script via AST and returns them as a `[scriptblock]` for dot-source into Pester `BeforeAll`. Used by `enrich-bdn-report.Tests.ps1` and `make-synthetic-fixtures.Tests.ps1` for the helper-function tests (`Get-Percentile`, `Copy-Report`).
- For the script-body tests, the production scripts are invoked directly via `& $scriptPath` with Pester mocks at the wrapper-function seams (`Get-Content`, `Set-Content`, `Test-Path`, `New-Item`, `Get-ChildItem`); coverage is attributed to the production script files.
- New `scripts/powershell/PoshQC/settings/pester.runsettings.psd1` adds repo-local Pester runsettings with the four benchmark scripts in `CodeCoverage.Path`, enabling the coverage XML to reflect the scope required by the remediation plan. The bundled PoshQC runsettings (in the VS Code extension) restrict coverage to `.claude/hooks/*.ps1` and were not modified.

## Test Quality

- 28 Pester tests across four `*.Tests.ps1` files, organized into `Describe`/`Context`/`It`.
- Mocks declare matching named parameters where production calls use `-LiteralPath`/`-Path`.
- No real filesystem writes; no temporary files; deterministic.
- Floating-point assertions use absolute tolerance where round-trip JSON serialization may introduce micro-deltas.

## Verdict

No blocking findings. The remediation pass introduces no new code-review concerns.
