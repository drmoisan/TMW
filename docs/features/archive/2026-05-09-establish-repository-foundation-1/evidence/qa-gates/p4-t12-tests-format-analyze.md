# P4-T12 — Rewrite validate-quality-tiers.Tests.ps1: format + analyze

Timestamp: 2026-05-10T00-00
Command: mcp__drm-copilot__run_poshqc_format then mcp__drm-copilot__run_poshqc_analyze (scope: tests/powershell)
EXIT_CODE: 0
Output Summary:
- Rewrote tests/powershell/validate-quality-tiers.Tests.ps1 to dot-source the script under test in `BeforeAll` and call `Invoke-QualityTiersValidation` in-process.
- Removed all `& pwsh -NoProfile -File <script>` invocations; in-process call replaces the prior subprocess pattern, restoring Pester line-coverage visibility.
- All prior test scenarios preserved (config missing, empty config, missing `projects:` key, invalid tier value, mismatched declared paths, live `quality-tiers.yml` passes, each valid tier value t1..t4).
- Mismatch scenario uses the optional `-RepoRoot` seam to point the validator at a `$TestDrive` mini-repo containing a single undeclared `package.json`, which deterministically triggers the exit-6 branch.
- Tests use `$TestDrive` only.
- PoshQC format: exit 0; no diagnostics.
- PoshQC analyze: exit 0; no diagnostics.
