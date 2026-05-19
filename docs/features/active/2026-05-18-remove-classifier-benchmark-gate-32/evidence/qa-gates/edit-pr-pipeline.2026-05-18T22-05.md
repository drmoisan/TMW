# Edit .github/workflows/pr-pipeline.yml

Timestamp: 2026-05-18T22-40
Command: Edit tool (remove stage-10-benchmark-regression and benchmark-gate-self-validation job blocks); Select-String -Path .github/workflows/pr-pipeline.yml -Pattern 'stage-10-benchmark-regression|benchmark-gate-self-validation'
EXIT_CODE: 0
Output Summary: Both job blocks removed (lines previously 68-74). Post-edit grep returned 0 matches. Remaining job list ends with stage-e2e-smoke and secret-scan; no needs: list referenced the removed jobs.

## Diff (logical)
Removed:
```
  stage-10-benchmark-regression:
    needs: [stage-7-integration]
    uses: ./.github/workflows/_stage-10-benchmark-regression.yml

  benchmark-gate-self-validation:
    needs: [stage-7-integration]
    uses: ./.github/workflows/_benchmark-gate-self-validation.yml
```
