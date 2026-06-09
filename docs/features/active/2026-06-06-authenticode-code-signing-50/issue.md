# authenticode-code-signing (Issue #50)

- Date captured: 2026-06-06
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/authenticode-code-signing/ (Issue #50)

- Issue: #50
- Issue URL: https://github.com/drmoisan/TMW/issues/50
- Last Updated: 2026-06-06
- Work Mode: full-feature

## Problem / Why

The repository currently has no code-signing infrastructure. First-party PowerShell
scripts and built .NET assemblies ship unsigned, so there is no Authenticode provenance
for the artifacts this project produces. The owner wants all first-party signable
artifacts signed with a specific code-signing certificate to establish provenance and
support execution policies that require signed scripts.

## Proposed Behavior

Add build/release-time Authenticode signing (Model B) driven by a code-signing
certificate identified by thumbprint `6461584F8CB3A2A384F575918E17D4B4AD8EE733`
(`CN=Daniel Moisan`, Code Signing EKU, expires 2027-07-06). Signing is performed by a
dedicated, tested signing tool that resolves the certificate from the certificate store
by thumbprint and signs:

- (a) First-party PowerShell scripts (`.ps1`, `.psm1`, `.psd1`) — approximately 49 files
  under `.githooks/`, `.github/`, `scripts/`, `tests/`, `.claude/`. Vendored
  `node_modules` scripts are excluded.
- (b) Built .NET assemblies / executables, signed at publish time.

Signatures are produced as part of a build/release step and are not committed into source
files (Model B), keeping the working tree clean and surviving the seven-stage toolchain
loop and routine agent/hook edits.

## Acceptance Criteria (early draft)

- [ ] A signing tool resolves the certificate by thumbprint from the certificate store
      and fails fast with a clear error when the certificate is absent, lacks a private
      key, or lacks the Code Signing EKU.
- [ ] The tool signs first-party PowerShell scripts (`.ps1/.psm1/.psd1`) and excludes
      `node_modules` and other vendored/third-party scripts.
- [ ] The tool signs built .NET assemblies/executables at publish time.
- [ ] A verification path confirms signature validity for the produced artifacts.
- [ ] Signing is a build/release step (Model B); no signature blocks are committed into
      source `.ps1` files.
- [ ] The tool, its tests, and its docs satisfy the repository toolchain and coverage
      gates.

## Constraints & Risks

- The certificate is a personal/self-issued certificate (`CN=Daniel Moisan`); signatures
  validate only on machines that trust it. Appropriate for internal provenance, not
  public-distribution trust.
- The private key and any `.pfx` export must never be committed to the repository; the
  secret-scan gate would block it and committing a key is prohibited.
- CI-runner signing requires the private key provisioned as a GitHub Actions secret and
  touches `.github/workflows/**` (triggering `modified-workflow-needs-green-run`). It is
  deferred to a human-gated (HI) follow-up; the initial scope targets local/release
  signing only.
- Embedding signatures into committed source (Model A) is rejected: it is invalidated by
  any edit and conflicts with routine agent/hook edits.

## Test Conditions to Consider

- [ ] Certificate resolution by thumbprint: present/valid, absent, no private key, wrong EKU.
- [ ] File-selection logic includes first-party scripts and excludes `node_modules`/vendored paths.
- [ ] Signature application and verification for PowerShell scripts and .NET assemblies.
- [ ] Idempotency and re-sign behavior on already-signed artifacts.

## Next Step

- [ ] Promote to GitHub issue (feature request template)
- [ ] Create `docs/features/active/authenticode-code-signing/` folder from the template