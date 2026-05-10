#Requires -Version 7.0
<#
.SYNOPSIS
  Idempotent gitleaks installer (Windows-first, with linux/macos branches for CI).
.DESCRIPTION
  Resolves the gitleaks binary via two channels in this order:
    1. winget install --id gitleaks.gitleaks --silent (Windows interactive/CI).
    2. gh release download from gitleaks/gitleaks (asset matching the host OS+arch),
       extracted into <repo>/.tools/gitleaks/.
  Writes the resolved binary path to stdout. Idempotent: if the binary already
  resolves on PATH or under .tools/gitleaks/, exits 0 without re-installing.
.PARAMETER Version
  Optional pinned release tag (e.g. v8.18.4). Default: latest.
.PARAMETER ToolsDir
  Local install directory. Default: <repo>/.tools/gitleaks.
#>
[CmdletBinding()]
param(
    [string]$Version = 'latest',
    [string]$ToolsDir = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..', '.tools', 'gitleaks')
)

$ErrorActionPreference = 'Stop'

function Resolve-GitleaksOnPath {
    $cmd = Get-Command -Name gitleaks -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Resolve-GitleaksInToolsDir {
    param([string]$Dir)
    $exe = if ($IsWindows) { 'gitleaks.exe' } else { 'gitleaks' }
    $candidate = Join-Path -Path $Dir -ChildPath $exe
    if (Test-Path -LiteralPath $candidate) { return (Resolve-Path $candidate).Path }
    return $null
}

$existing = Resolve-GitleaksOnPath
if ($existing) {
    Write-Output $existing
    exit 0
}
$existing = Resolve-GitleaksInToolsDir -Dir $ToolsDir
if ($existing) {
    Write-Output $existing
    exit 0
}

if ($IsWindows) {
    $winget = Get-Command -Name winget -ErrorAction SilentlyContinue
    if ($winget) {
        & winget install --id gitleaks.gitleaks --silent --accept-package-agreements --accept-source-agreements
        $resolved = Resolve-GitleaksOnPath
        if ($resolved) {
            Write-Output $resolved
            exit 0
        }
    }
}

if (-not (Test-Path -LiteralPath $ToolsDir)) {
    New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
}

$assetPattern = if ($IsWindows) { 'gitleaks_*_windows_x64.zip' }
elseif ($IsMacOS) { 'gitleaks_*_darwin_x64.tar.gz' }
else { 'gitleaks_*_linux_x64.tar.gz' }

$ghArgs = @('release', 'download')
if ($Version -ne 'latest') { $ghArgs += @($Version) }
$ghArgs += @('-R', 'gitleaks/gitleaks', '-p', $assetPattern, '-D', $ToolsDir, '--clobber')
& gh @ghArgs
if ($LASTEXITCODE -ne 0) {
    throw "gh release download failed with exit $LASTEXITCODE"
}

$archive = Get-ChildItem -Path $ToolsDir -Filter $assetPattern | Select-Object -First 1
if (-not $archive) { throw "No gitleaks archive matched $assetPattern under $ToolsDir" }

if ($archive.Extension -eq '.zip') {
    Expand-Archive -Path $archive.FullName -DestinationPath $ToolsDir -Force
}
else {
    tar -xzf $archive.FullName -C $ToolsDir
    if ($LASTEXITCODE -ne 0) { throw "tar extract failed with exit $LASTEXITCODE" }
}

$resolved = Resolve-GitleaksInToolsDir -Dir $ToolsDir
if (-not $resolved) { throw "gitleaks binary not found in $ToolsDir after extraction" }
Write-Output $resolved
exit 0
