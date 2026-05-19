# Baseline — actionlint over Renamed Callees + Orchestrator

- Timestamp: 2026-05-19T08-44
- Issue: #33
- Command (plan): `actionlint -color=never <files>`
- Command (executed): `actionlint -no-color .github/workflows/_stage-1-format.yml .github/workflows/_stage-2-lint.yml .github/workflows/_stage-3-typecheck.yml .github/workflows/_stage-5-test.yml .github/workflows/_stage-7-integration.yml .github/workflows/pr-pipeline.yml`
- EXIT_CODE: 0
- actionlint version: 1.7.11

## Deviation Note

The plan's stated flag `-color=never` is not valid for actionlint v1.7.11 (it expects a boolean for `-color`). The semantically equivalent flag in this version is `-no-color`, which was used. No behavioral difference in linting outcome.

## Output Summary

actionlint produced 0 diagnostics across all six workflow files (five callees + orchestrator). Baseline is clean.
