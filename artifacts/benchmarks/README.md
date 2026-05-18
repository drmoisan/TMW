# Benchmark Baselines

This folder holds the committed BenchmarkDotNet (BDN) baseline used by the
pre-merge benchmark regression gate (PR-pipeline stage 10). The single
authoritative file is `baseline.json`.

## Schema Fields Consumed by the Comparator

`scripts/benchmarks/compare-benchmarks.ps1` consumes the following fields per
benchmark entry in BDN's `*-report-full.json` JSON:

- `FullName` (string) — benchmark identifier, for example
  `TaskMaster.Benchmarks.ClassifierBenchmarks.Classify_Command`.
- `Statistics.Median` (double, nanoseconds) — median per-iteration mean
  latency. BDN's `JsonExporter.Full` emits `Statistics.Median` natively, so no
  enrichment is required for this field. The comparator surfaces this as
  `median-latency-ns` in its diff output.
- `Memory.BytesAllocatedPerOperation` (long, bytes) — allocations per
  operation. The comparator surfaces this as `allocated-bytes`.

The gate reads `Statistics.Median` directly from BDN. The repository still
contains `scripts/benchmarks/enrich-bdn-report.ps1`, which historically
computed `P99` from `Statistics.OriginalValues` and wrote it back into
`Statistics.Percentiles` because `JsonExporter.Full` omits `P99` from its
default percentile set. That enrichment remains in the workflows for now but
is no longer consumed by the comparator.

## Stage-10 Thresholds

- Median latency on a T1 benchmark id (matched by the `-T1BenchmarkIdPattern`
  argument to the comparator): a `FAIL_LATENCY` verdict is reported only when
  **both** of the following are true (AND semantics):
  - the relative regression is strictly greater than **5%** (controlled by
    `-LatencyThresholdPercent`, default 5.0), AND
  - the absolute median delta (`median_current_ns - median_baseline_ns`) is
    strictly greater than **25 ns** (controlled by `-LatencyMinDeltaNs`,
    default 25.0).
- Allocated bytes on any benchmarked id: regression strictly greater than
  **10%** blocks the PR. The allocation gate has no absolute floor.

Improvements (negative deltas) never block.

### Why the absolute-delta floor

The classifier benchmarks run at roughly 10–60 ns median latency. On GitHub
`windows-latest` runners, measurement noise (CPU frequency scaling, noisy
neighbors, JIT/GC scheduling) is comparable to the 5% relative threshold at
that scale: small timing jitter on a sub-100 ns benchmark looks like a 5%
regression and produces a false positive on otherwise-clean PRs. The 25 ns
absolute floor establishes a noise-tolerant lower bound so the gate fires
only when a regression is both relatively significant and absolutely visible
above the CI measurement noise floor on sub-100 ns benchmarks. The 25 ns
figure reflects observed CI-runner variance on these benchmarks and is
documented in the commit history for this PR. Larger, genuinely regressing
changes still trip both conditions and continue to block.

## Rebaselining Policy

`baseline.json` is updated only by a deliberate, human-approved PR that:

1. Re-runs the benchmark project locally on a fixed-configuration host.
2. Replaces `baseline.json` with the new `*-report-full.json`.
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

The benchmark configuration (`BenchmarkConfig.cs`) uses a job with 5 warmup
iterations and 20 measurement iterations plus the memory diagnoser so that
`Statistics.Median` is computed over 20 samples per benchmark. The comparator
reads `Statistics.Median` from the resulting report.
