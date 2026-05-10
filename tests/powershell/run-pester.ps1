#Requires -Version 7.0
# Helper to run the Pester suite using the repo's PesterConfiguration.psd1.
# Used by docs and CI; tests run against the configuration file at
# tests/powershell/PesterConfiguration.psd1. This is a thin wrapper to avoid
# shell-quoting issues when invoking from non-PowerShell shells.

Import-Module Pester -MinimumVersion 5.0.0
$hashtable = Import-PowerShellDataFile -Path "$PSScriptRoot/PesterConfiguration.psd1"
$cfg = New-PesterConfiguration -Hashtable $hashtable
Invoke-Pester -Configuration $cfg
exit $LASTEXITCODE
