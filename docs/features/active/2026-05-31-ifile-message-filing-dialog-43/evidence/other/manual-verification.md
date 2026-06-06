# iFile Manual-Verification Dossier (Issue #43)

Timestamp: 2026-06-01T00-00

This dossier enumerates the acceptance criteria that require manual device/host verification
(AC-2, AC-3, AC-11, AC-12, AC-13, AC-19, AC-20, AC-21, AC-24 per `spec.md`). The implementing
code and all CI-verifiable portions are complete and green (see `evidence/qa-gates/`). The items
below MUST be exercised on real Outlook clients before the feature is considered fully verified.
No device evidence is fabricated; each criterion carries a `PENDING-DEVICE` marker until run.

## Human-interaction exceptions (autonomous-execution mandate, issue #45)

Under the autonomous-execution mandate, the manual items below are declared as permitted
exceptions with human-execution runbooks (response: `exception`). Execute the runbooks to clear
the `PENDING-DEVICE` / `PENDING-TENANT` markers:

- **HI-1 (AC-19):** Entra delegated-scope grant + admin consent — see
  `../../runbooks/entra-admin-consent.runbook.md`.
- **HI-2 (AC-2, AC-3, AC-11, AC-12, AC-13, AC-20, AC-21, AC-24):** Outlook on-device verification
  (desktop + iOS) — see `../../runbooks/outlook-on-device-verification.runbook.md`.

The automatable items (Graph permission *declarations* via `az ad app permission add`; production
manifest-domain substitution) are handled as scope-change/build steps, not runbook steps.

## Hosts/devices under test (to be filled in on verification)

- Outlook desktop (Windows or Mac) build/version: _PENDING-DEVICE_
- Outlook mobile (iOS or Android) build/version: _PENDING-DEVICE_
- Azure AD tenant + consented scopes (`Mail.ReadWrite`, `Files.ReadWrite`, `Mail.ReadBasic`):
  _PENDING-DEVICE_ (see `aad-scope-changes.md`)

## Criteria

| AC | What to verify on-device | CI portion (done) | Observed result | Pass/Fail |
|---|---|---|---|---|
| AC-2 | On desktop, activating `iFile` opens an Office Dialog containing a search textbox and a results list. | dialog-host Office.js contract test (options shape + messageParent round trip) | _PENDING-DEVICE_ | _PENDING-DEVICE_ |
| AC-3 | On Outlook mobile, activating `iFile` opens the same search UI inline in the full-screen task pane (no dialog), from the same bundle. | host-detection branch unit test (selectPresentation), shared-bundle build (dist/ifile.html) | _PENDING-DEVICE_ | _PENDING-DEVICE_ |
| AC-11 | The resolved message REST id is accepted by Graph on a real device (mobile: itemId as-is; desktop: convertToRestId). | resolveMessageRestId branch unit tests | _PENDING-DEVICE_ | _PENDING-DEVICE_ |
| AC-12 | Selecting a result moves the opened message to the chosen Outlook folder end-to-end on a real client. | Graph move-request contract test (POST /me/messages/{id}/move body { destinationId }) | _PENDING-DEVICE_ | _PENDING-DEVICE_ |
| AC-13 | Non-inline file attachments are saved to the mirrored OneDrive folder beneath the persisted Archive root; inline content is skipped; intermediate folders created. | AttachmentFilter unit test, OutlookToOneDrivePath unit/property tests, handler integration tests, Graph drive contract test | _PENDING-DEVICE_ | _PENDING-DEVICE_ |
| AC-19 | AAD delegated scopes (`Mail.ReadWrite`, `Files.ReadWrite`, `Mail.ReadBasic`) are granted/consented so the OBO token works; manifests carry ReadWrite. | manifest.json (MailboxItem.ReadWrite.User), manifest.xml (ReadWriteMailbox) validated | _PENDING-DEVICE_ | _PENDING-DEVICE_ |
| AC-20 | Behavior verified on both Outlook desktop and Outlook mobile form factors. | n/a (manual only) | _PENDING-DEVICE_ | _PENDING-DEVICE_ |
| AC-21 | On first filing with no stored mapping, the user is presented with select-or-create for the OneDrive Archive root; no folder named `Archive` is auto-created. | archive-root-picker unit tests, handler ArchiveRootRequired integration test | _PENDING-DEVICE_ | _PENDING-DEVICE_ |
| AC-24 | The Archive-root picker is presented per host (desktop dialog/in-pane vs. mobile inline) with identical select-or-create capability and persisted-mapping result. | host-detection branch + shared-flow tests | _PENDING-DEVICE_ | _PENDING-DEVICE_ |

## Notes

- AC-1 (command ordering) is structurally verified in CI (manifest assertions: `iFile` declared
  first in its desktop `manifest.json` group, in the desktop `manifest.xml` group, and in the
  mobile `MobileFormFactor` group). The visible on-device ordering remains a manual confirmation
  and can be recorded alongside AC-20.
- AC-22 and AC-23 (mapping persistence/reuse) are fully covered by CI integration tests and are
  not in the manual-only set, though they are naturally exercised during the AC-21/AC-13 device runs.
