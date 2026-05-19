# Edit .github/workflows/README.md

Timestamp: 2026-05-18T22-40
Command: Edit tool (remove three deleted-workflow rows from inventory table, two dispatch lines, two branch-protection table rows, and the bullet for benchmark-baseline-refresh); Select-String -Path .github/workflows/README.md -Pattern 'stage-10-benchmark-regression|benchmark-gate-self-validation|benchmark-baseline-refresh'
EXIT_CODE: 0
Output Summary: All references removed; grep returned 0 matches. Inventory table renumbering: _stage-e2e-smoke remains row 14, _secret-scan becomes row 15 (was 17). Markdown table column counts consistent on remaining rows.

## Diff (logical)
- Removed inventory rows 15 and 16 (stage-10, benchmark-gate-self-validation); renumbered _secret-scan from 17 to 15.
- Removed bullet "- `benchmark-baseline-refresh.yml` — manual benchmark baseline refresh (out of scope)."
- Removed dispatch lines for `_stage-10-benchmark-regression.yml` and `_benchmark-gate-self-validation.yml`.
- Removed branch-protection table rows for `stage-10-benchmark-regression` and `benchmark-gate-self-validation`.
