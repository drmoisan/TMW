# Edit docs/ci.research.md

Timestamp: 2026-05-18T22-40
Command: Edit tool (remove "Benchmark p99 regression" row from tier-matrix table at line 121); Select-String -Path docs/ci.research.md -Pattern 'Benchmark p99 regression'
EXIT_CODE: 0
Output Summary: Row removed; grep returned 0 matches; surrounding table preserves 5-column structure.

## Diff (logical)
Removed line:
```
| Benchmark p99 regression | < 5% | < 10% | none | none |
```
