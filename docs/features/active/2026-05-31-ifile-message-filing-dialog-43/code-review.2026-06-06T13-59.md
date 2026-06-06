# Code Review: iFile Message-Filing Dialog — Cycle 4 Reaudit (#43)

**Review Date:** 2026-06-06
**Reviewer:** feature-review agent
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Feature Folder Selection Rule:** Sole active feature folder for issue #43 / branch `feature/ifile-message-filing-dialog-43`.
**Base Branch:** `main` (working-tree diff assessed against `HEAD` = `2292b0f`, the branch head)
**Head Branch:** working tree on `feature/ifile-message-filing-dialog-43`
**Review Type:** Post-remediation re-review (cycle 4)

---

## Executive Summary

Cycle 4 realigns the in-repo iFile authentication chain onto the Entra app the user has already configured (`3592bf52-46f6-4eb0-835c-4f961058de97`, "TaskMaster Web"), replacing the previously hard-coded app `2921bc0b-...` ("Graph Mail Calendar PoC") whose registration lacked a matching NAA `brk-multihub` SPA redirect and therefore produced a pre-AAD broker rejection on Outlook iOS. The cycle also reverts a temporary on-device PII diagnostic so the MSAL logger no longer enables PII logging and again drops PII-flagged log lines. Documentation references in two runbooks were realigned to the new client ID / Application ID URI.

**What changed (cycle-4 deliverables):**
- `src/taskpane/ifile/naa-token-acquirer.ts`: `CLIENT_ID` realigned to `3592bf52-46f6-4eb0-835c-4f961058de97`; `piiLoggingEnabled` restored to `false`; the `if (containsPii) { return; }` guard and the third `containsPii` callback parameter reinstated in `createMsalLogCapture`; all `DIAGNOSTIC` / `REVERT before release` comment text removed.
- `manifest.json`, `manifest.xml`: `webApplicationInfo` id/resource updated to the new client ID and the Application ID URI `api://taskmaster-ios-3000.use.devtunnels.ms/3592bf52-46f6-4eb0-835c-4f961058de97`.
- `tests/taskpane/ifile/naa-token-acquirer.test.ts`: clientId assertion updated; PII-skip coverage restored (true and false paths).
- `runbooks/entra-app-sso-config.runbook.md`, `runbooks/outlook-on-device-verification.runbook.md`: old client ID / App ID URI references realigned.

Scope note: the working-tree diff against `HEAD` for `naa-token-acquirer.ts` (+180 lines) and its test (+285 lines) is dominated by the pre-existing, uncommitted MSAL log-capture subsystem (`createMsalLogCapture`, `attachMsalLog`, `stripMsalBoilerplate`, `MsalLogCapture`, popup-fallback error wiring) introduced during cycles 2–3 on-device debugging — not by cycle 4. This is confirmed by the cycle-4 P0 baseline coverage evidence, which already names `attachMsalLog` at the baseline line numbers, and by the prompt's note that an uncommitted prior working state exists. Cycle-4 edits within this file are limited to the four items listed above. The pre-existing subsystem and other uncommitted files (README, `ifile.html`, `ifile.ts`, `build-stamp.ts`, `sign-in-error-detail.ts`, the audit-folder reorganization) are out of this cycle's scope and are noted only as observations.

**Top 3 risks:**
1. Feature DONE remains gated on three declared human-execution exceptions (HI-1 admin consent, HI-2 mobile build + on-device re-verification, HI-3 backend OBO user-secrets injection). These are not code defects but block end-to-end confirmation that sign-in now succeeds.
2. A large uncommitted prior working state (MSAL log-capture subsystem plus several untracked files) coexists with the cycle-4 deliverables in the working tree. It is functioning and covered, but it has not itself been through an in-cycle audit and is carried forward unreviewed by this cycle.
3. The Application ID URI and SPA redirect are bound to a Dev Tunnel host (`taskmaster-ios-3000.use.devtunnels.ms`). Production-domain substitution remains an explicitly deferred follow-up.

**PR readiness recommendation:** **Conditional Go** — The cycle-4 code change is correct, scoped, and fully verified by a clean seven-stage TypeScript toolchain with no coverage regression. Merge readiness for the feature as a whole remains gated on the three declared human exceptions, which are tracked and are not code defects.

---

## Findings Table

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| Info | `src/taskpane/ifile/naa-token-acquirer.ts` | L29 | `CLIENT_ID` realigned to `3592bf52-46f6-4eb0-835c-4f961058de97`; no occurrence of the old client ID remains. | None. | Matches scope contract section 3 item 1; the new value is a non-secret Application ID. | `rg -n "3592bf52" src/...` → L29; `rg "2921bc0b" src/ tests/ manifest.*` → none |
| Info | `src/taskpane/ifile/naa-token-acquirer.ts` | L82, L127-131, L143 | PII diagnostic reverted: `piiLoggingEnabled: false`, `if (containsPii) { return; }` guard + third callback parameter reinstated, all `DIAGNOSTIC`/`REVERT` text removed. | None. | Matches scope contract section 3 item 5; restores PII-safe logging. | `rg -n "DIAGNOSTIC|REVERT before release"` → none; guard present at L128 |
| Info | `manifest.json` / `manifest.xml` | json L36-37 / xml L268-269 | `webApplicationInfo` id and resource updated to new client ID and Application ID URI. | None. | Matches scope contract section 3 items 2–3; both manifests validate. | `npm run validate` / `validate:xml` → exit 0, "manifest is valid" |
| Info | `tests/taskpane/ifile/naa-token-acquirer.test.ts` | L465, L156-185, L317 | clientId assertion updated; PII-skip coverage restored (PII-flagged message excluded, non-PII retained at same level); `piiLoggingEnabled` asserted `false`. | None. | Matches scope contract section 3 items 4–5; covers both true/false branches of the reinstated guard. | `npm run test:coverage` → 163 tests pass; branch coverage on file 95.23% |
| Minor | `docs/.../runbooks/entra-app-sso-config.runbook.md` | L169 | Cycle added `--id b3c44e17-...` (a non-secret dotnet UserSecretsId) to the `dotnet user-secrets set` example, slightly beyond a pure client-ID swap. | Accept; record as observation. | The value is a non-secret project identifier (already gitleaks-allowlisted in commit `2292b0f`), not a secret. Operationally consistent with HI-3. | runbook diff L166-169; branch commit `2292b0f` |
| Info | `src/taskpane/ifile/naa-token-acquirer.ts` | n/a | MSAL import boundary intact: `@azure/msal-browser` is imported only by this module among governed pure modules; depcruise reports 0 errors. | None. | Confirms the `ifile-pure-modules-no-host-deps` rule still holds. | `npm run depcruise` → 0 errors; `sign-in-error-detail.ts` reference is a doc-comment, not an import |

No Blocker or Major findings.

---

## Implementation Audit

### TypeScript implementation audit

#### What changed well

- The client-ID realignment is a single-source change: the value lives in one `CLIENT_ID` constant and is threaded into the MSAL `Configuration.auth.clientId`, with the manifests carrying the mirrored non-secret identifier. No duplication was introduced.
- The PII-diagnostic revert restores the intended safety posture cleanly: `piiLoggingEnabled: false` plus an explicit `if (containsPii) { return; }` short-circuit at the top of the logger callback, before the level filter. The callback signature `(level, message, containsPii)` remains structurally assignable to MSAL's `ILoggerCallback`.
- The revert removed all temporary `DIAGNOSTIC ONLY` / `REVERT before release` markers, leaving no release-blocking annotations in the file.

#### Type safety and maintainability

- `npm run typecheck` (`tsc --noEmit`) passes with zero errors. No `any` escape hatches were introduced by the cycle-4 edits. The exported types (`MsalLoggerCallback`, `MsalLoggerOptions`, `MsalLogCapture`) are pre-existing prior-state surface, not cycle-4 additions; they are precisely typed and narrowed to the consumed fields.
- File length remains within the 500-line limit.

#### Error handling and logging

- The PII-skip guard ensures MSAL PII-flagged content is never folded into the captured `msalLog` diagnostic. With `piiLoggingEnabled: false`, MSAL also will not emit PII content through the callback in the first place, giving defense in depth.
- The pre-existing `attachMsalLog` helper is guarded so attaching the diagnostic cannot itself throw and mask the original error; this behavior is unchanged by cycle 4.

---

## Test Quality Audit

The cycle-4 test edits restore PII-skip behavioral coverage and update the clientId assertion. The full suite was re-run independently and passes.

### Reviewed test and QA artifacts

- `tests/taskpane/ifile/naa-token-acquirer.test.ts` — Asserts the new clientId (`3592bf52-...`), that a `containsPii: true` Warning/Error is excluded while a `containsPii: false` message at the same level is retained, and that `loggerOptions.piiLoggingEnabled` is `false`. Both branches of the reinstated guard are exercised.
- `evidence/qa-gates/final-ts-test-coverage.2026-06-06T13-42.md` — Records 163 tests passing, all-files 95.47% line / 92.49% branch. Independently reproduced: `npm run test:coverage` → exit 0, identical headline figures.
- `evidence/qa-gates/final-coverage-delta.2026-06-06T13-42.md` — Records baseline→post-change with no regression on changed lines; `naa-token-acquirer.ts` branch coverage rose 95.00% → 95.23%, confirming the reinstated PII-skip branch is covered.

### Quality assessment prompts

- **Determinism:** The logger seam is driven directly in tests via injected `logCapture`; no wall-clock, timers, or network. Deterministic.
- **Isolation:** Each test targets a single behavior (clientId value, PII-skip true path, PII-skip false path, loggerOptions shape).
- **Speed:** Full suite (29 files, 163 tests) runs as a fast unit suite; no integration latency observed.
- **Diagnostics:** Assertions are specific (exact clientId string, exact drained-message arrays), so failures would localize clearly.

---

## Security / Correctness Checks

| Check | Status | Evidence |
|---|---|---|
| No secrets in code | ✅ PASS | `evidence/qa-gates/secret-scan.2026-06-06T13-42.md` and independent scan: only the non-secret client ID, tenant ID, and Application ID URI are present; "secret" appears only in phrases describing these as non-secret. OBO ClientSecret remains the uncommitted HI-3 user-secrets step. |
| No unsafe subprocess or command construction | N/A | No subprocess or shell construction in the TypeScript diff. |
| Input validation at boundaries | ✅ PASS | The logger callback validates `containsPii` and `level` before retaining a message; `attachMsalLog` guards non-object errors and a non-writable target. |
| Error handling remains explicit | ✅ PASS | Silent and popup acquisition failures are rethrown after attaching the captured diagnostic; no error is swallowed. |
| Configuration / path handling is safe | ✅ PASS | Client ID / Application ID URI are static non-secret constants mirrored in the manifests; both manifests validate. |
| MSAL import boundary preserved | ✅ PASS | `npm run depcruise` → 0 errors; `@azure/msal-browser` imported only by `naa-token-acquirer.ts` among governed modules. |
| No immutable historical artifact rewritten | ✅ PASS | Deleted audit/remediation files in `git status` are moves into dated subfolders (content preserved); research doc and prior inputs/plans intact. |

---

## Research Log

No external research was required. All findings are grounded in the working-tree diff, the cycle-4 evidence artifacts, the scope contract, the executed plan, and independently re-run toolchain commands.

---

## Verdict

The cycle-4 code change is correct and within the scope contract: it realigns the iFile authentication chain onto the configured Entra app, reverts the temporary PII diagnostic, and updates the two operational runbooks, with no in-scope source or test file retaining the old client ID and no secret value entering the repository. The seven-stage TypeScript toolchain passes clean (format, lint, typecheck, dependency-cruiser with the MSAL boundary intact, vitest + coverage, both manifest validations) and coverage did not regress on changed lines.

The change is ready for normal PR flow with respect to code quality. Feature-level merge readiness remains gated on the three declared human exceptions (HI-1, HI-2, HI-3), which are tracked and are not code defects. Recommendation: **Conditional Go**.

**Blocking findings (this artifact): 0**
