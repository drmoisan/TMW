# P4-T11 — Rewrite check-conventional-commit.Tests.ps1: format + analyze

Timestamp: 2026-05-10T00-00
Command: mcp__drm-copilot__run_poshqc_format then mcp__drm-copilot__run_poshqc_analyze (scope: tests/powershell)
EXIT_CODE: 0
Output Summary:
- Rewrote tests/powershell/check-conventional-commit.Tests.ps1 to dot-source the script under test in `BeforeAll` and call `Invoke-ConventionalCommitCheck` in-process.
- Removed all `& pwsh -NoProfile -File <script>` invocations; in-process call replaces the prior subprocess pattern, restoring Pester line-coverage visibility.
- All prior test scenarios preserved (missing file, empty/comment-only, invalid format, valid format including breaking-change and scoped breaking, comment-then-valid, all allowed types).
- Tests use `$TestDrive` only; no temp files outside `$TestDrive`; no `Start-Sleep`.
- PoshQC format: exit 0; no diagnostics.
- PoshQC analyze: exit 0; no diagnostics. (Note: the verbatim plan body declared an unused `$stderr = New-Object System.Text.StringBuilder` local; this was removed as a minimum mechanical adjustment to clear `PSUseDeclaredVarsMoreThanAssignments`. Behavior is unchanged because the variable was never read.)
