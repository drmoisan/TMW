# Remediation Inputs — iFile Message-Filing Dialog (#43)

- Cycle: 1
- Entry timestamp: 2026-06-04T17-50
- Author: orchestrator
- Feature folder: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- Branch: `feature/ifile-message-filing-dialog-43`
- Open PR: #44 (state OPEN, mergeable)
- Trigger class: material functional defect found in manual on-device verification (equivalent to a failed acceptance criterion). AC-4, AC-5, and AC-8 do not hold on a physical Outlook iOS client.

## 1. Observed Defect

On a physical iPhone (Outlook iOS), the iFile dialog renders and exposes the search textbox, but typing a known folder name returns no matching folders. No results appear and no error is shown. The search container is effectively inert.

User-stated expectation: the folder tree must be cached client-side so that, as characters are entered, matching folder names are returned in a way that is visible and responsive.

## 2. Expected Behavior (restated from issue/spec)

- AC-4/AC-5: Typing in the textbox prepends matching folder-leaf results to the list and updates as input changes; clearing the box removes them.
- AC-8: The folder list is loaded once per container open and filtered in-memory per keystroke (client-side cache), so per-keystroke matching is responsive and does not re-fetch.
- The search must function on a real Outlook iOS client, not only in unit tests.

## 3. Evidence (verified during triage)

The host-neutral and backend layers are present and unit-tested; the defect is concentrated in the on-device runtime/wiring path, which the original delivery excluded from coverage (`ifile.ts host-bootstrap excluded from TS coverage`, per the execution summary; the blanket production-coverage exclusion was later removed in commit `c264671`).

1. **Backend URL default is unreachable from a device (leading root cause).**
   `webpack.config.js:62-64` injects `__API_BASE_URL__` as `process.env.API_BASE_URL ?? "https://localhost:3000"`. `src/taskpane/ifile/ifile.ts:22,38` constructs `IFileApiClient(API_BASE_URL)`. From a physical iPhone, `https://localhost:3000` resolves to the device itself, so `GET /api/ifile/folders` cannot reach the backend and the fetch fails. A mobile build must inject a reachable URL (Dev Tunnel / deployed host) via the `API_BASE_URL` env var; if that injection did not occur, the folder load can never succeed on device.

2. **A failed one-time load yields a silent, inert search box (latent amplifying defect).**
   `src/taskpane/ifile/inline-host.ts:48-57` — `mountInline` performs `await controller.open()` *before* attaching the `input` listener. `IFileController.open` (`ifile-controller.ts:48-50`) calls `loadLeaves()` with no error handling, and `IFileApiClient.loadLeafFolders` (`ifile-api-client.ts:31-48`) throws on a non-OK/failed fetch. When the load throws: (a) the `input` event listener is never bound, so subsequent keystrokes do nothing; (b) the only error sink is `console.error` in `ifile.ts:29`, so the user sees an empty, non-functional box with no diagnostic. This matches the report precisely and makes the failure undiagnosable on device.

3. **Token acquisition path may not match the researched mobile path (contributing risk).**
   `src/taskpane/ifile/ifile.ts:37` uses `Office.auth.getAccessToken({ allowSignInPrompt: true })`. Research decision OD-8 specified NAA-primary token acquisition with backend OBO fallback. If SSO fails on iOS, `bootstrap()` rejects before the controller is wired, producing the same dead-UI outcome as (2).

4. **Layers confirmed correct (do not rework without cause).**
   - `src/taskpane/ifile/folder-search.ts`, `wildcard-matcher.ts`, `search-result-ordering.ts`, `result-list-composer.ts`: pure search/match/order logic, unit- and property-tested.
   - `src/taskpane/ifile/ifile-controller.ts`: caches leaves on `open()`, filters per keystroke, never re-fetches.
   - `src/TaskMaster.Infrastructure/IFile/GraphFolderTreeReader.cs` + `src/TaskMaster.Api/Program.cs:166-184`: recursive enumeration with full paths, leaf filter (`ChildFolderCount == 0`), path-bearing projection.

## 4. Scope for This Cycle

In scope:
- Make the on-device folder load actually reach the backend (resolve the build-time/runtime backend-URL configuration for the mobile bundle).
- Make the search container resilient and diagnosable: bind the keystroke handler so the box is responsive independent of load timing, and surface a visible non-blocking error/empty state when the one-time load fails rather than failing silently.
- Align token acquisition with the researched mobile path (OD-8) if confirmed to be a cause.
- Add automated regression coverage for the previously-uncovered host-bootstrap/wiring seam and the load-failure path, so this defect class is caught by CI.

Out of scope (do not expand the cycle): classifier/recent sources, the filing/move/OneDrive mirroring behavior (unless a fix here regresses it), and unrelated refactors.

## 5. Constraints

- No-COM architecture (`.claude/rules/architecture-boundaries.md`): mailbox/folder access only via Office.js or Graph; business logic host-neutral; UI as web UI. Layer-boundary and dependency-cruiser rules apply.
- File-size cap 500 lines; TypeScript suppression policy; full seven-stage toolchain must pass.
- No production file may be excluded from coverage (`general-unit-test.md` coverage-exclusion policy). The bootstrap/wiring seam must be tested, not excluded.
- Autonomous-execution mandate (#45): any step that cannot be automated must be declared as a human-interaction requirement with exactly one response (scope_change | exception | halt). Final on-device visual/end-to-end confirmation is already a declared exception (HI-2, runbook `runbooks/outlook-on-device-verification.runbook.md`); the build-with-reachable-URL + sideload step is part of that runbook. The code-and-test changes must be fully automatable and CI-verified; only the final on-device confirmation remains a declared exception.

## 6. Exit Criteria for This Cycle

- The on-device folder-load path reaches a reachable backend (configuration resolved and documented in the verification runbook).
- A one-time load failure no longer disables the keystroke handler and is surfaced visibly to the user (deterministic, testable).
- New automated tests cover the host-bootstrap/wiring seam and the load-failure path; the seam is no longer coverage-excluded; changed-line coverage meets thresholds.
- Full toolchain green; the three end-of-cycle reaudit artifacts (`code-review`, `feature-audit`, `policy-audit`) report `blocking_count == 0`.
- The on-device confirmation (HI-2) is restated as the remaining declared exception with its runbook updated to include the backend-URL build step; it gates feature DONE but not cycle exit.

## 7. Handoff

Next delegate: `atomic-planner` — author `remediation-plan.2026-06-04T17-50.md` against this inputs file and the `atomic-plan-contract`. The plan must diagnose-then-fix items 1–3, add the regression coverage in item 4, and keep within the per-batch production/test budget. Do not delegate to typed-engineer workers from the orchestrator; `atomic-executor` invokes workers while executing the approved plan.
