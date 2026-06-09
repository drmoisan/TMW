# authenticode-code-signing — Feature Document

- **Issue:** #50
- **Issue URL:** https://github.com/drmoisan/TMW/issues/50
- **Owner:** drmoisan
- **Last Updated:** 2026-06-06
- **Status:** Draft
- **Work Mode:** full-feature

## Purpose

This document consolidates the issue, the research findings, and the confirmed scope
decisions for adding Authenticode code signing to the repository. It is the overview that
ties the spec (`spec.md`) and user story (`user-story.md`) together and records the non-goals
and risks.

## Background

The repository has no code-signing infrastructure. First-party PowerShell scripts and built
.NET assemblies ship unsigned, so there is no Authenticode provenance for the artifacts this
project produces, and there is no path to an execution policy that requires signed scripts.
The owner wants all first-party signable artifacts signed with a specific code-signing
certificate to establish provenance and to support signed-script execution policies.

Research (`artifacts/research/2026-06-06-authenticode-code-signing-50.md`) verified the
repository conventions relevant to this feature: the PoshQC + Pester PowerShell toolchain,
the injectable-scriptblock seam pattern already used by `Start-MobileConnectivity.ps1`, the
first-party script inventory (49 scripts across six subtrees), and the location of the
signing thumbprint in a dedicated dotnet user-secrets store.

## Confirmed Approach

- **Single tested PowerShell tool:** `scripts/powershell/Invoke-AuthenticodeSigning.ps1`,
  with Pester tests at `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`.
  PowerShell is chosen over a .NET console tool because `Set-AuthenticodeSignature` is a
  native PowerShell 7+ cmdlet that handles both script and assembly file types uniformly,
  the seam pattern is already validated in the codebase, and no new `quality-tiers.yml`
  entry or dotnet toolchain integration is required.
- **Model B (build/release-time signing):** signatures are applied as a discrete step and
  are not committed into source. Model A (embedded signatures in committed source) is
  rejected because edits invalidate the signature and conflict with routine agent/hook
  edits.
- **Scope (a) — first-party PowerShell scripts** (`.ps1`/`.psm1`/`.psd1`) selected by the
  include globs (`.githooks/**/*.ps1`, `.github/scripts/**/*.ps1`, `scripts/**/*.{ps1,psm1,psd1}`,
  `tests/**/*.{ps1,psd1}`, `.claude/hooks/**/*.ps1`) and constrained by the exclude globs
  (`node_modules/**`, `artifacts/**`).
- **Scope (b) — first-party `TaskMaster.*` assemblies/executables**, signed at publish time
  via a post-publish invocation that passes exact output paths through `-FilePaths`. Vendor
  DLLs are not signed.
- **Certificate resolution from configuration:** thumbprint
  `6461584F8CB3A2A384F575918E17D4B4AD8EE733` resolved from `Signing:CertThumbprint` in the
  dotnet user-secrets store `3716a8f0-9bab-4f69-a7b9-4173cda73ff3`. The thumbprint is not
  hardcoded. The tool fails fast when the config, certificate, private key, or Code Signing
  EKU is missing.
- **Timestamping:** RFC3161 via `http://timestamp.digicert.com`, so signatures survive
  certificate expiry (2027-07-06). An unreachable timestamp server produces a warning, not a
  hard failure.
- **Testable seam design:** four behavioral units (config resolution, certificate
  resolution, file enumeration, sign dispatch) are isolated behind injectable scriptblock
  seams (`ReadSecretsAction`, `ResolveCertAction`, `EnumerateFilesAction`, `SignFileAction`)
  so the logic is deterministically unit-testable without a real certificate or temporary
  files. The irreducible host-bound surface is two thin wrappers
  (`Invoke-SetAuthenticodeSignature`, `Resolve-SigningCert`), kept minimal and left in the
  coverage denominator.

## Scope Summary

In scope:

- A single tested PowerShell signing tool and its Pester test file.
- Signing first-party PowerShell scripts and first-party `TaskMaster.*` assemblies/executables.
- Configuration-driven certificate resolution, RFC3161 timestamping, verification, and fail-
  fast error handling.

Out of scope (non-goals):

- **CI-runner signing.** Requires the private key provisioned as a CI secret and changes to
  `.github/workflows/**`, which triggers the `modified-workflow-needs-green-run` policy.
  Deferred to a human-gated follow-up because provisioning a signing key into CI is a
  security-sensitive change requiring human review. Until then, CI release builds produce
  unsigned assemblies.
- **Signing TypeScript/web bundles and vendored/third-party scripts and binaries.** Only
  first-party PowerShell scripts and first-party `TaskMaster.*` assemblies are signed; re-
  signing a vendor binary would break the vendor's existing signature.

## Risks

1. **Self-signed certificate trust scope.** The certificate is personal/self-issued
   (`CN=Daniel Moisan`). Signatures are cryptographically valid but `Get-AuthenticodeSignature`
   returns a non-`Valid` status on any machine that does not have the certificate in its
   trusted root/publisher store. This is appropriate for internal provenance, not public-
   distribution trust. Documented as a limitation (spec AC-17).
2. **Timestamp-server availability.** The DigiCert RFC3161 endpoint is a public free service
   outside the project's control. The tool warns and continues when it is unreachable; a
   signature without a timestamp is still valid while the certificate is unexpired.
3. **Bootstrap execution policy.** The signing script is itself unsigned until it has been
   signed. The first invocation may require running PowerShell with `-ExecutionPolicy Bypass`
   or `Unrestricted`. Documented in the tool synopsis (spec AC-18).
4. **Private-key handling.** The private key and any `.pfx` export must never be committed;
   the secret-scan gate would block it and committing a key is prohibited.
5. **`artifacts/` mirror scripts.** `.claude/hooks/` scripts are mirrored under
   `artifacts/.claude/hooks/`. The current decision excludes `artifacts/` from signing; if
   that is revisited, both the canonical and mirror paths must be signed consistently.

## Quality Obligations

- Toolchain: PoshQC (Invoke-Formatter, then PSScriptAnalyzer) followed by Pester.
- Coverage: uniform line >= 85%, branch >= 75%; no production file excluded from coverage
  measurement; host-bound surface kept minimal.
- 500-line file limit applies to the tool and its test file.
- Tests use injected seams and must not create temporary files or scan real directories.

## File Change Requirements

| File | Action |
|---|---|
| `scripts/powershell/Invoke-AuthenticodeSigning.ps1` | Create (signing tool) |
| `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1` | Create (Pester tests) |

No changes required to `quality-tiers.yml`, `Directory.Build.props`, any `.csproj`, or any
CI workflow for the in-scope work.

## References

- Issue: `docs/features/active/2026-06-06-authenticode-code-signing-50/issue.md`
- Spec: `docs/features/active/2026-06-06-authenticode-code-signing-50/spec.md`
- User story: `docs/features/active/2026-06-06-authenticode-code-signing-50/user-story.md`
- Research findings: `artifacts/research/2026-06-06-authenticode-code-signing-50.md`
- Rules: `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`,
  `.claude/rules/quality-tiers.md`, `.claude/rules/tonality.md`
