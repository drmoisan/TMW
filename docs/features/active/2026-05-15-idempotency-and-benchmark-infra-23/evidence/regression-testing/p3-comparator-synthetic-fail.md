# [P3-T3] Synthetic Latency Regression — Comparator Exits 1

Timestamp: 2026-05-15T22-05
Command: `pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath tests/TaskMaster.Benchmarks/Fixtures/SyntheticLatencyRegressionFixture.json -T1BenchmarkIdPattern "ClassifierBenchmarks"`
EXIT_CODE: 1
Output:
```
id, p99_baseline_ns, p99_current_ns, p99_delta_pct, alloc_baseline_b, alloc_current_b, alloc_delta_pct, verdict
TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command, 8.8601, 9.7462, 10.00, 32, 32, 0.00, FAIL_LATENCY
TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath, 26.6209, 26.6209, 0.00, 248, 248, 0.00, PASS
TaskMaster.Benchmarks.ClassifierBenchmarks.TrainingState_Update, 4.8464, 4.8464, 0.00, 0, 0, 0.00, PASS
```
Output Summary: Synthetic fixture introduces a +10% p99 regression on `ClassifierBenchmarks.Classify_Command` (a T1 hot path). Comparator reports `FAIL_LATENCY` for that id and exits 1, demonstrating the stage-10 gate fires for T1 latency regression above 5%.
