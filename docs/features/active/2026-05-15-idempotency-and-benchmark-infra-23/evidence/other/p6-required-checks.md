# [P6-T3] Required Checks Documentation

Timestamp: 2026-05-15T22-21
EXIT_CODE: 0

Two new jobs are added to `.github/workflows/pr-pipeline.yml` and are intended to be configured as required PR checks for the `main` branch:

1. `stage-10-benchmark-regression` — benchmark regression gate (AC3 / AC7).
2. `benchmark-gate-self-validation` — proves the gate fires for both synthetic latency regression (AC7) and deliberately non-idempotent handler (AC8).

Repository administrators must add both job names to the branch-protection "Require status checks to pass before merging" list for `main`. Branch-protection settings are not managed in repository files and so cannot be updated from this PR; this artifact records the requirement so the repo owner can configure them after merge.

No other workflow files were modified (verified by `git diff --name-only -- .github/`).
