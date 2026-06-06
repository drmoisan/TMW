# Remediation Inputs — iFile Message-Filing Dialog (#43)

- Cycle: 2
- Entry timestamp: 2026-06-04T20-29
- Author: orchestrator
- Feature folder: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- Branch: `feature/ifile-message-filing-dialog-43`
- Open PR: #44
- Trigger class: new defect surfaced during HI-2 on-device verification (scope-change rule from cycle 1). Acceptance criteria AC-2/AC-3/AC-20/AC-24 remain unmet on a physical Outlook iOS client.
- Research basis (pre-cycle): `artifacts/research/2026-06-04-ifile-token-path-naa-vs-sso-research-43.md` (MCP/web-sourced, current Microsoft docs, captured 2026-06-04).

## 1. Observed Defect

On a physical iPhone, after building with a reachable `API_BASE_URL` (`https://taskmaster-api-7287.use.devtunnels.ms`, confirmed baked into `dist/ifile.js`), the iFile container renders and shows the visible error: "iFile could not start. Check your connection and sign-in, then try again." Cycle 1's resilience fix is working (the box renders and the failure is visible instead of silent). The remaining failure is in token acquisition.

## 2. Root Cause (evidence-based)

- The built bundle baked `isMobileBuild=false` and a non-localhost URL, so the URL-guard path is excluded. The visible message is rendered by the token-acquisition catch in `bootstrap` (`src/taskpane/ifile/ifile.ts`).
- The client uses `Office.auth.getAccessToken(...)` — the **legacy Office SSO** path. Per current Microsoft requirement-set docs (captured 2026-06-04), the backing requirement set `IdentityAPI 1.3` is **not listed in the Outlook iOS support matrix**; the iOS row lists `NestedAppAuth 1.1` instead. Legacy SSO is not the supported path on Outlook iOS.
- The existing Entra app "Graph Mail Calendar PoC" (client `2921bc0b-4518-4547-b8ca-f937713688ec`, tenant `d80d0ee6-3e37-43d7-9974-0ae662873253`) is not configured for SSO/OBO: no Application ID URI, no exposed `access_as_user` scope, no pre-authorized Office clients, no SPA redirect, no client secret. The manifests contain no `webApplicationInfo`/`<WebApplicationInfo>`, and `validDomains`/`<AppDomains>` omit the Dev Tunnel hosts.

This confirms the OD-8 token risk that cycle 1 deferred (Phase-4 `OUT_OF_SCOPE_DEFERRED`).

## 3. Resolution Direction (from research; OD-8 affirmed and refined)

NAA (nested app authentication) via MSAL.js is GA on Outlook iOS (build v4.2433.0) and is the Microsoft-recommended path. OD-8 ("NAA primary; OBO server-side") is affirmed; its fallback wording is refined: when `NestedAppAuth 1.1` is unsupported at runtime, fall back to the Office dialog API interactive flow, not `getAccessToken`. All privileged Graph operations remain server-side via the already-wired OBO backend; the client acquires a token via NAA and sends it to the backend.

## 4. Scope for This Cycle

In scope (CI-verifiable, automatable here):
1. Add `@azure/msal-browser` (official Microsoft library; entailed by OD-8/NAA — the only iOS-supported path per research). Document the dependency rationale.
2. Replace the client token path: implement `createNestablePublicClientApplication` + `acquireTokenSilent` → `acquireTokenPopup`, gated by a runtime `Office.context.requirements.isSetSupported("NestedAppAuth","1.1")` check, with a documented fallback for unsupported environments. Keep the token acquisition behind the existing injected `TokenAcquirer` seam in `bootstrap` so it stays host-neutral and testable.
3. Add `webApplicationInfo` (manifest.json) and `<WebApplicationInfo>` (manifest.xml) and add the Dev Tunnel hosts to `validDomains`/`<AppDomains>`, per the exact shapes in the research (section 3).
4. Split the single generic bootstrap error into distinct, deterministic, testable messages by failure stage: **configuration** (URL-guard), **sign-in** (token acquisition), and **connection** (folder fetch). This makes future on-device failures self-diagnosing.
5. Backend config: ensure the `AzureAd` section keys the OBO path needs (`Instance`, `TenantId`, `ClientId`, `Audience`) are wired from configuration; the **`ClientSecret` must come from user-secrets/environment and must never be committed**. Non-secret identifiers may live in non-secret config.
6. Regression tests for the NAA-supported and NAA-unsupported branches, the token-failure → sign-in-message path, and the stage-specific message mapping. No production file may be coverage-excluded.

In scope (documentation, automatable here): an Entra-app SSO configuration runbook (the 8 ordered steps from research section 2), and an update to the on-device verification runbook noting the Application ID URI / SPA redirect must match the active tunnel host.

Out of scope (do not expand): classifier/recent sources; the filing/move/OneDrive behavior except to avoid regression; production-domain deployment (the tunnel hosts are dev-scoped — note the production-domain substitution as a follow-up, do not hardcode a production URL).

## 5. Human-Interaction Requirements (autonomous-execution mandate)

The code/manifest/test changes are automatable and must be CI-verified. The Entra configuration cannot be performed from this repo/CI (it needs tenant/app-owner and Global-Admin credentials), so it is a declared exception with a runbook produced by this cycle:

- **HI-3 (new):** Configure the existing Entra app for NAA + OBO — add the `brk-multihub://` SPA redirect, set the Application ID URI, expose `access_as_user`, pre-authorize the Office umbrella client `ea5a67f6-b6f3-4338-b240-c655ddc3cc8e`, add the Graph delegated permissions, set `requestedAccessTokenVersion: 2`, and create the client secret + inject it into backend user-secrets. Response: **exception**; runbook is a cycle deliverable (e.g. `runbooks/entra-app-sso-config.runbook.md`). The orchestrator registers HI-3 in the checkpoint only after the runbook file exists.
- **HI-1 (existing):** Grant tenant admin consent for the Graph delegated scopes — unchanged; cross-referenced by the HI-3 runbook (step 6).
- **HI-2 (existing):** Build the mobile bundle with a reachable `API_BASE_URL` (and Application-ID-URI/SPA-redirect matching the active tunnel), sideload, and verify end-to-end on device — updated to reference the NAA token path.

No requirement may be left as an undeclared manual dependency. None of these resolve to `halt`.

## 6. Constraints

- No-COM architecture; dependency-cruiser layer boundaries (MSAL is a host/auth adapter concern — keep it out of the pure modules; the bootstrap seam already isolates token acquisition behind `TokenAcquirer`).
- New runtime dependency policy: `@azure/msal-browser` is justified by OD-8 + research; document why. No other new dependencies.
- 500-line file cap; TypeScript suppression policy; full seven-stage toolchain green; no production file coverage-excluded.
- Secrets: the client secret and any token values must never be committed. Dev Tunnel hosts are session-scoped; do not bake a production URL.

## 7. Exit Criteria for This Cycle

- The client acquires a Graph-capable token via NAA when supported, with a runtime guard and a documented fallback; `getAccessToken` is no longer the sole/primary path.
- Manifests declare the SSO app info and the Dev Tunnel domains per research section 3.
- Bootstrap failures render stage-specific (configuration / sign-in / connection) messages, covered by tests.
- Full toolchain green; changed-line coverage meets thresholds; the bootstrap/token seam stays in coverage.
- The HI-3 Entra runbook exists and is registered as a declared exception; HI-1/HI-2 updated.
- The three end-of-cycle reaudit artifacts report `blocking_count == 0`.
- Feature DONE remains gated on the human executing HI-3 (Entra config) + HI-1 (consent) + HI-2 (build + on-device re-verification). That gating is correct and declared, not a code defect.

## 8. Handoff

Next delegate: `atomic-planner` — author `remediation-plan.2026-06-04T20-29.md` against this inputs file and the research, following the `atomic-plan-contract`. Diagnose-then-implement the NAA path; keep token acquisition behind the existing `TokenAcquirer` seam for host-neutral testability; respect the per-batch budget. The orchestrator delegates only to atomic-planner → atomic-executor → feature-review for this cycle; `atomic-executor` invokes typed-engineer workers internally.
