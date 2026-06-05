# Code Review: iFile Message-Filing Dialog (#43) — Cycle 2 Reaudit

**Review Date:** 2026-06-04
**Reviewer:** feature-review agent
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Base Branch:** `main` (merge-base `0eb035f`)
**Head Branch:** `feature/ifile-message-filing-dialog-43` (cycle-2 changes in the working tree, uncommitted)
**Review Type:** Post-remediation re-review (cycle 2)

---

## Executive Summary

Cycle 2 replaces the legacy `Office.auth.getAccessToken` SSO path with nested app authentication
(NAA) via `@azure/msal-browser`, isolated behind the existing host-neutral `TokenAcquirer` seam. A
new host-bound adapter (`naa-token-acquirer.ts`) gates on
`Office.context.requirements.isSetSupported("NestedAppAuth","1.1")`, attempts `acquireTokenSilent`
and falls back to `acquireTokenPopup` on `InteractionRequiredAuthError`, and returns a deterministic
rejecting acquirer when NAA is unsupported. The bootstrap error is split into stage-specific
configuration/sign-in/connection messages. Both manifests declare `WebApplicationInfo` and the Dev
Tunnel domains. All toolchain checks were re-run and pass for TypeScript.

**What changed:** new `naa-token-acquirer.ts` (only MSAL importer) and `api-base-url.ts` (pure URL
guard); modified `ifile.ts` (stage-specific messages, NAA wiring, Office-free `bootstrap` seam),
`inline-host.ts` (injectable load-failure message), `.dependency-cruiser.cjs` (MSAL added to the
forbidden set for pure modules), both manifests, `package.json` (MSAL dependency), and
`Program.cs` (OBO/Graph DI wiring). New tests cover the NAA adapter, the bootstrap seam, the host
shell, and the URL guard.

**Top 3 risks:**
1. C# coverage evidence is stale for the changed `Program.cs` DI wiring (tracked in policy-audit POL-1; not a code defect).
2. The NAA-unsupported fallback names the Office-dialog interactive flow, which is an explicit out-of-scope follow-up (not yet built) — acceptable and deterministic, but the on-device unsupported path remains unverified until HI-2.
3. Final tenancy (`common` vs single-tenant authority) is governed by the human-gated HI-3 Entra config, not by this code.

**PR readiness recommendation:** **Conditional Go** — the code is sound; the one blocking item is the stale C# coverage artifact (policy-audit POL-1), which is an evidence-freshness gap, not a code change.

---

## Findings Table

| Severity | File | Location | Finding | Recommendation | Rationale | Evidence |
|---|---|---|---|---|---|---|
| Info | `tests/taskpane/ifile/ifile.host-shell.test.ts` | `FakeOffice.auth` | `auth.getAccessToken` member in the test fake is no longer used by `runBootstrap` (token path is the injected NAA acquirer). | Remove the vestigial member in a future pass. | Dead scaffolding; minor clarity. | File read lines 14-32; grep shows `getAccessToken` absent from `src/`. |
| Info | `src/taskpane/ifile/naa-token-acquirer.ts` | `AUTHORITY` (line 36) | Authority is `common`; single-tenant alternative documented in a comment but not selected. | None this cycle; governed by HI-3 runtime config. | Tenancy is a deployment decision. | File read lines 30-37. |

No Blocker or Major findings in the code.

---

## Implementation Audit

### TypeScript implementation audit

#### What changed well

- NAA acquisition is correctly silent-first with an interaction-required popup fallback; a
  non-interaction error is re-thrown without attempting popup, avoiding masking transient/network
  failures.
- The MSAL instance is constructed only when NAA is supported, so an unsupported environment never
  reaches MSAL — verified by the test asserting `createInstance` is not called in the unsupported
  branch.
- All host/MSAL boundaries (`isNaaSupported`, `createInstance`, `nestableClientConstructor`,
  `isInteractionRequired`, `onUnsupported`) are injectable with safe runtime defaults, so the
  adapter is unit-testable without the Office host or a real broker, and the defaults stay in
  coverage (98.14% lines / 100% branches).
- Token acquisition stays behind the `TokenAcquirer` seam; `bootstrap` imports no Office and no MSAL
  symbols (grep confirms MSAL is imported only by the adapter), keeping the seam host-neutral.
- Stage-specific error messages are routed deterministically (configuration from the URL-guard
  catch, sign-in from the token catch, connection from the one-time load) and each is asserted by a
  dedicated test including distinctness checks.

#### Type safety and maintainability

- MSAL is narrowed to local `NestablePublicClient`/`TokenResult` interfaces; `Configuration` is
  imported type-only. `unknown` is used for caught errors with explicit narrowing. No suppressions
  in any cycle-2 file. `tsc --noEmit` clean.

#### Error handling and logging

- Fail-fast with specific errors (URL guard throws; NAA-unsupported rejects). No silent swallow —
  each catch renders a visible `data-ifile-error` / `role="alert"` row; `runBootstrap` additionally
  logs via `console.error` as a last resort and keeps the search box responsive.

### C# implementation audit

#### What changed well

- `Program.cs` chains
  `.AddMicrosoftIdentityWebApi(...).EnableTokenAcquisitionToCallDownstreamApi().AddMicrosoftGraph().AddInMemoryTokenCaches()`,
  the correct OBO enablement pattern; the added comment explains the `AddInMemoryTokenCaches()`
  requirement for build-time DI validation. No secret is embedded; OBO is configured from
  `GetSection("AzureAd")`.

#### Type safety and API notes

- The CORS edit is a formatting reflow with no behavior change; `csproj` change is whitespace only.

#### Error handling and logging

- No new error paths introduced; the wiring relies on the framework's existing validation.
- Coverage of the changed lines is tracked as a FAIL in the policy-audit (stale C# artifact); from a
  correctness standpoint the wiring is sound. Cross-reference only, not a separate code-review FAIL.

---

## Test Quality Audit

The cycle-2 tests are deterministic, isolated, and require no host runtime, real network, or real
MSAL.

### Reviewed test and QA artifacts

- `tests/taskpane/ifile/naa-token-acquirer.test.ts` — supported/unsupported/popup/re-throw and the default host/MSAL boundaries; injects a fake MSAL instance, never instantiates a real broker.
- `tests/taskpane/ifile/ifile.bootstrap.test.ts` — token-failure and load-failure render visible, stage-specific error rows; positive render path.
- `tests/taskpane/ifile/ifile.host-shell.test.ts` — DOM resolution, URL-guard routing, NAA supported/unsupported branches via injected acquirer; stubbed `fetch`/`Office`.
- `coverage/lcov.info` — regenerated 21:05; repo-wide 96.48% lines / 95.47% branches.

### Quality assessment prompts

- **Determinism:** no real timers/RNG; promises drive async; globals restored in `afterEach`.
- **Isolation:** one behavior per test.
- **Speed:** full suite ~8.7s.
- **Diagnostics:** assertions check exact message constants and call counts.

---

## Security / Correctness Checks

| Check | Status | Evidence |
|---|---|---|
| No secrets in code | ✅ PASS | Manifests/adapter carry only non-secret client ID, App ID URI, tenant ID, Dev Tunnel hosts; backend secret via user-secrets (csproj `UserSecretsId` GUID). Grep found no secret value. |
| No unsafe subprocess or command construction | N/A | No shell/subprocess in scope. |
| Input validation at boundaries | ✅ PASS | URL guard validates the backend URL host (with malformed-URL fall-back); NAA support check gates MSAL construction. |
| Error handling remains explicit | ✅ PASS | Specific throws/rejections; visible stage-specific error states; non-interaction errors re-thrown. |
| Configuration / path handling is safe | ✅ PASS | Dev Tunnel hosts are session-scoped and documented as deploy-time replaceable; no production URL hardcoded. |

---

## Research Log

No external research was required for this review. All verdicts derive from re-running the
repository toolchain and inspecting the diff and feature-folder artifacts.

---

## Verdict

The cycle-2 NAA implementation is correct and well-isolated: token acquisition stays behind the
`TokenAcquirer` seam, MSAL is confined to a single host-bound adapter (enforced by depcruise and
verified by grep), the supported/unsupported/popup/re-throw branches are deterministic and tested,
and the stage-specific error messages are routed and asserted. Type safety, suppression policy, the
500-line cap, secrets handling, and test quality all pass. No Blocker or Major code findings were
identified.

The single blocking item for the cycle exit is external to the code: the C# coverage artifact is
stale for the changed `Program.cs` DI wiring (policy-audit POL-1). This is an evidence-freshness
gap, not a code defect. Recommendation: **Conditional Go** — regenerate a current C# coverage
artifact, then proceed.

### Verdict Counts
- FAIL findings: **0**
- Blocking-PARTIAL findings: **0**
- code-review blocking_count = **0**
