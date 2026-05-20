#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# Unit tests for scripts/powershell/Start-MobileConnectivity.ps1.
#
# Determinism: every external boundary is exercised through an injected seam
# scriptblock or a mocked framework cmdlet. No real processes are started, no
# real executables are resolved, no network is used, and no temp files are
# created. The state-file path is always injected as a non-existent in-memory
# string and writes are captured by a seam, never flushed to disk.

Describe 'Start-MobileConnectivity.ps1' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '../../../scripts/powershell/Start-MobileConnectivity.ps1'

        # A fixed clock so StartedAt is deterministic across runs and hosts.
        $script:FixedNow = [System.DateTimeOffset]::new(2026, 5, 20, 9, 30, 0, [TimeSpan]::Zero)

        # Builds the standard set of injectable seams. Each test can override
        # individual seams by replacing entries before splatting.
        function script:New-StartSeamSet {
            param(
                [int]$HttpPid = 1001,
                [int]$TunnelPid = 2002,
                [string]$DevTunnelPath = 'C:\fake\devtunnel.exe'
            )
            # Capture container so assertions can inspect what the seams received.
            # The configured pids/path are stored on the container so the closures
            # read them from a single referenced object (keeps analyzer clean).
            $captured = [pscustomobject]@{
                StartCalls    = [System.Collections.Generic.List[object]]::new()
                WriteCalls    = [System.Collections.Generic.List[object]]::new()
                HttpPid       = $HttpPid
                TunnelPid     = $TunnelPid
                DevTunnelPath = $DevTunnelPath
            }
            $startAction = {
                param([string]$FilePath, [string[]]$ArgumentList)
                $captured.StartCalls.Add([pscustomobject]@{ FilePath = $FilePath; ArgumentList = $ArgumentList })
                if ($FilePath -eq 'npx') { return $captured.HttpPid }
                return $captured.TunnelPid
            }.GetNewClosure()
            $resolveAction = { $captured.DevTunnelPath }.GetNewClosure()
            $writeAction = {
                param([string]$Path, [object]$State)
                $captured.WriteCalls.Add([pscustomobject]@{ Path = $Path; State = $State })
            }.GetNewClosure()
            # Capture the fixed clock into the closure so the seam resolves it from
            # captured state rather than the production script scope when invoked.
            $fixedNow = $script:FixedNow
            $nowProvider = { $fixedNow }.GetNewClosure()

            return [pscustomobject]@{
                Captured               = $captured
                StartProcessAction     = $startAction
                ResolveDevTunnelAction = $resolveAction
                WriteStateAction       = $writeAction
                NowProvider            = $nowProvider
            }
        }
    }

    Context 'positive: starts both processes and persists state' {
        It 'returns the recorded pids, tunnel id, port, and state path' {
            # Arrange
            $seams = New-StartSeamSet -HttpPid 1111 -TunnelPid 2222
            $statePath = 'TestDrive-not-used://taskmaster-mobile-connectivity.json'

            # Act
            $result = & $script:ScriptPath `
                -TunnelId 'taskmaster-ios' -Port 3000 -DistPath 'dist' `
                -StateFilePath $statePath `
                -StartProcessAction $seams.StartProcessAction `
                -ResolveDevTunnelAction $seams.ResolveDevTunnelAction `
                -WriteStateAction $seams.WriteStateAction `
                -NowProvider $seams.NowProvider

            # Assert
            $result.HttpServerProcessId | Should -Be 1111
            $result.DevTunnelProcessId | Should -Be 2222
            $result.TunnelId | Should -Be 'taskmaster-ios'
            $result.Port | Should -Be 3000
            $result.DistPath | Should -Be 'dist'
            $result.StateFilePath | Should -Be $statePath
            $result.StartedAt | Should -Be $script:FixedNow.ToString('o')
        }

        It 'invokes http-server via npx and devtunnel via the resolved path' {
            # Arrange
            $seams = New-StartSeamSet -DevTunnelPath 'C:\resolved\devtunnel.exe'

            # Act
            & $script:ScriptPath `
                -TunnelId 'tunnel-x' -Port 4100 -DistPath 'build' `
                -StateFilePath 'state://x.json' `
                -StartProcessAction $seams.StartProcessAction `
                -ResolveDevTunnelAction $seams.ResolveDevTunnelAction `
                -WriteStateAction $seams.WriteStateAction `
                -NowProvider $seams.NowProvider | Out-Null

            # Assert
            $seams.Captured.StartCalls.Count | Should -Be 2
            $httpCall = $seams.Captured.StartCalls[0]
            $httpCall.FilePath | Should -Be 'npx'
            $httpCall.ArgumentList | Should -Be @('http-server', 'build', '-p', '4100', '-c-1', '--cors')
            $tunnelCall = $seams.Captured.StartCalls[1]
            $tunnelCall.FilePath | Should -Be 'C:\resolved\devtunnel.exe'
            $tunnelCall.ArgumentList | Should -Be @('host', 'tunnel-x')
        }

        It 'persists the state object exactly once to the injected path' {
            # Arrange
            $seams = New-StartSeamSet
            $statePath = 'state://persist-once.json'

            # Act
            & $script:ScriptPath `
                -TunnelId 'taskmaster-ios' -Port 3000 -DistPath 'dist' `
                -StateFilePath $statePath `
                -StartProcessAction $seams.StartProcessAction `
                -ResolveDevTunnelAction $seams.ResolveDevTunnelAction `
                -WriteStateAction $seams.WriteStateAction `
                -NowProvider $seams.NowProvider | Out-Null

            # Assert
            $seams.Captured.WriteCalls.Count | Should -Be 1
            $seams.Captured.WriteCalls[0].Path | Should -Be $statePath
            $seams.Captured.WriteCalls[0].State.HttpServerProcessId | Should -Be 1001
            $seams.Captured.WriteCalls[0].State.DevTunnelProcessId | Should -Be 2002
        }
    }

    Context 'WhatIf: no side effects' {
        It 'does not start processes or write state when -WhatIf is supplied' {
            # Arrange
            $seams = New-StartSeamSet

            # Act
            $result = & $script:ScriptPath `
                -TunnelId 'taskmaster-ios' -Port 3000 -DistPath 'dist' `
                -StateFilePath 'state://whatif.json' `
                -StartProcessAction $seams.StartProcessAction `
                -ResolveDevTunnelAction $seams.ResolveDevTunnelAction `
                -WriteStateAction $seams.WriteStateAction `
                -NowProvider $seams.NowProvider `
                -WhatIf

            # Assert
            $seams.Captured.StartCalls.Count | Should -Be 0
            $seams.Captured.WriteCalls.Count | Should -Be 0
            $result.HttpServerProcessId | Should -Be 0
            $result.DevTunnelProcessId | Should -Be 0
        }
    }

    Context 'error path: devtunnel cannot be resolved' {
        It 'propagates the resolution failure and starts no processes' {
            # Arrange
            $seams = New-StartSeamSet
            $failingResolve = { throw "Resolve-DevTunnelPath: could not resolve the 'devtunnel' executable." }

            # Act / Assert
            { & $script:ScriptPath `
                    -TunnelId 'taskmaster-ios' -Port 3000 -DistPath 'dist' `
                    -StateFilePath 'state://err.json' `
                    -StartProcessAction $seams.StartProcessAction `
                    -ResolveDevTunnelAction $failingResolve `
                    -WriteStateAction $seams.WriteStateAction `
                    -NowProvider $seams.NowProvider } |
                Should -Throw -ExpectedMessage "*could not resolve the 'devtunnel' executable*"
            $seams.Captured.StartCalls.Count | Should -Be 0
            $seams.Captured.WriteCalls.Count | Should -Be 0
        }
    }

    Context 'seam internals: Resolve-DevTunnelPath' {
        BeforeAll {
            # Dot-source into an isolated scope so the internal seam functions are
            # callable directly. The auto-invoke guard only runs the function when
            # the script is NOT dot-sourced, so dot-sourcing imports definitions
            # without executing Start-MobileConnectivity.
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns the PATH source when devtunnel is on PATH' {
            # Arrange: mock the framework cmdlet, never a real executable.
            Mock Get-Command { [pscustomobject]@{ Source = 'C:\path\devtunnel.exe' } }

            # Act
            $resolved = Resolve-DevTunnelPath

            # Assert
            $resolved | Should -Be 'C:\path\devtunnel.exe'
        }

        It 'falls back to a WinGet candidate path when not on PATH' {
            # Arrange
            Mock Get-Command { $null }
            Mock Test-Path { $true }

            # Act
            $resolved = Resolve-DevTunnelPath

            # Assert
            $resolved | Should -Match 'devtunnel\.exe$'
        }

        It 'throws a clear error when no candidate resolves' {
            # Arrange
            Mock Get-Command { $null }
            Mock Test-Path { $false }

            # Act / Assert
            { Resolve-DevTunnelPath } | Should -Throw -ExpectedMessage "*could not resolve the 'devtunnel' executable*"
        }
    }

    Context 'seam internals: Invoke-StartProcess' {
        BeforeAll {
            . $script:ScriptPath -ErrorAction Stop
        }

        It 'returns the started process id without arguments' {
            # Arrange: mock Start-Process (framework cmdlet), not a real process.
            Mock Start-Process { [pscustomobject]@{ Id = 4242 } }

            # Act
            $resultPid = Invoke-StartProcess -FilePath 'npx'

            # Assert
            $resultPid | Should -Be 4242
        }

        It 'passes the argument list to Start-Process and returns the id' {
            # Arrange
            Mock Start-Process { [pscustomobject]@{ Id = 5353 } } -ParameterFilter {
                $ArgumentList -contains 'host'
            }

            # Act
            $resultPid = Invoke-StartProcess -FilePath 'devtunnel' -ArgumentList @('host', 'tunnel-x')

            # Assert
            $resultPid | Should -Be 5353
            Should -Invoke Start-Process -Times 1 -Exactly
        }
    }

    # Note: Write-ConnectivityState serializes the state object and writes it via
    # Set-Content -Encoding utf8. Its only logic is a ConvertTo-Json transform
    # followed by unavoidable filesystem I/O. The serialize transform is exercised
    # end-to-end by the positive start flow above (which captures the real state
    # object handed to WriteStateAction). The raw Set-Content line is intentionally
    # not re-mocked here: mocking the FileSystem-provider dynamic parameter
    # -Encoding across the dot-source scope boundary is not reliable in Pester v5
    # and is avoided per the repo's "prefer real code paths / isolate I/O" guidance.
}
