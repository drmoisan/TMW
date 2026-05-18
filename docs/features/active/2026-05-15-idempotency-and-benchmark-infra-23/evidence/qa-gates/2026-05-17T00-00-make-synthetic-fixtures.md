# QA Gate: make-synthetic-fixtures update

Timestamp: 2026-05-17T00:00Z
Scope:
- scripts/benchmarks/make-synthetic-fixtures.ps1
- tests/scripts/benchmarks/make-synthetic-fixtures.Tests.ps1
- tests/TaskMaster.Benchmarks/Fixtures/SyntheticLatencyRegressionFixture.json (regenerated)
- tests/TaskMaster.Benchmarks/Fixtures/SyntheticAllocationRegressionFixture.json (regenerated)

## Toolchain (MCP PoshQC tools not registered in this session; used direct Invoke-* equivalents)

### Format (Invoke-Formatter)
Command: pwsh Invoke-Formatter on the two PowerShell files
EXIT_CODE: 0
Output Summary: both files unchanged (already formatted)

### Analyze (Invoke-ScriptAnalyzer)
Command: Invoke-ScriptAnalyzer -Path <file> -Severity Error,Warning,Information
EXIT_CODE: 0
Output Summary: 0 findings on make-synthetic-fixtures.ps1; 0 findings on make-synthetic-fixtures.Tests.ps1

### Pester
Command: Invoke-Pester -Path tests/scripts/benchmarks
EXIT_CODE: 0
Output Summary: Total=37 Passed=37 Failed=0 Skipped=0

## Comparator verification against regenerated latency fixture

Command:
pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath tests/TaskMaster.Benchmarks/Fixtures/SyntheticLatencyRegressionFixture.json -T1BenchmarkIdPattern ClassifierBenchmarks

CSV output:
id, median_baseline_ns, median_current_ns, median_delta_pct, alloc_baseline_b, alloc_current_b, alloc_delta_pct, verdict
TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command, 14.9781, 14.9781, 0.00, 32, 32, 0.00, PASS
TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath, 64.6621, 129.3242, 100.00, 248, 248, 0.00, FAIL_LATENCY
TaskMaster.Benchmarks.ClassifierBenchmarks.TrainingState_Update, 9.0020, 9.0020, 0.00, 0, 0, 0.00, PASS

$LASTEXITCODE: 1

Verdict: Gate fires as required. InputNormalization_EdgePath shows median_delta_pct=100.00 (>5) and absolute delta ~64.66 ns (>25).
