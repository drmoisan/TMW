# authenticode-code-signing — Spec

- **Issue:** #50
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-06-06
- **Status:** Draft
- **Version:** 1.0
- **Work Mode:** full-feature

## Overview

The repository has no code-signing infrastructure. First-party PowerShell scripts and
built .NET assemblies ship unsigned, so there is no Authenticode provenance for the
artifacts this project produces. This feature adds build/release-time Authenticode
signing (Model B) driven by a single tested PowerShell tool. Signatures are produced as a
build/release step and are not committed into source, keeping the working tree clean and
surviving the seven-stage toolchain loop and routine agent/hook edits.

The tool resolves a code-signing certificate by thumbprint from configuration (dotnet
user-secrets), signs the in-scope first-party artifacts, applies an RFC3161 timestamp, and
verifies the result. The tool's configuration-resolution and file-selection logic are
isolated behind injectable scriptblock seams so they are deterministically unit-testable
without a real certificate or temporary files.

## Behavior

### Signing model

- **Model B (build/release-time signing).** Signatures are applied as a discrete step and
  are not stored in committed source files. No `# SIG # Begin signature block` content is
  committed.
- **Model A (embedded signatures in committed source) is rejected.** Embedded signatures
  are invalidated by any edit and conflict with routine agent/hook edits.

### What is signed

- **Scope (a) — first-party PowerShell scripts** (`.ps1`, `.psm1`, `.psd1`). Approximately
  49 files across six subtrees. Selected by the include globs below and constrained by the
  exclude globs.
- **Scope (b) — built first-party .NET assemblies and executables** (`TaskMaster.*.dll`,
  `TaskMaster.*.exe`), signed at publish time via a post-publish invocation that passes the
  exact output paths through the `-FilePaths` parameter. Vendor/third-party DLLs are not
  signed; re-signing a vendor binary breaks the vendor's existing signature.

### Certificate

- Thumbprint `6461584F8CB3A2A384F575918E17D4B4AD8EE733` (`CN=Daniel Moisan`, Code Signing
  EKU, expires 2027-07-06).
- The thumbprint is resolved from configuration key `Signing:CertThumbprint` in the dotnet
  user-secrets store id `3716a8f0-9bab-4f69-a7b9-4173cda73ff3`. The tool MUST read the
  thumbprint from this configuration and MUST NOT hardcode it.
- The certificate is resolved from `Cert:\CurrentUser\My` by matching thumbprint and
  requiring `HasPrivateKey = True`.

### Timestamping

- RFC3161 timestamping via `http://timestamp.digicert.com` so signatures remain valid after
  the certificate expires.
- When the timestamp server is unreachable, the tool warns and continues; it does not hard-
  fail. A signature without a timestamp is still valid while the certificate is unexpired.

## Inputs / Outputs

### Inputs

- `-RepoRoot` (string, optional, default = current directory): root directory scanned for
  in-scope scripts.
- `-ConfigKey` (string, optional, default = `Signing:CertThumbprint`): configuration key
  holding the certificate thumbprint.
- `-SecretsJsonPath` (string, optional, default = the canonical dotnet user-secrets path for
  store `3716a8f0-9bab-4f69-a7b9-4173cda73ff3`): path to `secrets.json`.
- `-TimestampServer` (string, optional, default = `http://timestamp.digicert.com`): RFC3161
  timestamp endpoint.
- `-FilePaths` (string[], optional, default = empty): explicit file list. When provided,
  signs exactly these files (used for post-publish .NET assembly signing) instead of
  enumerating PowerShell scripts.
- Seam parameters (scriptblock, optional, injected by tests): `ReadSecretsAction`,
  `ResolveCertAction`, `EnumerateFilesAction`, `SignFileAction`. Each has a production
  default that calls the corresponding named helper.
- `-WhatIf` / `-Confirm`: standard `SupportsShouldProcess` switches.

### Outputs

- One log line per file indicating the signing outcome.
- A summary count of files signed, files skipped, and warnings emitted.
- Process exit code (see Exit Codes).
- No files are written outside the artifacts being signed. Tests write no files.

### Config keys and defaults

- `Signing:CertThumbprint` in user-secrets store `3716a8f0-9bab-4f69-a7b9-4173cda73ff3`.
- The dotnet user-secrets `secrets.json` is a flat JSON object; the value lives at the
  colon-separated key `"Signing:CertThumbprint"` (not nested).

### Versioning / backward-compatibility constraints

- No existing public API changes. This adds a new standalone tool and its test file. No
  `.csproj`, `quality-tiers.yml`, `Directory.Build.props`, or CI workflow changes are
  required for the in-scope work.

## API / CLI Surface

### Tool

`scripts/powershell/Invoke-AuthenticodeSigning.ps1` (`#Requires -Version 7.0`,
`SupportsShouldProcess`).

### Named helper functions (testable units behind seams)

- `Read-SigningThumbprint -JsonPath -Key` — reads and validates the thumbprint from
  `secrets.json`.
- `Resolve-SigningCert -Thumbprint` — resolves the certificate from `Cert:\CurrentUser\My`.
- `Get-FirstPartySignableFiles -Root` — enumerates in-scope scripts with include/exclude
  rules.
- `Invoke-SetAuthenticodeSignature -Path -Cert -TimestampServer` — applies the signature.
- `Test-AuthenticodeSignature -Path` — verifies signature status.

### Include globs (scope a)

```
.githooks/**/*.ps1
.github/scripts/**/*.ps1
scripts/**/*.ps1
scripts/**/*.psm1
scripts/**/*.psd1
tests/**/*.ps1
tests/**/*.psd1
.claude/hooks/**/*.ps1
```

### Exclude globs

```
node_modules/**
artifacts/**
```

`artifacts/` is excluded because it contains generated/pushed-down copies treated as
derivative artifacts.

### Example invocations

Sign all in-scope first-party scripts:

```powershell
./scripts/powershell/Invoke-AuthenticodeSigning.ps1
```

Preview without modifying files:

```powershell
./scripts/powershell/Invoke-AuthenticodeSigning.ps1 -WhatIf
```

Sign published first-party .NET assemblies:

```powershell
dotnet publish src/TaskMaster.Api/TaskMaster.Api.csproj -o ./publish
$assemblies = Get-ChildItem ./publish -Filter 'TaskMaster.*.dll' -File |
    Select-Object -ExpandProperty FullName
./scripts/powershell/Invoke-AuthenticodeSigning.ps1 -FilePaths $assemblies
```

### Contracts and validation rules

- Configuration is resolved before any file is signed; a configuration failure aborts the
  run before any side effect.
- The certificate must have a private key. A certificate without a private key is a fail-
  fast condition.
- The certificate must carry the Code Signing EKU. A certificate lacking that EKU is a
  fail-fast condition.
- Vendor binaries are never signed; only `TaskMaster.*.dll` / `TaskMaster.*.exe` outputs are
  eligible in scope (b).

## Data & State

- The tool reads `secrets.json` (read-only) and the current-user certificate store (read-
  only). It writes Authenticode signature data into the artifacts it signs.
- No caching or persisted state beyond the signature embedded in each signed artifact.
- No migration or backfill is required.
- Idempotency: `Set-AuthenticodeSignature` atomically replaces any existing signature block;
  re-signing the same file is safe and produces a new timestamp. The tool does not need to
  check whether a file is already signed before signing it.

## Config-Resolution Contract

1. If `-SecretsJsonPath` does not exist, fail fast with an actionable error that includes
   the remediation command (`dotnet user-secrets set 'Signing:CertThumbprint' '<thumbprint>'
   --id 3716a8f0-9bab-4f69-a7b9-4173cda73ff3`).
2. Parse `secrets.json` as JSON. On parse failure, fail fast with an error naming the path.
3. Read the value at `-ConfigKey`. If absent, empty, or whitespace, fail fast with an error
   naming the path and key.
4. Resolve the certificate by the returned thumbprint from `Cert:\CurrentUser\My`. If no
   matching certificate with a private key is found, fail fast with an error naming the
   thumbprint.
5. Validate that the certificate carries the Code Signing EKU. If not, fail fast.

## Signing, Timestamp, and Verify Behavior

- For each in-scope file (or each `-FilePaths` entry), invoke `Set-AuthenticodeSignature`
  with `-HashAlgorithm SHA256` and the configured timestamp server.
- After signing, the returned status must be `Valid` on the signing machine; any other
  status for the signing-machine result is a per-file failure.
- When the timestamp server is unreachable, emit a warning and continue. Absence of a
  timestamp is not a hard failure.
- Verification (`Get-AuthenticodeSignature`) confirms the signing-machine status. On
  machines that do not trust the certificate, verification returns a non-`Valid` status;
  this is the documented self-signed-trust limitation, not a tool defect.

## Error / Fail-Fast Behavior

- Missing `secrets.json`, missing/empty config key, JSON parse failure: fail fast, no files
  signed.
- Certificate not found, no private key, or missing Code Signing EKU: fail fast, no files
  signed.
- Per-file sign failure: report the file and its status; the run reports a non-zero exit
  code at completion. The tool does not silently ignore a failed file.
- Timestamp server unreachable: warn and continue (not fail-fast).

## Exit Codes

- `0` — all eligible files signed and verified on the signing machine (timestamp warnings do
  not change this).
- Non-zero — configuration/certificate fail-fast occurred, or one or more files failed to
  sign or verify. The error stream names the cause.

## Constraints & Risks

- The certificate is a personal/self-issued certificate (`CN=Daniel Moisan`); signatures
  validate only on machines that trust it. Appropriate for internal provenance, not public-
  distribution trust.
- The private key and any `.pfx` export must never be committed; the secret-scan gate would
  block it and committing a key is prohibited.
- CI-runner signing requires the private key provisioned as a GitHub Actions secret and
  touches `.github/workflows/**` (triggering `modified-workflow-needs-green-run`). It is
  deferred to a human-gated follow-up; the initial scope targets local/release signing only.
- The signing script itself is unsigned until it has been signed (bootstrap problem). The
  first invocation may require `-ExecutionPolicy Bypass`/`Unrestricted`; this is documented
  in the tool synopsis.
- Timestamp-server availability is outside the project's control; the warn-not-fail behavior
  is the mitigation.

## Quality Obligations

- PowerShell toolchain: PoshQC (Invoke-Formatter, then PSScriptAnalyzer) followed by Pester.
- Coverage is uniform: line coverage >= 85%, branch coverage >= 75%. No production file is
  excluded from coverage measurement; the host-bound wrappers
  (`Invoke-SetAuthenticodeSignature`, `Resolve-SigningCert`) remain in the denominator and
  are kept minimal.
- 500-line file limit applies to the tool and its test file.
- Tests use injectable seams; tests must not create temporary files or scan real
  directories.

## Implementation Strategy

- New files: `scripts/powershell/Invoke-AuthenticodeSigning.ps1` and
  `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`.
- Four behavioral units behind named seams (config resolution, certificate resolution, file
  enumeration, sign call), each independently unit-testable by injecting a scriptblock.
- No new dependencies; `Set-AuthenticodeSignature`/`Get-AuthenticodeSignature` are native
  PowerShell 7+ cmdlets.
- No CI workflow change; CI signing is deferred (see Non-Goals).

## Non-Goals

- **CI-runner signing.** Requires the private key as a CI secret and changes to
  `.github/workflows/**`. Deferred to a human-gated follow-up. Rationale: provisioning a
  signing key into CI is a security-sensitive change that requires human review and triggers
  the `modified-workflow-needs-green-run` policy.
- **Signing TypeScript/web bundles** and **vendored/third-party scripts and binaries.**
  Out of scope; only first-party PowerShell scripts and first-party `TaskMaster.*`
  assemblies are signed.

## Acceptance Criteria

- [x] **AC-1** The tool resolves the certificate thumbprint from configuration key
      `Signing:CertThumbprint` in the user-secrets store at the configured `secrets.json`
      path. The thumbprint is not hardcoded in the script.
- [x] **AC-2** When `secrets.json` is missing, or the config key is absent/empty, the tool
      fails fast with an actionable error that includes the remediation command and does not
      sign any file.
- [x] **AC-3** When no certificate matching the resolved thumbprint with `HasPrivateKey =
      True` exists in `Cert:\CurrentUser\My`, the tool fails fast with an error naming the
      thumbprint and signs no file.
- [x] **AC-4** When the resolved certificate lacks the Code Signing EKU, the tool fails fast
      with an error and signs no file.
- [x] **AC-5** File enumeration includes exactly the in-scope first-party PowerShell scripts
      per the include globs and excludes `node_modules/**` and `artifacts/**`. Missing
      subtrees are skipped without error.
- [x] **AC-6** Invoked with `-FilePaths` listing first-party `TaskMaster.*.dll`/`.exe`
      outputs, the tool signs exactly those files and does not enumerate PowerShell scripts.
- [x] **AC-7** Vendor/third-party DLLs are never signed; only `TaskMaster.*` outputs are
      eligible in scope (b).
- [x] **AC-8** Each successfully processed file is signed with SHA256 and an RFC3161
      timestamp from the configured timestamp server.
- [x] **AC-9** When the timestamp server is unreachable, the tool emits a warning and
      continues; it does not hard-fail solely because timestamping failed.
- [x] **AC-10** A verification path (`Get-AuthenticodeSignature`) confirms the signing-
      machine status is `Valid` for each signed file; a non-`Valid` signing-machine result is
      reported as a per-file failure.
- [x] **AC-11** Signing is a build/release step (Model B); no signature blocks are committed
      into source `.ps1`/`.psm1`/`.psd1` files.
- [x] **AC-12** Running with `-WhatIf` reports which files would be signed without modifying
      any file.
- [x] **AC-13** Re-running the tool on already-signed files succeeds (idempotent re-sign)
      without corrupting any file.
- [x] **AC-14** Config-resolution, file-enumeration, and sign-dispatch logic are unit-tested
      via injected seams (`ReadSecretsAction`, `ResolveCertAction`, `EnumerateFilesAction`,
      `SignFileAction`) without a real certificate and without creating temporary files.
- [x] **AC-15** Pester tests pass with line coverage >= 85% and branch coverage >= 75%; no
      production file is excluded from coverage measurement.
- [x] **AC-16** PSScriptAnalyzer reports zero errors, Invoke-Formatter reports no changes,
      and the tool and test files are each under 500 lines.
- [x] **AC-17** The documentation records the self-signed-certificate trust limitation
      (signatures validate only on machines that trust the certificate; non-trusting machines
      see a non-`Valid` status) and the deferral of CI-runner signing with its rationale.
- [x] **AC-18** The tool synopsis documents the bootstrap execution-policy step required to
      run the unsigned signer on first use.

## Definition of Done

- [x] Acceptance criteria documented and mapped to tests or demos
- [x] Behavior matches acceptance criteria in all documented environments
- [x] Tests updated/added (Pester unit tests via seams)
- [x] Edge cases and error handling covered by tests
- [x] Docs updated (this spec, user-story, feature-document; tool synopsis)
- [x] Logging added (per-file outcome and summary)
- [x] Toolchain pass completed (format -> lint -> test) with coverage thresholds met

## Seeded Test Conditions

- [x] Certificate resolution by thumbprint: present/valid, absent, no private key, wrong EKU.
- [x] File-selection logic includes first-party scripts and excludes `node_modules`/vendored
      paths.
- [x] Signature application and verification for PowerShell scripts and .NET assemblies.
- [x] Idempotency and re-sign behavior on already-signed artifacts.
- [x] Timestamp-server-unreachable path warns and continues.
- [x] `-WhatIf` performs no modification.
