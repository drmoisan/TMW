# Benchmark Baselines

This folder holds the committed BenchmarkDotNet (BDN) baseline used by the
pre-merge benchmark regression gate (PR-pipeline stage 10). The single
authoritative file is `baseline.json`.

## Schema Fields Consumed by the Comparator

`scripts/benchmarks/compare-benchmarks.ps1` consumes the following fields per
benchmark entry in BDN's `*-report-full.json` JSON:

- `FullName` (string) — benchmark identifier, for example
  `TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command`.
- `Statistics.Percentiles.P99` (double, nanoseconds) — p99 latency. The
  comparator surfaces this as `p99-latency-ns` in its diff output.
- `Memory.BytesAllocatedPerOperation` (long, bytes) — allocations per
  operation. The comparator surfaces this as `allocated-bytes`.

BenchmarkDotNet's `JsonExporter.Full` omits `P99` from its default percentile
set (`P0/P25/P50/P67/P80/P85/P90/P95/P100`). The pipeline therefore enriches
the report immediately after capture using
`scripts/benchmarks/enrich-bdn-report.ps1`, which computes `P99` from
`Statistics.OriginalValues` and writes it back into `Statistics.Percentiles`.

## Stage-10 Thresholds

- p99 latency on a T1 benchmark id (matched by the `-T1BenchmarkIdPattern`
  argument to the comparator): a `FAIL_LATENCY` verdict is reported only when
  **both** of the following are true (AND semantics):
  - the relative regression is strictly greater than **5%** (controlled by
    `-LatencyThresholdPercent`, default 5.0), AND
  - the absolute p99 delta (`p99_current_ns - p99_baseline_ns`) is strictly
    greater than **5 ns** (controlled by `-LatencyMinDeltaNs`, default 5.0).
- Allocated bytes on any benchmarked id: regression strictly greater than
  **10%** blocks the PR. The allocation gate has no absolute floor.

Improvements (negative deltas) never block.

### Why the absolute-delta floor

The classifier benchmarks run at roughly 10–60 ns p99. On GitHub
`windows-latest` runners, measurement noise (CPU frequency scaling, noisy
neighbors, JIT/GC scheduling) is comparable to the 5% relative threshold at
that scale: a 0.5 ns timing jitter on a 10 ns benchmark looks like a 5%
regression and produces a false positive on otherwise-clean PRs. The 5 ns
absolute floor establishes a noise-tolerant lower bound so the gate fires
only when a regression is both relatively significant and absolutely visible
above the CI measurement noise floor on sub-100 ns benchmarks. Larger,
genuinely regressing changes still trip both conditions and continue to
block.

## Rebaselining Policy

`baseline.json` is updated only by a deliberate, human-approved PR that:

1. Re-runs the benchmark project locally on a fixed-configuration host.
2. Replaces `baseline.json` with the new `*-report-full.json` and reruns
   `scripts/benchmarks/enrich-bdn-report.ps1` so the P99 field is present.
3. Records the justification in the PR description (which benchmark moved,
   why the new floor is acceptable, and any links to root-cause analysis).

Rebaselines are PR-reviewable; the regression gate must not be silently lowered.

## Reproducibility

The capture command used by stage 10 is:

```
dotnet run -c Release --project tests/TaskMaster.Benchmarks -- \
  --filter "*ClassifierBenchmarks*" \
  --exporters JSON \
  --artifacts artifacts/benchmarks/run
```

The benchmark configuration (`BenchmarkConfig.cs`) uses `Job.ShortRun` plus
the memory diagnoser so the run is deterministic enough to gate PRs but short
enough to fit pre-merge CI budgets.
