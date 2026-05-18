# [P7-T7] Stage 10 Local Dry-Run

Timestamp: 2026-05-15T22-29
Commands:
1. `dotnet run -c Release --project tests/TaskMaster.Benchmarks --no-build -- --filter "*ClassifierBenchmarks*" --exporters JSON --artifacts artifacts/benchmarks/run-p7`
2. `pwsh -NoProfile -File scripts/benchmarks/enrich-bdn-report.ps1 -Path artifacts/benchmarks/run-p7/results/TaskMaster.Benchmarks.ClassifierBenchmarks-report-full.json`
3. `pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath artifacts/benchmarks/run-p7/results/TaskMaster.Benchmarks.ClassifierBenchmarks-report-full.json -T1BenchmarkIdPattern "ClassifierBenchmarks"`

EXIT_CODE: 0
Output:
```
id, p99_baseline_ns, p99_current_ns, p99_delta_pct, alloc_baseline_b, alloc_current_b, alloc_delta_pct, verdict
TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command, 8.8601, 7.6025, -14.19, 32, 32, 0.00, PASS
TaskMaster.Benchmarks.ClassifierBenchmarks.InputNormalization_EdgePath, 26.6209, 25.3524, -4.77, 248, 248, 0.00, PASS
TaskMaster.Benchmarks.ClassifierBenchmarks.TrainingState_Update, 4.8464, 4.8640, 0.36, 0, 0, 0.00, PASS
```
Output Summary: A freshly-produced run measured slightly faster than the committed baseline (negative latency deltas) and identical allocations; all three benchmarks PASS the stage-10 thresholds. The end-to-end stage-10 path is verified locally.
