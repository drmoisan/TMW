# Feature Audit: iFile Message-Filing Dialog — Cycle 4 Reaudit (#43)

**Audit Date:** 2026-06-06
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Base Branch:** `main`
**Head Branch:** `feature/ifile-message-filing-dialog-43` (working tree; cycle-4 deltas assessed against `HEAD` = `2292b0f`)
**Work Mode:** `full-feature`
**Audit Type:** Post-remediation acceptance verification (cycle 4)

---

## Scope and Baseline

- **Base branch:** `main`
- **Head branch/commit:** `feature/ifile-message-filing-dialog-43`, working tree atop `HEAD` `2292b0f`
- **Merge base:** N/A for this cycle (cycle-4 deltas assessed as the working-tree diff against branch `HEAD`)
- **Evidence sources:**
  - Primary: cycle-4 scope contract `remediation-inputs.2026-06-06T13-42.md` and executed plan `remediation-plan.2026-06-06T13-42.md`
  - Toolchain evidence: `evidence/qa-gates/final-ts-*.2026-06-06T13-42.md`, `evidence/qa-gates/final-manifest-validate.2026-06-06T13-42.md`, `evidence/qa-gates/final-coverage-delta.2026-06-06T13-42.md`
  - Secret / stale-value evidence: `evidence/qa-gates/secret-scan.2026-06-06T13-42.md`, `evidence/qa-gates/stale-value-check.2026-06-06T13-42.md`
  - Feature evidence: `evidence/remediation-baseline/*.2026-06-06T13-42.md`
- **Feature folder used:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
- **Requirements source:** `spec.md` (AC-1..AC-24) and `user-story.md` (full-feature work mode)
- **Work mode resolution note:** `issue.md` line 13 persists `- Work Mode: full-feature`; AC sources are therefore `spec.md` and `user-story.md`.
- **Scope note:** Cycle 4 is a narrow authentication-app realignment plus a PII-diagnostic revert and runbook alignment. It changes the AAD app binding that AC-19 and the device-verified ACs (AC-2, AC-3, AC-20) depend on, but does not deliver new feature behavior. This audit evaluates the ACs materially affected by cycle 4 and carries forward the prior-cycle status of unaffected ACs. Feature DONE remains gated on declared human exceptions HI-1 (admin consent), HI-2 (mobile build + on-device re-verification), and HI-3 (backend OBO user-secrets injection).

---

## Acceptance Criteria Inventory

**Authoritative AC source files for this run:**
- `spec.md` — primary (AC-1..AC-24, checkbox-backed)
- `user-story.md` — secondary

### Acceptance criteria materially affected by cycle 4

The cycle-4 change touches the AAD app binding (`CLIENT_ID`, manifest `webApplicationInfo`, Application ID URI) and the on-device NAA sign-in path. The directly affected criteria are:

- **AC-19** Manifest and AAD scope changes are present: `manifest.json` adds `MailboxItem.ReadWrite.User`; `manifest.xml` uses `ReadWriteMailbox`; AAD delegated scopes include `Mail.ReadWrite`, `Files.ReadWrite`, and `Mail.ReadBasic`. *(CI-verifiable: manifest assertion. Manual: consent/token verification against the registered app.)*
- **AC-2** Activating `iFile` on desktop opens an Office Dialog containing a search textbox and a results list. *(Device/host-verified portion gated on HI-2.)*
- **AC-3** Activating `iFile` on Outlook mobile opens the same search UI inline in the full-screen surface. *(Device/host-verified portion gated on HI-2.)*
- **AC-20** Behavior is verified on both Outlook desktop and Outlook mobile form factors. *(Manual: device/host verification on both form factors — HI-2.)*

The remaining criteria (AC-1, AC-4..AC-18, AC-21..AC-24) are not materially changed by cycle 4; their prior-cycle checkbox state in `spec.md` is carried forward unchanged.

---

## Acceptance Criteria Evaluation

| # | Criterion | Status | Evidence | Verification command(s) | Notes |
|---|-----------|--------|----------|--------------------------|-------|
| AC-19 | Manifest + AAD scope changes present and bound to the configured app | PARTIAL | Manifests carry the delegated scopes and validate; `webApplicationInfo` id/resource now bind the configured app `3592bf52-...`. The CI-verifiable manifest half is satisfied; the consent/token verification half against the registered app is HI-1/HI-2. | `npm run validate`, `npm run validate:xml` (both exit 0); `rg -n "3592bf52" manifest.json manifest.xml` | Not blocking. The CI-verifiable portion passes; the manual consent/token portion is a declared human exception (HI-1, HI-2), not a code defect. |
| AC-2 | Desktop dialog opens with search UI | PARTIAL | Host-neutral dialog/search code unchanged and covered; cycle 4 corrects the app binding the desktop sign-in path resolves. On-device confirmation that sign-in now succeeds is HI-2. | `npm run test:coverage` (163 pass) | Not blocking; device-verified half gated on HI-2. |
| AC-3 | Mobile inline search UI opens; sign-in succeeds | PARTIAL | This cycle's root-cause fix targets exactly the Outlook iOS broker rejection (client-ID/app-registration mismatch). The realignment is in place; on-device confirmation that folder search returns results is HI-2. | `rg -n "3592bf52" src/taskpane/ifile/naa-token-acquirer.ts` (L29) | Not blocking; device-verified half gated on HI-2. |
| AC-20 | Verified on both desktop and mobile form factors | PARTIAL | Form-factor verification is the explicit HI-2 human exception; cycle 4 removes the known code-side blocker (wrong app binding) so the on-device re-verification can proceed. | n/a (manual) | Not blocking; declared human exception. |

No criterion regressed in cycle 4. No criterion moved from PASS to a lower state.

---

## Summary

**Overall Feature Readiness:** NEEDS REVISION (feature-level, gated on declared human exceptions; no code defect)

**Criteria summary (cycle-4-affected set):**
- **PASS:** 0 criteria
- **PARTIAL:** 4 criteria (AC-2, AC-3, AC-19, AC-20 — each PARTIAL solely on a declared human-gated portion)
- **UNVERIFIED:** 0 criteria
- **FAIL:** 0 criteria

Carried-forward (unaffected by cycle 4): `spec.md` shows 15 criteria checked `[x]` (AC-1, AC-4..AC-10, AC-14..AC-18, AC-22, AC-23) and 9 unchecked `[ ]` (AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24), consistent with the declared human-gated set.

**Top gaps preventing feature PASS:**

1. HI-1 — tenant-admin consent on the Graph delegated permissions for app `3592bf52-...`.
2. HI-2 — mobile build and on-device re-verification that sign-in now succeeds and folder search returns results.
3. HI-3 — backend OBO user-secrets injection (`AzureAd:ClientId` / `Audience` / `ClientSecret`) for the new app; never committed.

These are declared human-execution exceptions, not code defects, and they do not constitute blocking findings for cycle-4 exit.

**Recommended follow-up verification steps:**

1. Execute HI-1/HI-3 against app `3592bf52-...` (admin consent + user-secrets), then perform the HI-2 on-device verification per `runbooks/outlook-on-device-verification.runbook.md`.
2. On successful on-device sign-in, promote AC-2, AC-3, AC-19, AC-20 to PASS and check them off in `spec.md`.

---

## Acceptance Criteria Check-off

Per the acceptance-criteria tracking rules, only criteria evaluated as PASS may be checked off. All four cycle-4-affected criteria are PARTIAL (each blocked solely on a declared human-gated portion), so none are checked off in this cycle. No `spec.md` checkbox state was changed by this audit.

### AC Status Summary

- Source: `spec.md` (primary), `user-story.md` (secondary)
- Total AC items: 24
- Checked off (delivered): 15 (unchanged this cycle)
- Remaining (unchecked): 9 (AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24)
- Items remaining: the nine human-gated / not-yet-device-verified criteria listed above.

| Source File | Total AC | Checked (PASS) | Unchecked | Notes |
|-------------|----------|----------------|-----------|-------|
| `spec.md` | 24 | 15 | 9 | Checkbox-backed; no change this cycle (all cycle-4-affected ACs are PARTIAL on human-gated portions). |
| `user-story.md` | n/a | n/a | n/a | Secondary narrative source; not a checkbox-backed AC ledger. |

No source-file checkbox change was made: every cycle-4-affected criterion remains PARTIAL on a declared human exception, so check-off is not warranted.

**Blocking findings (this artifact): 0**
