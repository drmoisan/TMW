# pr-pipeline.yml needs: audit

Timestamp: 2026-05-18T22-40
Command: Select-String -Path .github/workflows/pr-pipeline.yml -Pattern 'stage-10-benchmark-regression|benchmark-gate-self-validation'
EXIT_CODE: 0
Output Summary: 0 matches; no needs: list still references the removed job names.
