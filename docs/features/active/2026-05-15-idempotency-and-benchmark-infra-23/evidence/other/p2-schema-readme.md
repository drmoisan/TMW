# [P2-T4] artifacts/benchmarks/README.md Review

Timestamp: 2026-05-15T22-01
EXIT_CODE: 0
Output Summary: README created at `artifacts/benchmarks/README.md`. Documents:
- Explicit schema field list: `FullName`, `Statistics.Percentiles.P99`, `Memory.BytesAllocatedPerOperation`.
- Comparator-facing names: `p99-latency-ns`, `allocated-bytes`.
- Note on BDN's omission of P99 and the enrich-bdn-report.ps1 post-processing step.
- Stage-10 thresholds: p99 > 5% on T1 ids, allocation > 10% any id.
- Rebaselining policy (deliberate human-approved PR).
- Capture command reproducible by stage 10.
