# Remediation Plan — iFile Message-Filing Dialog (#43)

- Cycle: 2
- Entry timestamp: 2026-06-04T20-29
- Work Mode: full-bug (spec.md present; new functional defect surfaced during HI-2 on-device verification)
- Feature folder: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- Inputs source: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/remediation-inputs.2026-06-04T20-29.md`
- Research source: `artifacts/research/2026-06-04-ifile-token-path-naa-vs-sso-research-43.md`
- Cycle-1 precedent plan: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/remediation-plan.2026-06-04T17-50.md`
- Target plan path (update in place): `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/remediation-plan.2026-06-04T20-29.md`
- Branch: `feature/ifile-message-filing-dialog-43`
- Open PR: #44

## Evidence-Location Invariant

All evidence artifacts produced by this plan are written under `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/evidence/<kind>/` per `evidence-and-timestamp-conventions`. Remediation baseline evidence is written under `evidence/remediation-baseline/`; QA-gate evidence under `evidence/qa-gates/`; regression evidence under `evidence/regression-testing/`; other evidence (verification dossiers) under `evidence/other/`. No `artifacts/...` evidence path is used. Any caller-supplied non-canonical evidence path is rejected and replaced with the canonical `<FEATURE>/evidence/<kind>/` path.

## Languages in Scope

- **TypeScript** — all production and test code changes are under `src/taskpane/ifile/**`, plus configuration files `package.json` and `.dependency-cruiser.cjs`, and the two manifest files `manifest.json` / `manifest.xml`. The full TypeScript seven-stage toolchain (format → lint → typecheck → depcruise → test/coverage) applies. Coverage policy: line >= 85%, branch >= 75%, no regression on changed lines (`general-unit-test.md`, `quality-tiers.md`).
- **C# — verification only, no code change.** Per inputs section 4 item 5 and research section 4, the backend `AzureAd` section is already read from configuration in `src/TaskMaster.Api/Program.cs` (`AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))` + `EnableTokenAcquisitionToCallDownstreamApi()`), and `src/TaskMaster.Api/appsettings.json` declares the `AzureAd` keys (`Instance`, `TenantId`, `ClientId`, `Audience`) with empty values and correctly omits `ClientSecret`. This cycle verifies and documents that wiring; it does not modify any C# source. Therefore no C# build/test QA loop is in scope. If any task below would require a C# source change, stop and escalate as a scope change rather than editing backend code.

## Per-Batch Budget

Each batch touches at most 3 production files and at most 3 test files. No production/test/script file may exceed 500 lines (Markdown docs and manifests are exempt from the 500-line cap; manifests are configuration/data files). Batch boundaries are marked per phase below.

## Diagnose-Then-Fix Boundaries

Do NOT rework these confirmed-correct layers. MSAL (`@azure/msal-browser`) MUST NOT be imported by any of these modules; it belongs only in the host-bound auth adapter and host shell:
- Pure host-neutral modules: `src/taskpane/ifile/folder-search.ts`, `wildcard-matcher.ts`, `search-result-ordering.ts`, `result-list-composer.ts`, `folder-path-builder.ts`, `folder-result.ts`, `message-id-resolver.ts`, `host-presentation.ts`, `archive-root-picker.ts`, `api-base-url.ts`.
- `src/taskpane/ifile/ifile-controller.ts` (host-neutral controller).
- The exported `bootstrap` seam in `src/taskpane/ifile/ifile.ts` MUST stay Office-free and MSAL-free; NAA is injected into it via the existing `TokenAcquirer` seam.
- `src/TaskMaster.Infrastructure/IFile/GraphFolderTreeReader.cs` and the `/api/ifile/folders` leaf filter in `src/TaskMaster.Api/Program.cs` (confirmed correct in cycle 1; do not modify).

## Secrets and Identifiers Constraint (applies to every task)

- Non-secret identifiers MAY appear in committed files and client code: client ID `2921bc0b-4518-4547-b8ca-f937713688ec`, tenant ID `d80d0ee6-3e37-43d7-9974-0ae662873253`, Application ID URI `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec`.
- The client secret and any token value MUST NEVER be committed. The backend client secret is supplied only via `dotnet user-secrets` or environment injection.
- Dev Tunnel hostnames (`taskmaster-ios-3000.use.devtunnels.ms`, `taskmaster-api-7287.use.devtunnels.ms`) are session-scoped dev values. Do NOT bake a production domain. The production-domain substitution is recorded as an out-of-scope follow-up below.

---

### Phase 0 — Policy Read and Remediation Baseline Capture

- [x] [P0-T1] Read repository policy files in required order and record the read evidence. Files to read, in order: `CLAUDE.md`; `.claude/rules/general-code-change.md`; `.claude/rules/general-unit-test.md`; `.claude/rules/typescript.md`; `.claude/rules/typescript-suppressions.md`; `.claude/rules/architecture-boundaries.md`; `.claude/rules/csharp.md`; `.claude/rules/quality-tiers.md`; `.claude/rules/tonality.md`. Write `evidence/remediation-baseline/phase0-instructions-read.md` containing `Timestamp:`, `Policy Order:`, and the explicit list of files read. Acceptance: artifact exists with all three fields populated and lists every file above.

- [x] [P0-T2] Capture TypeScript format baseline. Command: `npm run format:check`. Write `evidence/remediation-baseline/ts-format.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact records exit code and whether any files are unformatted.

- [x] [P0-T3] Capture TypeScript lint baseline. Command: `npm run lint`. Write `evidence/remediation-baseline/ts-lint.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact records exit code and error/warning counts.

- [x] [P0-T4] Capture TypeScript type-check baseline. Command: `npm run typecheck`. Write `evidence/remediation-baseline/ts-typecheck.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact records exit code and error count.

- [x] [P0-T5] Capture TypeScript architecture-boundary baseline. Command: `npm run depcruise`. Write `evidence/remediation-baseline/ts-arch.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: artifact records exit code and violation count.

- [x] [P0-T6] Capture TypeScript test + coverage baseline. Command: `npm run test:coverage`. Write `evidence/remediation-baseline/ts-test-coverage.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. `Output Summary:` MUST include numeric headline line% and branch% totals and the current per-file coverage for `src/taskpane/ifile/ifile.ts` and `src/taskpane/ifile/inline-host.ts`. Acceptance: numeric coverage values recorded (no placeholders).

- [x] [P0-T7] Capture the backend `AzureAd` config-wiring baseline (read-only; no build). Inspect and quote the relevant lines of `src/TaskMaster.Api/Program.cs` (`AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))` and `EnableTokenAcquisitionToCallDownstreamApi()`) and `src/TaskMaster.Api/appsettings.json` (`AzureAd` keys `Instance`/`TenantId`/`ClientId`/`Audience`, and confirm `ClientSecret` is absent). Write `evidence/remediation-baseline/backend-azuread-config.md` with `Timestamp:`, `Command:` (record `READ-ONLY INSPECTION` since no command runs), `EXIT_CODE:` (`0`), and `Output Summary:` quoting the wiring lines and the appsettings keys. Acceptance: artifact confirms the OBO-path keys are read from configuration and `ClientSecret` is not committed; establishes that no C# code change is required this cycle.

---

### Phase 1 — Diagnostic Regression Tests (fail-before evidence)

Batch 1 (test files only; 0 production / 3 test files). These tests are written against the NOT-YET-IMPLEMENTED NAA seam and stage-specific messages, so they MUST fail on current code. Each is tagged `[expect-fail]` with an auditable fail-before artifact.

- [x] [P1-T1] [expect-fail] Add a failing regression test for the NAA token-acquirer adapter. File: `tests/taskpane/ifile/naa-token-acquirer.test.ts` (new). Import the not-yet-existing factory `createNaaTokenAcquirer` from `src/taskpane/ifile/naa-token-acquirer.ts`. Assert, using injected fakes for the MSAL instance, the Office requirements check, and a fallback hook (no real `@azure/msal-browser` import in the test — inject a fake public-client-application shape): (a) when `isSetSupported("NestedAppAuth","1.1")` returns true and `acquireTokenSilent` resolves, the returned acquirer resolves the access token; (b) when `acquireTokenSilent` rejects with an `InteractionRequiredAuthError`-shaped error, the acquirer calls `acquireTokenPopup` and resolves its token; (c) when `isSetSupported` returns false, the acquirer invokes the documented fallback branch and rejects/propagates a clear unsupported-environment error. Run with `npm run test -- naa-token-acquirer`. This test MUST fail (module does not yet exist). Write `evidence/regression-testing/fail-before-naa-token-acquirer.2026-06-04T20-29.md` with `Timestamp:`, `Command:`, `EXIT_CODE:` (non-zero), `SearchScope:`, `SearchPatterns:`, `SearchResult:`, and the import/compile failure. Acceptance: artifact shows the test failing for the missing-module reason.

- [x] [P1-T2] [expect-fail] Add a failing regression test for stage-specific bootstrap messages. File: `tests/taskpane/ifile/ifile.bootstrap.test.ts` (extend). Add tests that drive the exported `bootstrap` seam and assert the rendered error row text matches a distinct **sign-in** message constant when `acquireToken` rejects, and a distinct **connection** message constant when `loadLeaves` rejects after a successful token. Import the not-yet-exported message constants (e.g. `SIGN_IN_FAILURE_MESSAGE`, `CONNECTION_FAILURE_MESSAGE`) from `src/taskpane/ifile/ifile.ts`. Run with `npm run test -- ifile.bootstrap`. This test MUST fail (constants not yet exported; current code uses a single `BOOTSTRAP_FAILURE_MESSAGE`). Write `evidence/regression-testing/fail-before-stage-messages-bootstrap.2026-06-04T20-29.md` with `Timestamp:`, `Command:`, `EXIT_CODE:` (non-zero), `SearchScope:`, `SearchPatterns:`, `SearchResult:`, and the failing assertion/compile text. Acceptance: artifact shows the test failing on current code.

- [x] [P1-T3] [expect-fail] Add a failing regression test for the configuration-stage message in the host shell. File: `tests/taskpane/ifile/ifile.host-shell.test.ts` (extend). Add a test that drives `runBootstrap` (or the host-shell URL-guard path) with an Office fake and a mobile-build flag + localhost URL, and asserts the rendered error row text matches a distinct **configuration** message constant (e.g. `CONFIGURATION_FAILURE_MESSAGE`) rather than the generic message. Run with `npm run test -- ifile.host-shell`. This test MUST fail (constant not yet exported; current code renders the generic `BOOTSTRAP_FAILURE_MESSAGE` on URL-guard failure). Write `evidence/regression-testing/fail-before-config-message-host-shell.2026-06-04T20-29.md` with `Timestamp:`, `Command:`, `EXIT_CODE:` (non-zero), `SearchScope:`, `SearchPatterns:`, `SearchResult:`, and the failing assertion/compile text. Acceptance: artifact shows the test failing on current code.

---

### Phase 2 — Stage-Specific Bootstrap Messages

Batch 2 (2 production files; 1 test file). Splits the single generic failure message into deterministic, testable per-stage messages. No MSAL yet — this phase is independent of the dependency add so it can land and be verified on its own.

- [x] [P2-T1] Replace the single `BOOTSTRAP_FAILURE_MESSAGE` with three distinct exported message constants and route each failure stage to its message. File: `src/taskpane/ifile/ifile.ts`. Define and export `CONFIGURATION_FAILURE_MESSAGE` (URL-guard / build-configuration failure), `SIGN_IN_FAILURE_MESSAGE` (token acquisition failure), and `CONNECTION_FAILURE_MESSAGE` (folder-fetch failure). In `bootstrap`, render `SIGN_IN_FAILURE_MESSAGE` on the token-acquisition catch. In `runBootstrap`, render `CONFIGURATION_FAILURE_MESSAGE` on the `assertReachableApiBaseUrl` catch. Keep each message text professional and specific per `tonality.md`. Keep `ifile.ts` under 500 lines and host-bound wiring thin. Acceptance: `npm run typecheck` clean; the three constants are exported; `npm run test -- ifile.bootstrap` passes including the Phase 1 [P1-T2] tests; `npm run test -- ifile.host-shell` passes including [P1-T3].

- [x] [P2-T2] Route the inline-host one-time load failure to the connection-stage message. File: `src/taskpane/ifile/inline-host.ts`. Change `mountInline` so the load-failure branch renders the connection-stage message. Either accept the message as a parameter (preferred: keep `inline-host.ts` host-neutral and let `bootstrap` pass `CONNECTION_FAILURE_MESSAGE`) or export a connection-stage constant from `inline-host.ts` and have `ifile.ts` re-use it; choose the option that avoids `inline-host.ts` importing from `ifile.ts` (no new circular dependency). Update `mountInline`'s signature and its single caller in `ifile.ts` accordingly. Keep `inline-host.ts` under 500 lines. Acceptance: `npm run typecheck` clean; `npm run depcruise` reports no new circular dependency; the connection-stage message is rendered on load failure.

- [x] [P2-T3] Extend the resilient-wiring tests for the connection-stage message and the no-regression positive path. File: `tests/taskpane/ifile/inline-host.test.ts` (extend). Assert: (a) a failed one-time load renders the connection-stage message text and keeps the box responsive; (b) the positive path (successful load) still renders results on input with no error row (no regression). Run with `npm run test -- inline-host`. Acceptance: both scenarios pass; positive path unchanged.

---

### Phase 3 — NAA Dependency and Architecture-Boundary Guard

Batch 3 (2 production/config files; 0 test files). Adds the runtime dependency and the dependency-cruiser rule that forbids MSAL in the pure modules, BEFORE the NAA code lands, so the boundary guard is in force when Phase 4 adds the adapter.

- [x] [P3-T1] Add `@azure/msal-browser` as a runtime dependency and document the rationale. File: `package.json`. Add `@azure/msal-browser` to the `dependencies` block (not `devDependencies`) at a current stable pinned version. In the same change, add a short rationale comment in the cycle documentation is not possible inside `package.json` (JSON has no comments); instead record the rationale in `evidence/other/naa-dependency-rationale.md` with `Timestamp:` and the justification: OD-8 NAA-primary; NAA is the only Outlook-iOS-supported token path per research section 1; `@azure/msal-browser` is the official Microsoft library implementing `createNestablePublicClientApplication`. Run `npm install` to update `package-lock.json`. Acceptance: `@azure/msal-browser` appears under `dependencies` in `package.json` and is resolved in `package-lock.json`; the rationale artifact exists. Do NOT add any other new runtime dependency.

- [x] [P3-T2] Extend the dependency-cruiser pure-module rule to forbid MSAL imports in the host-neutral modules. File: `.dependency-cruiser.cjs`. In the `ifile-pure-modules-no-host-deps` forbidden rule, add `node_modules/@azure/msal-browser` to the `to.path` array (alongside the existing `^src/api-client/`, `node_modules/@types/office-js`, `node_modules/@microsoft/microsoft-graph-client`) so that any import of `@azure/msal-browser` from a pure module is a Blocking architecture violation. Keep `dependencyTypesNot: ["type-only"]` as-is. Update the rule `comment` to mention MSAL. Acceptance: `npm run depcruise` runs clean against current source (no pure module imports MSAL yet); the rule now lists `@azure/msal-browser` as a forbidden target for the pure modules.

---

### Phase 4 — NAA Token Acquisition Behind the TokenAcquirer Seam

Batch 4 (2 production files; 1 test file). Implements NAA in a thin host-bound auth adapter and injects it through the existing `TokenAcquirer` seam so `bootstrap` stays Office-free and MSAL-free.

- [x] [P4-T1] Implement the NAA token-acquirer adapter. File: `src/taskpane/ifile/naa-token-acquirer.ts` (new, host-bound). Export an async factory `createNaaTokenAcquirer` that: (a) gates on a runtime support check `Office.context.requirements.isSetSupported("NestedAppAuth", "1.1")`; (b) when supported, constructs the MSAL instance via `createNestablePublicClientApplication` with `clientId: "2921bc0b-4518-4547-b8ca-f937713688ec"` and `authority: "https://login.microsoftonline.com/common"` (non-secret identifiers; the tenant id `d80d0ee6-3e37-43d7-9974-0ae662873253` is acceptable as a single-tenant authority alternative, documented in a comment), and `cache.cacheLocation: "localStorage"`; (c) returns a `TokenAcquirer` that calls `acquireTokenSilent({ scopes: ["Mail.ReadBasic", "Mail.ReadWrite", "Files.ReadWrite"] })`, and on `InteractionRequiredAuthError` falls back to `acquireTokenPopup` with the same scopes, returning the resolved `accessToken`; (d) when `NestedAppAuth 1.1` is NOT supported, executes the documented fallback branch: surface a clear, specific error indicating the environment does not support NAA and that the Office dialog interactive flow is the required fallback (the full Office-dialog interactive flow is scoped as an explicit out-of-scope follow-up below — do NOT silently drop it; this branch must produce a deterministic, testable error/signal, not a silent no-op). Inject the support-check function, the MSAL-instance factory, and the fallback hook as parameters with safe defaults so the adapter is unit-testable without the Office host or a real MSAL instance. Keep the file under 500 lines. This file is host-bound; it is the ONLY iFile module permitted to import `@azure/msal-browser`. Acceptance: `npm run test -- naa-token-acquirer` passes including the Phase 1 [P1-T1] tests; `npm run typecheck` clean; `npm run depcruise` clean (MSAL imported only here, not in any pure module).

- [x] [P4-T2] Wire the NAA acquirer into the host shell, replacing the legacy SSO call as the primary path. File: `src/taskpane/ifile/ifile.ts`. In `runBootstrap`, replace `acquireToken: () => Office.auth.getAccessToken({ allowSignInPrompt: true })` with the NAA acquirer produced by `createNaaTokenAcquirer(...)`, injected through the existing `TokenAcquirer` seam into `bootstrap`. Keep `bootstrap` itself unchanged in signature and Office-free/MSAL-free (it receives the acquirer via `BootstrapDeps.acquireToken`). When `createNaaTokenAcquirer` reports the unsupported-environment fallback, the token-acquisition catch in `bootstrap` renders `SIGN_IN_FAILURE_MESSAGE` (from Phase 2) so the failure is visible and stage-specific. Keep `ifile.ts` under 500 lines and the host-bound wiring thin. Acceptance: `npm run typecheck` clean; `runBootstrap` no longer uses `Office.auth.getAccessToken` as the sole/primary path; `npm run depcruise` clean.

- [x] [P4-T3] Add host-shell regression tests for the NAA-supported and NAA-unsupported branches at the wiring level. File: `tests/taskpane/ifile/ifile.host-shell.test.ts` (extend). Using the Office fake and an injected NAA-acquirer seam: (a) NAA-supported branch resolves a token and the box loads results (positive path); (b) NAA-unsupported branch routes to the sign-in-stage visible message and keeps the box responsive. Run with `npm run test -- ifile.host-shell`. Acceptance: both branches pass; no regression in the existing host-shell tests.

---

### Phase 5 — Manifests: SSO App Info and Dev Tunnel Domains

Batch 5 (2 manifest/config files; 0 test files). Manifests are configuration/data files exempt from the 500-line cap. Use the exact shapes/values from research section 3. Do NOT add a production domain.

- [x] [P5-T1] Add `webApplicationInfo` and Dev Tunnel domains to the unified manifest. File: `manifest.json`. Add a root-level `webApplicationInfo` object with `id: "2921bc0b-4518-4547-b8ca-f937713688ec"` and `resource: "api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec"` (research section 3.2). Add `"taskmaster-ios-3000.use.devtunnels.ms"` and `"taskmaster-api-7287.use.devtunnels.ms"` to the `validDomains` array, matching the existing scheme-less `localhost` entry convention (research section 3.5). Record in a comment-free way; if the manifest must remain comment-free, capture the desktop/web-only caveat (the unified manifest is not operative on iOS) in `evidence/other/manifest-changes.md`. Acceptance: `npm run validate` passes (`office-addin-manifest validate manifest.json`); `webApplicationInfo.id`/`resource` and both Dev Tunnel domains are present; no production domain added.

- [x] [P5-T2] Add `<WebApplicationInfo>` and Dev Tunnel `<AppDomain>` entries to the add-in (XML) manifest. File: `manifest.xml`. Add the two `<AppDomain>` entries `https://taskmaster-ios-3000.use.devtunnels.ms/` and `https://taskmaster-api-7287.use.devtunnels.ms/` to `<AppDomains>` (trailing-slash + https scheme, matching the existing `<AppDomain>` convention). Add a `<WebApplicationInfo>` block at the END of the inner `<VersionOverrides xsi:type="VersionOverridesV1_1">` section (after `</Hosts>`/`</Resources>`, before the inner `</VersionOverrides>` close, per research section 3.3 placement note) with `<Id>2921bc0b-4518-4547-b8ca-f937713688ec</Id>`, `<Resource>api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec</Resource>`, and `<Scopes>` listing `openid`, `profile`, `Mail.ReadBasic`, `Mail.ReadWrite`, `Files.ReadWrite` (research section 3.3). Acceptance: `npm run validate:xml` passes (`office-addin-manifest validate manifest.xml`); the `<WebApplicationInfo>` block and both Dev Tunnel `<AppDomain>` entries are present; no production domain added.

---

### Phase 6 — Backend Config Verification (no C# code change)

Batch 6 (0 production code files; documentation/verification only). Per inputs section 4 item 5: the backend already reads the `AzureAd` OBO keys; this is a verification + documentation task, not a code change.

- [x] [P6-T1] Verify and document the backend `AzureAd` OBO config wiring. Inspect `src/TaskMaster.Api/Program.cs` and `src/TaskMaster.Api/appsettings.json` (and confirm `src/TaskMaster.Api/appsettings.Development.json` does not commit a `ClientSecret`). Write `evidence/other/backend-azuread-verification.2026-06-04T20-29.md` recording: (a) `Program.cs` reads `GetSection("AzureAd")` and enables OBO via `EnableTokenAcquisitionToCallDownstreamApi()`; (b) `appsettings.json` declares `Instance`, `TenantId`, `ClientId`, `Audience` (non-secret identifiers may be populated in non-secret config; values are environment-supplied at deploy/dev time); (c) `ClientSecret` is NOT committed and MUST be supplied via `dotnet user-secrets set "AzureAd:ClientSecret" <value>` or environment injection per research section 4; (d) the expected non-secret values (TenantId `d80d0ee6-...`, ClientId `2921bc0b-...`, Audience `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-...`, Instance `https://login.microsoftonline.com/`). Acceptance: artifact confirms no C# source change is required; if inspection reveals the keys are NOT read from configuration, stop and escalate as a scope change (do not edit backend code under this plan without escalation).

---

### Phase 7 — Documentation Deliverables (doc-only; declared-exception runbooks)

Doc-only phase. Markdown files exempt from the 500-line cap. These runbooks support declared human-interaction exceptions HI-1/HI-2/HI-3.

- [x] [P7-T1] Create the HI-3 Entra-app SSO configuration runbook. File: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/entra-app-sso-config.runbook.md` (new). Include the 8 ordered steps from research section 2 (SPA redirect `brk-multihub://taskmaster-ios-3000.use.devtunnels.ms`; set Application ID URI; expose `access_as_user`; pre-authorize the Office umbrella client `ea5a67f6-b6f3-4338-b240-c655ddc3cc8e`; add Graph delegated permissions `Mail.ReadBasic`/`Mail.ReadWrite`/`Files.ReadWrite`/`openid`/`profile`; grant admin consent — cross-reference HI-1 / `entra-admin-consent.runbook.md` at step 6; set `requestedAccessTokenVersion: 2`; create the client secret and inject via user-secrets, never commit). Include the MCP/web source citations and the capture date (2026-06-04) from research section "Sources Consulted". Mark the runbook as the HI-3 declared exception (response: exception). Acceptance: the file exists with the 8 ordered steps, source citations with capture date, the secret-handling warning, and the HI-3 exception declaration.

- [x] [P7-T2] Update the on-device verification runbook to reference the NAA token path. File: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/outlook-on-device-verification.runbook.md`. Add/adjust content so the runbook: (a) references the NAA token path (`createNestablePublicClientApplication` + `acquireTokenSilent`/`acquireTokenPopup`) as the active client token mechanism instead of legacy `getAccessToken`; (b) states the requirement that the Application ID URI and SPA redirect host MUST match the active Dev Tunnel host used for the build; (c) cross-references `entra-app-sso-config.runbook.md` (HI-3) as a prerequisite alongside `entra-admin-consent.runbook.md` (HI-1). Keep the existing HI-2 exception framing and the reachable-`API_BASE_URL` build step. Acceptance: the runbook references the NAA path, the URI/redirect-must-match-tunnel requirement, and the HI-3 prerequisite.

---

### Phase 8 — Final QA Loop (TypeScript) and Coverage Delta

Run steps in order. If any step fails or changes files, restart from [P8-T1]. The C# backend is not modified this cycle (Phase 6 is verification-only), so no C# QA loop is run; this is consistent with the in-scope-languages declaration above.

- [x] [P8-T1] Final TypeScript format. Command: `npm run format`. Write `evidence/qa-gates/final-ts-format.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: exit code 0; if files changed, restart the loop.

- [x] [P8-T2] Final TypeScript lint. Command: `npm run lint`. Write `evidence/qa-gates/final-ts-lint.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: 0 errors; if it fails or fixes files, restart the loop.

- [x] [P8-T3] Final TypeScript type-check. Command: `npm run typecheck`. Write `evidence/qa-gates/final-ts-typecheck.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: 0 errors.

- [x] [P8-T4] Final TypeScript architecture-boundary check. Command: `npm run depcruise`. Write `evidence/qa-gates/final-ts-arch.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. Acceptance: 0 violations, including the extended `ifile-pure-modules-no-host-deps` rule confirming no pure module imports `@azure/msal-browser` and that MSAL is imported only by `naa-token-acquirer.ts`.

- [x] [P8-T5] Final TypeScript test + coverage. Command: `npm run test:coverage`. Write `evidence/qa-gates/final-ts-test-coverage.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. `Output Summary:` MUST include numeric headline line% and branch% totals and per-file coverage for `src/taskpane/ifile/ifile.ts`, `src/taskpane/ifile/inline-host.ts`, and `src/taskpane/ifile/naa-token-acquirer.ts`. Acceptance: all tests pass; line >= 85%, branch >= 75%; numeric values recorded (no placeholders).

- [x] [P8-T6] Manifest validation gate. Commands: `npm run validate` and `npm run validate:xml`. Write `evidence/qa-gates/final-manifest-validate.md` with `Timestamp:`, both `Command:` lines, both `EXIT_CODE:` values, and `Output Summary:`. Acceptance: both validators exit 0 with the new `webApplicationInfo`/`<WebApplicationInfo>` and Dev Tunnel domains present.

- [x] [P8-T7] Coverage delta / threshold verification. Compare Phase 0 [P0-T6] baseline against Phase 8 [P8-T5] post-change coverage. Write `evidence/qa-gates/final-coverage-delta.md` reporting: baseline line%/branch%, post-change line%/branch%, and changed-line coverage for the modified/new files (`ifile.ts`, `inline-host.ts`, `naa-token-acquirer.ts`). Acceptance: no regression on changed lines; changed-line coverage meets line >= 85% / branch >= 75%; the NAA adapter and the stage-message routing are covered and no production file is coverage-excluded. If thresholds are not met, the cycle outcome is remediation-required (not PASS).

---

## Out-of-Scope Notes (for potential follow-up cycles)

- **Production-domain substitution (carried forward).** The Application ID URI, SPA redirect (`brk-multihub://...`), `webApplicationInfo.resource`/`<Resource>`, manifest `validDomains`/`<AppDomains>`, and the backend `AzureAd:Audience` are all Dev-Tunnel-host-scoped (`taskmaster-ios-3000.use.devtunnels.ms`). When a stable production domain exists, all of these must be updated to it. Recorded as a follow-up; no production URL is hardcoded this cycle.
- **Full Office-dialog interactive fallback (new, surfaced during planning).** Phase 4 [P4-T1] implements the NAA-unsupported branch as a guarded, deterministic error path that surfaces the sign-in-stage message and names the Office dialog interactive flow as the required fallback. The full implementation of the Office dialog API interactive MSAL flow (research section 1.2) is larger than this cycle's batch budget and is recorded here as an explicit out-of-scope follow-up. It is NOT silently dropped: the unsupported-environment branch produces a visible, testable signal.
- **No other new defects** outside the inputs scope were identified during planning. The confirmed-correct host-neutral search modules and the C# Graph folder reader are not reworked (diagnose-then-fix boundary).

## Preflight

This plan is to be validated via `atomic-executor` preflight (validation only) using `DIRECTIVE: PREFLIGHT VALIDATION ONLY`, expecting `PREFLIGHT: ALL CLEAR` or `PREFLIGHT: REVISIONS REQUIRED`, and via the `mcp__drm-copilot__validate_orchestration_artifacts` plan validator (`artifact_type: "plan"`, `artifact_path:` this file). The target plan path is reused across all revision iterations; no timestamped sibling plan file is created during this cycle.
