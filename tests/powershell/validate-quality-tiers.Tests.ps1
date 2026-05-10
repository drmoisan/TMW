#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'validate-quality-tiers.ps1' {
    BeforeAll {
        $script:UnderTest = (Resolve-Path "$PSScriptRoot/../../.github/scripts/validate-quality-tiers.ps1").Path
        # Dot-source loads the function only; the CLI guard prevents the script's
        # exit branch from running during dot-source.
        . $script:UnderTest
        $script:Fix = Join-Path -Path $TestDrive -ChildPath 'cfg'
        New-Item -ItemType Directory -Path $script:Fix -Force | Out-Null

        function Invoke-Validator {
            param(
                [string]$ConfigPath,
                [string]$RepoRoot
            )
            $sw = New-Object System.IO.StringWriter
            $origErr = [Console]::Error
            [Console]::SetError($sw)
            try {
                if ([string]::IsNullOrEmpty($RepoRoot)) {
                    $result = @(Invoke-QualityTiersValidation -ConfigPath $ConfigPath)
                }
                else {
                    $result = @(Invoke-QualityTiersValidation -ConfigPath $ConfigPath -RepoRoot $RepoRoot)
                }
            }
            finally {
                [Console]::SetError($origErr)
            }
            # Function may emit a Write-Output success line in addition to the integer
            # return value; the integer is always the final pipeline element.
            $code = $result[-1]
            return @{ Output = $sw.ToString(); ExitCode = [int]$code }
        }
    }

    It 'exits 2 when config is missing' {
        $r = Invoke-Validator -ConfigPath (Join-Path -Path $script:Fix -ChildPath 'absent.yml')
        $r.ExitCode | Should -Be 2
        $r.Output | Should -Match 'not found'
    }

    It 'exits 3 when config is empty' {
        $p = Join-Path -Path $script:Fix -ChildPath 'empty.yml'
        Set-Content -Path $p -Value ''
        (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 3
    }

    It 'exits 4 when projects: key is missing' {
        $p = Join-Path -Path $script:Fix -ChildPath 'no-projects.yml'
        Set-Content -Path $p -Value "version: 1`nfoo: bar"
        (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 4
    }

    It 'exits 5 on invalid tier value' {
        $p = Join-Path -Path $script:Fix -ChildPath 'bad-tier.yml'
        Set-Content -Path $p -Value @"
projects:
  - path: ./
    tier: t9
"@
        (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 5
    }

    It 'exits 6 when an existing project directory is not declared' {
        # Build a deterministic mini-repo under $TestDrive that contains a project
        # marker (package.json) in an undeclared subdir, then run the validator
        # against it via the optional -RepoRoot seam.
        $miniRepo = Join-Path -Path $TestDrive -ChildPath 'mini-repo'
        New-Item -ItemType Directory -Path $miniRepo -Force | Out-Null
        $undeclared = Join-Path -Path $miniRepo -ChildPath 'undeclared-project'
        New-Item -ItemType Directory -Path $undeclared -Force | Out-Null
        Set-Content -Path (Join-Path -Path $undeclared -ChildPath 'package.json') -Value '{}'

        $p = Join-Path -Path $script:Fix -ChildPath 'mismatch.yml'
        Set-Content -Path $p -Value @"
projects:
  - path: nonexistent-elsewhere
    tier: t1
"@
        (Invoke-Validator -ConfigPath $p -RepoRoot $miniRepo).ExitCode | Should -Be 6
    }

    It 'exits 0 against the live repo quality-tiers.yml' {
        $live = (Resolve-Path "$PSScriptRoot/../../quality-tiers.yml").Path
        (Invoke-Validator -ConfigPath $live).ExitCode | Should -Be 0
    }

    It 'accepts each valid tier value t1..t4' {
        foreach ($t in 't1', 't2', 't3', 't4') {
            $p = Join-Path -Path $script:Fix -ChildPath "tier-$t.yml"
            $liveRaw = Get-Content -Raw -Path (Resolve-Path "$PSScriptRoot/../../quality-tiers.yml").Path
            $rewritten = $liveRaw -replace 'tier:\s*t\d', "tier: $t"
            Set-Content -Path $p -Value $rewritten
            (Invoke-Validator -ConfigPath $p).ExitCode | Should -Be 0 -Because "tier '$t' must be accepted"
        }
    }
}
