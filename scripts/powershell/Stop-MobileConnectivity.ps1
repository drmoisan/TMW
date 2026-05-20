#Requires -Version 7.0
<#
.SYNOPSIS
    Stops the two background processes started by Start-MobileConnectivity.ps1
    for Outlook Mobile (iOS) connectivity, then removes the state file.

.DESCRIPTION
    Reads the JSON state file written by Start-MobileConnectivity.ps1, stops both
    recorded processes by process id (the static HTTP server and the Microsoft
    Dev Tunnel host), then deletes the state file.

    If the state file is missing, a clear warning is emitted and the script exits
    non-fatally without attempting to stop any process.

    Process stop and existence checks are isolated behind seam functions so the
    behavior is unit-testable without touching real processes.

.PARAMETER StateFilePath
    Path to the JSON state file recording the started process ids. Defaults to a
    deterministic file in the OS temp directory, matching the default used by
    Start-MobileConnectivity.ps1.

.PARAMETER ReadStateAction
    Optional seam returning the parsed state object, or $null when the state file
    is absent. Defaults to Read-ConnectivityState. Injected by tests.

.PARAMETER StopProcessAction
    Optional seam that stops a process by id. Defaults to Invoke-StopProcess.
    Injected by tests for determinism.

.PARAMETER RemoveStateAction
    Optional seam that removes the state file. Defaults to Remove-ConnectivityState.
    Injected by tests for determinism.

.OUTPUTS
    A [pscustomobject] describing the stop outcome (StateFileFound, StoppedProcessIds).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$StateFilePath = (Join-Path ([System.IO.Path]::GetTempPath()) 'taskmaster-mobile-connectivity.json'),

    [Parameter(Mandatory = $false)]
    [scriptblock]$ReadStateAction = { param([string]$Path) Read-ConnectivityState -Path $Path },

    [Parameter(Mandatory = $false)]
    [scriptblock]$StopProcessAction = { param([int]$ProcessId) Invoke-StopProcess -ProcessId $ProcessId },

    [Parameter(Mandatory = $false)]
    [scriptblock]$RemoveStateAction = { param([string]$Path) Remove-ConnectivityState -Path $Path }
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-ConnectivityState {
    <#
    .SYNOPSIS
        Reads and parses the connectivity state file, or returns $null when the
        file does not exist. Seam for tests.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    return ($raw | ConvertFrom-Json -ErrorAction Stop)
}

function Invoke-StopProcess {
    <#
    .SYNOPSIS
        Stops a process by id. Returns $true when a process was stopped, $false
        when no matching running process existed. Seam for tests.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($null -eq $process) {
        return $false
    }

    Stop-Process -Id $ProcessId -Force -ErrorAction Stop
    return $true
}

function Remove-ConnectivityState {
    <#
    .SYNOPSIS
        Removes the connectivity state file if present. Seam for tests.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        if ($PSCmdlet.ShouldProcess($Path, 'Remove connectivity state file')) {
            Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
        }
    }
}

function Get-RecordedProcessId {
    <#
    .SYNOPSIS
        Reads a process-id property from the state object, returning 0 when the
        property is absent or non-positive.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$State,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    if ($State.PSObject.Properties.Name -notcontains $PropertyName) {
        return 0
    }

    $value = $State.$PropertyName
    if ($null -eq $value) {
        return 0
    }

    $parsed = 0
    if (-not [int]::TryParse([string]$value, [ref]$parsed) -or $parsed -le 0) {
        return 0
    }

    return $parsed
}

function Stop-MobileConnectivity {
    <#
    .SYNOPSIS
        Stops the recorded http-server and devtunnel host processes and removes
        the state file.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StateFilePath,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ReadStateAction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$StopProcessAction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$RemoveStateAction
    )

    $state = & $ReadStateAction $StateFilePath
    if ($null -eq $state) {
        Write-Warning "Stop-MobileConnectivity: state file '$StateFilePath' was not found. No background processes were stopped. If processes are still running, stop them manually."
        return ([pscustomobject]@{
                StateFileFound    = $false
                StoppedProcessIds = @()
            })
    }

    $recordedIds = @(
        (Get-RecordedProcessId -State $state -PropertyName 'HttpServerProcessId'),
        (Get-RecordedProcessId -State $state -PropertyName 'DevTunnelProcessId')
    ) | Where-Object { $_ -gt 0 }

    $stopped = [System.Collections.Generic.List[int]]::new()
    foreach ($processId in $recordedIds) {
        if ($PSCmdlet.ShouldProcess("process id $processId", 'Stop process')) {
            $wasStopped = [bool](& $StopProcessAction $processId)
            if ($wasStopped) {
                $stopped.Add($processId)
            }
            else {
                Write-Warning "Stop-MobileConnectivity: process id $processId was not running; nothing to stop."
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($StateFilePath, 'Remove connectivity state file')) {
        & $RemoveStateAction $StateFilePath
    }

    Write-Information "Stopped $($stopped.Count) recorded process(es) and removed the state file '$StateFilePath'." -InformationAction Continue

    return ([pscustomobject]@{
            StateFileFound    = $true
            StoppedProcessIds = $stopped.ToArray()
        })
}

if ($MyInvocation.InvocationName -ne '.') {
    Stop-MobileConnectivity `
        -StateFilePath $StateFilePath `
        -ReadStateAction $ReadStateAction `
        -StopProcessAction $StopProcessAction `
        -RemoveStateAction $RemoveStateAction `
        -WhatIf:$WhatIfPreference
}
