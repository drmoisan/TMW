# OD-8 Token-Path Investigation ([P4-T1])

Timestamp: 2026-06-04T17-50
File under review: src/taskpane/ifile/ifile.ts — token acquisition via
`Office.auth.getAccessToken({ allowSignInPrompt: true })` (now invoked through the injected
`acquireToken` dependency inside the `runBootstrap` host shell).
Spec reference: OD-8 (spec.md lines 404-407, 445-447).

## Decision

OUT_OF_SCOPE_DEFERRED

## Finding / Rationale

1. OD-8 specifies NAA as the *primary* client-side token path, with a *fallback* to backend
   on-behalf-of via the `getAccessTokenAsync` SSO token. The current call,
   `Office.auth.getAccessToken({ allowSignInPrompt: true })`, is the Office.js SSO
   (`getAccessToken`) path — i.e. it implements OD-8's explicitly specified fallback. It is not a
   path that contradicts OD-8; it is the documented fallback path. OD-8 does not mandate that NAA
   be present for the cycle to be conformant — it mandates NAA-primary with the SSO/OBO fallback,
   and all privileged operations remain server-side (which they do: the client sends only a bearer
   token; no Graph writes run on the client per `ifile-api-client.ts`).

2. The remediation inputs classify the token path as a *contributing risk* (inputs section 3),
   not a confirmed cause. The confirmed root causes from triage are:
   - the unreachable `https://localhost:3000` backend URL on a physical device (inputs section 3,
     item 1 — "leading root cause"), now guarded by `assertReachableApiBaseUrl` (Phase 2), and
   - the silent, inert search box when the one-time load fails (inputs section 3, item 2 —
     "latent amplifying defect"), now fixed by the resilient `mountInline`/`bootstrap` wiring
     (Phase 3).

3. The inputs' stated mechanism for the token risk is: "If SSO fails on iOS, `bootstrap()` rejects
   before the controller is wired, producing the same dead-UI outcome as (2)." After Phase 3, that
   mechanism no longer holds: a token rejection is caught in `bootstrap`, the input handler is
   bound, and a visible error state (`[data-ifile-error]`) is rendered instead of dead UI. This is
   verified by the test `tests/taskpane/ifile/ifile.bootstrap.test.ts >
   "binds the input handler and surfaces a visible error when token acquisition fails"`.
   The silent-failure symptom the token risk would otherwise cause is therefore removed this cycle.

4. No evidence was gathered (and none exists in the triage inputs) that the SSO `getAccessToken`
   call itself *fails* on the target iOS client; the on-device failure is fully explained by the
   unreachable URL plus the inert-box amplifier. Performing a speculative NAA rewrite without
   confirming SSO failure as a cause would exceed the approved scope and the remediation inputs,
   and the plan prohibits a speculative rewrite without `ALIGN_REQUIRED`.

## Consequence

[P4-T2] (conditional token-path alignment) is NOT executed this cycle. It is recorded as
not-applicable, with this artifact as the pointer. If a future on-device verification (HI-2)
shows a token-acquisition failure after the URL and resilience fixes are in place, a follow-up
cycle should reopen OD-8 alignment (NAA-primary with OBO fallback) with that device evidence.
