# Edit .claude/rules/quality-tiers.md

Timestamp: 2026-05-18T22-40
Command: Edit tool (remove "Benchmark p99 regression" row at line 45 from tier-dependent gate matrix); Select-String -Path .claude/rules/quality-tiers.md -Pattern 'Benchmark p99 regression'
EXIT_CODE: 0
Output Summary: Row removed; grep returned 0 matches.

## Diff (logical)
Removed line 45:
```
| Benchmark p99 regression | < 5% | < 10% | none | none |
```
Other rows untouched.
