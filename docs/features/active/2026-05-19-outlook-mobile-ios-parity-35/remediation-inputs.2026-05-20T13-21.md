# Remediation Inputs — outlook-mobile-ios-parity (Issue #35)

- Issue: #35
- Date: 2026-05-20
- Resolved base branch: `main` @ `b25e678bd82312301eaad971b1a04173915e2314`
- Head SHA under review: `de298e6705f16131993a0f231bf5a1b2a356dc37`
- Source audits:
  - `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/policy-audit.2026-05-20T13-21.md`
  - `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/code-review.2026-05-20T13-21.md`
  - `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/feature-audit.2026-05-20T13-21.md`

## Remediation Determination

No remediation is required for issue #35. None of the remediation trigger conditions fire:

- Policy audit verdict: PASS (no meaningful FAIL or PARTIAL findings).
- Toolchain checks: all seven stages pass in a single pass (format, lint, type-check,
  architecture, unit, contract/schema, integration-as-feasible).
- Code review: zero Critical/High/Medium findings; zero blockers. Only informational items.
- Required acceptance criteria: all 13 CI-verifiable and the 3 in-scope on-device criteria
  (P6-T2/T3/T4) are PASS. Criterion 17 (P6-T5) is N/A by product-owner decision, out of
  scope for #35, and tracked as issue #37 — it is not a FAIL/PARTIAL of this branch.
- Coverage: TypeScript repo-wide 98.01% line / 93.87% branch; changed file `taskpane.ts`
  96.47% / 90.62%; all above the uniform 85% / 75% thresholds, no regression on changed lines.
  Coverage artifact `coverage/lcov.info` present for the only changed-source language.
- Coverage artifact presence: satisfied for TypeScript (the only language with changed source
  files). Python/PowerShell/C# have zero changed source files; their absence is acceptable.

Blocking findings count: 0.

Because no remediation trigger fired, no remediation plan file is created and no
`atomic_planner` handoff is performed for issue #35.

## Blocking Findings

None.

## Non-Blocking / Tracked-Elsewhere Items (informational; not #35 remediation)

These are recorded for traceability only. They are out of scope for issue #35 and must not be
folded into a #35 remediation cycle.

1. Unwired classify/confirm/reject workflow.
   - Files: `src/taskpane/taskpane.ts` (no handler on `classify-btn`; `getRenderDom()` omits
     classify controls; `ClassifierClient` never instantiated in product code; no bearer
     token), `src/taskpane/taskpane.html` (controls present in markup only).
   - Expected behavior (for #37, not #35): tapping Classify calls the backend and renders
     label/confidence; Confirm/Reject post feedback; `baseUrl` build-injected; bearer token
     obtained with failure-path handling; unit coverage meets thresholds.
   - Tracking: GitHub issue #37 (wire-classify-feedback-workflow);
     `docs/features/potential/promoted/2026-05-20-wire-classify-feedback-workflow.md`.
   - Verification command when addressed under #37: `npm run test:coverage`, plus on-device
     classify success re-test for #35 P6-T5.

2. `webpack.config.js` `urlProd` placeholder.
   - File/location: `webpack.config.js` L8 (`https://www.contoso.com/`).
   - Note: intentional for this feature; device verification used a transient, uncommitted Dev
     Tunnel URL. Set `urlProd` to a managed staging host when one exists (future work, not a
     #35 blocker).

3. dependency-cruiser `no-orphans` warning on generated `src/api-client/v1.ts`.
   - Optional: add an explicit orphan exception for generated clients in
     `.dependency-cruiser.cjs`. Non-blocking (0 errors, exit 0).

## Do-Not-Do List

- Do not wire the classify/feedback workflow into `src/` as part of issue #35; that is issue
  #37's scope and would expand #35 beyond its no-`src`-logic-change boundary.
- Do not weaken any policy, coverage threshold, or toolchain gate to accommodate the items
  above.
- Do not silently skip the P6-T5 criterion or re-label it PASS; it remains N/A with a
  documented root cause and the #37 tracking reference.
- Do not commit a transient Dev Tunnel URL into `webpack.config.js` `urlProd`.
