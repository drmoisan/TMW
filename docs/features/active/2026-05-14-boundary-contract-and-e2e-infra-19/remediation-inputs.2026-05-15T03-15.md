# Remediation Inputs — boundary-contract-and-e2e-infra (Issue #19)

- Timestamp: 2026-05-15T03-15
- Companion artifacts:
  - `policy-audit.2026-05-15T03-15.md`
  - `code-review.2026-05-15T03-15.md`
  - `feature-audit.2026-05-15T03-15.md`

This document lists items that warrant follow-up. None of these are blocking findings for Issue #19's merge; they are recorded so a future remediation pass or follow-up issue can address them without losing context.

## Remediation-required findings

### R1 — `TaskMaster.Api` repo-wide coverage is below uniform thresholds (pre-existing)

- Source: policy-audit (Coverage Verification — C#) and `evidence/qa-gates/coverage-delta.md`.
- Observation: `TaskMaster.Api` line coverage is 23.18% and branch coverage is 6.14% in the post-change state. The uniform thresholds are line >= 85% / branch >= 75%.
- Provenance: pre-existing baseline gap (baseline was 18.97% / 4.12%). Issue #19 improved coverage by +4.21 pp / +2.02 pp while adding +40 valid lines.
- Suggested treatment: a separate follow-up to expand `TaskMaster.Api.Tests` host-integration coverage for `Program.cs` minimal-API endpoints and DI registration paths.
- Blocking for Issue #19? No. The "no regression on changed lines" gate is satisfied; the absolute threshold gap is pre-existing.

### R2 — AC9 not empirically verified end-to-end (CI run pending)

- Source: feature-audit (AC9 row); `evidence/regression-testing/validation-e2e-smoke.md`.
- Observation: The Playwright suite-pass case against the test tenant cannot be executed locally because the four required secrets are unavailable. The CI wiring is in place; success will be observable on the first PR carrying the `e2e:run` label.
- Suggested treatment: ensure repository secrets `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `E2E_API_BASE_URL` are populated before applying the `e2e:run` label or merging into the merge queue, so the first CI invocation produces direct evidence for AC9.
- Blocking for Issue #19? No. The plan's `[expect-pass]` task text permits documenting the gated CI invocation path in lieu of a local run.

## Non-required follow-ups (informational)

### I1 — `parseClassifyResponse` error path uses `JSON.stringify` on `unknown`

- Source: code-review F1.
- Suggested treatment: wrap stringify in a try/catch with a `String(value)` fallback.

### I2 — Smoke spec accepts `confidence` as `number` or `string`

- Source: code-review F3.
- Suggested treatment: tighten to `typeof body.confidence === "number"` once the suite has run green against the test tenant.

### I3 — `openapi-fetch` declared as runtime dep but currently unused at runtime

- Source: code-review (Dependencies section).
- Suggested treatment: confirm whether the dependency should remain `dependencies` or move to `devDependencies` until the deferred `createClient` migration consumes it.

### I4 — `info.version` derives from `Assembly.GetName().Version` with a silent `"1.0.0"` fallback

- Source: code-review F4.
- Suggested treatment: prefer `<InformationalVersion>`/`<Version>` MSBuild constants, or throw if the assembly version is null, to remove the silent-fallback path.

### I5 — E2E token channel via `storageState.localStorage` is indirect

- Source: code-review F5.
- Suggested treatment: switch to Playwright's `extraHTTPHeaders` fixture when the suite is next revised.
