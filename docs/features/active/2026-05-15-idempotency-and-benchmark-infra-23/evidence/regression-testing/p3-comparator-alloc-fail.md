# [P3-T4] Synthetic Allocation Regression — Comparator Exits 1

Timestamp: 2026-05-15T22-05
Command: `pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath tests/TaskMaster.Benchmarks/Fixtures/SyntheticAllocationRegressionFixture.json -T1BenchmarkIdPattern "ClassifierBenchmarks"`
EXIT_CODE: 1
Output:
```
id, p99_baseline_ns, p99_current_ns, p99_delta_pct, alloc_baseline_b, alloc_current_b, alloc_delta_pct, verdict
TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command, 8.8601, 8.8601, 0.00, 32, 32, 0.00, PASS
TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath, 26.6209, 26.6209, 0.00, 248, 274, 10.48, FAIL_ALLOC
TaskMaster.Benchmarks.ClassifierBenchmarks.TrainingState_Update, 4.8464, 4.8464, 0.00, 0, 0, 0.00, PASS
```
Output Summary: Synthetic fixture introduces a +10.5% allocation regression on `ClassifierBenchmarks.InputNormalization_EdgePath` (raised from the default Classify_Command target whose 32-byte allocation rounds to 35B / +9.4% — under the 10% threshold). With InputNormalization (248B baseline → 274B = +10.48%), the comparator reports `FAIL_ALLOC` and exits 1, demonstrating allocation-regression detection above the 10% threshold.
