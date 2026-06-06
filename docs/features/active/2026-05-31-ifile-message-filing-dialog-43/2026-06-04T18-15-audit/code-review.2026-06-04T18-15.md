# Code Review: iFile Message-Filing Dialog — Remediation Cycle 1 (#43)

**Review Date:** 2026-06-04
**Reviewer:** feature-review
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Base Branch:** `main`
**Head Branch:** `feature/ifile-message-filing-dialog-43` (working tree, cycle 1 changes)
**Review Type:** Post-remediation re-review

---

## Executive Summary

This review covers remediation cycle 1 for issue #43, which fixes a defect found in on-device verification: on a physical iPhone the iFile search returned no matching folders with no error shown. Three root causes were addressed: (1) the mobile bundle defaulted the backend URL to `https://localhost:3000`, unreachable from a device; (2) a failed one-time folder load left a silent, inert search box; (3) the host-bootstrap seam was previously coverage-excluded. The change is small and well-factored: a new pure URL-reachability guard, a restructured `mountInline` that binds the keystroke handler before the one-time load settles and renders a deterministic visible error state, a split of `ifile.ts` into a testable host-neutral `bootstrap` seam plus a thin host-bound `runBootstrap` shell, and a build-time `__IS_MOBILE_BUILD__` flag in `webpack.config.js`.

**What changed:**
- `src/taskpane/ifile/api-base-url.ts` (new): pure `assertReachableApiBaseUrl` guard, throws for a mobile build pointed at a loopback host, returns the URL unchanged otherwise.
- `src/taskpane/ifile/inline-host.ts`: binds the `input` handler and renders the initial state before awaiting `controller.open()`; guards the one-time load so failure renders a distinct `data-ifile-error` / `role="alert"` row via the new `renderLoadError`, never throwing.
- `src/taskpane/ifile/ifile.ts`: split into host-neutral `bootstrap(deps)` and thin host-bound `runBootstrap()`; URL-guard and token-failure paths route to the visible error state; host registration guarded by `if (typeof Office !== "undefined")`.
- `webpack.config.js`: injects `__IS_MOBILE_BUILD__` from `IFILE_MOBILE_BUILD`; localhost default retained for desktop dev only; mobile build requirement documented.
- Tests: `api-base-url.test.ts` (new), `ifile.bootstrap.test.ts` (new), `ifile.host-shell.test.ts` (new), `inline-host.test.ts` (extended).
- Doc: `runbooks/outlook-on-device-verification.runbook.md` (build-with-reachable-URL step + HI-2 restatement).

Confirmed-correct layers (`folder-search.ts`, `wildcard-matcher.ts`, `search-result-ordering.ts`, `result-list-composer.ts`, `ifile-controller.ts`, the C# backend) were reviewed for regression only and were not modified. The resilience fix correctly relies on `IFileController.search()` tolerating a null leaf cache and `open()` using `??=` (no partial cache on failure, retry-safe).

**Top 3 risks:**
1. On the `bootstrap` token-acquisition-failure branch, a no-op `() => undefined` input handler is bound instead of the real `update` handler, so keystrokes are inert on that specific branch (the load-failure path keeps the box responsive). Minor; the error row is still visible and directs the user to retry.
2. The host-only registration block (`ifile.ts` lines 141-149) cannot execute under the test runtime, leaving a small visible uncovered region; this is the thinnest possible host wiring and is intentionally not excluded from coverage.
3. Device-runtime behavior (the actual on-device folder load) remains confirmable only by the HI-2 manual runbook, not CI.

**PR readiness recommendation:** **Go** — All cycle exit criteria are met, the full toolchain is green (reviewer-reproduced), and no Blocker or Major finding exists.

---

## Findings Table

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| Minor | `src/taskpane/ifile/ifile.ts` | lines 66-72 (token-failure branch) | On token-acquisition failure, a no-op `() => undefined` input handler is bound rather than the real `update`; keystrokes are inert on that branch (unlike the load-failure path). | Bind the real `update` handler on the token-failure branch for behavioral parity. Non-blocking. | "Responsive" is weaker on this branch, though the visible error row satisfies the exit criterion and a token failure means no list could load anyway. | Read of `ifile.ts:62-83`; compared with `mountInline` resilient binding in `inline-host.ts:72-92` |
| Info | `src/taskpane/ifile/ifile.ts` | lines 141-149 | Host-registration block (`if (typeof Office !== "undefined") { Office.onReady(...) }`) is uncovered under the test runtime. | Keep as-is; this is the thinnest host-only wiring and is correctly not coverage-excluded. | Leaving it measured (not excluded) preserves coverage-policy compliance. | `npm run test:coverage` text report: `ifile.ts` 85.48%, uncovered 141-149 |
| Info | `src/taskpane/ifile/api-base-url.ts` | line 35 | Defensive `?? withoutScheme` nullish fallback is unreachable with valid string inputs. | No action. | Branch coverage 90.9% on the file remains above threshold. | `npm run test:coverage` text report: `api-base-url.ts` 100% lines / 90.9% branches, uncovered line 35 |

No Blocker or Major findings.

---

## Implementation Audit

### TypeScript implementation audit

#### What changed well

- The URL-reachability concern is isolated into a pure, host-neutral module (`api-base-url.ts`) with no Office.js/fetch/I/O, satisfying the `ifile-pure-modules-no-host-deps` architecture rule and keeping it trivially unit-testable.
- `ifile.ts` was split so the wiring logic (`bootstrap`) is Office-free and dependency-injected (`acquireToken`, `loadLeaves`, `dom`, `onSelect`), with the host-bound glue (`runBootstrap`) kept thin. This is the correct response to the previously coverage-excluded seam: the logic is now measured (0% -> 85.48%) rather than excluded.
- `mountInline` binds the keystroke handler and renders the initial state before awaiting `controller.open()`, then guards the load in a `try/catch`. This directly resolves the silent-inert-box defect and is verified by tests asserting the box stays responsive after a failed load.
- The error state is deterministic and testable: `renderLoadError` writes a single row with a stable `data-ifile-error="true"` marker plus `role="alert"`, distinct from a result row (`data-folder-id`), and clears prior content first.

#### Type safety and maintainability

- No `any`. Exported seams are explicitly typed (`BootstrapDeps`, `TokenAcquirer`, `LeafLoader`, `ApiBaseUrlGuardOptions`, `InlineHostDom`). `catch (error: unknown)` is used without unsafe narrowing. No suppressions (`eslint-disable`, `@ts-expect-error`, `@ts-ignore`, `@ts-nocheck`) were introduced.
- All changed files are well under the 500-line cap (`ifile.ts` 153, `api-base-url.ts` 61, `inline-host.ts` 92).
- `npm run typecheck` and `npm run lint` both EXIT 0 (reviewer-run).

#### Error handling and logging

- Failures fail fast and surface visibly: the URL guard throws a specific `Error`; the token-failure, URL-guard-failure, and load-failure paths render the visible error state instead of a silent `console.error`. The single remaining `console.error`-only path (missing host DOM) is appropriate because there is no DOM to render into.

---

## Test Quality Audit

The cycle added diagnostic fail-before regression tests (evidence under `evidence/regression-testing/`) and final QA-gate evidence under `evidence/qa-gates/`. Coverage, regression, and toolchain evidence are present. The only verification gap is the inherently manual on-device confirmation (HI-2), which is a declared exception and not a CI gap.

### Reviewed test and QA artifacts

- `tests/taskpane/ifile/api-base-url.test.ts` — verifies the guard throws for loopback hosts on a mobile build (incl. `127.0.0.1`, `[::1]`), returns the URL unchanged for desktop and non-loopback hosts, and exercises the malformed-URL fallback (both loopback and non-loopback). Deterministic, AAA-structured.
- `tests/taskpane/ifile/inline-host.test.ts` — verifies responsiveness and a visible distinct error row after a failed load, error-row distinctness from a result row, and positive-path preservation.
- `tests/taskpane/ifile/ifile.bootstrap.test.ts` — drives the Office-free `bootstrap` seam: error surfaced + box bound on token failure and on load failure; positive path renders results once.
- `tests/taskpane/ifile/ifile.host-shell.test.ts` — drives `runBootstrap` with an Office fake and stubbed fetch: missing-DOM logs, URL-guard rejection renders visible error, reachable desktop build loads and renders, dialog-presentation posts selection to parent.
- `evidence/qa-gates/final-ts-test-coverage.2026-06-04T17-50.md` and `final-coverage-delta.2026-06-04T17-50.md` — record 117/117 pass, repo-wide 96.25% lines / 95.05% branches, and the `ifile.ts` 0% -> 85.48% seam recovery. Reviewer reproduced these numbers independently.

### Quality assessment prompts

- **Determinism:** No `setTimeout`, `Thread.Sleep`, `Date.now`, or real wall-clock waits; async resolved via awaited promises; `host-shell` resets mocks via `vi.restoreAllMocks()` / `vi.unstubAllGlobals()`. No temp files; fetch is stubbed.
- **Isolation:** Each test targets one behavior with a descriptive name.
- **Speed:** Full suite (26 files, 117 tests) completes in the standard Vitest run; no slow paths introduced.
- **Diagnostics:** Assertions are specific (marker attributes, call counts, rendered text), so failures localize clearly.

---

## Security / Correctness Checks

| Check | Status | Evidence |
|---|---|---|
| No secrets in code | ✅ PASS | No URL/token hardcoded; the Dev-Tunnel URL is supplied at build time via env var and documented as not committed (webpack comment, runbook Section 0). |
| No unsafe subprocess or command construction | N/A | No subprocess/command construction in scope. |
| Input validation at boundaries | ✅ PASS | `assertReachableApiBaseUrl` validates the build-time URL and fails closed for malformed mobile URLs; DOM presence checked before wiring. |
| Error handling remains explicit | ✅ PASS | Failures throw specific errors or render a visible error state; no swallowed errors except the structural missing-DOM log. |
| Configuration / path handling is safe | ✅ PASS | `webpack.config.js` injects only a boolean flag and the env-sourced URL; localhost default constrained to desktop dev. |

---

## Research Log

No external research was required. All findings are grounded in diff inspection, direct file reads, and reviewer-run toolchain output (`format --check`, `lint`, `typecheck`, `depcruise`, `test:coverage`).

---

## Verdict

The remediation is correct and well-scoped. The three root causes are addressed with a clear separation between pure logic (the URL guard), host-neutral wiring (`bootstrap`, `mountInline`, `renderLoadError`), and thin host-bound glue (`runBootstrap`). The load-failure path is resilient and the error state is deterministic and unit-testable. The full toolchain is green (reviewer-reproduced) and the previously-excluded seam is now measured. One Minor non-blocking inconsistency remains (no-op handler on the token-failure branch) and is recommended as a follow-up, not a gate. This change is ready for normal PR flow.

**Findings count:** Blocker 0, Major 0, Minor 1, Info 2.
**FAIL findings: 0. Blocking-PARTIAL findings: 0.**
