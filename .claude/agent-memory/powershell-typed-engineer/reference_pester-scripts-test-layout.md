---
name: pester-scripts-test-layout
description: Where Pester tests for scripts/ live and how they import the script under test in this repo
metadata:
  type: reference
---

Pester tests for `scripts/` live under `tests/pester/<area>/<ScriptName>.Tests.ps1` (e.g. the parser at `scripts/orchestration/Invoke-CiGateParser.ps1` is tested by `tests/pester/orchestration/CiGate.Parser.Tests.ps1`). Tests invoke the script under test directly via `& $script:ScriptPath -Param ...` (the script's param block + auto-invoke guard `if ($MyInvocation.InvocationName -ne '.')` runs the public function and returns its output). Seam scriptblocks (NowProvider, *Action) are injected as parameters for determinism. Each test file starts with `#Requires -Version 7.0` and `#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }`.

**How to apply:** Mirror this layout for new `scripts/powershell/*.ps1`: place tests at `tests/pester/powershell/<ScriptName>.Tests.ps1`. To exercise internal seam helper functions directly, dot-source the script in a `BeforeAll` (the auto-invoke guard skips when dot-sourced) and mock the underlying framework cmdlets — but note the dynamic-parameter limitation in [[pester-dynamic-param-mocking]]. The repo's PoshQC pester runsettings is at `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`; coverage thresholds are line >= 85% / branch >= 75% (uniform across tiers).
