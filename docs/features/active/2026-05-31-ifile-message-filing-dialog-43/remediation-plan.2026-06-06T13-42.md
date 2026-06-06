# Remediation Plan — iFile #43 — Cycle 4

- **Plan timestamp:** 2026-06-06T13-42
- **Cycle:** 4
- **Branch:** feature/ifile-message-filing-dialog-43
- **PR:** #44
- **Scope contract:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/remediation-inputs.2026-06-06T13-42.md`
- **Language in scope:** TypeScript only (no backend C# production change expected; verified in Phase 1)
- **Evidence root:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/`

## Canonical values (target state)

| Element | Old value | New value |
|---|---|---|
| Client (application) ID | `2921bc0b-4518-4547-b8ca-f937713688ec` | `3592bf52-46f6-4eb0-835c-4f961058de97` |
| Application ID URI / resource | `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec` | `api://taskmaster-ios-3000.use.devtunnels.ms/3592bf52-46f6-4eb0-835c-4f961058de97` |
| Authority | `https://login.microsoftonline.com/common` (unchanged) | unchanged |
| Tenant ID | `d80d0ee6-3e37-43d7-9974-0ae662873253` (unchanged) | unchanged |

## Scope guard

This plan implements exactly the six required changes in scope contract section 3. Anything discovered during execution that is not in this plan triggers a separate cycle per the scope-change rule; it must not be folded into this cycle. Historical/audit artifacts (prior remediation-inputs/plans, research doc, evidence files) are an immutable record and MUST NOT be rewritten. No client secret or any secret value may enter the repository; only the non-secret client ID, tenant ID, and Application ID URI may appear in committed files.

## Evidence path invariant

All evidence artifacts produced by this plan are written under `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/<kind>/` per `evidence-and-timestamp-conventions`. Non-canonical locations such as `artifacts/baselines/`, `artifacts/qa/`, or `artifacts/coverage/` are prohibited and fail preflight.

---

### Phase 0 — Policy Reading and Baseline Capture

- [x] [P0-T1] Read the policy files in required order and record the read in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/phase0-instructions-read.2026-06-06T13-42.md`. The artifact MUST include `Timestamp:`, `Policy Order:`, and an explicit list of files read: `CLAUDE.md`, `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`, `.claude/rules/architecture-boundaries.md`, `.claude/rules/benchmark-baselines.md`, `.claude/rules/tonality.md`. Acceptance: artifact exists with all listed files and the three required fields.
- [x] [P0-T2] Capture baseline Prettier format state by running `npm run format` (or `npx prettier --check "src/**/*.ts"` for a non-mutating check) and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/ts-format.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact exists with all four fields and the pass/fail signal.
- [x] [P0-T3] Capture baseline ESLint state by running `npm run lint` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/ts-lint.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact exists with all four fields and the error count.
- [x] [P0-T4] Capture baseline type-check state by running `npm run typecheck` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/ts-typecheck.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact exists with all four fields and the error count.
- [x] [P0-T5] Capture baseline architecture-boundary state by running `npm run depcruise` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/ts-arch.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. The summary MUST confirm zero violations and note that the MSAL import-boundary rule (only `naa-token-acquirer.ts` may import `@azure/msal-browser`) is present and passing. Acceptance: artifact exists with all four fields and the violation count.
- [x] [P0-T6] Capture baseline test + coverage state by running `npm run test:coverage` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/ts-test-coverage.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. The summary MUST include numeric baseline line-coverage and branch-coverage headline values and the test pass count. Acceptance: artifact exists with all four fields and numeric line and branch coverage values (not placeholders).
- [x] [P0-T7] Capture baseline manifest validation by running `npm run validate` and `npm run validate:xml` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/remediation-baseline/manifest-validate.2026-06-06T13-42.md` with `Timestamp:`, `Command:` (both commands), `EXIT_CODE:` (per command), `Output Summary:`. Acceptance: artifact exists with both commands recorded and their pass/fail signals.

---

### Phase 1 — Backend C# Verification (No Production Change Expected)

- [x] [P1-T1] Verify no backend C# production code references the old client ID `2921bc0b-4518-4547-b8ca-f937713688ec` or the old Application ID URI. Search production C# source (exclude `tests/`, evidence files, and committed config that is documentation) using a content search across `*.cs` and any committed non-secret backend config. Record the search scope, patterns, and result in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/other/backend-verification.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`, `SearchScope:`, `SearchPatterns:`, `SearchResult:`. Acceptance: artifact exists; if any production C# match is found, the outcome is "out-of-scope finding — separate cycle required" and execution stops for that item; if none is found, the outcome is "no backend C# production change required" and the OBO client ID/audience/secret remain the HI-3 user-secrets human step (uncommitted).

---

### Phase 2 — Client ID and Application ID URI Realignment

- [x] [P2-T1] In `src/taskpane/ifile/naa-token-acquirer.ts`, replace the `CLIENT_ID` constant value (line ~29) from `2921bc0b-4518-4547-b8ca-f937713688ec` to `3592bf52-46f6-4eb0-835c-4f961058de97`. Acceptance: the `CLIENT_ID` constant equals the new value and no occurrence of the old client ID remains in the file (verify via content search of the file).
- [x] [P2-T2] In `src/taskpane/ifile/naa-token-acquirer.ts`, verify the doc comments (the `CLIENT_ID` comment at line ~26 and the `AUTHORITY` single-tenant example at line ~31) do not cite the old client ID; update any that do. The tenant ID `d80d0ee6-3e37-43d7-9974-0ae662873253` in the authority comment is unchanged. Acceptance: no occurrence of `2921bc0b-4518-4547-b8ca-f937713688ec` remains anywhere in the file.
- [x] [P2-T3] In `manifest.json`, update `webApplicationInfo.id` (line ~36) to `3592bf52-46f6-4eb0-835c-4f961058de97` and `webApplicationInfo.resource` (line ~37) to `api://taskmaster-ios-3000.use.devtunnels.ms/3592bf52-46f6-4eb0-835c-4f961058de97`. Acceptance: both fields hold the new values and no occurrence of the old client ID remains in `manifest.json`.
- [x] [P2-T4] In `manifest.xml`, update `<WebApplicationInfo><Id>` (line ~268) to `3592bf52-46f6-4eb0-835c-4f961058de97` and `<Resource>` (line ~269) to `api://taskmaster-ios-3000.use.devtunnels.ms/3592bf52-46f6-4eb0-835c-4f961058de97`. Acceptance: both elements hold the new values and no occurrence of the old client ID remains in `manifest.xml`.
- [x] [P2-T5] In `tests/taskpane/ifile/naa-token-acquirer.test.ts`, update the clientId assertion (line ~465, `expect(config.auth.clientId).toBe("2921bc0b-4518-4547-b8ca-f937713688ec")`) to assert `"3592bf52-46f6-4eb0-835c-4f961058de97"`. Acceptance: the assertion expects the new client ID and no occurrence of the old client ID remains in the test file.

---

### Phase 3 — Revert Temporary PII Diagnostic

- [x] [P3-T1] In `src/taskpane/ifile/naa-token-acquirer.ts`, restore `piiLoggingEnabled: false` in the `loggerOptions` returned by `createMsalLogCapture` (currently `true` at line ~157), and remove the three `DIAGNOSTIC ONLY` / `REVERT before release` comment blocks that reference the temporary diagnostic (at the `MsalLogCapture` interface ~lines 90–92, the `createMsalLogCapture` doc comment ~lines 129–131, and the inline `piiLoggingEnabled` comment ~lines 154–156). Acceptance: `piiLoggingEnabled` is `false` and no `REVERT before release` text remains in the file.
- [x] [P3-T2] In `src/taskpane/ifile/naa-token-acquirer.ts`, reinstate the PII-skip guard in the `loggerCallback` defined inside `createMsalLogCapture` (lines ~141–149): restore the third callback parameter `containsPii` and add `if (containsPii) { return; }` as the first statement, and remove the inline `DIAGNOSTIC ONLY` comment (~lines 135–140) explaining the removal. The callback must remain structurally assignable to `MsalLoggerCallback`. Acceptance: the callback signature is `(level, message, containsPii)`, the guard `if (containsPii) { return; }` is present before the level filter, and the file passes type-check (verified in Phase 5).
- [x] [P3-T3] In `tests/taskpane/ifile/naa-token-acquirer.test.ts`, update the `loggerOptions` assertion test (lines ~311–321) so it asserts `piiLoggingEnabled` is `false`, and remove the `DIAGNOSTIC ONLY` / `REVERT before release` language from that test's name and comments. Acceptance: the test asserts `expect(capture.loggerOptions.piiLoggingEnabled).toBe(false)` and no `REVERT before release` text remains in the test file.
- [x] [P3-T4] In `tests/taskpane/ifile/naa-token-acquirer.test.ts`, restore PII-skip coverage by converting the existing diagnostic test "captures a Warning/Error message flagged as containing PII" (lines ~156–191) into a test asserting that a PII-flagged Warning/Error message is NOT captured while a non-PII message at the same level IS captured. Update the test name and comments to remove `DIAGNOSTIC ONLY` language. Acceptance: a test exists asserting a `containsPii: true` message is excluded from `msalLog` and a `containsPii: false` message at the same level is included.
- [x] [P3-T5] In `tests/taskpane/ifile/naa-token-acquirer.test.ts`, update the buffer test "drops Info and Verbose messages regardless of the PII flag" (lines ~323–339) so its expectation reflects the reinstated PII skip: the PII-flagged Warning message (`"warning-pii"`, `containsPii: true`) is now excluded, so the drained result equals `["error-nonpii"]` (or equivalent), and adjust the test name/comments accordingly. Acceptance: the assertion reflects the PII-flagged message being dropped and the test passes (verified in Phase 5).
- [x] [P3-T6] Confirm coverage on the changed lines does not regress: the reinstated `if (containsPii) { return; }` branch must be exercised by the restored PII-skip tests (both the true and false paths of `containsPii`). Acceptance: the PII-skip branch is covered by at least one test asserting the true path and one asserting the false path; confirmed against the Phase 5 coverage report.

---

### Phase 4 — Operational Runbook Alignment

- [x] [P4-T1] In `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/entra-app-sso-config.runbook.md`, update the operational references to the old client ID and Application ID URI (lines ~20, ~66, ~91, ~185) to the new client ID `3592bf52-46f6-4eb0-835c-4f961058de97` and the new Application ID URI `api://taskmaster-ios-3000.use.devtunnels.ms/3592bf52-46f6-4eb0-835c-4f961058de97` (the `access_as_user` scope suffix on line ~91 is preserved with the new URI). The tenant ID is unchanged. Acceptance: no occurrence of the old client ID remains in this runbook; all updated references hold the new values.
- [x] [P4-T2] In `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/outlook-on-device-verification.runbook.md`, update the operational reference to the old Application ID URI (line ~56) to `api://taskmaster-ios-3000.use.devtunnels.ms/3592bf52-46f6-4eb0-835c-4f961058de97`. Acceptance: no occurrence of the old client ID remains in this runbook; the updated reference holds the new value.
- [x] [P4-T3] Confirm no historical/audit artifact was modified: verify the diff for this cycle touches only the six in-scope file targets plus this plan and evidence files, and does NOT modify prior remediation-inputs/plans, the research doc, or pre-existing evidence files. Acceptance: a content search across prior remediation-inputs/plans, the research doc, and pre-existing evidence files confirms no edits to those files in this cycle.

---

### Phase 5 — Repository-Wide Secret and Stale-Value Verification

- [x] [P5-T1] Verify no client secret or other secret value entered the repository in this cycle. Confirm that the only Entra identifiers added to committed files are the non-secret client ID `3592bf52-46f6-4eb0-835c-4f961058de97`, the tenant ID `d80d0ee6-3e37-43d7-9974-0ae662873253`, and the Application ID URI. Record the verification in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/secret-scan.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`, `SearchScope:`, `SearchPatterns:`, `SearchResult:`. Acceptance: artifact confirms no secret value present; `SearchResult` shows only the non-secret identifiers.
- [x] [P5-T2] Verify the old client ID `2921bc0b-4518-4547-b8ca-f937713688ec` no longer appears in any in-scope production or test file (`naa-token-acquirer.ts`, `naa-token-acquirer.test.ts`, `manifest.json`, `manifest.xml`) or the two in-scope runbooks. Record the search in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/stale-value-check.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`, `SearchScope:`, `SearchPatterns:`, `SearchResult:`. Remaining occurrences in immutable historical/audit artifacts are expected and acceptable and must be recorded as such. Acceptance: artifact confirms zero occurrences in the in-scope files; any occurrences are only in immutable historical artifacts.

---

### Phase 6 — Final QA Loop (TypeScript Seven-Stage Toolchain)

Run the full toolchain in order: format → lint → type-check → architecture-boundary → test (coverage) → manifest validation. If any stage fails or changes files, fix within the in-scope targets and restart from P6-T1. Each command-bearing task MUST execute its stated command and record an artifact; `SKIPPED` is not a valid passing outcome.

- [x] [P6-T1] Run `npm run format` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/final-ts-format.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: format reports a clean pass; if it changed files, restart from P6-T1.
- [x] [P6-T2] Run `npm run lint` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/final-ts-lint.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: zero lint errors.
- [x] [P6-T3] Run `npm run typecheck` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/final-ts-typecheck.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: zero type errors.
- [x] [P6-T4] Run `npm run depcruise` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/final-ts-arch.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. The summary MUST confirm zero violations and that the MSAL import-boundary rule still restricts `@azure/msal-browser` to `naa-token-acquirer.ts`. Acceptance: zero architecture violations and the MSAL boundary preserved.
- [x] [P6-T5] Run `npm run test:coverage` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/final-ts-test-coverage.2026-06-06T13-42.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. The summary MUST include numeric post-change line-coverage and branch-coverage headline values and the test pass count. Acceptance: all tests pass; line coverage >= 85% and branch coverage >= 75%.
- [x] [P6-T6] Run `npm run validate` and `npm run validate:xml` and record results in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/final-manifest-validate.2026-06-06T13-42.md` with `Timestamp:`, `Command:` (both), `EXIT_CODE:` (per command), `Output Summary:`. Acceptance: both manifest validations pass.
- [x] [P6-T7] Record the coverage delta in `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/qa-gates/final-coverage-delta.2026-06-06T13-42.md` with `Timestamp:`, baseline line/branch coverage (from P0-T6), post-change line/branch coverage (from P6-T5), and changed-line coverage for the edited files (`naa-token-acquirer.ts`). Acceptance: the artifact reports baseline, post-change, and changed-line coverage with no regression on changed lines.

---

## Exit gate

This remediation plan is complete when all Phase 0–6 tasks are checked with their evidence artifacts present and field-complete. Cycle 4 exits when the end-of-cycle `code-review`, `feature-audit`, and `policy-audit` artifacts report a combined `blocking_count` of 0. Feature #43 DONE remains gated on HI-1 (admin consent), HI-2 (on-device re-verification), and HI-3 (backend OBO user-secrets injection) — declared human exceptions, not code defects.
