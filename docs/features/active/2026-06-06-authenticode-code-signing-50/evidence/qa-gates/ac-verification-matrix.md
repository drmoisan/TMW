# Final QA — Acceptance Criteria Verification Matrix (AC-1..AC-18)

- Timestamp: 2026-06-06T12-24
- Task: [P5-T5]
- Source of ACs (full-feature mode): `docs/features/active/2026-06-06-authenticode-code-signing-50/spec.md`

Production file: `scripts/powershell/Invoke-AuthenticodeSigning.ps1`
Test file: `tests/pester/powershell/Invoke-AuthenticodeSigning.Tests.ps1`
Runbook: `docs/features/active/2026-06-06-authenticode-code-signing-50/runbook.md`

| AC | Covered by | Verdict |
|---|---|---|
| AC-1 (thumbprint from config, not hardcoded) | `Read-SigningThumbprint`; orchestrator resolves config before side effects; test `returns the thumbprint when the key is present`; parse-check confirms no thumbprint literal | PASS |
| AC-2 (missing secrets/key -> fail-fast with remediation, no file signed) | `Read-SigningThumbprint` three fail-fast branches; tests `throws with the remediation command when secrets.json is missing`, `throws when the key is absent or empty`, `throws naming the path when the JSON cannot be parsed` | PASS |
| AC-3 (no matching cert with private key -> fail-fast naming thumbprint, no file signed) | `Resolve-SigningCert` not-found branch; tests `aborts before signing when the cert is absent`, `aborts before signing when the cert has no private key`, seam-internals `throws naming the thumbprint when no matching cert with a private key exists` | PASS |
| AC-4 (cert lacks Code Signing EKU -> fail-fast, no file signed) | `Resolve-SigningCert` EKU validation; tests `aborts before signing when the cert lacks the Code Signing EKU`, seam-internals `throws when the cert lacks the Code Signing EKU` and `returns a cert with a private key and the Code Signing EKU` | PASS |
| AC-5 (include globs, exclude node_modules/artifacts, missing subtree skipped) | `Test-IsExcludedRelativePath`, `Get-FirstPartySignableFileList`; predicate tests (both separators, include/exclude), seam-internals `returns first-party hits and skips missing subtrees and excluded paths` and `returns an empty result when no include subtree exists`, orchestrator `handles a missing subtree (empty enumeration) without error` | PASS |
| AC-6 (`-FilePaths` signs exactly those, no enumeration) | Orchestrator `-FilePaths` branch; test `signs exactly the provided paths and does not enumerate` (enumeration seam invoked zero times) | PASS |
| AC-7 (vendor DLLs never signed; only TaskMaster.* eligible) | `-FilePaths` test signs only the provided `TaskMaster.*.dll` paths; runbook section 1 documents the first-party-only rule; the tool signs exactly the provided list and never re-enumerates vendor binaries | PASS |
| AC-8 (SHA256 + RFC3161 timestamp) | `Invoke-SetAuthenticodeSignature` passes `-HashAlgorithm SHA256` and the timestamp server; seam-internals `passes SHA256 and the timestamp server and returns the Valid result` | PASS |
| AC-9 (timestamp server unreachable -> warn, not hard-fail) | `Invoke-SetAuthenticodeSignature` catch/fallback; seam-internals `warns and signs without a timestamp when the timestamp server is unreachable`; orchestrator `continues past a timestamp-unreachable warning without hard failure` | PASS |
| AC-10 (verify Valid; non-Valid is per-file failure) | `Test-AuthenticodeSignature`; `Invoke-SetAuthenticodeSignature` non-Valid throw; orchestrator status-check; tests `surfaces a per-file failure when the seam reports a non-Valid status`, `reports a per-file failure when the seam returns a non-Valid status object`, seam-internals `returns $true/$false` and `throws a per-file failure when the signing status is not Valid` | PASS |
| AC-11 (Model B; no committed signature blocks) | Verified by working-tree check: `grep` of the new files and `git grep` across all tracked `.ps1`/`.psm1`/`.psd1` found zero `# SIG # Begin signature block` occurrences | PASS |
| AC-12 (`-WhatIf` reports without modifying) | Orchestrator `ShouldProcess`; test `records zero sign calls under -WhatIf` (signed=0, skipped=2) | PASS |
| AC-13 (idempotent re-sign succeeds) | Orchestrator + spec idempotency note; test `signs the same paths on a second run and reports success both times` | PASS |
| AC-14 (seam-injected unit tests, no real cert, no temp files) | All four seams injected in tests; no `TestDrive:`, no filesystem writes, no real cert access; determinism header documents this | PASS |
| AC-15 (coverage line >= 85% / branch >= 75%, no production file excluded) | `evidence/qa-gates/final-pester-coverage.md` (line 92.31%); `evidence/qa-gates/coverage-delta.md`; production file measured directly, not excluded | PASS |
| AC-16 (PSScriptAnalyzer 0 errors, formatter no changes, files < 500 lines) | `evidence/qa-gates/final-poshqc-analyze.md` (0 errors), `evidence/qa-gates/final-poshqc-format.md` (idempotent, 0 change), `evidence/qa-gates/p3-file-size-check.md` (449 / 483 lines) | PASS |
| AC-17 (docs record self-signed trust limitation + CI-deferral rationale) | `runbook.md` sections 3 (self-signed trust limitation) and 4 (CI-runner deferral and rationale) | PASS |
| AC-18 (synopsis documents bootstrap execution-policy step) | Tool `.NOTES` synopsis bootstrap section; `runbook.md` section 2 | PASS |

## Model B aggregate verification (AC-7, AC-11)

- AC-11: `git grep "SIG # Begin signature block" -- '*.ps1' '*.psm1' '*.psd1'` returned no matches (exit 1);
  the new files contain no signature blocks. No signature blocks are committed into source.
- AC-7: the tool signs only first-party targets — enumeration is limited to first-party include globs and
  `-FilePaths` mode signs exactly the caller-provided `TaskMaster.*` outputs; vendor binaries are never
  enumerated or re-signed.

All 18 acceptance criteria are verified PASS.
