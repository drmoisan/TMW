#Requires -Version 7.0
<#
.SYNOPSIS
    Starts the two background processes used to establish Outlook Mobile (iOS)
    connectivity for the add-in: a static HTTP server for the built bundle and a
    Microsoft Dev Tunnel host that exposes it over trusted HTTPS.

.DESCRIPTION
    Starts two long-lived background processes used during on-device iOS
    verification:
      1. A static HTTP server serving the built 'dist/' folder on the chosen
         port, equivalent to: npx http-server dist -p 3000 -c-1 --cors
      2. A Microsoft Dev Tunnel host that exposes that local port over trusted
         HTTPS, equivalent to: devtunnel host <TunnelId>

    The process ids, tunnel id, port, and a started-at timestamp are persisted as
    a small JSON state object to -StateFilePath so Stop-MobileConnectivity.ps1 can
    later stop the same processes.

    The 'devtunnel' executable is resolved robustly: Get-Command first, then the
    WinGet Links shim, then the WinGet Packages path. Resolution fails with a
    clear error when none resolve.

    PREREQUISITE (not performed by this script): the bundle must be built with
    'npm run build' and 'urlProd' in webpack.config.js set to the Dev Tunnel URL
    before starting connectivity. This script does not modify webpack.config.js,
    does not set urlProd, and does not run the build.

.PARAMETER TunnelId
    The Microsoft Dev Tunnel id to host. Defaults to 'taskmaster-ios'.

.PARAMETER Port
    The local TCP port the static HTTP server listens on. Defaults to 3000.

.PARAMETER DistPath
    The folder served by the static HTTP server. Defaults to 'dist'.

.PARAMETER StateFilePath
    Path to the JSON state file recording the started process ids. Defaults to a
    deterministic file in the OS temp directory.

.PARAMETER StartProcessAction
    Optional seam returning a process id for a started external process. Defaults
    to Invoke-StartProcess. Injected by tests for determinism.

.PARAMETER ResolveDevTunnelAction
    Optional seam returning the resolved devtunnel executable path. Defaults to
    Resolve-DevTunnelPath. Injected by tests for determinism.

.PARAMETER WriteStateAction
    Optional seam that persists the state object to disk. Defaults to
    Write-ConnectivityState. Injected by tests for determinism.

.PARAMETER NowProvider
    Optional clock seam returning a DateTimeOffset for the started-at timestamp.
    Defaults to the current UTC time. Injected by tests for determinism.

.OUTPUTS
    A [pscustomobject] describing the persisted state (HttpServerProcessId,
    DevTunnelProcessId, TunnelId, Port, DistPath, StartedAt, StateFilePath).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$TunnelId = 'taskmaster-ios',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 3000,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$DistPath = 'dist',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$StateFilePath = (Join-Path ([System.IO.Path]::GetTempPath()) 'taskmaster-mobile-connectivity.json'),

    [Parameter(Mandatory = $false)]
    [scriptblock]$StartProcessAction = { param([string]$FilePath, [string[]]$ArgumentList) Invoke-StartProcess -FilePath $FilePath -ArgumentList $ArgumentList },

    [Parameter(Mandatory = $false)]
    [scriptblock]$ResolveDevTunnelAction = { Resolve-DevTunnelPath },

    [Parameter(Mandatory = $false)]
    [scriptblock]$WriteStateAction = { param([string]$Path, [object]$State) Write-ConnectivityState -Path $Path -State $State },

    [Parameter(Mandatory = $false)]
    [scriptblock]$NowProvider = { [System.DateTimeOffset]::UtcNow }
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-DevTunnelPath {
    <#
    .SYNOPSIS
        Resolves the devtunnel executable path robustly. Seam for tests.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $onPath = Get-Command -Name 'devtunnel' -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -ne $onPath) {
        return $onPath.Source
    }

    $localAppData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)
    $candidatePaths = @(
        (Join-Path $localAppData 'Microsoft/WinGet/Links/devtunnel.exe'),
        (Join-Path $localAppData 'Microsoft/WinGet/Packages/Microsoft.devtunnel_Microsoft.Winget.Source_8wekyb3d8bbwe/devtunnel.exe')
    )

    foreach ($candidate in $candidatePaths) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    throw "Resolve-DevTunnelPath: could not resolve the 'devtunnel' executable. Checked PATH, the WinGet Links shim, and the WinGet Packages path. Install Dev Tunnels (winget install Microsoft.devtunnel) or add devtunnel to PATH."
}

function Invoke-StartProcess {
    <#
    .SYNOPSIS
        Starts an external process and returns its process id. Seam for tests.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$ArgumentList = @()
    )

    $startArgs = @{
        FilePath    = $FilePath
        PassThru    = $true
        ErrorAction = 'Stop'
    }
    if ($ArgumentList.Count -gt 0) {
        $startArgs['ArgumentList'] = $ArgumentList
    }

    $process = Start-Process @startArgs
    return [int]$process.Id
}

function Write-ConnectivityState {
    <#
    .SYNOPSIS
        Persists the connectivity state object to disk as JSON. Seam for tests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [object]$State
    )

    $json = $State | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath $Path -Value $json -Encoding utf8 -ErrorAction Stop
}

function Start-MobileConnectivity {
    <#
    .SYNOPSIS
        Starts the http-server and devtunnel host processes and persists state.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TunnelId,

        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [string]$DistPath,

        [Parameter(Mandatory = $true)]
        [string]$StateFilePath,

        [Parameter(Mandatory = $true)]
        [scriptblock]$StartProcessAction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ResolveDevTunnelAction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$WriteStateAction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$NowProvider
    )

    $devTunnelPath = & $ResolveDevTunnelAction

    $httpServerArgs = @('http-server', $DistPath, '-p', [string]$Port, '-c-1', '--cors')
    $devTunnelArgs = @('host', $TunnelId)

    $httpServerProcessId = 0
    $devTunnelProcessId = 0

    if ($PSCmdlet.ShouldProcess("http-server $DistPath -p $Port -c-1 --cors", 'Start static HTTP server')) {
        $httpServerProcessId = [int](& $StartProcessAction 'npx' $httpServerArgs)
    }

    if ($PSCmdlet.ShouldProcess("devtunnel host $TunnelId", 'Start Dev Tunnel host')) {
        $devTunnelProcessId = [int](& $StartProcessAction $devTunnelPath $devTunnelArgs)
    }

    $startedAt = (& $NowProvider).ToString('o')

    $state = [pscustomobject]@{
        HttpServerProcessId = $httpServerProcessId
        DevTunnelProcessId  = $devTunnelProcessId
        TunnelId            = $TunnelId
        Port                = $Port
        DistPath            = $DistPath
        StartedAt           = $startedAt
    }

    if ($PSCmdlet.ShouldProcess($StateFilePath, 'Write connectivity state file')) {
        & $WriteStateAction $StateFilePath $state
    }

    Write-Information "Started http-server (pid $httpServerProcessId) and devtunnel host (pid $devTunnelProcessId) for tunnel '$TunnelId' on port $Port." -InformationAction Continue
    Write-Information "Reminder: the bundle must be built with 'npm run build' and webpack.config.js 'urlProd' set to the Dev Tunnel URL before this connectivity is usable." -InformationAction Continue

    return ([pscustomobject]@{
            HttpServerProcessId = $httpServerProcessId
            DevTunnelProcessId  = $devTunnelProcessId
            TunnelId            = $TunnelId
            Port                = $Port
            DistPath            = $DistPath
            StartedAt           = $startedAt
            StateFilePath       = $StateFilePath
        })
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-MobileConnectivity `
        -TunnelId $TunnelId `
        -Port $Port `
        -DistPath $DistPath `
        -StateFilePath $StateFilePath `
        -StartProcessAction $StartProcessAction `
        -ResolveDevTunnelAction $ResolveDevTunnelAction `
        -WriteStateAction $WriteStateAction `
        -NowProvider $NowProvider `
        -WhatIf:$WhatIfPreference
}
