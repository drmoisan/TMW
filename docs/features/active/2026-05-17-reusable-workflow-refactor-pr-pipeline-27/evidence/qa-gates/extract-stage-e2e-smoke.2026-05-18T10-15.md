# Phase 2 extraction - stage-e2e-smoke

Timestamp: 2026-05-18T10-15
Command: ConvertFrom-Yaml .github/workflows/_stage-e2e-smoke.yml + structural diff of jobs.stage-e2e-smoke.steps vs evidence/baseline/pr-pipeline.pre-refactor.yml; actionlint .github/workflows/_stage-e2e-smoke.yml
EXIT_CODE: 0

Output Summary: callee .github/workflows/_stage-e2e-smoke.yml parses OK; actionlint clean; steps block byte-identical to baseline jobs.stage-e2e-smoke.steps (verified by powershell-yaml round-trip equality). needs: relocated to caller (Phase 3).
Declared workflow_call.secrets: AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, E2E_API_BASE_URL (all required: true). if-guard NOT moved to callee (remains caller-level per spec invariant).
