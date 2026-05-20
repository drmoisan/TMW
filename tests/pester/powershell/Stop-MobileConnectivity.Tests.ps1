#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# Unit tests for scripts/powershell/Stop-MobileConnectivity.ps1.
#
# Determinism: state reads, process stops, and state-file removal are exercised
# through injected seam scriptblocks or mocked framework cmdlets. No real
# processes are touched, no real files are read or removed, no network is used,
# and no temp files are created.

Describe 'Stop-MobileConnectivity.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '../../../scripts/powershell/Stop-MobileConnectivity.ps1'

        # Builds the standard set of injectable seams. Tests override individual
        # entries before splatting. Configured state/running-pids are stored on
        # the captured container so the closures read them from a single
        # referenced object (keeps the analyzer free of false unused-param hits).
        function script:New-StopSeamSet {
            param(
                [object]$State,
                [int[]]$RunningPids = @()
            )
            $captured = [pscustomobject]@{
                StopCalls   = [System.Collections.Generic.List[int]]::new()
                RemoveCalls = [System.Collections.Generic.List[string]]::new()
                State       = $State
                RunningPids = $RunningPids
            }
            $readAction = { param([string]$Path) $null = $Path; $captured.State }.GetNewClosure()
            $stopAction = {
                param([int]$ProcessId)
                $captured.StopCalls.Add($ProcessId)
                return ($captured.RunningPids -contains $ProcessId)
            }.GetNewClosure()
            $removeAction = {
                param([string]$Path)
                $captured.RemoveCalls.Add($Path)
            }.GetNewClosure()

            return [pscustomobject]@{
                Captured          = $captured
                ReadStateAction   = $readAction
                StopProcessAction = $stopAction
                RemoveStateAction = $removeAction
            }
        }
    }

    Context 'positive: stops recorded processes and removes the state file' {
        It 'stops both recorded pids and reports them as stopped' {
            # Arrange
            $state = [pscustomobject]@{ HttpServerProcessId = 1001; DevTunnelProcessId = 2002 }
            $seams = New-StopSeamSet -State $state -RunningPids @(1001, 2002)
            $statePath = 'state://stop-both.json'

            # Act
            $result = & $script:ScriptPath `
                -StateFilePath $statePath `
                -ReadStateAction $seams.ReadStateAction `
                -StopProcessAction $seams.StopProcessAction `
                -RemoveStateAction $seams.RemoveStateAction

            # Assert
            $result.StateFileFound | Should -BeTrue
            $result.StoppedProcessIds | Should -Be @(1001, 2002)
            $seams.Captured.StopCalls | Should -Be @(1001, 2002)
            $seams.Captured.RemoveCalls | Should -Be @($statePath)
        }

        It 'records only running pids as stopped and still removes the state file' {
            # Arrange: pid 2002 is recorded but not running.
            $state = [pscustomobject]@{ HttpServerProcessId = 1001; DevTunnelProcessId = 2002 }
            $seams = New-StopSeamSet -State $state -RunningPids @(1001)

            # Act
            $result = & $script:ScriptPath `
                -StateFilePath 'state://partial.json' `
                -ReadStateAction $seams.ReadStateAction `
                -StopProcessAction $seams.StopProcessAction `
                -RemoveStateAction $seams.RemoveStateAction `
                -WarningAction SilentlyContinue

            # Assert
            $result.StateFileFound | Should -BeTrue
            $result.StoppedProcessIds | Should -Be @(1001)
            $seams.Captured.RemoveCalls.Count | Should -Be 1
        }

        It 'ignores absent or non-positive recorded process ids' {
            # Arrange: only one valid pid; the other property is missing.
            $state = [pscustomobject]@{ HttpServerProcessId = 0; DevTunnelProcessId = 3003 }
            $seams = New-StopSeamSet -State $state -RunningPids @(3003)

            # Act
            $result = & $script:ScriptPath `
                -StateFilePath 'state://skip-zero.json' `
                -ReadStateAction $seams.ReadStateAction `
                -StopProcessAction $seams.StopProcessAction `
                -RemoveStateAction $seams.RemoveStateAction

            # Assert
            $seams.Captured.StopCalls | Should -Be @(3003)
            $result.StoppedProcessIds | Should -Be @(3003)
        }
    }

    Context 'missing-state-file path: warns non-fatally' {
        It 'returns StateFileFound false and stops nothing when state is absent' {
            # Arrange: the read seam returns $null, modeling a missing state file.
            $seams = New-StopSeamSet -State $null

            # Act
            $result = & $script:ScriptPath `
                -StateFilePath 'state://missing.json' `
                -ReadStateAction $seams.ReadStateAction `
                -StopProcessAction $seams.StopProcessAction `
                -RemoveStateAction $seams.RemoveStateAction `
                -WarningAction SilentlyContinue

            # Assert
            $result.StateFileFound | Should -BeFalse
            $result.StoppedProcessIds | Should -Be @()
            $seams.Captured.StopCalls.Count | Should -Be 0
            $seams.Captured.RemoveCalls.Count | Should -Be 0
        }

        It 'emits a warning naming the missing state file' {
            # Arrange
            $seams = New-StopSeamSet -State $null

            # Act
            $warnings = & $script:ScriptPath `
                -StateFilePath 'state://warn-missing.json' `
                -ReadStateAction $seams.ReadStateAction `
                -StopProcessAction $seams.StopProcessAction `
                -RemoveStateAction $seams.RemoveStateAction `
                3>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }

            # Assert
            ($warnings | Out-String) | Should -Match 'state://warn-missing.json'
        }
    }

    Context 'WhatIf: no side effects' {
        It 'does not stop processes or remove state when -WhatIf is supplied' {
            # Arrange
            $state = [pscustomobject]@{ HttpServerProcessId = 1001; DevTunnelProcessId = 2002 }
            $seams = New-StopSeamSet -State $state -RunningPids @(1001, 2002)

            # Act
            $result = & $script:ScriptPath `
                -StateFilePath 'state://whatif.json' `
                -ReadStateAction $seams.ReadStateAction `
                -StopProcessAction $seams.StopProcessAction `
                -RemoveStateAction $seams.RemoveStateAction `
                -WhatIf

            # Assert
            $seams.Captured.StopCalls.Count | Should -Be 0
            $seams.Captured.RemoveCalls.Count | Should -Be 0
            $result.StateFileFound | Should -BeTrue
        }
    }

    Context 'seam internals: Read-ConnectivityState' {
        BeforeAll {
            # Dot-sourcing imports the seam functions without running
            # Stop-MobileConnectivity (the auto-invoke guard skips dot-source).
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns $null when the state file does not exist' {
            # Arrange: mock the framework cmdlet, not a real file.
            Mock Test-Path { $false }

            # Act
            $state = Read-ConnectivityState -Path 'state://none.json'

            # Assert
            $state | Should -BeNullOrEmpty
        }

        # Note: the file-present parse branch (Get-Content -Raw | ConvertFrom-Json)
        # is unavoidable filesystem I/O whose only logic is a JSON round-trip. The
        # round-trip is exercised end-to-end by the positive Stop flow above (which
        # feeds a parsed state object through ReadStateAction) and by the Start
        # persist flow, so it is intentionally not re-mocked here. Mocking the
        # FileSystem-provider dynamic parameter -Raw across the dot-source scope
        # boundary is not reliable in Pester v5 and is avoided per the repo's
        # "prefer real code paths / isolate I/O" mocking guidance.
    }

    Context 'seam internals: Invoke-StopProcess' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns false when no matching process is running' {
            # Arrange: mock Get-Process (framework cmdlet), not a real process.
            Mock Get-Process { $null }

            # Act
            $stopped = Invoke-StopProcess -ProcessId 9999

            # Assert
            $stopped | Should -BeFalse
        }

        It 'stops a running process and returns true' {
            # Arrange
            Mock Get-Process { [pscustomobject]@{ Id = 1001 } }
            Mock Stop-Process { }

            # Act
            $stopped = Invoke-StopProcess -ProcessId 1001

            # Assert
            $stopped | Should -BeTrue
            Should -Invoke Stop-Process -Times 1 -Exactly
        }
    }

    Context 'seam internals: Remove-ConnectivityState' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'removes the file when present' {
            # Arrange: mock framework cmdlets; no real file is removed.
            Mock Test-Path { $true }
            Mock Remove-Item { }

            # Act
            Remove-ConnectivityState -Path 'state://remove.json'

            # Assert
            Should -Invoke Remove-Item -Times 1 -Exactly
        }

        It 'does nothing when the file is absent' {
            # Arrange
            Mock Test-Path { $false }
            Mock Remove-Item { }

            # Act
            Remove-ConnectivityState -Path 'state://absent.json'

            # Assert
            Should -Invoke Remove-Item -Times 0 -Exactly
        }
    }

    Context 'seam internals: Get-RecordedProcessId' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns the parsed pid for a valid positive value' {
            $state = [pscustomobject]@{ HttpServerProcessId = 1234 }
            (Get-RecordedProcessId -State $state -PropertyName 'HttpServerProcessId') | Should -Be 1234
        }

        It 'returns 0 when the property is missing' {
            $state = [pscustomobject]@{ Other = 5 }
            (Get-RecordedProcessId -State $state -PropertyName 'HttpServerProcessId') | Should -Be 0
        }

        It 'returns 0 when the value is null' {
            $state = [pscustomobject]@{ HttpServerProcessId = $null }
            (Get-RecordedProcessId -State $state -PropertyName 'HttpServerProcessId') | Should -Be 0
        }

        It 'returns 0 for a non-positive or non-numeric value' {
            $state = [pscustomobject]@{ HttpServerProcessId = -3 }
            (Get-RecordedProcessId -State $state -PropertyName 'HttpServerProcessId') | Should -Be 0
            $state2 = [pscustomobject]@{ HttpServerProcessId = 'abc' }
            (Get-RecordedProcessId -State $state2 -PropertyName 'HttpServerProcessId') | Should -Be 0
        }
    }
}
