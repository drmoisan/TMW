# Edit .gitignore

Timestamp: 2026-05-18T22-40
Command: Edit tool (remove artifacts/benchmarks block at lines 61-67); Select-String -Path .gitignore -Pattern 'artifacts/benchmarks'; git status --porcelain
EXIT_CODE: 0
Output Summary: Block removed; grep returned 0 matches; git status returned 17 changed lines normally (file remains a valid gitignore).

## Diff (logical)
Removed:
```
# Versioned benchmark baseline (Issue #23): the committed reference run
# consumed by pre-merge pipeline stage 10. Runtime outputs under
# artifacts/benchmarks/run*/ remain ignored via the trailing patterns below.
!artifacts/benchmarks/
artifacts/benchmarks/*
!artifacts/benchmarks/baseline.json
!artifacts/benchmarks/README.md
```
