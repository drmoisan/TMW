# Phase 0 — Policy Read Evidence

- Timestamp: 2026-06-06T11-40
- Task: [P0-T1]

## Policy Order

Policy files read in the required order per `.claude/skills/policy-compliance-order`:

1. `CLAUDE.md` (standing instructions, auto-loaded)
2. `.claude/rules/general-code-change.md` (cross-language code change policy)
3. `.claude/rules/general-unit-test.md` (cross-language unit test policy)
4. `.claude/rules/quality-tiers.md` (T1–T4 module rigor tiers and gate matrix)
5. `.claude/rules/powershell.md` (PowerShell-specific standards, toolchain, seam patterns, change budget)
6. `.claude/rules/tonality.md` (required professional tone policy)

## Files Read

- `c:\Users\DanMoisan\repos\TMW\.claude\rules\general-code-change.md`
- `c:\Users\DanMoisan\repos\TMW\.claude\rules\general-unit-test.md`
- `c:\Users\DanMoisan\repos\TMW\.claude\rules\quality-tiers.md`
- `c:\Users\DanMoisan\repos\TMW\.claude\rules\powershell.md`
- `c:\Users\DanMoisan\repos\TMW\.claude\rules\tonality.md`

## Supporting References Read

- Spec: `docs/features/active/2026-06-06-authenticode-code-signing-50/spec.md` (AC-1..AC-18)
- Research design: `artifacts/research/2026-06-06-authenticode-code-signing-50.md`
- Seam reference: `scripts/powershell/Start-MobileConnectivity.ps1`
- Test reference: `tests/pester/powershell/Start-MobileConnectivity.Tests.ps1`
- Pester runsettings: `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`

## Output Summary

All six policy files were read in the required precedence order. Key constraints recorded for this
feature: PowerShell toolchain order is format -> analyze -> test (type-check N/A); direct-mode budget is
2 production files; 500-line file limit applies to tool and test; coverage uniform line >= 85% / branch
>= 75% with no production file excluded; seam-based deterministic tests with no temp files and no real
certificate access; no hardcoded thumbprint; fail-fast with actionable errors; professional tone in all
authored content.
