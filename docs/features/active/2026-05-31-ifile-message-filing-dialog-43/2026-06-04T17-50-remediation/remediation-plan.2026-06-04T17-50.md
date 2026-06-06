# Remediation Plan — iFile Message-Filing Dialog (#43)

- Cycle: 1
- Entry timestamp: 2026-06-04T17-50
- Work Mode: full-bug (spec.md present; functional defect found in on-device verification)
- Feature folder: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- Inputs source: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/remediation-inputs.2026-06-04T17-50.md`
- Spec source: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/spec.md`
- Target plan path (update in place): `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/remediation-plan.2026-06-04T17-50.md`
- Branch: `feature/ifile-message-filing-dialog-43`

## Evidence-Location Invariant

All evidence artifacts produced by this plan are written under `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/<kind>/` per `evidence-and-timestamp-conventions`. Remediation baseline evidence is written under `evidence/remediation-baseline/`; QA-gate evidence under `evidence/qa-gates/`; regression evidence under `evidence/regression-testing/`. No `artifacts/...` evidence path is used.

## Languages in Scope

- TypeScript only. All production and test changes are under `src/taskpane/ifile/**`, `webpack.config.js`, and a host-neutral guard module. The C# backend (`GraphFolderTreeReader.cs`, `/api/ifile/folders` leaf filter) is confirmed correct in triage and is not modified; therefore no C# production/test changes and no C# QA loop are in scope this cycle. If any task below would require a C# source change, stop and escalate as a scope change.
- Coverage policy applies to TypeScript: line >= 85%, branch >= 75%, no regression on changed lines (`general-unit-test.md`, `quality-tiers.md`).

## Per-Batch Budget

Each batch touches at most 3 production files and at most 3 test files. No file may exceed 500 lines. Batch boundaries are marked per phase below.

## Diagnose-Then-Fix Boundaries

Do NOT rework these confirmed-correct layers without an explicit, evidence-backed cause recorded in a regression artifact first:
- `src/taskpane/ifile/folder-search.ts`, `wildcard-matcher.ts`, `search-result-ordering.ts`, `result-list-composer.ts`
- `src/taskpane/ifile/ifile-controller.ts`
- `src/TaskMaster.Infrastructure/IFile/GraphFolderTreeReader.cs`, the `/api/ifile/folders` leaf filter in `src/TaskMaster.Api/Program.cs`

---

### Phase 0 — Policy Read and Remediation Baseline Capture

- [x] [P0-T1] Read repository policy files in required order and record the read evidence. Files to read: `CLAUDE.md`; `.claude/rules/general-code-change.md`; `.claude/rules/general-unit-test.md`; `.claude/rules/typescript.md`; `.claude/rules/typescript-suppressions.md`; `.claude/rules/architecture-boundaries.md`; `.claude/rules/quality-tiers.md`; `.claude/rules/tonality.md`. Write `evidence/remediation-baseline/phase0-instructions-read.md` containing `Timestamp:`, `Policy Order:`, and the explicit list of files read. Acceptance: artifact exists with all three fields populated and lists every file above.

- [x] [P0-T2] Capture TypeScript format baseline. Command: `npm run format`. Write `evidence/remediation-baseline/ts-format.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact records exit code and whether any files were reformatted.

- [x] [P0-T3] Capture TypeScript lint baseline. Command: `npm run lint`. Write `evidence/remediation-baseline/ts-lint.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact records exit code and error/warning counts.

- [x] [P0-T4] Capture TypeScript type-check baseline. Command: `npm run typecheck`. Write `evidence/remediation-baseline/ts-typecheck.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact records exit code and error count.

- [x] [P0-T5] Capture TypeScript architecture-boundary baseline. Command: `npm run depcruise`. Write `evidence/remediation-baseline/ts-arch.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact records exit code and violation count.

- [x] [P0-T6] Capture TypeScript test + coverage baseline. Command: `npm run test:coverage`. Write `evidence/remediation-baseline/ts-test-coverage.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. `Output Summary:` MUST include numeric headline line% and branch% totals and the current per-file coverage for `src/taskpane/ifile/ifile.ts` and `src/taskpane/ifile/inline-host.ts`. Acceptance: numeric coverage values recorded (no placeholders); the baseline establishes that `ifile.ts` is currently uncovered or under threshold.

---

### Phase 1 — Diagnostic Regression Tests (fail-before evidence)

Batch 1 (test files only; 0 production / 3 test files).

- [x] [P1-T1] [expect-fail] Add a failing regression test that proves the load-failure path disables the keystroke handler. File: `tests/taskpane/ifile/inline-host.test.ts`. Add a test under `describe("inline-host mountInline")` that: constructs an `IFileController` whose `loadLeaves` rejects, calls `mountInline`, then dispatches an `input` event with a value that would match a known leaf, and asserts the results region shows a visible error/empty-state row AND that a subsequent keystroke still invokes search. Run with `npm run test -- inline-host`. This test MUST fail against current `inline-host.ts` (handler never bound; load throws). Write `evidence/regression-testing/fail-before-inline-host-load-failure.2026-06-04T17-50.md` with `Timestamp:`, `Command:`, `EXIT_CODE:` (non-zero), and the failing assertion text. Acceptance: artifact shows the test failing on current code.

- [x] [P1-T2] [expect-fail] Add a failing regression test for the backend-URL guard. File: `tests/taskpane/ifile/api-base-url.test.ts` (new). Import the not-yet-existing guard (`assertReachableApiBaseUrl` from `src/taskpane/ifile/api-base-url.ts`) and assert it throws for `"https://localhost:3000"` when the build is flagged as mobile, and returns the URL unchanged for a non-localhost host. Run with `npm run test -- api-base-url`. This test MUST fail (module does not yet exist). Write `evidence/regression-testing/fail-before-api-base-url-guard.2026-06-04T17-50.md` with `Timestamp:`, `Command:`, `EXIT_CODE:` (non-zero), and the import/compile failure. Acceptance: artifact shows the test failing for the missing-module reason.

- [x] [P1-T3] [expect-fail] Add a failing wiring-seam test for the host-bootstrap module. File: `tests/taskpane/ifile/ifile.bootstrap.test.ts` (new). Drive `src/taskpane/ifile/ifile.ts` through the test seam (Office fake) and assert that when token acquisition or the one-time folder load fails, `bootstrap` still binds the input handler and surfaces a visible error state rather than leaving the box inert. Run with `npm run test -- ifile.bootstrap`. This test MUST fail against current `ifile.ts` (bootstrap rejects before wiring; only `console.error`). Write `evidence/regression-testing/fail-before-ifile-bootstrap.2026-06-04T17-50.md` with `Timestamp:`, `Command:`, `EXIT_CODE:` (non-zero), and the failing assertion text. Acceptance: artifact shows the test failing on current code.

---

### Phase 2 — Backend-URL Reachability Guard (root cause 1)

Batch 2 (2 production files; 0 net-new test files — the Phase 1 guard test is exercised here).

- [x] [P2-T1] Add a host-neutral backend-URL guard module. File: `src/taskpane/ifile/api-base-url.ts` (new). Implement `assertReachableApiBaseUrl(url: string, options: { isMobileBuild: boolean }): string` that fail-fasts (throws a clear `Error`) when `isMobileBuild` is true and the URL host is `localhost`/`127.0.0.1`/`[::1]`, and otherwise returns the URL unchanged. Pure (no Office.js, no fetch, no I/O); must satisfy the `ifile-pure-modules-no-host-deps` dependency-cruiser rule. Keep under 500 lines. Acceptance: `npm run test -- api-base-url` passes (the Phase 1 [P1-T2] test now passes); `npm run typecheck` and `npm run depcruise` clean for this file.

- [x] [P2-T2] Wire the guard into the build-time URL injection and document the mobile build step. File: `webpack.config.js`. At the `DefinePlugin` injection (lines ~57-65), inject an additional compile-time flag `__IS_MOBILE_BUILD__` derived from an explicit env var (for example `IFILE_MOBILE_BUILD`), keep `__API_BASE_URL__` sourced from `process.env.API_BASE_URL`, and update the adjacent comment to state that a mobile build MUST set `API_BASE_URL` to a reachable Dev-Tunnel/deployed host and set the mobile-build flag. Do not hardcode any production/Dev-Tunnel URL; the actual URL value is supplied at build time per the HI-2 runbook. Acceptance: `webpack.config.js` defines both `__API_BASE_URL__` and `__IS_MOBILE_BUILD__`; the localhost default remains only for non-mobile desktop dev; comment documents the mobile build requirement.

- [x] [P2-T3] Consume the guard in the host bootstrap so a localhost URL in a mobile build fails fast and visibly. File: `src/taskpane/ifile/ifile.ts`. Replace the bare `const API_BASE_URL = __API_BASE_URL__;` usage so the resolved base URL passes through `assertReachableApiBaseUrl(__API_BASE_URL__, { isMobileBuild: __IS_MOBILE_BUILD__ })` before constructing `IFileApiClient`. Declare `__IS_MOBILE_BUILD__` alongside `__API_BASE_URL__`. The guard failure must route to the same visible error sink introduced in Phase 3 (not silent `console.error`). Acceptance: `npm run typecheck` clean; the bootstrap uses the guarded URL; no hardcoded URL added.

---

### Phase 3 — Load-Failure Resilience and Visible Error State (defect 2)

Batch 3 (2 production files; 1 test file).

- [x] [P3-T1] Restructure `mountInline` to bind the input handler regardless of load outcome and surface a visible, deterministic error/empty state. File: `src/taskpane/ifile/inline-host.ts`. Change `mountInline` so it (a) attaches the `input` listener and performs an initial `update()` before or independent of the one-time load completing, (b) wraps `controller.open()` so a load failure does not throw out of `mountInline` and does not prevent handler binding, and (c) renders a visible, testable error/empty-state row into the results list (a deterministic message element, distinct from a normal result row, e.g. via a dedicated render path) when the one-time load fails. Add a small exported helper (for example `renderLoadError(dom, message)`) so the error state is unit-testable without Office.js. Keep host-neutral where possible; keep the file under 500 lines. Acceptance: `npm run test -- inline-host` passes including the Phase 1 [P1-T1] test; the box remains responsive after a failed load; the error state is rendered into `dom.resultsList`.

- [x] [P3-T2] Route the host-bootstrap error sink to the visible state instead of silent `console.error`. File: `src/taskpane/ifile/ifile.ts`. Restructure `bootstrap`/the `Office.onReady` catch so that a token-acquisition failure, URL-guard failure, or load failure binds the input handler (where the DOM exists) and renders the visible error state via the helper from [P3-T1], rather than only logging to `console.error`. The keystroke handler must be bound whenever `searchInput`/`resultsList` are present, independent of load/token outcome. Keep `ifile.ts` under 500 lines and as thin as possible (host-bound wiring only; reusable logic delegated to host-neutral helpers). Acceptance: `npm run test -- ifile.bootstrap` passes including the Phase 1 [P1-T3] test; `npm run typecheck` clean.

- [x] [P3-T3] Add positive-path and additional negative-path unit assertions for the resilient wiring. File: `tests/taskpane/ifile/inline-host.test.ts` (extend) and `tests/taskpane/ifile/ifile.bootstrap.test.ts` (extend). Cover: (a) successful load still renders results on input (existing behavior preserved, no regression), (b) failed load renders the error state and keeps the box responsive, (c) the error-state element is distinct from a result row and carries a stable, assertable marker. Run with `npm run test -- inline-host ifile.bootstrap`. Acceptance: all listed scenarios pass; positive path unchanged.

---

### Phase 4 — Token-Acquisition Path Investigation (contributing risk 3, OD-8)

Batch 4 (0 or 1 production file conditional; 0 or 1 test file conditional).

- [x] [P4-T1] Guarded investigation of the token path. File under review: `src/taskpane/ifile/ifile.ts:37` (`Office.auth.getAccessToken({ allowSignInPrompt: true })`) against spec OD-8 (NAA-primary, backend OBO fallback via `getAccessTokenAsync` SSO). Determine whether the current SSO call is implicated in the on-device failure given the Phase 3 resilient wiring (a token rejection now surfaces a visible error rather than dead UI). Write `evidence/regression-testing/od8-token-path-investigation.2026-06-04T17-50.md` with `Timestamp:`, the finding, and one of two decisions: `ALIGN_REQUIRED` (with the specific evidence that the SSO path causes the device failure) or `OUT_OF_SCOPE_DEFERRED` (SSO not confirmed as a cause this cycle; resilient error surfacing already removes the silent-failure symptom). Acceptance: artifact records a definitive decision with rationale; no speculative rewrite is performed without `ALIGN_REQUIRED`.

- [x] [P4-T2] (Conditional — execute only if [P4-T1] decides `ALIGN_REQUIRED`) Align token acquisition with OD-8. NOT APPLICABLE: [P4-T1] decided OUT_OF_SCOPE_DEFERRED; see `evidence/regression-testing/od8-token-path-investigation.2026-06-04T17-50.md`. Skip branch authorized by this task text. Files: `src/taskpane/ifile/ifile.ts` plus one host-neutral helper if extraction is warranted (for example `src/taskpane/ifile/token-acquisition.ts`), and a matching test `tests/taskpane/ifile/token-acquisition.test.ts`. Implement NAA-primary with backend OBO fallback per OD-8, keeping privileged operations server-side. Keep within the 3-production/3-test batch budget and the 500-line cap. Run `npm run test -- token`. Acceptance: if executed, the NAA-primary/OBO-fallback behavior is unit-tested and passes; if [P4-T1] decided `OUT_OF_SCOPE_DEFERRED`, this task is recorded as not-applicable with a pointer to the [P4-T1] artifact (explicit skip branch authorized by this task text).

---

### Phase 5 — HI-2 Runbook Update (declared exception, doc-only)

- [x] [P5-T1] Update the on-device verification runbook to include the backend-URL build step. File: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/outlook-on-device-verification.runbook.md`. Add a step that sets `API_BASE_URL` to a reachable Dev-Tunnel/deployed host and sets the mobile-build flag (`IFILE_MOBILE_BUILD`) before `npm run build`, sideloads the bundle, and confirms the iFile search returns matching folders on a physical iPhone. Restate HI-2 as the remaining declared exception that gates feature DONE but not cycle exit. Acceptance: runbook contains the build-with-reachable-URL step and the HI-2 exception restatement; this is a Markdown doc change exempt from the 500-line cap.

---

### Phase 6 — Final QA Loop (TypeScript) and Coverage Delta

Run steps in order. If any step fails or changes files, restart from [P6-T1].

- [x] [P6-T1] Final TypeScript format. Command: `npm run format`. Write `evidence/qa-gates/final-ts-format.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: exit code 0; if files changed, restart the loop.

- [x] [P6-T2] Final TypeScript lint. Command: `npm run lint`. Write `evidence/qa-gates/final-ts-lint.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: 0 errors; if it fails or fixes files, restart the loop.

- [x] [P6-T3] Final TypeScript type-check. Command: `npm run typecheck`. Write `evidence/qa-gates/final-ts-typecheck.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: 0 errors.

- [x] [P6-T4] Final TypeScript architecture-boundary check. Command: `npm run depcruise`. Write `evidence/qa-gates/final-ts-arch.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: 0 violations (including `ifile-pure-modules-no-host-deps` for the new `api-base-url.ts`).

- [x] [P6-T5] Final TypeScript test + coverage. Command: `npm run test:coverage`. Write `evidence/qa-gates/final-ts-test-coverage.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. `Output Summary:` MUST include numeric headline line% and branch% totals and per-file coverage for `src/taskpane/ifile/ifile.ts`, `src/taskpane/ifile/inline-host.ts`, and `src/taskpane/ifile/api-base-url.ts`. Acceptance: all tests pass; line >= 85%, branch >= 75%; numeric values recorded (no placeholders).

- [x] [P6-T6] Coverage delta / threshold verification. Compare Phase 0 [P0-T6] baseline against Phase 6 [P6-T5] post-change coverage. Write `evidence/qa-gates/final-coverage-delta.md` reporting: baseline line%/branch%, post-change line%/branch%, and changed-line coverage for the modified/new files (`ifile.ts`, `inline-host.ts`, `api-base-url.ts`, and any Phase 4 file). Acceptance: no regression on changed lines; changed-line coverage meets line >= 85% / branch >= 75%; the previously-uncovered host-bootstrap seam is now covered and no production file is coverage-excluded. If thresholds are not met, the cycle outcome is remediation-required (not PASS).

---

## Out-of-Scope Notes (for potential follow-up cycles)

- No new defects outside the inputs scope were identified during planning. If execution surfaces a new issue (for example a backend leaf-filter edge case or a manifest/AAD gap), record it as an explicit out-of-scope note here and do not fold it into this cycle.
- The classifier/recent result sources and the filing/move/OneDrive behavior remain out of scope; touch them only to avoid regression.

## Preflight

This plan is to be validated via `atomic-executor` preflight (validation only) using `DIRECTIVE: PREFLIGHT VALIDATION ONLY`, expecting `PREFLIGHT: ALL CLEAR` or `PREFLIGHT: REVISIONS REQUIRED`, and via the `mcp__drm-copilot__validate_orchestration_artifacts` plan validator. The target plan path is reused across all revision iterations.
