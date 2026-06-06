# Authenticode Code Signing — Runbook

This runbook covers operating `scripts/powershell/Invoke-AuthenticodeSigning.ps1`, the build/release-time
Authenticode signing tool (Model B). Signatures are produced as a discrete release step and are not committed
into source.

## Prerequisites

- PowerShell 7+.
- The code-signing certificate present in `Cert:\CurrentUser\My` with a private key and the Code Signing
  EKU.
- The certificate thumbprint stored in dotnet user-secrets (store id
  `3716a8f0-9bab-4f69-a7b9-4173cda73ff3`, key `Signing:CertThumbprint`). The tool reads the thumbprint from
  this store and never hardcodes it. To set it:

  ```powershell
  dotnet user-secrets set 'Signing:CertThumbprint' '<thumbprint>' --id 3716a8f0-9bab-4f69-a7b9-4173cda73ff3
  ```

## 1. Invocation examples

### Sign all in-scope first-party PowerShell scripts (default)

```powershell
./scripts/powershell/Invoke-AuthenticodeSigning.ps1
```

This enumerates the in-scope first-party scripts (the include globs under `.githooks/`, `.github/scripts/`,
`scripts/`, `tests/`, `.claude/hooks/`) and excludes `node_modules/**` and `artifacts/**`. Each file is
signed with SHA256 and an RFC3161 timestamp from `http://timestamp.digicert.com`, then verified on the
signing machine. The tool emits one log line per file and a summary count (signed / skipped / warnings /
failed).

### Preview without modifying files (`-WhatIf`)

```powershell
./scripts/powershell/Invoke-AuthenticodeSigning.ps1 -WhatIf
```

`-WhatIf` reports which files would be signed and performs no signing.

### Sign published first-party .NET assemblies (post-publish, `-FilePaths`)

```powershell
dotnet publish src/TaskMaster.Api/TaskMaster.Api.csproj -o ./publish
$assemblies = Get-ChildItem ./publish -Filter 'TaskMaster.*.dll' -File |
    Select-Object -ExpandProperty FullName
./scripts/powershell/Invoke-AuthenticodeSigning.ps1 -FilePaths $assemblies
```

When `-FilePaths` is provided, the tool signs exactly those files and does not enumerate PowerShell scripts.
Only first-party `TaskMaster.*.dll` / `TaskMaster.*.exe` outputs are eligible; vendor/third-party binaries
are never signed because re-signing a vendor binary invalidates the vendor's existing signature.

Re-running the tool over already-signed files is safe (idempotent re-sign):
`Set-AuthenticodeSignature` atomically replaces any existing signature block and produces a new timestamp.

## 2. Bootstrap execution-policy step (first run of the unsigned signer)

The signing script is itself unsigned until it has been signed (a bootstrap condition). On a machine whose
PowerShell execution policy would block an unsigned script, run the first invocation with an execution-policy
bypass:

```powershell
pwsh -ExecutionPolicy Bypass -File ./scripts/powershell/Invoke-AuthenticodeSigning.ps1
```

or, for the current process only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted
./scripts/powershell/Invoke-AuthenticodeSigning.ps1
```

After the script (and the other first-party scripts) have been signed and the signing certificate is trusted
on the machine, the bypass is no longer required. This requirement is also stated in the tool's `.NOTES`
synopsis.

## 3. Self-signed-certificate trust limitation

The signing certificate is a personal/self-issued certificate (`CN=Daniel Moisan`). Signatures are
cryptographically valid, but Windows and PowerShell treat a signature as `Valid` only on machines that trust
the certificate (the certificate present in the machine's Trusted Root / Trusted Publisher stores).

On a machine that does not trust the certificate, `Get-AuthenticodeSignature` reports a non-`Valid` status
(for example `UnknownError`). This is the documented trust limitation of a self-issued certificate, not a
defect in the tool. The tool's verification path confirms the `Valid` status on the signing machine; a
non-`Valid` signing-machine result is reported as a per-file failure. This signing model is appropriate for
internal provenance, not for public-distribution trust.

## 4. CI-runner signing deferral and rationale

CI-runner signing is deferred to a human-gated follow-up and is out of scope for this tool's initial
delivery. Rationale:

- CI signing requires the private key provisioned as a GitHub Actions secret (for example a PFX exported and
  protected by a secret passphrase), imported on a `windows-latest` runner before signing and removed
  afterward. Provisioning a signing key into CI is a security-sensitive change that requires human review.
- Modifying `.github/workflows/**` triggers the `modified-workflow-needs-green-run` policy, which requires a
  green workflow run against the branch head before merge.

Until CI signing is implemented, release builds produced in CI are unsigned; signing is performed
locally/at release time using this tool. A future CI signing step should evaluate whether
`Set-AuthenticodeSignature` or `signtool.exe` is more reliable on the `windows-latest` runner.

## Exit codes

- `0` — all eligible files signed and verified on the signing machine (timestamp warnings do not change
  this).
- Non-zero — a configuration/certificate fail-fast occurred, or one or more files failed to sign or verify.
  The warning/error stream names the cause.
