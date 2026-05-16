# [P3-T2] Comparator Self-Compare Rows

Timestamp: 2026-05-15T22-03
Command: `pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath artifacts/benchmarks/baseline.json`
EXIT_CODE: 0
Output:
```
id, p99_baseline_ns, p99_current_ns, p99_delta_pct, alloc_baseline_b, alloc_current_b, alloc_delta_pct, verdict
TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command, 8.8601, 8.8601, 0.00, 32, 32, 0.00, PASS
TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath, 26.6209, 26.6209, 0.00, 248, 248, 0.00, PASS
TaskMaster.Benchmarks.ClassifierBenchmarks.TrainingState_Update, 4.8464, 4.8464, 0.00, 0, 0, 0.00, PASS
```
Output Summary: Per-row diff verified: id, p99 baseline/current/delta, alloc baseline/current/delta, verdict. All PASS.
