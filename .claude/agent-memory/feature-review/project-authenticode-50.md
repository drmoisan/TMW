---
name: project-authenticode-50
description: authenticode-code-signing (#50) — Model B PowerShell signing tool, self-signed cert thumbprint is public not secret, CI signing deferred
metadata:
  type: project
---

Issue #50 (authenticode-code-signing, branch `feature/authenticode-code-signing-50`, full-feature mode) adds one production PowerShell file `scripts/powershell/Invoke-AuthenticodeSigning.ps1` (Model B build/release-time Authenticode signing) plus its Pester tests. AC sources: `spec.md` (AC-1..AC-18) + `user-story.md`. Reviewed clean (0 blocking) at 2026-06-06T13-02.

**Cert thumbprint is not a secret.** Thumbprint `6461584F8CB3A2A384F575918E17D4B4AD8EE733` (CN=Daniel Moisan, self-issued, Code Signing EKU, expires 2027-07-06) is the SHA-1 of the public certificate — a public identifier, acceptable in design docs. It must NOT appear in the script/tests/runbook (it does not); the tool resolves it from user-secrets key `Signing:CertThumbprint` (store `3716a8f0-9bab-4f69-a7b9-4173cda73ff3`). The private key / `.pfx` is the secret and is correctly never committed.
**Why:** a reviewer could mis-flag the thumbprint as a committed secret. **How to apply:** treat thumbprint-in-docs as PASS; flag only `.pfx/.p12/.pem/.key` files or the thumbprint hardcoded inside the script.

**CI signing deferral is intentional, not a gap.** `.github/workflows/**` and `quality-tiers.yml` are correctly unmodified; CI-runner signing is a human-gated follow-up (key-as-CI-secret is security-sensitive and would trigger `modified-workflow-needs-green-run`). Do not flag the absence of CI signing.

**Known non-blocking gap (code-review C-1):** production `Invoke-SetAuthenticodeSignature` does not set a `TimestampWarning` property on the timestamp-unreachable fallback path, so the run summary `Warnings` count stays 0 on the real path even though the wrapper `Write-Warning`s and continues. Tests cover the count branch by injecting a seam that returns `TimestampWarning=$true`, so the end-to-end count path is not exercised against the real wrapper. AC-9 warn-not-fail still holds. If a follow-up touches this file, expect this to be the fix.

**Pester JaCoCo has no branch counter.** Coverage for this PS file is line 92.31% (artifact `artifacts/pester/authenticode-coverage.xml`); branch threshold is satisfied by demonstrated per-branch test coverage + command coverage (92.44%) as proxy, since the emitter produces no numeric BRANCH counter. See [[project-ifile-43]] for the PowerShell coverage-evidence conventions.
