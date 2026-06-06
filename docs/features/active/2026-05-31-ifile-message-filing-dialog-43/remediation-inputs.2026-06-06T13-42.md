# Remediation Inputs — iFile #43 — Cycle 4

- **Entry timestamp:** 2026-06-06T13-42
- **Cycle:** 4 (cycles 1–3 complete; each exited at blocking_count 0)
- **Branch:** feature/ifile-message-filing-dialog-43
- **PR:** #44
- **Author:** Orchestrator
- **Allowed in-cycle delegates:** atomic-planner, atomic-executor, feature-review only

---

## 1. Trigger

On-device diagnosis (2026-06-06) of the Outlook iOS NAA sign-in failure
(`fromBridgeError -> ServerError`, no `AADSTS` code, no correlation id) identified a
**client-ID / app-registration mismatch**, not a missing redirect URI.

The iFile client authenticates against Entra app **`2921bc0b-4518-4547-b8ca-f937713688ec`**
("Graph Mail Calendar PoC"), hard-coded at `src/taskpane/ifile/naa-token-acquirer.ts`
(`CLIENT_ID`) and mirrored in both manifests. The user has fully configured a **different**
Entra app — **`3592bf52-46f6-4eb0-835c-4f961058de97`** ("TaskMaster Web") — with the NAA
`brk-multihub://taskmaster-ios-3000.use.devtunnels.ms` SPA redirect, the
`api://taskmaster-ios-3000.use.devtunnels.ms/3592bf52-46f6-4eb0-835c-4f961058de97`
Application ID URI, the `access_as_user` scope, the pre-authorized Office umbrella client
`ea5a67f6-b6f3-4338-b240-c655ddc3cc8e`, and 9 Microsoft Graph delegated permissions.

Because the Office host broker resolves the redirect registration for the app whose client ID
MSAL presents (`2921bc0b-…`), and that app has no matching `brk-multihub` SPA redirect, the
broker rejects the request before any AAD round-trip. This reproduces the observed pre-AAD
broker rejection exactly (no AADSTS code, no correlation id).

## 2. Selected resolution (Option A — confirmed by user)

Align the entire in-repo iFile authentication chain on the app the user already configured,
`3592bf52-46f6-4eb0-835c-4f961058de97`. This avoids re-doing the Entra configuration that is
already in place on that app. The tenant (`d80d0ee6-3e37-43d7-9974-0ae662873253`) and the
Dev Tunnel hosts are unchanged.

New canonical values:

| Element | New value |
|---|---|
| Client (application) ID | `3592bf52-46f6-4eb0-835c-4f961058de97` |
| Application ID URI / resource | `api://taskmaster-ios-3000.use.devtunnels.ms/3592bf52-46f6-4eb0-835c-4f961058de97` |
| Authority | `https://login.microsoftonline.com/common` (unchanged) |
| Tenant ID | `d80d0ee6-3e37-43d7-9974-0ae662873253` (unchanged) |

## 3. Required changes (in-repo, automatable + CI-verifiable)

1. **`src/taskpane/ifile/naa-token-acquirer.ts`**
   - Replace `CLIENT_ID` value with `3592bf52-46f6-4eb0-835c-4f961058de97`.
   - Update the doc-comment reference to the single-tenant authority example if it cites the
     old client ID (none expected; verify).
2. **`manifest.json`** — `webApplicationInfo.id` and `webApplicationInfo.resource` updated to
   the new client ID / new Application ID URI.
3. **`manifest.xml`** — `<WebApplicationInfo><Id>` and `<Resource>` updated to the same.
4. **`tests/taskpane/ifile/naa-token-acquirer.test.ts`** — update the clientId assertion
   (`expect(config.auth.clientId).toBe(...)`) to the new client ID.
5. **Revert the temporary on-device PII diagnostic** in
   `src/taskpane/ifile/naa-token-acquirer.ts` (flagged "REVERT before release" at the
   `piiLoggingEnabled: true` setting and the removed `containsPii` skip): restore
   `piiLoggingEnabled: false` and reinstate the `if (containsPii) { return; }` guard with its
   third callback parameter. Update the corresponding tests so the PII-skip behavior is
   covered again. Prior memory established this log path yields only an opaque telemetry token
   for this failure class, so no diagnostic capability of value is lost.
6. **Documentation alignment** — update operational references that name the old client ID /
   App ID URI so they do not contradict the shipped configuration:
   - `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/entra-app-sso-config.runbook.md`
   - `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/runbooks/outlook-on-device-verification.runbook.md`
   Historical/audit artifacts (prior remediation-inputs/plans, research doc, evidence files)
   are an immutable record and must NOT be rewritten.

## 4. Out of scope / human steps (unchanged exceptions)

- **HI-3** — Entra app configuration now targets `3592bf52-…`; the user reports it is already
  configured. The backend OBO `AzureAd:ClientId` / `AzureAd:Audience` / `AzureAd:ClientSecret`
  must be set in **user-secrets** to the new app's values (never committed). Runbook update is
  in scope (item 6); the user-secrets injection remains the human step.
- **HI-1** — admin consent on the Graph delegated permissions (tenant-admin action).
- **HI-2** — mobile build + on-device re-verification that sign-in now succeeds and folder
  search returns results.
- Production-domain substitution for the Dev Tunnel host remains a separate follow-up.

## 5. Constraints

- No secret value (client secret) may enter the repository. Only the non-secret client ID,
  tenant ID, and Application ID URI may appear in committed files.
- Full seven-stage TypeScript toolchain must pass (format, lint, typecheck, dependency-cruiser
  including the MSAL import-boundary rule, vitest + coverage, contract, integration), plus
  manifest `validate` / `validate:xml`. Coverage must not regress on changed lines.
- The `@azure/msal-browser` import boundary (only `naa-token-acquirer.ts`) must be preserved.
- No backend C# production change is expected; verify none is required.

## 6. Exit gate

Cycle 4 exits when the end-of-cycle `code-review`, `feature-audit`, and `policy-audit`
artifacts report a combined `blocking_count` of 0. Feature #43 DONE remains gated on HI-1,
HI-2, HI-3 (declared human exceptions), which are not code defects.

## 7. References

- Diagnosis memory: `.claude/agent-memory/orchestrator/project_ifile_naa_signin_blocked_43.md`
- Token-path research: `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/2026-06-04-ifile-token-path-naa-vs-sso-research-43.md`
- Plan-shape contract: `atomic-plan-contract`
- Handoff chain: `.claude/skills/remediation-handoff-atomic-planner/SKILL.md`
