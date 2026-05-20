# Code Review — outlook-mobile-ios-parity (Issue #35)

- Issue: #35
- Date: 2026-05-20
- Resolved base branch: `main` @ `b25e678bd82312301eaad971b1a04173915e2314`
- Head SHA under review: `de298e6705f16131993a0f231bf5a1b2a356dc37`
- Range: `b25e678..de298e6` (50 files, +1564 / -1)
- Scope: full branch diff vs base. Only TypeScript has changed source files; no Python files
  changed (typed-Python review not applicable).

> Template provenance: the MCP `code-review-template` asset is not exposed as a callable tool
> in this environment and no repository code-review template file exists. This artifact was
> authored directly with the required `## Executive Summary` and `## Findings Table` sections
> and the mandated findings-table header.

## Executive Summary

The change set is small in `src/` and well-isolated. The only new runtime logic is the
guarded `closeTaskpane()` host call and its bootstrap wiring in `src/taskpane/taskpane.ts`;
render logic remains pure and Office-free, preserving testability. The new `manifest.xml`
correctly mirrors the desktop configuration and adds a `<MobileFormFactor>` referencing the
same hosted bundle, and it validates against the add-in manifest schema with Outlook iOS
reported as a supported platform. The webpack `<AppDomain>` production-rewrite fix in commit
`de298e6` is correct and minimal: widening the copy glob to `manifest*.{json,xml}` plus the
`<AppDomain>` trailing slash makes the existing `urlDev`→`urlProd` find-replace cover the
AppDomain, eliminating the residual `localhost` reference in the built `dist/manifest.xml`.

Code quality is consistent with repository standards: strong typing, `unknown` + narrowing
rather than `any`, fail-fast `requireElement()`, Arrange–Act–Assert tests, deterministic mocks.
Coverage on changed files exceeds the uniform thresholds. No blocking findings were identified.
The notable functional limitation — the classify/feedback workflow is not wired into the
product on any platform — is real and independently confirmed, but it is a pre-existing gap
explicitly out of scope for issue #35 and tracked as issue #37; it is not introduced or
worsened by this branch.

## Findings Table

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| Info | src/taskpane/taskpane.ts | onReady L135-143; getRenderDom L98-104 | The `classify-btn`/`confirm-btn`/`reject-btn` controls in the HTML have no handlers wired; `getRenderDom()` collects only status/subject/from; `ClassifierClient` is never instantiated in product code; no bearer token is obtained. Classify is inert on desktop and mobile. | No action in #35. Resolve under issue #37 (wire-classify-feedback-workflow). Keep mobile parity reasoning documented. | Pre-existing functional gap; #35 is mobile enablement with explicitly no `src` wiring changes. Mobile parity holds because classify is equally inert on both surfaces. | `src/taskpane/taskpane.ts` L98-104, L135-143; `src/taskpane/taskpane.html` L32-37; `evidence/notes/sideload-and-render.2026-05-20T09-45.md` P6-T5 section; issue #37 |
| Info | src/api-client/v1.ts | whole file | dependency-cruiser reports a `no-orphans` warning on the generated OpenAPI client. | Leave as-is or add an explicit orphan exception for generated clients in `.dependency-cruiser.cjs`. | Generated file with no importer in the current graph; 0 errors, exit 0; non-blocking. | `npm run depcruise` output: "1 dependency violations (0 errors, 1 warnings)" |
| Info | webpack.config.js | L8 urlProd | `urlProd` remains the placeholder `https://www.contoso.com/`; device builds depend on a transient Dev Tunnel URL set at build time and reverted (not committed). | Acceptable for this feature (device verification only). When a managed staging host exists, set `urlProd` to it and capture as evidence. | The spec accepts a transient endpoint for on-device verification; the placeholder is intentional and documented. | `webpack.config.js` L8; `evidence/notes/hosting-endpoint.md` build-provenance note |
| Info | manifest.xml | L14-15 IconUrl/HighResolutionIconUrl | `IconUrl`/`HighResolutionIconUrl` reference `icon-64.png`/`icon-128.png`; `validate:xml` notes the icon-64 URL detail. | None required; validator passes and these are store-listing icons distinct from the nine mobile command icons. | The validator returns "The manifest is valid."; the detail line is informational, not an error. | `evidence/qa-gates/validate-xml.md`; live `npm run validate:xml` EXIT 0 |
| Info | src/taskpane/taskpane.ts | renderClassificationResult L49-65 | The function and `renderClassifying` are exported and unit-tested but never called from product wiring (same root cause as the unwired classify gap). | Will be consumed when #37 wires the workflow. No dead-code removal recommended now. | Helpers are intentionally pre-built for #37; removing them would only be re-added. | `coverage/lcov.info` FNDA renderClassifying=1, renderClassificationResult=3 (test-only); issue #37 |

No Critical, High, or Medium findings. No blocking findings.

## Notes on the AppDomain Production-Build Fix (commit de298e6)

- The committed source `manifest.xml` `<AppDomain>` is now `https://localhost:3000/` (trailing
  slash added). The webpack production transform replaces every `https://localhost:3000/` with
  `urlProd`, so the AppDomain is now rewritten on production builds.
- The copy glob change `manifest*.json` → `manifest*.{json,xml}` is required for the transform
  to run against `manifest.xml` at all; previously only `manifest.json` was transformed.
- Verified by the executor that a production build yields zero `localhost` references in
  `dist/manifest.xml` and that `npm run validate:xml` / `npm run validate` pass, with
  `manifest.json` unchanged (`evidence/notes/hosting-endpoint.md`,
  `evidence/regression-testing/manifest-json-unchanged.md`). This review re-ran both validators
  live (EXIT 0).

## Test Quality Observations

- The two added `closeTaskpane` tests cover both the host-supported and host-unavailable
  branches and assert behavior precisely (`taskpane.test.ts` L237-267); they do not reach into
  Office.js beyond a minimal `ui.closeContainer` stub. Good isolation.
- Tests are deterministic: no timers, no `Date.now`, no network, mocks reset per test.
- The `closeTaskpane()` guard (`typeof ui.closeContainer === "function"`) is appropriate for
  the mobile-vs-desktop host-capability difference and avoids throwing where the API is absent.
