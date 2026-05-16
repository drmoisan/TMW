# [P6-T1] Stage 10 Workflow YAML

Timestamp: 2026-05-15T22-20
Command: `pwsh -NoProfile -Command "Get-Content '.github/workflows/pr-pipeline.yml' -Raw | ConvertFrom-Yaml"`
EXIT_CODE: 0
Output Summary: YAML parses cleanly. New job `stage-10-benchmark-regression` runs on `windows-latest`, depends on `stage-7-integration`, and performs:
1. `actions/checkout@v4`
2. `actions/setup-dotnet@v4` with `global-json-file: global.json`
3. Run benchmarks: `dotnet run -c Release --project tests/TaskMaster.Benchmarks -- --filter "*ClassifierBenchmarks*" --exporters JSON --artifacts artifacts/benchmarks/run`
4. Enrich BDN report with P99 via `scripts/benchmarks/enrich-bdn-report.ps1`
5. Compare via `pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath <report> -T1BenchmarkIdPattern "ClassifierBenchmarks"`

Comparator exit code propagates through the job, blocking the PR on regression.
