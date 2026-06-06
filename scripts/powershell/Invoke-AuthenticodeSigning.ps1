#Requires -Version 7.0
<#
.SYNOPSIS
    Applies Authenticode signatures to first-party PowerShell scripts and built
    first-party .NET assemblies as a build/release-time step (Model B). Signatures
    are not committed into source.

.DESCRIPTION
    Resolves a code-signing certificate by thumbprint from configuration (dotnet
    user-secrets store id 3716a8f0-9bab-4f69-a7b9-4173cda73ff3, key
    'Signing:CertThumbprint'), enumerates the in-scope first-party PowerShell
    scripts (or signs exactly the files passed via -FilePaths), signs each with
    SHA256 and an RFC3161 timestamp, and verifies the resulting status on the
    signing machine.

    Configuration is resolved before any file is signed; a configuration or
    certificate failure aborts the run before any side effect. The thumbprint is
    never hardcoded in this script.

    Configuration resolution, certificate resolution, file enumeration, and the
    signing call are isolated behind injectable scriptblock seams
    (ReadSecretsAction, ResolveCertAction, EnumerateFilesAction, SignFileAction)
    so the orchestration is deterministically unit-testable without a real
    certificate and without creating temporary files.

.NOTES
    BOOTSTRAP EXECUTION POLICY (first run of the unsigned signer):
    This signing script is itself unsigned until it has been signed (a bootstrap
    condition). On a machine whose PowerShell execution policy would block an
    unsigned script, run the first invocation with an execution-policy bypass, for
    example:

        pwsh -ExecutionPolicy Bypass -File ./scripts/powershell/Invoke-AuthenticodeSigning.ps1

    or, for the current process only:

        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted

    After the script (and the other first-party scripts) have been signed and the
    signing certificate is trusted on the machine, the bypass is no longer
    required.

    SELF-SIGNED TRUST LIMITATION:
    The signing certificate is a personal/self-issued certificate. Signatures
    validate as 'Valid' only on machines that trust the certificate. On machines
    that do not trust it, Get-AuthenticodeSignature reports a non-'Valid' status;
    this is a trust limitation of self-issued certificates, not a defect.

.PARAMETER RepoRoot
    Root directory scanned for in-scope scripts. Defaults to the current directory.

.PARAMETER ConfigKey
    Configuration key holding the certificate thumbprint. Defaults to
    'Signing:CertThumbprint'.

.PARAMETER SecretsJsonPath
    Path to the dotnet user-secrets secrets.json. Defaults to the canonical path
    for store 3716a8f0-9bab-4f69-a7b9-4173cda73ff3.

.PARAMETER TimestampServer
    RFC3161 timestamp endpoint. Defaults to http://timestamp.digicert.com.

.PARAMETER FilePaths
    Explicit file list. When provided, signs exactly these files (used for
    post-publish first-party .NET assembly signing) instead of enumerating
    PowerShell scripts.

.PARAMETER ReadSecretsAction
    Seam returning the thumbprint from secrets. Defaults to Read-SigningThumbprint.

.PARAMETER ResolveCertAction
    Seam returning the resolved signing certificate. Defaults to Resolve-SigningCert.

.PARAMETER EnumerateFilesAction
    Seam returning the in-scope file list. Defaults to Get-FirstPartySignableFileList.

.PARAMETER SignFileAction
    Seam applying the signature to one file. Defaults to Invoke-SetAuthenticodeSignature.

.OUTPUTS
    A [pscustomobject] summarizing the run (Signed, Skipped, Warnings, Failed).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoRoot = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$ConfigKey = 'Signing:CertThumbprint',

    [Parameter(Mandatory = $false)]
    [string]$SecretsJsonPath = (Join-Path $env:APPDATA 'Microsoft\UserSecrets\3716a8f0-9bab-4f69-a7b9-4173cda73ff3\secrets.json'),

    [Parameter(Mandatory = $false)]
    [string]$TimestampServer = 'http://timestamp.digicert.com',

    [Parameter(Mandatory = $false)]
    [AllowEmptyCollection()]
    [string[]]$FilePaths = @(),

    [Parameter(Mandatory = $false)]
    [scriptblock]$ReadSecretsAction = { param([string]$JsonPath, [string]$Key) Read-SigningThumbprint -JsonPath $JsonPath -Key $Key },

    [Parameter(Mandatory = $false)]
    [scriptblock]$ResolveCertAction = { param([string]$Thumbprint) Resolve-SigningCert -Thumbprint $Thumbprint },

    [Parameter(Mandatory = $false)]
    [scriptblock]$EnumerateFilesAction = { param([string]$Root) Get-FirstPartySignableFileList -Root $Root },

    [Parameter(Mandatory = $false)]
    [scriptblock]$SignFileAction = { param([string]$Path, [object]$Cert, [string]$Ts) Invoke-SetAuthenticodeSignature -Path $Path -Cert $Cert -TimestampServer $Ts }
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-SigningThumbprint {
    <#
    .SYNOPSIS
        Reads and validates the certificate thumbprint from a dotnet user-secrets
        secrets.json. Fails fast with actionable errors. Pure JSON read; seam-able.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonPath,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    if (-not (Test-Path -LiteralPath $JsonPath)) {
        throw "Signing config not found at '$JsonPath'. Run: dotnet user-secrets set 'Signing:CertThumbprint' '<thumbprint>' --id 3716a8f0-9bab-4f69-a7b9-4173cda73ff3"
    }

    try {
        $secrets = Get-Content -LiteralPath $JsonPath -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Failed to parse signing config JSON at '$JsonPath': $($_.Exception.Message)"
    }

    $thumbprint = $null
    if ($null -ne $secrets -and ($secrets.PSObject.Properties.Name -contains $Key)) {
        $thumbprint = $secrets.$Key
    }

    if ([string]::IsNullOrWhiteSpace($thumbprint)) {
        throw "Config key '$Key' not found or empty in '$JsonPath'."
    }

    return [string]$thumbprint
}

function Test-IsExcludedRelativePath {
    <#
    .SYNOPSIS
        Pure predicate: returns $true when a repo-relative path lies under an
        excluded root ('node_modules' or 'artifacts'). Separator-agnostic. No
        filesystem access.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$RelativePath
    )

    $normalized = $RelativePath -replace '\\', '/'
    $normalized = $normalized.TrimStart('/')
    foreach ($excludedRoot in @('node_modules', 'artifacts')) {
        if ($normalized -eq $excludedRoot -or $normalized.StartsWith($excludedRoot + '/')) {
            return $true
        }
    }

    return $false
}

function Get-FirstPartySignableFileList {
    <#
    .SYNOPSIS
        Enumerates in-scope first-party PowerShell scripts under -Root applying the
        include globs and the exclusion predicate. Missing subtrees are skipped
        without error. Host-bound directory access; seam-able.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $includeGlobs = @(
        '.githooks/**/*.ps1',
        '.github/scripts/**/*.ps1',
        'scripts/**/*.ps1',
        'scripts/**/*.psm1',
        'scripts/**/*.psd1',
        'tests/**/*.ps1',
        'tests/**/*.psd1',
        '.claude/hooks/**/*.ps1'
    )

    $rootFull = (Resolve-Path -LiteralPath $Root).Path
    $results = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($glob in $includeGlobs) {
        $segments = $glob -split '/'
        $subdir = $segments[0]
        $filter = $segments[-1]
        $searchPath = Join-Path $rootFull $subdir
        if (-not (Test-Path -LiteralPath $searchPath -PathType Container)) {
            continue
        }

        $hits = Get-ChildItem -Path $searchPath -Recurse -Filter $filter -File -ErrorAction SilentlyContinue
        foreach ($hit in $hits) {
            $relative = $hit.FullName.Substring($rootFull.Length).TrimStart('\', '/')
            if (Test-IsExcludedRelativePath -RelativePath $relative) {
                continue
            }
            if ($seen.Add($hit.FullName)) {
                $results.Add($hit.FullName)
            }
        }
    }

    return $results.ToArray()
}

function Resolve-SigningCert {
    <#
    .SYNOPSIS
        Resolves the signing certificate from Cert:\CurrentUser\My by thumbprint,
        requiring a private key and the Code Signing EKU. Fails fast otherwise.
        Host-bound cert-store access; seam-able. Kept minimal.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Thumbprint
    )

    $cert = Get-ChildItem -Path 'Cert:\CurrentUser\My' |
        Where-Object { $_.Thumbprint -eq $Thumbprint -and $_.HasPrivateKey } |
            Select-Object -First 1

    if ($null -eq $cert) {
        throw "No certificate with thumbprint '$Thumbprint' and HasPrivateKey=True found in Cert:\CurrentUser\My."
    }

    $hasCodeSigningEku = $false
    foreach ($ext in $cert.Extensions) {
        if ($ext -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]) {
            foreach ($oid in $ext.EnhancedKeyUsages) {
                if ($oid.Value -eq '1.3.6.1.5.5.7.3.3') {
                    $hasCodeSigningEku = $true
                }
            }
        }
    }

    if (-not $hasCodeSigningEku) {
        throw "Certificate with thumbprint '$Thumbprint' does not carry the Code Signing EKU (1.3.6.1.5.5.7.3.3)."
    }

    return $cert
}

function Invoke-SetAuthenticodeSignature {
    <#
    .SYNOPSIS
        Applies an Authenticode signature to one file with SHA256 and an RFC3161
        timestamp. A non-'Valid' signing-machine status is a per-file failure; an
        unreachable timestamp server warns and continues. Host-bound; seam-able.
        Kept minimal.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [object]$Cert,

        [Parameter(Mandatory = $true)]
        [string]$TimestampServer
    )

    $result = $null
    try {
        $result = Set-AuthenticodeSignature -FilePath $Path -Certificate $Cert -HashAlgorithm SHA256 -TimestampServer $TimestampServer -ErrorAction Stop
    }
    catch {
        Write-Warning "Timestamp server '$TimestampServer' unreachable for '$Path'; signing without a timestamp. Detail: $($_.Exception.Message)"
        $result = Set-AuthenticodeSignature -FilePath $Path -Certificate $Cert -HashAlgorithm SHA256 -ErrorAction Stop
    }

    if ($result.Status -ne 'Valid') {
        throw "Signing failed for '$Path': Status=$($result.Status)."
    }

    return $result
}

function Test-AuthenticodeSignature {
    <#
    .SYNOPSIS
        Verifies a file's Authenticode signature, returning $true when the
        signing-machine status is 'Valid'. Host-bound; seam-able.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $signature = Get-AuthenticodeSignature -FilePath $Path -ErrorAction Stop
    return ($signature.Status -eq 'Valid')
}

function Invoke-AuthenticodeSigning {
    <#
    .SYNOPSIS
        Orchestrates configuration/certificate resolution, file selection, and
        per-file signing through injected seams. Resolves config and certificate
        before any side effect; honors ShouldProcess/-WhatIf; reports a summary.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$ConfigKey,

        [Parameter(Mandatory = $true)]
        [string]$SecretsJsonPath,

        [Parameter(Mandatory = $true)]
        [string]$TimestampServer,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$FilePaths,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ReadSecretsAction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ResolveCertAction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$EnumerateFilesAction,

        [Parameter(Mandatory = $true)]
        [scriptblock]$SignFileAction
    )

    # Resolve configuration and certificate before any side effect. A failure here
    # aborts the run (throws) before any file is signed.
    $thumbprint = & $ReadSecretsAction $SecretsJsonPath $ConfigKey
    $cert = & $ResolveCertAction $thumbprint

    # Select files: explicit -FilePaths bypasses enumeration entirely.
    if ($FilePaths.Count -gt 0) {
        $targets = $FilePaths
    }
    else {
        $targets = @(& $EnumerateFilesAction $RepoRoot)
    }

    $signed = 0
    $skipped = 0
    $warnings = 0
    $failed = 0

    foreach ($target in $targets) {
        if (-not $PSCmdlet.ShouldProcess($target, 'Apply Authenticode signature')) {
            $skipped++
            Write-Information "WhatIf: would sign '$target'." -InformationAction Continue
            continue
        }

        try {
            $result = & $SignFileAction $target $cert $TimestampServer
            if ($null -ne $result -and $null -ne $result.Status -and $result.Status -ne 'Valid') {
                $failed++
                Write-Warning "Sign failed for '$target': Status=$($result.Status)."
                continue
            }
            $signed++
            if ($null -ne $result -and $result.PSObject.Properties.Name -contains 'TimestampWarning' -and $result.TimestampWarning) {
                $warnings++
                Write-Warning "Signed '$target' without a timestamp (timestamp server unreachable)."
            }
            Write-Information "Signed '$target'." -InformationAction Continue
        }
        catch {
            $failed++
            Write-Warning "Sign failed for '$target': $($_.Exception.Message)"
        }
    }

    Write-Information "Signing summary: signed=$signed skipped=$skipped warnings=$warnings failed=$failed." -InformationAction Continue

    $summary = [pscustomobject]@{
        Signed   = $signed
        Skipped  = $skipped
        Warnings = $warnings
        Failed   = $failed
        Success  = ($failed -eq 0)
    }

    if ($failed -gt 0) {
        $global:LASTEXITCODE = 1
    }

    return $summary
}

if ($MyInvocation.InvocationName -ne '.') {
    $runSummary = Invoke-AuthenticodeSigning `
        -RepoRoot $RepoRoot `
        -ConfigKey $ConfigKey `
        -SecretsJsonPath $SecretsJsonPath `
        -TimestampServer $TimestampServer `
        -FilePaths $FilePaths `
        -ReadSecretsAction $ReadSecretsAction `
        -ResolveCertAction $ResolveCertAction `
        -EnumerateFilesAction $EnumerateFilesAction `
        -SignFileAction $SignFileAction `
        -WhatIf:$WhatIfPreference

    # Emit the run summary to the pipeline so callers (and tests) receive it.
    $runSummary

    if ($null -ne $runSummary -and -not $runSummary.Success) {
        exit 1
    }
}
