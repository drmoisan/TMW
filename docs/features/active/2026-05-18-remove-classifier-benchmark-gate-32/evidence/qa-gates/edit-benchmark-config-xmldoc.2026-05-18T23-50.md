# P6-T15 — Edit BenchmarkConfig.cs XML doc-comment to remove compare-benchmarks.ps1 reference

- Timestamp: 2026-05-18T23-50
- Task: P6-T15
- File edited: `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs`

## Diff

Replaced (lines 11-13 of original):

```
/// is stable against single-iteration jitter on shared CI runners. Includes the
/// memory diagnoser to capture allocations and the full JSON exporter so the
/// statistics consumed by <c>scripts/benchmarks/compare-benchmarks.ps1</c> are emitted.
```

With:

```
/// is stable against single-iteration jitter on shared CI runners. Includes the
/// memory diagnoser to capture allocations and the full JSON exporter for downstream analysis.
```

## Verification

### Select-String

- Command: `Select-String -Path tests/TaskMaster.Benchmarks/BenchmarkConfig.cs -Pattern 'compare-benchmarks'`
- EXIT_CODE: 0
- Output Summary: no matches (zero hits)

### dotnet build

- Command: `dotnet build tests/TaskMaster.Benchmarks -c Release`
- EXIT_CODE: 0
- Output Summary: Build succeeded. 0 Warning(s). 0 Error(s). TaskMaster.Benchmarks.dll produced under bin/Release/net10.0/.

## Result

PASS. Stale XML doc reference removed; project still compiles cleanly.
