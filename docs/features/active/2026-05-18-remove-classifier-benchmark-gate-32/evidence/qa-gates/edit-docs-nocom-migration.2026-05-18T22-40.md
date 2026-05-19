# Edit docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md

Timestamp: 2026-05-18T22-40
Command: Edit tool (rephrase bullet at line 1020 to omit `artifacts/benchmarks/baseline.json` reference); Select-String -Path docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md -Pattern 'artifacts/benchmarks'
EXIT_CODE: 0
Output Summary: Path reference removed; grep returned 0 matches; surrounding paragraph reads coherently.

## Diff (logical)
Before:
```
- BenchmarkDotNet referenced from a dedicated `*.Benchmarks` project; baseline runs are recorded in `artifacts/benchmarks/baseline.json`.
```
After:
```
- BenchmarkDotNet referenced from a dedicated `*.Benchmarks` project.
```

## Excerpt of edited paragraph (5 lines surrounding)
```
Required outcome:

- BenchmarkDotNet referenced from a dedicated `*.Benchmarks` project.
- Pre-merge pipeline stage 10 (benchmark regression) compares each PR's results to the baseline; p99 latency regression > 5% on T1 hot paths or allocation regression > 10% blocks the PR.
- An idempotency test fixture is provided that runs the same Graph-subscription notification through the worker N times and asserts the post-state matches a single-execution post-state, using `FakeTimeProvider` and a deterministic message-id seed.
```

Note: The plan's P4-T9 scope is strictly the `artifacts/benchmarks` string per the grep target. Line 1021's "Pre-merge pipeline stage 10 (benchmark regression)" prose remains; it is not within the seven grep-sweep patterns and is therefore not in scope for this plan.
