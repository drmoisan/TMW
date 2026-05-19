# Phase 6 — secrets surface verified for stage-e2e-smoke

Timestamp: 2026-05-18T10-15
Command: ConvertFrom-Yaml .github/workflows/_stage-e2e-smoke.yml + .github/workflows/pr-pipeline.yml; inspect on.workflow_call.secrets keys and jobs.stage-e2e-smoke.secrets
EXIT_CODE: 0

Callee `_stage-e2e-smoke.yml`:
- on.workflow_call.secrets keys: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, E2E_API_BASE_URL (all required: true).

Caller `pr-pipeline.yml`:
- jobs.stage-e2e-smoke.secrets: `inherit` (forwards every available secret to the callee).

Output Summary: all four expected secrets declared on the callee; caller passes secrets: inherit. Secrets contract intact.
