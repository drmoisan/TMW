# AAD Delegated Scope Changes — iFile (Issue #43)

Timestamp: 2026-06-01T00-00

The iFile filing workflow performs server-side Microsoft Graph operations (folder enumeration,
message move, attachment content fetch, OneDrive folder create + upload) via the existing
on-behalf-of (OBO) token flow in `TaskMaster.Api`. The following delegated scopes must be added
to the Azure AD app registration. These are applied in the Azure portal app registration (an
out-of-repo resource), not in any repo file (AC-19, AAD portion; manual verification required).

## Required delegated scopes

- `Mail.ReadBasic` — enumerate the mailbox folder tree (`GET /me/mailFolders` + recursive
  `/childFolders`). Ensure this scope is present.
- `Mail.ReadWrite` — minimum scope for `POST /me/messages/{id}/move` and for reading full
  message/attachment content server-side.
- `Files.ReadWrite` — minimum scope for OneDrive folder creation and attachment upload beneath
  the mapped Archive root.

## Manifest-side changes already applied in-repo (AC-19, CI portion)

- `manifest.json` `authorization.permissions.resourceSpecific`: `MailboxItem.ReadWrite.User`
  (supersedes the prior `MailboxItem.Read.User`).
- `manifest.xml` `<Permissions>`: `ReadWriteMailbox` (was `ReadItem`).
- `manifest.json` `validDomains` and `manifest.xml` `<AppDomains>`: production HTTPS domain
  placeholder (`https://www.contoso.com`) added, documented as deploy-time configurable for the
  dialog same-origin requirement.

## Manual verification requirement

The AAD scope grants and admin/user consent cannot be verified by CI in this repository. On a
real Azure AD tenant, verify that:
1. The app registration includes the three delegated scopes above.
2. Consent has been granted (admin or user) so the OBO token can be exchanged for a Graph token
   carrying these scopes.
3. A live filing operation succeeds end-to-end (move + OneDrive mirror) using the consented token.

Status: PENDING-TENANT — the scopes are documented here and must be applied and consented in the
Azure app registration, then confirmed on a real Outlook desktop and mobile client (AC-19, AC-20).
