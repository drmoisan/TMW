# Remediation Inputs: iFile Message-Filing Dialog (Issue #43)

**Generated:** 2026-06-01T08-29
**Feature Folder:** `docs/features/active/2026-05-31-ifile-message-filing-dialog-43`
**Base Branch:** `main` (merge-base `ff6aa007fefcd24ff18b96240525d7c9bafd7d18`)
**Head Branch:** `feature/ifile-message-filing-dialog-43` (`0357d88d13b1efdc0ee9d29999623fe2bf61bd72`)
**Work Mode:** `full-feature`

## Source Audit Artifacts

- `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/policy-audit.2026-06-01T08-29.md`
- `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/code-review.2026-06-01T08-29.md`
- `docs/features/active/2026-05-31-ifile-message-filing-dialog-43/feature-audit.2026-06-01T08-29.md`

## BLOCKING Findings

None. No Blocker or Major code-review findings, no toolchain failures, no coverage gaps, and no policy FAIL findings. The `modified-workflow-needs-green-run` rule did not fire: the branch diff modifies no path under `.github/workflows/**`, `scripts/benchmarks/**`, or `.github/actions/**`.

## Remediation-Required Findings (non-blocking; manual/deploy verification)

These items prevent the feature from being declared fully verified but are not code defects and are not CI-closable in this repository. They are tracked here for follow-up.

| ID | Severity | Type | Finding | Required action | Source artifact |
|---|---|---|---|---|---|
| R-1 | Non-blocking | AC PARTIAL | AC-19: manifest changes applied (`MailboxItem.ReadWrite.User`, `ReadWriteMailbox`), but AAD delegated-scope grant/consent (`Mail.ReadWrite`, `Files.ReadWrite`, `Mail.ReadBasic`) is out-of-repo and PENDING-TENANT. | Grant and consent the three scopes in the Azure AD app registration; confirm an OBO Graph token carrying them. | `feature-audit` AC-19; `evidence/other/aad-scope-changes.md` |
| R-2 | Non-blocking | AC UNVERIFIED | AC-20: behavior not verified on real Outlook desktop and mobile clients (manual-only). | Execute the manual-verification dossier on both form factors; record build/version and observed results. | `feature-audit` AC-20; `evidence/other/manual-verification.md` |
| R-3 | Non-blocking | AC device-PENDING | AC-2, AC-3, AC-11, AC-12, AC-13, AC-21, AC-24: CI portions PASS; on-device dialog/inline render, real-device REST-id acceptance, end-to-end move, real OneDrive write, and per-host picker remain PENDING-DEVICE. | Confirm each on real clients during the AC-20 device runs. | `feature-audit`; `evidence/other/manual-verification.md` |
| R-4 | Minor | Config | Manifests use a `https://localhost:3000/ifile.html` source location with a documented production-domain placeholder. | Configure the production HTTPS domain at deploy time for the same-origin dialog requirement. | `code-review` Findings Table; `evidence/other/aad-scope-changes.md` |
| R-5 | Minor | Convention | C# coverage artifact is at `tests/**/TestResults/**/coverage.cobertura.xml` rather than the SKILL-referenced `artifacts/csharp/coverage.xml`. | Optional: emit/copy a consolidated C# coverage artifact to the canonical path for future automated verification. Numeric per-file coverage is already verifiable from the present cobertura files. | `policy-audit` Section 1.2.1 |

## Disposition

No code remediation is required to merge the CI-verifiable scope. The outstanding items (R-1 through R-3) are mandatory manual device/tenant verifications that must be completed before the feature is declared fully verified on real clients; R-4 is a deploy-time configuration step; R-5 is an optional convention alignment. Because there are no BLOCKING findings and no code defects, no atomic remediation plan for source changes is warranted at this time; the items above are tracking inputs for the manual verification and deploy steps.
