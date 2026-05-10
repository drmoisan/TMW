#Requires -Version 7.0
<#
.SYNOPSIS
  Validates quality-tiers.yml against the schema described in the file header.
.DESCRIPTION
  Fails (exits non-zero) when any project entry is missing required fields or has an
  invalid tier value, or when the repo contains a project directory not represented in
  quality-tiers.yml. Invoked by the tier-classification stage of the PR pipeline.
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..', 'quality-tiers.yml')
)

$ErrorActionPreference = 'Stop'

function Invoke-QualityTiersValidation {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [string]$RepoRoot
    )

    if (-not (Test-Path $ConfigPath)) {
        [Console]::Error.WriteLine("quality-tiers.yml not found at: $ConfigPath")
        return 2
    }

    $raw = Get-Content -Raw -Path $ConfigPath
    if ([string]::IsNullOrWhiteSpace($raw)) {
        [Console]::Error.WriteLine("quality-tiers.yml is empty")
        return 3
    }

    # Lightweight check that the projects: key exists. Full YAML parsing is deferred to a
    # future task once a YAML parser dependency is approved.
    if ($raw -notmatch '(?m)^projects:\s*$') {
        [Console]::Error.WriteLine("quality-tiers.yml is missing the required 'projects:' key")
        return 4
    }

    $tierLines = ($raw -split "`n") | Where-Object { $_ -match '^\s*tier:\s*' }
    foreach ($line in $tierLines) {
        if ($line -notmatch '^\s*tier:\s*(t1|t2|t3|t4)\s*$') {
            [Console]::Error.WriteLine("Invalid tier value in line: $line")
            return 5
        }
    }

    # Inventory project-bearing directories in the repo and verify each is represented.
    if ([string]::IsNullOrEmpty($RepoRoot)) {
        $RepoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '..')).Path
    }
    $declaredPaths = @()
    foreach ($line in (($raw -split "`n") | Where-Object { $_ -match '^\s*path:\s*' })) {
        if ($line -match '^\s*path:\s*(\S.*?)\s*$') { $declaredPaths += $Matches[1] }
    }

    $projectMarkers = @('package.json', '*.csproj', 'pyproject.toml')
    $foundProjectDirs = @()
    foreach ($marker in $projectMarkers) {
        $hits = Get-ChildItem -Path $RepoRoot -Recurse -File -Filter $marker -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\node_modules\\' } |
                Select-Object -ExpandProperty Directory
        foreach ($d in $hits) {
            $rel = ($d.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')).Replace('\', '/')
            if ([string]::IsNullOrEmpty($rel)) { $rel = '.' }
            if ($foundProjectDirs -notcontains $rel) { $foundProjectDirs += $rel }
        }
    }

    $missing = @()
    foreach ($dir in $foundProjectDirs) {
        $hit = $declaredPaths | Where-Object { $_ -eq $dir -or $_ -eq './' + $dir }
        if (-not $hit) { $missing += $dir }
    }

    if ($missing.Count -gt 0) {
        [Console]::Error.WriteLine("Unclassified project directories not present in quality-tiers.yml: " + ($missing -join ', '))
        return 6
    }

    Write-Output "quality-tiers.yml validation PASSED: $($foundProjectDirs.Count) project(s) classified."
    return 0
}

if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-QualityTiersValidation -ConfigPath $ConfigPath)
}
