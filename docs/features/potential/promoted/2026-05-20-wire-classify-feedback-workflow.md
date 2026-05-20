# wire-classify-feedback-workflow (Issue #37)

- Date captured: 2026-05-20
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/wire-classify-feedback-workflow/ (Issue #37)

- Issue: #37
- Issue URL: https://github.com/drmoisan/TMW/issues/37
- Last Updated: 2026-05-20
## Problem / Why

The task pane renders a Classify / Confirm / Reject control surface, but the
classify/feedback workflow is not wired into the product on any platform. The button
exists in markup but has no click handler, the HTTP client is never instantiated in
product code, and no bearer token is ever obtained. This was discovered during the
Outlook Mobile iOS work (issue #35) when on-device verification of P6-T5 ("classification
succeeds over HTTPS") could not pass — tapping Classify is inert on desktop and mobile
alike. Issue #35 was scoped to mobile enablement (manifest + responsive UI) and explicitly
made no `src` logic changes, so this gap is tracked separately here.

Evidence (as of 2026-05-20):
- `src/taskpane/taskpane.html` defines `classify-btn`, `confirm-btn`, `reject-btn`, and
  `classification-result`.
- `src/taskpane/taskpane.ts` `getRenderDom()` collects only `status`, `selected-subject`,
  `selected-from`; `Office.onReady` wires `ItemChanged` and the Close button only — no
  handler is attached to `classify-btn`.
- `ClassifierClient` (`src/taskpane/classifier-client.ts`) is instantiated only in its unit
  test, never in product code. The pure helpers `renderClassifying` /
  `renderClassificationResult` exist and are unit-tested but are never called from product
  wiring.
- `ClassifierClient.classify(req, bearerToken)` requires a bearer token; nothing in the
  codebase obtains one (no SSO / `getAccessToken`).

## Proposed Behavior

Wire the classify/confirm/reject workflow end to end:
- Attach a click handler to `classify-btn` that reads the current item, calls
  `ClassifierClient.classify`, and renders the result via the existing
  `renderClassifying` / `renderClassificationResult` helpers.
- Wire `confirm-btn` / `reject-btn` to `ClassifierClient.recordFeedback`.
- Provide the classifier `baseUrl` via build-time injection (consistent with the
  `urlDev`/`urlProd` webpack pattern).
- Implement a bearer-token source (e.g., Office SSO `getAccessToken`), including the
  unsupported-host fallback path.

## Acceptance Criteria (early draft)

- [ ] Tapping Classify calls the backend and displays label + confidence.
- [ ] Confirm/Reject become enabled after a classification and post feedback.
- [ ] Classifier `baseUrl` is build-injected, not hard-coded.
- [ ] A bearer token is obtained and attached; failure paths handled.
- [ ] Unit coverage for the new wiring meets repository thresholds.
- [ ] Works on Outlook iOS (verifies #35 P6-T5 end to end).

## Constraints & Risks

- No-COM, Office.js-only architecture boundary holds.
- Bearer-token acquisition on Outlook iOS must use supported APIs (no remote DevTools for
  debugging on device).
- Classifier backend must be reachable over trusted HTTPS from the device for mobile use.

## Test Conditions to Consider

- [ ] Unit tests for the classify/confirm/reject click handlers (DOM + client mocked).
- [ ] Token-acquisition success and failure paths.
- [ ] Integration/contract check against the classifier OpenAPI schema.

## Next Step

- [ ] Promote to GitHub issue (feature request template)
- [ ] Create `docs/features/active/wire-classify-feedback-workflow/` folder from the template