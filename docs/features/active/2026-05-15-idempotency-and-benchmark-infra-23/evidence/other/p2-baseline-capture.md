# [P2-T3] Baseline Capture

Timestamp: 2026-05-15T22-00
Commands:
1. `dotnet run -c Release --project tests/TaskMaster.Benchmarks --no-build -- --filter "*ClassifierBenchmarks*" --exporters JSON --artifacts artifacts/benchmarks/run`
2. `cp artifacts/benchmarks/run/results/TaskMaster.Benchmarks.ClassifierBenchmarks-report-full.json artifacts/benchmarks/baseline.json`
3. `pwsh -NoProfile -File scripts/benchmarks/enrich-bdn-report.ps1 -Path artifacts/benchmarks/baseline.json`

EXIT_CODE: 0
Output Summary:
- 3 classifier benchmarks executed: Classify_Command (mean 8.46ns / 32B), InputNormalization_EdgePath (mean 26.35ns / 248B), TrainingState_Update (mean 4.78ns / 0B).
- Baseline JSON copied to `artifacts/benchmarks/baseline.json`.
- Enrichment step injected `Statistics.Percentiles.P99` per BDN report (BenchmarkDotNet's JsonExporter.Full omits P99 from its default percentile set; the enrichment computes P99 from `Statistics.OriginalValues` so the comparator contract documented in `artifacts/benchmarks/README.md` is satisfied).
- Verified each entry contains `FullName`, `Statistics.Percentiles.P99`, and `Memory.BytesAllocatedPerOperation`.
- P99 values: Classify_Command=8.86, InputNormalization_EdgePath=26.62, TrainingState_Update=4.85.
- Allocated bytes: 32, 248, 0.
