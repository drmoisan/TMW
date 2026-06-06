# `authenticode-code-signing` — User Story

- Issue: #50
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-06-06
- Work Mode: full-feature

## Story Statement

- As the repository owner, I want a single tested tool that signs all first-party PowerShell
  scripts and built `TaskMaster.*` assemblies with my code-signing certificate at
  build/release time, so that the artifacts this project produces carry Authenticode
  provenance and can run under execution policies that require signed scripts.
- As the repository owner, I want the signing tool to resolve the certificate from
  configuration and fail fast with an actionable message when the certificate or its private
  key is missing, so that I never produce a partially or silently unsigned release.
- As a contributor, I want signatures to be applied as a release step rather than committed
  into source, so that routine edits and the seven-stage toolchain loop do not invalidate
  signatures or create noisy diffs.

## Problem / Why

The repository has no code-signing infrastructure. First-party PowerShell scripts and built
.NET assemblies ship unsigned, so there is no Authenticode provenance for the artifacts this
project produces and no path to an execution policy that requires signed scripts. The owner
wants all first-party signable artifacts signed with a specific code-signing certificate to
establish provenance and support signed-script execution policies, without committing
signature data or the private key into the repository.

## Personas & Scenarios

- Persona: Repository owner / release operator (Daniel Moisan)
  - Who: the person who holds the code-signing certificate
    (`CN=Daniel Moisan`, thumbprint `6461584F8CB3A2A384F575918E17D4B4AD8EE733`) in their
    current-user certificate store, with the thumbprint recorded in dotnet user-secrets.
  - What they care about: provenance for first-party artifacts; a clean working tree; a
    repeatable signing step that does not require manual per-file commands.
  - Constraints: the private key must never be committed; the certificate is self-issued, so
    it is trusted only on machines that have it installed; CI cannot sign yet because the key
    is not provisioned as a CI secret.
  - Goals and frustrations: wants one command that signs everything in scope and reports a
    clear summary; wants an unambiguous error rather than a partial or silent unsigned
    release.
  - Context and motivations: preparing to enable a signed-script execution policy and to give
    downstream consumers a way to verify that scripts and assemblies originate from this
    project.

- Scenario: Sign first-party scripts before a release
  - Who is acting: the repository owner on their Windows workstation.
  - What triggered the action: preparing a release that should carry signed first-party
    scripts.
  - Steps: run `./scripts/powershell/Invoke-AuthenticodeSigning.ps1`. The tool reads the
    thumbprint from user-secrets, resolves the certificate (verifying it has a private key and
    the Code Signing EKU), enumerates the in-scope scripts, signs each with SHA256 and an
    RFC3161 timestamp, verifies the signing-machine status, and prints a per-file outcome plus
    a summary count.
  - Obstacles or decisions: if `secrets.json` or the config key is missing, the run aborts
    before signing with a message that includes the remediation command. If the timestamp
    server is unreachable, the tool warns and continues rather than failing the release.
  - Expected outcome: all in-scope first-party scripts are signed; the working tree contains
    signed artifacts but no committed signature blocks (Model B); the owner sees a clear
    summary and a zero exit code.

- Scenario: Sign published .NET assemblies
  - Who is acting: the repository owner after `dotnet publish`.
  - What triggered the action: a publish produced first-party `TaskMaster.*` outputs that
    should be signed alongside vendor DLLs that must not be signed.
  - Steps: collect the `TaskMaster.*.dll`/`.exe` paths from the publish directory and pass
    them to the tool via `-FilePaths`. The tool signs exactly those files.
  - Obstacles or decisions: vendor DLLs (for example `Microsoft.Graph.dll`) are excluded so
    their existing vendor signatures remain intact.
  - Expected outcome: only first-party assemblies are signed and verified; no vendor binary is
    re-signed.

- Scenario: Preview before signing
  - Who is acting: the repository owner verifying scope before a release.
  - What triggered the action: a desire to confirm exactly which files will be signed.
  - Steps: run the tool with `-WhatIf`.
  - Expected outcome: the tool lists the files it would sign and modifies nothing.

## Value

- Establishes Authenticode provenance for first-party scripts and assemblies, enabling a path
  to signed-script execution policies.
- Keeps the working tree clean by applying signatures at release time rather than committing
  signature blocks (Model B), so signing does not conflict with routine edits or the
  seven-stage toolchain loop.
- Fail-fast configuration and certificate validation prevent partial or silently unsigned
  releases.

## Acceptance Criteria

- [x] The tool resolves the certificate thumbprint from configuration
      (`Signing:CertThumbprint` in user-secrets) and does not hardcode it.
- [x] The tool fails fast with an actionable error when `secrets.json` or the config key is
      missing, and signs nothing in that case.
- [x] The tool fails fast when no certificate with the resolved thumbprint and a private key
      exists, or when the certificate lacks the Code Signing EKU.
- [x] The tool signs first-party PowerShell scripts (`.ps1`/`.psm1`/`.psd1`) per the include
      globs and excludes `node_modules` and `artifacts` and other vendored/third-party
      scripts.
- [x] The tool signs built first-party `TaskMaster.*` .NET assemblies/executables at publish
      time via `-FilePaths`, and does not sign vendor DLLs.
- [x] Each signed file receives an RFC3161 timestamp; an unreachable timestamp server
      produces a warning, not a hard failure.
- [x] A verification path confirms signing-machine signature validity for the produced
      artifacts.
- [x] Signing is a build/release step (Model B); no signature blocks are committed into
      source files.
- [x] Running with `-WhatIf` reports the files that would be signed without modifying any
      file.
- [x] The tool, its tests, and its docs satisfy the repository toolchain (PoshQC + Pester)
      and coverage gates (line >= 85%, branch >= 75%), with no production file excluded from
      coverage.
- [x] Documentation records the self-signed-certificate trust limitation and the CI-runner
      signing deferral with rationale.

## Non-Goals

- CI-runner signing. Requires the private key as a CI secret and changes to
  `.github/workflows/**`; deferred to a human-gated follow-up because provisioning a signing
  key into CI is security-sensitive and triggers `modified-workflow-needs-green-run`.
- Signing TypeScript/web bundles and vendored/third-party scripts and binaries.
